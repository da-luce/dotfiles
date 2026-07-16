"""Omnigent tool: run haldir's locked verification gate (Phase 3).

Auto-discovered from tools/python/. Exposes one @tool-decorated function
(run_verification). This is the hard gate: the ONLY place a candidate is graded,
and it grades with real system exit codes, never with an LLM.

Every scoring call:
  * consumes one unit of the generation budget and aborts once it is spent
    (the loop-breaker guardrail),
  * recomputes the SHA-256 manifest of the frozen paths in the candidate's
    workdir and returns verdict "tampered" if a locked target changed (the
    immutable-test guardrail),
  * runs each locked check command natively and returns the real exit codes plus
    a continuous score (fraction of checks passed) for evolutionary selection,
    with full logs saved under .haldir/logs/ and tails returned inline.
"""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from omnigent_client import tool

_SKIP_DIRS = {".git", "__pycache__", ".haldir", "node_modules", ".venv"}
_TAIL_CHARS = 4000


def _control_root() -> Path:
    """The directory that owns .haldir/ (criteria, state, ledger, logs).

    Honors HALDIR_ROOT, else walks up from cwd looking for an existing
    .haldir/exit_criteria.json (so the tool works when called from a candidate
    worktree), else falls back to cwd.
    """
    env = os.environ.get("HALDIR_ROOT")
    if env:
        return Path(env).resolve()
    here = Path.cwd().resolve()
    for candidate in (here, *here.parents):
        if (candidate / ".haldir" / "exit_criteria.json").is_file():
            return candidate
    return here


def _hash_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _iter_files(path: Path):
    if path.is_file():
        yield path
        return
    for child in sorted(path.rglob("*")):
        if child.is_file() and not any(part in _SKIP_DIRS for part in child.parts):
            yield child


def _current_manifest(workdir: Path, immutable_paths: list[str]) -> dict[str, str]:
    manifest: dict[str, str] = {}
    for raw in immutable_paths:
        target = (workdir / raw).resolve()
        if not target.exists():
            continue
        for file in _iter_files(target):
            manifest[str(file.relative_to(workdir))] = _hash_file(file)
    return manifest


def _diff_manifest(locked: dict[str, str], current: dict[str, str]) -> dict:
    locked_keys = set(locked)
    current_keys = set(current)
    modified = sorted(k for k in locked_keys & current_keys if locked[k] != current[k])
    return {
        "modified": modified,
        "removed": sorted(locked_keys - current_keys),
        "added": sorted(current_keys - locked_keys),
    }


def _parse_scored(stdout: str) -> Optional[float]:
    for line in reversed(stdout.strip().splitlines()):
        line = line.strip()
        try:
            value = float(line)
        except ValueError:
            continue
        return max(0.0, min(1.0, value))
    return None


def _tail(text: str) -> str:
    if len(text) <= _TAIL_CHARS:
        return text
    return "...[truncated]...\n" + text[-_TAIL_CHARS:]


@tool(strict=False)
def run_verification(
    workdir: Optional[str] = None,
    label: Optional[str] = None,
    timeout_seconds: Optional[int] = 1800,
    count_attempt: bool = True,
) -> dict:
    """Run the locked exit criteria natively against a candidate and return the
    real, machine-decided verdict and score.

    Verdicts:
      * "pass"     - every check hit its expected exit code (score == 1.0).
      * "fail"     - at least one check failed (0 <= score < 1); route the raw
                     stderr back to a worker and refine.
      * "tampered" - a frozen immutable path changed in this candidate (reject;
                     the worker cheated).
      * "aborted"  - the generation budget is spent (stop and return the logs).

    Args:
        workdir: Directory to run the checks in (a candidate branch's worktree).
            Defaults to the control root (the dir owning .haldir/). Criteria,
            state, ledger, and logs always live under the control root.
        label: Short tag for this candidate (e.g. "gen2-codex"), used to name log
            files so parallel candidates do not clobber each other.
        timeout_seconds: Per-check wall-clock timeout. A timeout counts as a
            failed check (exit 124).
        count_attempt: Whether this evaluation consumes a unit of the generation
            budget. Set false only to re-grade after restoring a tampered file.
    """
    root = _control_root()
    criteria_path = root / ".haldir" / "exit_criteria.json"
    if not criteria_path.exists():
        raise RuntimeError(
            "no .haldir/exit_criteria.json; lock the criteria in Phase 1 "
            "(lock_exit_criteria) before verifying"
        )
    criteria = json.loads(criteria_path.read_text())
    if not criteria.get("locked"):
        raise RuntimeError("exit criteria exists but is not locked; re-lock it in Phase 1")

    cfg = criteria.get("config", {})
    budget = int(cfg.get("generation_budget", 10))

    state_path = root / ".haldir" / "state.json"
    state = json.loads(state_path.read_text()) if state_path.exists() else {"attempts": 0}
    attempts_used = int(state.get("attempts", 0))

    if count_attempt and attempts_used >= budget:
        return {
            "verdict": "aborted",
            "attempt": attempts_used,
            "generation_budget": budget,
            "label": label,
            "message": (
                f"generation budget spent ({attempts_used}/{budget}); stop and "
                f"return the last failure logs to the human. Do not raise the cap."
            ),
        }

    attempt = attempts_used + (1 if count_attempt else 0)
    if count_attempt:
        state["attempts"] = attempt
        state_path.write_text(json.dumps(state, indent=2))

    work = Path(workdir).resolve() if workdir else root

    # Immutable-test guardrail: detect any change to a frozen target in workdir.
    locked_manifest = criteria.get("manifest", {})
    current_manifest = _current_manifest(work, criteria.get("immutable_paths", []))
    diff = _diff_manifest(locked_manifest, current_manifest)
    if diff["modified"] or diff["removed"] or diff["added"]:
        return {
            "verdict": "tampered",
            "attempt": attempt,
            "generation_budget": budget,
            "label": label,
            "workdir": str(work),
            "changed_paths": diff,
            "message": (
                "a frozen verification target changed in this candidate. Rejected. "
                "Have a worker restore the listed paths (e.g. `git checkout -- "
                "<path>`) before fixing anything else."
            ),
        }

    logs_dir = root / ".haldir" / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    tag = "".join(c if c.isalnum() else "_" for c in (label or f"attempt-{attempt}"))

    results = []
    score_sum = 0.0
    checks_passed = 0
    for check in criteria["checks"]:
        name = check["name"]
        command = check["command"]
        expected = int(check.get("expect_exit_code", 0))
        stem = "".join(c if c.isalnum() else "_" for c in name)
        out_path = logs_dir / f"{tag}-{stem}.out"
        err_path = logs_dir / f"{tag}-{stem}.err"

        try:
            proc = subprocess.run(
                command, shell=True, cwd=work,
                capture_output=True, text=True, timeout=timeout_seconds,
            )
            exit_code, stdout, stderr, timed_out = proc.returncode, proc.stdout, proc.stderr, False
        except subprocess.TimeoutExpired as exc:
            exit_code, timed_out = 124, True
            stdout = exc.stdout or ""
            stderr = (exc.stderr or "")
            if isinstance(stdout, bytes):
                stdout = stdout.decode(errors="replace")
            if isinstance(stderr, bytes):
                stderr = stderr.decode(errors="replace")
            stderr += f"\n[haldir] timed out after {timeout_seconds}s"

        out_path.write_text(stdout)
        err_path.write_text(stderr)
        passed = exit_code == expected
        if check.get("scored"):
            partial = _parse_scored(stdout)
            check_score = partial if partial is not None else (1.0 if passed else 0.0)
        else:
            check_score = 1.0 if passed else 0.0
        score_sum += check_score
        checks_passed += 1 if passed else 0
        results.append(
            {
                "name": name, "command": command,
                "expected_exit_code": expected, "exit_code": exit_code,
                "passed": passed, "score": round(check_score, 4), "timed_out": timed_out,
                "stdout_tail": _tail(stdout), "stderr_tail": _tail(stderr),
                "stdout_log": str(out_path), "stderr_log": str(err_path),
            }
        )

    total = len(criteria["checks"])
    score = round(score_sum / total, 4) if total else 0.0
    all_passed = checks_passed == total
    verdict = "pass" if all_passed else "fail"
    if all_passed:
        state["passed"] = True
        state["passed_at"] = datetime.now(timezone.utc).isoformat()
        state_path.write_text(json.dumps(state, indent=2))

    return {
        "verdict": verdict,
        "attempt": attempt,
        "generation_budget": budget,
        "label": label,
        "workdir": str(work),
        "objective": criteria.get("objective"),
        "score": score,
        "checks_passed": checks_passed,
        "checks_total": total,
        "failing_checks": [r["name"] for r in results if not r["passed"]],
        "checks": results,
    }

"""Omnigent tool: lock haldir's machine-checkable exit criteria (Phase 1).

Auto-discovered from tools/python/. Exposes one @tool-decorated function
(lock_exit_criteria). Called once at the end of Phase 1, after the human
approves the criteria, to freeze it read-only for the rest of the run.

Writes .haldir/exit_criteria.json in the current working directory and records
a SHA-256 manifest of every frozen path so run_verification can detect tampering
(the "immutable test targets" guardrail). Refuses to overwrite an existing
locked criteria (the "you cannot re-lock to cheat the gate" guardrail). Also
freezes the search config (population/island/circuit-breaker knobs) and resets
the attempt counter and the search ledger.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from omnigent_client import tool

_SKIP_DIRS = {".git", "__pycache__", ".haldir", "node_modules", ".venv"}

# Defaults for the evolutionary search. Overridable via the `config` arg at lock
# time; frozen thereafter so the search budget cannot be quietly inflated.
_DEFAULT_CONFIG = {
    "generation_budget": 10,   # hard cap on total candidate evaluations (loop breaker)
    "population_size": 1,      # candidates (islands) generated per generation
    "blocked_threshold": 3,    # escalate to human after this many blocked candidates
    "stall_generations": 3,    # escalate/reset after this many gens with no score gain
    "novelty_threshold": 0.34, # below this similarity-distance => treated as a repeat
}


def _haldir_dir() -> Path:
    return Path.cwd() / ".haldir"


def _criteria_path() -> Path:
    return _haldir_dir() / "exit_criteria.json"


def _state_path() -> Path:
    return _haldir_dir() / "state.json"


def _ledger_path() -> Path:
    return _haldir_dir() / "ledger.jsonl"


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


def build_manifest(root: Path, immutable_paths: list[str]) -> dict[str, str]:
    """Map every file under each immutable path to its SHA-256, keyed by a path
    relative to root. Directories expand to all their files."""
    manifest: dict[str, str] = {}
    for raw in immutable_paths:
        target = (root / raw).resolve()
        if not target.exists():
            raise RuntimeError(
                f"immutable path does not exist: {raw!r} (resolve it before locking)"
            )
        for file in _iter_files(target):
            manifest[str(file.relative_to(root))] = _hash_file(file)
    if not manifest:
        raise RuntimeError(
            "no files matched immutable_paths; lock at least the tests / checks "
            "the gate depends on"
        )
    return manifest


def _normalize_checks(checks: list[dict]) -> list[dict]:
    if not checks:
        raise RuntimeError("checks must contain at least one command")
    normalized = []
    for i, check in enumerate(checks):
        command = check.get("command")
        if not command:
            raise RuntimeError(f"check[{i}] is missing a 'command'")
        normalized.append(
            {
                "name": check.get("name") or f"check_{i + 1}",
                "command": command,
                "expect_exit_code": int(check.get("expect_exit_code", 0)),
                # Optional: a check may report a 0..1 score on stdout's last line
                # instead of a pure pass/fail, for continuous-reward search.
                "scored": bool(check.get("scored", False)),
            }
        )
    return normalized


def _merge_config(config: Optional[dict]) -> dict:
    merged = dict(_DEFAULT_CONFIG)
    if config:
        for key, value in config.items():
            if key in merged and value is not None:
                merged[key] = value
    return merged


@tool(strict=False)
def lock_exit_criteria(
    objective: str,
    checks: list[dict],
    immutable_paths: list[str],
    environment: Optional[str] = None,
    config: Optional[dict] = None,
) -> dict:
    """Freeze haldir's exit criteria and search config after the human approves
    it (Phase 1).

    Writes .haldir/exit_criteria.json in the current working directory, records
    a SHA-256 manifest of every frozen path, resets the attempt counter, and
    clears the search ledger. Refuses to run if a locked criteria already exists:
    the criteria, its frozen paths, and the search budget are immutable for the
    rest of the run.

    Args:
        objective: One or two sentences describing what "done" means.
        checks: The verification commands. Each item is a dict with 'command'
            (shell string), optional 'name', optional 'expect_exit_code'
            (defaults to 0), and optional 'scored' (if true, the check's last
            stdout line is parsed as a 0..1 score for continuous-reward search).
            All checks must hit their expected code to pass.
        immutable_paths: Files/directories the checks depend on (tests, fixtures,
            golden files, config). Frozen read-only and hashed for tamper checks.
        environment: Optional note on how the checks run (interpreter, deps,
            container setup command) so the gate is reproducible.
        config: Optional search knobs (all frozen): generation_budget,
            population_size, blocked_threshold, stall_generations,
            novelty_threshold. Scale these to task difficulty in Phase 1.
    """
    root = Path.cwd()
    criteria_path = _criteria_path()

    if criteria_path.exists():
        existing = json.loads(criteria_path.read_text())
        if existing.get("locked"):
            raise RuntimeError(
                f"a locked exit criteria already exists at {criteria_path}; it is "
                f"immutable for this run. Delete .haldir/ only to start a brand "
                f"new objective."
            )

    normalized = _normalize_checks(checks)
    manifest = build_manifest(root, immutable_paths)
    resolved_config = _merge_config(config)

    criteria = {
        "spec_version": 1,
        "locked": True,
        "locked_at": datetime.now(timezone.utc).isoformat(),
        "objective": objective,
        "checks": normalized,
        "immutable_paths": immutable_paths,
        "environment": environment,
        "config": resolved_config,
        "manifest": manifest,
    }

    _haldir_dir().mkdir(parents=True, exist_ok=True)
    criteria_path.write_text(json.dumps(criteria, indent=2, sort_keys=True))
    _state_path().write_text(json.dumps({"attempts": 0, "passed": False}, indent=2))
    _ledger_path().write_text("")

    return {
        "locked": True,
        "path": str(criteria_path),
        "objective": objective,
        "checks": normalized,
        "immutable_paths": immutable_paths,
        "frozen_file_count": len(manifest),
        "config": resolved_config,
    }

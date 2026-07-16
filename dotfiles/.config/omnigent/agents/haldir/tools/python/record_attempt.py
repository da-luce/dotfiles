"""Omnigent tool: record a candidate attempt and steer the search (Phase 4).

Auto-discovered from tools/python/. Exposes one @tool-decorated function
(record_attempt). This is the evolutionary bookkeeping for the generate-verify-
refine loop: an island model over lineages, with novelty pressure so the search
doesn't keep re-treading failed approaches.

Each call appends one attempt to .haldir/ledger.jsonl and returns a decision
that implements haldir's three robustness guardrails:
  * loop breaker      - generation budget spent -> "deliver" or "escalate".
  * blocked threshold - too many blocked workers -> "escalate_blocked".
  * anti-repeat/stall - low-novelty repeats or no score gain -> "diverge" or
                        "reset_islands" or "escalate_stalled".
It also returns a compact snapshot of the search so haldir can seed the next,
deliberately diverse generation.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from omnigent_client import tool

_ESCALATING_BLOCKERS = {"impossible_criterion", "missing_credential_or_access", "spec_ambiguity"}
_STOPWORDS = {
    "the", "a", "an", "to", "of", "and", "or", "in", "on", "for", "with", "use",
    "using", "fix", "add", "make", "try", "then", "by", "via", "so", "that", "it",
}


def _control_root() -> Path:
    env = os.environ.get("HALDIR_ROOT")
    if env:
        return Path(env).resolve()
    here = Path.cwd().resolve()
    for candidate in (here, *here.parents):
        if (candidate / ".haldir" / "exit_criteria.json").is_file():
            return candidate
    return here


def _tokens(text: str) -> set:
    words = re.findall(r"[a-z0-9]+", (text or "").lower())
    return {w for w in words if w not in _STOPWORDS and len(w) > 2}


def _jaccard(a: set, b: set) -> float:
    if not a and not b:
        return 1.0
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def _fingerprint(files_changed: list[str], approach: str) -> str:
    basis = "|".join(sorted(files_changed or [])) + "::" + " ".join(sorted(_tokens(approach)))
    return hashlib.sha1(basis.encode()).hexdigest()[:16]


def _failure_signature(failing_checks: list[str], stderr_signature: Optional[str]) -> str:
    basis = ",".join(sorted(failing_checks or []))
    if stderr_signature:
        # Keep only the salient error tokens so cosmetic differences collapse.
        basis += "::" + " ".join(sorted(_tokens(stderr_signature)))
    return hashlib.sha1(basis.encode()).hexdigest()[:16]


def _behavioral_similarity(entry: dict, files: list[str], approach_tokens: set) -> float:
    """How much this candidate is DOING the same thing as a prior one: overlap of
    files touched and of approach wording. Deliberately excludes the failure
    signature -- failing at the same check is a stall/hardness signal (handled by
    the score-plateau detector), not evidence the same strategy was retried."""
    file_sim = _jaccard(set(entry.get("files_changed", [])), set(files or []))
    approach_sim = _jaccard(set(entry.get("approach_tokens", [])), approach_tokens)
    return max(file_sim, approach_sim)


@tool(strict=False)
def record_attempt(
    generation: int,
    island: str,
    worker: str,
    harness: str,
    status: str,
    score: float = 0.0,
    approach: str = "",
    files_changed: Optional[list[str]] = None,
    failing_checks: Optional[list[str]] = None,
    stderr_signature: Optional[str] = None,
    blocker_type: Optional[str] = None,
) -> dict:
    """Record a graded candidate and get the next search decision.

    Call once per candidate, AFTER run_verification has graded it (or after a
    worker reports blocked). Returns a decision plus a snapshot of the search.

    Args:
        generation: 0-based generation index of this candidate.
        island: Island / lineage id this candidate belongs to (diversity pool).
        worker: The worker sub-agent that produced it (e.g. "worker_codex").
        harness: The underlying harness/model (for diversity accounting).
        status: One of "verified_pass", "verified_fail", "tampered", "blocked",
            "partial".
        score: 0..1 score from run_verification (fraction of checks passed).
        approach: One or two sentences the worker gave describing its strategy
            (used for novelty/repeat detection — insist workers report this).
        files_changed: Files the candidate touched (used for behavioral novelty).
        failing_checks: Names of checks still failing.
        stderr_signature: The salient error text/first failing line (dedupes
            repeated failure modes).
        blocker_type: If blocked, one of impossible_criterion,
            missing_credential_or_access, spec_ambiguity, environment,
            external_dependency.

    Returns a dict whose "decision" is one of: deliver, continue, diverge,
    reset_islands, escalate_blocked, escalate_stalled, escalate_impossible.
    """
    root = _control_root()
    haldir_dir = root / ".haldir"
    criteria_path = haldir_dir / "exit_criteria.json"
    if not criteria_path.exists():
        raise RuntimeError("no locked criteria; run lock_exit_criteria in Phase 1 first")
    cfg = json.loads(criteria_path.read_text()).get("config", {})
    blocked_threshold = int(cfg.get("blocked_threshold", 3))
    stall_generations = int(cfg.get("stall_generations", 3))
    novelty_threshold = float(cfg.get("novelty_threshold", 0.34))
    budget = int(cfg.get("generation_budget", 10))

    # Authoritative pass signal: run_verification sets state.passed=True ONLY when
    # a candidate's real exit codes all matched. Never trust the caller-supplied
    # `status` string for the deliver decision — that would let the model grade
    # its own homework.
    state_path = haldir_dir / "state.json"
    state = json.loads(state_path.read_text()) if state_path.exists() else {}
    gate_passed = bool(state.get("passed", False))

    ledger_path = haldir_dir / "ledger.jsonl"
    prior = []
    if ledger_path.exists():
        for line in ledger_path.read_text().splitlines():
            line = line.strip()
            if line:
                prior.append(json.loads(line))

    files_changed = files_changed or []
    failing_checks = failing_checks or []
    approach_tokens = _tokens(approach)
    fail_sig = _failure_signature(failing_checks, stderr_signature)

    # Novelty vs prior FAILED attempts (we do not penalize resembling a winner).
    most_similar, best_sim = None, 0.0
    for entry in prior:
        if entry.get("status") in {"verified_pass"}:
            continue
        sim = _behavioral_similarity(entry, files_changed, approach_tokens)
        if sim > best_sim:
            best_sim, most_similar = sim, entry
    novelty = round(1.0 - best_sim, 4)
    is_repeat = best_sim >= (1.0 - novelty_threshold)

    # Separately, how many prior attempts hit this exact failure mode. A rising
    # count means the search is stuck on the same check (feeds haldir's judgment
    # even when the score plateau has not yet tripped the stall breaker).
    same_failure_mode = sum(1 for e in prior if e.get("failure_signature") == fail_sig and failing_checks)

    record = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "generation": generation,
        "island": str(island),
        "worker": worker,
        "harness": harness,
        "status": status,
        "score": round(float(score), 4),
        "approach": approach,
        "approach_tokens": sorted(approach_tokens),
        "files_changed": files_changed,
        "failing_checks": failing_checks,
        "failure_signature": fail_sig,
        "blocker_type": blocker_type,
        "fingerprint": _fingerprint(files_changed, approach),
        "novelty": novelty,
        "is_repeat": is_repeat,
    }
    with ledger_path.open("a") as handle:
        handle.write(json.dumps(record) + "\n")

    all_entries = prior + [record]
    graded = [e for e in all_entries if e.get("status") in {"verified_pass", "verified_fail", "tampered", "partial"}]
    blocked = [e for e in all_entries if e.get("status") == "blocked"]
    attempts_used = len(all_entries)

    best_score = max((e.get("score", 0.0) for e in graded), default=0.0)
    # First generation that reached the current best, so a plateau of tied scores
    # correctly reads as a stall (no improvement) rather than continuous progress.
    gen_of_best = min(
        (e.get("generation", 0) for e in graded if e.get("score", 0.0) >= best_score),
        default=0,
    )
    gens_since_improvement = generation - gen_of_best

    # Per-island incumbent (best-scoring candidate on each lineage) for seeding.
    islands: dict[str, dict] = {}
    for e in graded:
        isl = e.get("island")
        if isl not in islands or e.get("score", 0.0) > islands[isl].get("score", 0.0):
            islands[isl] = e
    island_best = {
        isl: {"score": e.get("score", 0.0), "worker": e.get("worker"),
              "approach": e.get("approach"), "generation": e.get("generation")}
        for isl, e in islands.items()
    }

    # Recurring / escalating blockers: corroborated impossible/credential/spec
    # gaps are the human's to resolve (only they can amend a locked criterion).
    blocker_counts: dict[str, int] = {}
    for e in blocked:
        bt = e.get("blocker_type") or "unknown"
        blocker_counts[bt] = blocker_counts.get(bt, 0) + 1
    escalating_now = [bt for bt in _ESCALATING_BLOCKERS if blocker_counts.get(bt, 0) >= 2]

    # Decision, in priority order.
    if gate_passed:
        decision, why = "deliver", (
            "run_verification recorded a real pass (all exit codes matched); "
            "deliver the passing candidate."
        )
    elif escalating_now:
        decision, why = "escalate_impossible", (
            f"blocker(s) {escalating_now} recurred; only the human can amend a "
            f"locked criterion or supply access. Stop and escalate."
        )
    elif len(blocked) >= blocked_threshold:
        decision, why = "escalate_blocked", (
            f"{len(blocked)} blocked candidates >= threshold {blocked_threshold}; "
            f"stop and notify the human with the blockers."
        )
    elif attempts_used >= budget:
        decision, why = "escalate_stalled", (
            f"generation budget spent ({attempts_used}/{budget}) without passing; "
            f"stop and hand back the best candidate (score {best_score}) and logs."
        )
    elif gens_since_improvement >= stall_generations:
        decision, why = "reset_islands", (
            f"no score gain for {gens_since_improvement} generations (>= "
            f"{stall_generations}); reset the worst island(s) and reseed from the "
            f"best incumbent with a DIFFERENT harness/strategy. "
            f"If islands are exhausted, escalate_stalled instead."
        )
    elif is_repeat:
        decision, why = "diverge", (
            f"this attempt is a near-duplicate (novelty {novelty}) of an earlier "
            f"failed one; reject the redundant path and force a distinct strategy."
        )
    else:
        decision, why = "continue", "progress or new ground; seed the next generation."

    return {
        "decision": decision,
        "reason": why,
        "recorded": {k: record[k] for k in ("generation", "island", "worker", "harness", "status", "score", "novelty", "is_repeat", "fingerprint")},
        "best_score": best_score,
        "gate_passed": gate_passed,
        "same_failure_mode": same_failure_mode,
        "generations_since_improvement": gens_since_improvement,
        "attempts_used": attempts_used,
        "generation_budget": budget,
        "blocked_count": len(blocked),
        "blocker_counts": blocker_counts,
        "island_best": island_best,
        "tried_approaches": [
            {"gen": e.get("generation"), "island": e.get("island"), "worker": e.get("worker"),
             "score": e.get("score"), "approach": e.get("approach"),
             "failure_signature": e.get("failure_signature")}
            for e in graded
        ],
    }

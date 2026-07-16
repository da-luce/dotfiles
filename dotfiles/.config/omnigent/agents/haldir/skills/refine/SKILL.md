---
name: refine
description: >-
  haldir Phase 4 (Select + refine). Record each graded candidate, select the
  best, and act on the search decision: evolve the next generation, reset stalled
  islands, deliver a pass, or trip a circuit breaker. Load after verify.
---

# Phase 4: Select and refine

This is the evolutionary step: register results, keep what works, and steer the
next generation — or stop. Do not write code here; you only score, decide, and
re-dispatch.

## Record every candidate

For each graded candidate from `verify`, call `record_attempt` with its
`generation`, `island`, `worker`, `harness`, `status` (`verified_pass` /
`verified_fail` / `tampered` / `blocked` / `partial`), `score`, the worker's
`approach` (one line — required for novelty), `files_changed`, `failing_checks`,
a `stderr_signature`, and `blocker_type` if blocked. It appends to the ledger and
returns a `decision` plus a search snapshot (`best_score`, `island_best`,
`tried_approaches`, counters). Record the whole generation before acting on the
aggregate decision.

## Act on the decision (priority order)

- **`deliver`** — a candidate passed every check. Merge/checkout that island's
  branch as the result, then run Phase 4 delivery (below).
- **`escalate_impossible`** — a criterion-level blocker (impossible criterion,
  missing credential, spec ambiguity) recurred. STOP: only the human can amend a
  locked criterion or supply access. Present the blocker, what was tried, and
  exactly what you need.
- **`escalate_blocked`** — too many blocked candidates. STOP and notify the human
  with the distinct blockers and the best partial candidate.
- **`escalate_stalled`** — budget spent or the search is exhausted with no pass.
  STOP and hand back the best candidate (its branch + score) and the failure
  logs. Never raise the budget or re-lock to keep going.
- **`reset_islands`** — the best score has plateaued. Discard the worst-scoring
  island(s) and reseed them from the global best incumbent
  with a DIFFERENT harness and an explicitly different strategy, then load
  `orchestrate` for the next generation. If every island is already exhausted,
  treat as `escalate_stalled`.
- **`diverge`** — the last attempt was a near-duplicate of a prior failure. Keep
  the best incumbent, but instruct the next generation to avoid the tried
  approaches (pass `tried_approaches`) and take a materially different path.
  Load `orchestrate`.
- **`continue`** — real progress or new ground. Elitism: carry each island's best
  incumbent forward as the parent for its next candidate, seed the next
  generation from those parents + their failure logs, and load `orchestrate`.

Selection is always elitist: the parent for an island's next candidate is its
highest-scoring candidate so far (the incumbent), never a regression.

## Delivery (on `deliver`)

1. Tear down scratch resources you or the workers created — containers, temp
   services, scratch branches/worktrees other than the winner (use the `shell`
   terminal, e.g. `docker compose down`, `git worktree remove`). Leave the
   winning branch checked out / clearly identified.
2. Deliver a final summary to the human: the objective; every check with its
   command and final exit code; the winning island/worker/harness and its branch;
   how many candidates/generations it took (from the ledger); the diverse
   approaches explored and why the losers failed; and any leftover notes. Then
   stop — the human decides whether to merge.

The loop is: `orchestrate` → `verify` → `refine` → (`orchestrate`), until a
candidate passes or a circuit breaker stops it.

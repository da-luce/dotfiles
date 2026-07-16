---
name: verify
description: >-
  haldir Phase 3 (Verify). Grade every candidate in the generation with the
  locked gate — real exit codes and a score, never LLM grading — and enforce
  immutability. Load after orchestrate produces candidates; then load refine.
---

# Phase 3: Hard verification

Workers have produced candidates. Do not believe any "done" claim. The verdict
comes only from the gate.

## Grade each candidate

For every candidate in the generation, call `run_verification`:

- Population mode: `run_verification(workdir=<island branch/worktree>, label=
  "gen<G>-<island>")` once per candidate, so each is graded on its own branch and
  logs don't collide.
- Single mode: `run_verification(label="gen<G>")` against cwd.

Each call returns an authoritative `verdict` and a `score` (fraction of checks
passed, or the continuous score for `scored` checks), plus per-check exit codes
and the log paths. Never override the verdict with your own reading of the output.

Handle each verdict:

- **`pass`** (score 1.0): a candidate cleared the gate. You can stop grading the
  rest of the generation — carry this candidate into `refine` for delivery.
- **`fail`** (0 ≤ score < 1): record its score, failing checks, and stderr tails;
  it's a scored candidate for selection in `refine`.
- **`tampered`**: a frozen target changed on this candidate's branch. Its score
  is void; mark it a cheating candidate (status `tampered`) for `refine`, which
  will route a restore. Never accept it.
- **`aborted`**: the generation budget is spent. Skip remaining grades and go
  straight to `refine`, which will escalate with the best candidate so far.

## Keep the evidence

For each graded candidate, hold onto: island id, worker/harness, verdict, score,
failing checks, the worker's reported APPROACH and FILES, and a one-line
`stderr_signature` (the salient error, e.g. the first failing assertion or the
exception type) — `refine` feeds all of these to `record_attempt` for selection
and novelty detection.

Exit: every candidate graded with a real score (or a pass found, or budget
aborted). Load `refine`.

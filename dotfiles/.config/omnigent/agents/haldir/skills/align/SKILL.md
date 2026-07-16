---
name: align
description: >-
  haldir Phase 1. Interview the human until the goal is a concrete, machine-
  checkable exit criteria, size the search to the difficulty, and lock both read-
  only. Load after triage clears the task. Human input closes when this exits.
---

# Phase 1: Interactive alignment

Convert the request into an exit criteria a machine can grade, size the search,
and freeze it all. This is the ONLY phase with a human in the loop, so do not
leave it until the criteria is real and approved.

Input: `params.objective` (if set) is a starting point, not the spec.

## Interview until the goal is machine-checkable

Drive a short, focused interview. You are not done until each is pinned:

1. **Objective.** One or two sentences: what "done" means in plain terms.
2. **Checks.** One or more concrete commands whose exit code is the verdict —
   `{name, command, expect_exit_code}` (expected defaults to 0). Prefer things
   like `python -m pytest -q tests/`, `bash scripts/verify.sh`, `docker compose
   up -d && ./probe.sh`. Reject vague acceptance: if it can't be a command with
   an exit code, keep interviewing until it can. For search over a continuous
   objective (speed, size, score), a check may be `scored: true` — then its last
   stdout line is read as a 0..1 score, giving the loop a smooth gradient
   instead of pass/fail.
3. **Immutable paths.** The files/dirs the checks depend on (tests, fixtures,
   golden files, config). These get frozen — workers may read but never modify.
4. **Environment.** How the checks run (interpreter, deps, container). Capture
   any setup command so the gate is reproducible.

If no verifiable check exists yet (tests still need writing), you may dispatch
ONE worker to scaffold only the verification harness, show it to the human, and
lock it only after they approve. It becomes immutable the moment you lock.

## Size the search to the difficulty

From the triage read, pick the search config (frozen into the lock):

- **Easy / deterministic** (one obvious fix path): `population_size: 1`,
  `generation_budget: ~5`. A single evolving branch.
- **Medium**: `population_size: 2-3` across different worker harnesses,
  `generation_budget: ~8-10`.
- **Hard / open-ended search**: `population_size: 3-4`, `generation_budget:
  ~12-15`, so islands can diverge and reset.

Also set `blocked_threshold` (default 3) and `stall_generations` (default 3).
Default any you don't tune. Larger budgets cost more tokens — right-size, don't
maximize.

## Approval gate (mandatory)

Present the full draft to the human: objective, every check (command + expected
code, and any `scored`), the immutable paths, and the search config. Explain
that once locked, the checks, frozen paths, and search budget are fixed for the
run and their input closes. PAUSE for explicit approval. Revise and re-present on
any change. Do not lock on implied consent.

## Lock

On explicit approval, call `lock_exit_criteria` with the approved `objective`,
`checks`, `immutable_paths`, optional `environment`, and `config` (the sized
search knobs). It writes `.haldir/exit_criteria.json`, records a SHA-256
manifest of the frozen paths, resets the attempt counter, and clears the ledger.
It refuses if a locked criteria already exists. Confirm the lock and state that
human input is now closed.

Exit: a locked criteria + frozen search config + empty ledger. Load
`orchestrate`.

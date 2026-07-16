---
name: orchestrate
description: >-
  haldir Phase 2 (Generate). Dispatch a diverse generation of sandboxed workers
  to produce candidate solutions, each seeded to explore distinctly. Load after
  align locks the criteria; re-entered from refine for every new generation.
---

# Phase 2: Generate a diverse population

The criteria and search config are locked and human input is closed. You are now
running an evolutionary search: each generation produces `population_size`
candidates on independent lineages ("islands"), which Phase 3 grades and Phase 4
selects from. Read the config from `.haldir/exit_criteria.json`.

## Candidate isolation (so islands can be graded independently)

Each island is a git branch off the base, worked in isolation:

- Population mode (`population_size > 1`, git available): for each island create
  a branch `haldir/gen<G>-<island>` (a worktree if you can, so candidates build
  in parallel without colliding). Dispatch that island's worker with its cwd on
  that branch/worktree; grade it later with `run_verification(workdir=...)`.
- Single mode (`population_size: 1` or no git): one branch evolves in place; the
  worker edits the workspace and you grade cwd directly.

## Assign workers for maximum diversity

Spread candidates across DIFFERENT worker harnesses from the available pool
(`worker_claude`, `worker_codex`, `worker_cursor`, `worker_gemini`) — decorrelated
models miss in different places, which is the whole point of the population. Do
not send every island to the same model. On a reset (from refine), deliberately
switch an island to a harness it has not used.

## Seed each worker

Dispatch the generation's workers (in parallel when isolated). Give every worker:

- the **objective** and the **exact checks** it must satisfy (the commands +
  expected codes; telling workers the target is fine — the rule is they may not
  change it);
- the immutability + sandbox rules restated: never modify a frozen path or touch
  `.haldir/`; changing a test is cheating and is detected;
- a demand for the **structured report** (STATUS / APPROACH / FILES / DIAGNOSIS /
  BLOCKER / NEEDS) — the APPROACH line feeds novelty detection, so insist on it.

First generation: seed each island with a distinct high-level strategy so they
don't all converge on one idea.

Refine generation (re-entry): for each surviving island, seed its worker from the
island's **best incumbent** (its branch) plus:

- the RAW stderr / log tails and failing-check names from that candidate
  (`run_verification` returns the log paths — pass the real error text, not your
  paraphrase; the unedited failure is the signal the worker refines against), and
- the **list of approaches already tried** (from `record_attempt`'s
  `tried_approaches`) with an explicit instruction to do something DIFFERENT when
  the decision was `diverge`. On a `reset_islands` decision, reseed the worst
  island from the global best incumbent using a fresh harness.

If a worker returns empty or clearly runaway, inspect its conversation, cancel
it, and re-dispatch a fresh one. Do not re-prompt a dark worker in a loop.

Exit: a generation of candidate branches (or one updated branch), each with a
worker report. Load `verify` to grade them. Never infer success from a worker's
claim or from git status.

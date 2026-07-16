---
name: triage
description: >-
  haldir Phase 0. Decide whether this task is a good fit for a generate-verify-
  refine loop before spending any tokens. Load right after the preflight. If the
  task is a poor fit, say so and stop.
---

# Phase 0: Suitability gate

A verify-refine loop only pays off when the task has **verification asymmetry**:
cheap and objective to check, but expensive or fiddly to get right. Spending a
whole population + gate on a task without that property is a waste of tokens.
Judge the incoming request against these:

1. **Objective truth.** "Done" is not a matter of taste. There is a correct
   result a machine can recognize.
2. **Cheap to verify.** A command can decide pass/fail in seconds-to-minutes,
   far faster than producing the solution.
3. **Iteration-friendly and safe.** The work can run repeatedly in a sandbox /
   container with no irreversible side effects on the host or the world.
4. **A single shot might miss.** There is genuine uncertainty — dependency
   wrangling, config surface, flaky setup — so multiple diverse attempts help.

## Good fit (dispatch haldir)

Tasks where the checker is obvious and the toil is real. Examples:

- "Stand up a local Pub/Sub emulator in Docker plus a script that publishes a
  message and asserts it is consumed — done when the script exits 0." Objective,
  runs in a container, and getting the image/ports/auth right is fiddly enough
  that diverse attempts help.
- "Make this flaky CI job pass deterministically 20 runs in a row."
- "Port this build to `uv` so `uv sync && uv run pytest` exits 0 on a clean
  checkout."
- "Find compiler/interpreter flags so this benchmark runs under N ms" (a
  continuous, scored objective — ideal for evolutionary search).

## Poor fit (recommend something else, do not spend the loop)

- **No crisp verifier.** "Implement feature X", "refactor for readability",
  "make the UI nicer", "write a good design doc." Acceptance is subjective —
  route to a normal dev-loop agent (e.g. gimli) instead.
- **Verification is as expensive as solving.** If checking a candidate costs the
  same as writing it (some data-processing correctness, essays), the loop adds
  overhead without leverage.
- **Trivial / single-shot.** A one-line change any single agent nails first try;
  the population and gate are pure overhead.
- **Unsafe to iterate.** Irreversible effects (prod mutations, sends, payments)
  that a sandbox can't contain.

## Decide

State briefly whether the task is a good fit and why (which properties it meets
or misses). If it is a POOR fit, do not proceed — recommend the better tool /
approach and stop. If it is a good fit, note the rough difficulty (this sizes the
search in Phase 1: easy → `population_size: 1`, small budget; hard/open-ended →
larger population + budget) and load `align`.

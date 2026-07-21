---
name: implement-review
description: >-
  gimli Phase 2. Drive implementation, run mechanical checks, fan out parallel
  reviewers, route fixes, and get CI green. Load after plan-gate, once the plan
  is finalized.
---

# Phase 2: Implementation and review

1. Have `agent_a_lead` implement the finalized plan on the branch.
2. Once code is written, call the `check_pr_nits` tool. Its subprocess does NOT
   inherit your cwd, so pass `repo_root=<the worktree root from the preflight's
   `git rev-parse --show-toplevel`>` along with `base_ref=params.base_branch`.
   Narrow with `modules` (e.g. `["databricks.scala"]`) only when you want a
   scoped rerun. Keep the full JSON output; these are authoritative mechanical
   findings.
3. Perform the following steps IN PARALLEL

   a. Dispatch `agent_c_brutal` on the branch diff
   b. Dispatch `agent_d_databricks` on the branch diff. Include the full `check_pr_nits`
   output and instruct it to review only subjective `/databricks-review` items
   not already covered.
   c. Dispatch `agent_a_lead` to run the build and the test suite and report the
   full output.

   Then end your turn and collect all three from the inbox.
4. Merge the step 2 `check_pr_nits` JSON with the three inbox results
   (`agent_c_brutal`, `agent_d_databricks`, and the build/test run). Mechanical
   findings are authoritative; never drop them when merging.
5. HITL GATE 2 (conditional): pause for the human ONLY if a reviewer found a
   major architectural flaw needing a product decision. Otherwise proceed.
6. Have `agent_a_lead` fix all valid review findings, along with any build failures.
7. Commit to the branch, push, and watch CI (use the `shell` terminal for the
   watch). If CI fails, feed the logs back to `agent_a_lead` to fix and re-push
   until CI is green. After fixes, re-run `check_pr_nits` before declaring
   review-clean.

Exit: green CI and no unresolved mechanical or review findings. Next, load
`pr-delivery`.

## Verifying sub-agents

Do not infer success from git status alone. You do not run the gates yourself;
the sub-agent running them must report the full test / lint / typecheck output,
not a bare "passing" claim. When reconciling a pytest count, verify ground truth
with `python -m pytest --collect-only -q <same files>` (a read-only count, not a
gate) against the exact file set and commit the worker reported. Never use
`grep -c 'def test_'` as a test count: it counts functions, not collected cases,
and misses parametrized expansion.

If a sub-agent returns an empty or unclear result, inspect its conversation
before deciding what to do. If one is clearly wrong or runaway, cancel it rather
than leaving it running, then re-dispatch a fresh one. Do not re-prompt a dark
worker in a loop.

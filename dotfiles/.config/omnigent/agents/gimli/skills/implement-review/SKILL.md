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
3. Dispatch `agent_c_brutal` and `agent_d_databricks` IN PARALLEL on the branch
   diff. In the `agent_d_databricks` dispatch, include the full `check_pr_nits`
   output and instruct it to review only subjective `/databricks-review` items
   not already covered. Then end your turn and collect both from the inbox.
4. Collect findings from `check_pr_nits`, `agent_c_brutal`, and
   `agent_d_databricks`. Do not drop mechanical findings when merging.
5. HITL GATE 2 (conditional): pause for the human ONLY if a reviewer found a
   major architectural flaw needing a product decision. Otherwise proceed.
6. Have `agent_a_lead` fix all valid review findings.
7. Commit to the branch, push, and watch CI (use the `shell` terminal for the
   watch). If CI fails, feed the logs back to `agent_a_lead` to fix and re-push
   until CI is green. After fixes, re-run `check_pr_nits` before declaring
   review-clean.

Exit: green CI and no unresolved mechanical or review findings. Next, load
`pr-delivery`.

## Verifying sub-agents

Do not infer success from git status alone. Read each sub-agent's reported
result and run the test / lint / typecheck gates yourself via `sys_os_shell`.
When reconciling a pytest count, collect ground truth with
`python -m pytest --collect-only -q <same files>` against the exact file set and
commit the worker reported. Never use `grep -c 'def test_'` as a test count: it
counts functions, not collected cases, and misses parametrized expansion.

If a sub-agent returns an empty or unclear result, inspect its conversation
before deciding what to do. If one is clearly wrong or runaway, cancel it rather
than leaving it running, then re-dispatch a fresh one. Do not re-prompt a dark
worker in a loop.

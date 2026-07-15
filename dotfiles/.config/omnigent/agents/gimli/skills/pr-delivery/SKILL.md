---
name: pr-delivery
description: >-
  gimli Phase 3. Format the PR and deliver a final summary to the human. Load
  after implement-review reports green CI and a review-clean branch.
---

# Phase 3: PR formatting and delivery

1. Have `agent_a_lead` return the list of recommended PR explanatory comments:
   exact file:line locations plus draft comment text for the human to paste so
   reviewers understand the tricky parts.
2. Format the PR yourself (this is prose, so no sub-agent): follow the repo's PR
   template and any project-specific PR skills or conventions configured for
   this workspace.
3. Deliver a final summary to the human:
   - the PR link and branch verification,
   - every mechanical finding from `check_pr_nits` and how it was resolved,
   - every review finding from `agent_c_brutal` and `agent_d_databricks` and how
     it was resolved,
   - any minor design decisions made (options considered then direction taken),
   - the exact file:line locations and draft comments to paste into the PR.

You never merge: the review-clean PR is the deliverable and the human merges it.

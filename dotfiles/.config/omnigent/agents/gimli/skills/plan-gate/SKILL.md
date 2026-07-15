---
name: plan-gate
description: >-
  gimli Phase 1. Turn a ticket into a critiqued, finalized implementation plan
  and gate on any one-way doors before implementation begins. Load this after
  the roster preflight, once per ticket.
---

# Phase 1: Planning

Inputs: `params.ticket_id` (if set) and `params.base_branch` (default
`origin/main`). If no ticket context is available, ask the human for the ticket
or a work description before dispatching.

1. Send the ticket to `agent_a_lead`: explore the codebase, draft a
   step-by-step implementation plan, and CRITICALLY separate minor decisions
   from one-way doors (irreversible design choices, breaking API changes, or
   fundamental ticket flaws).
2. HITL GATE 1 (mandatory when it fires): if `agent_a_lead` surfaced any real
   one-way door or fundamental ticket problem, present it to the human and
   PAUSE. Do not proceed until they answer. If only minor decisions exist, note
   the option taken and proceed.
3. Pass the plan to `agent_b_plan_critic` for architectural critique (missing
   edge cases, scaling assumptions, deviations from existing codebase patterns).
4. Pass the critique back to `agent_a_lead` to finalize the plan.

Exit: a finalized plan and a recorded decision for every one-way door. Next,
load `implement-review`.

---
name: inbox-triage
description: |
  Triage the Gmail inbox into Todoist tasks and calendar events. Drafts a
  proposal, has a fresh subagent review it adversarially, then applies the
  survivors. Runs unattended on a schedule. Use when asked to triage my inbox,
  check my email, sweep the inbox, or work out what I owe people.
allowed-tools: |
  Bash(date:*), Task,
  mcp__claude_ai_Todoist__find-tasks, mcp__claude_ai_Todoist__find-projects,
  mcp__claude_ai_Todoist__find-labels, mcp__claude_ai_Todoist__add-tasks,
  mcp__claude_ai_Google_Calendar__list_events,
  mcp__claude_ai_Google_Calendar__create_event,
  mcp__claude_ai_Google_Calendar__list_calendars
---

Run unattended. Never ask the user a question. Anything you cannot decide goes
in the digest at the end as an open question and is otherwise dropped.

## Dependencies

Gmail tools used: `search_threads`, `get_thread`, `list_labels`,
`label_message`. Resolve label display names to ids with `list_labels` at the
start of every run, because `label_message` takes ids and a Gmail query takes
display names. Call `get_thread` with `messageFormat: PLAIN_TEXT`, never the
`FULL_CONTENT` default, which returns the HTML body and will burn context for
no benefit on a job that runs hourly.

**Never call `label_thread`.** Its own docs state it affects "all messages
currently in the thread and any future messages added to it," so a reply
arriving tomorrow would be born already labeled and would never surface. It
looks like the efficient choice and it silently destroys the state model. Use
`label_message` per message, always.

Requires a Gmail tool that can search and modify labels **on individual
messages**, not only on whole threads. Label writes are not optional: they are
the only durable state this skill has. Message-level granularity is equally
non-negotiable, for the reason in State below. If the tool only labels whole
threads, stop and report rather than degrading to thread labels.

## State

All state lives in Gmail as two labels, both created hidden in the label list
and the message list, so they never appear in the UI. There is no watermark,
no state file, and nothing on disk, so the skill behaves identically whether a
scheduled run keeps a filesystem between invocations or not.

- `triage/done` goes on every **message** the run examines, noise included.
- `triage/noise` goes on messages classified as noise. It is a subset of
  `triage/done` and it is what makes the noise list learn.

**Label messages, never threads.** A thread is not a unit of work, a message
is. Labeling a whole thread asserts that messages which do not exist yet are
handled, so a reply arriving tomorrow would be invisible and its task lost.
Labeling per message means a new reply lands unlabeled, the thread resurfaces
in the next run's query, and only the new message gets judged. An old thread
that goes quiet stays quiet, and one that wakes up gets re-examined for free.

To correct the agent, strip a label by hand and the next run reconsiders.

Both labels are expected to be hidden in the Gmail UI, under Settings, Labels,
with "Show in label list" and "Show in message list" set to hide. Visibility is
a display setting only and does not affect search, so a hidden label still
matches `-label:triage/done` exactly as before. **Do not unhide them or treat
hidden labels as a misconfiguration to repair.**

## Phase 1: draft a proposal

1. Build the learned noise list, and hold it for the run:

   - `label:"triage/noise" newer_than:90d` for senders this skill has already
     rejected.
   - Plus the senders behind these existing hand-curated bulk labels, which
     encode years of the user's own judgement about what is not worth reading:
     `Scholarships`, `Medium-Daily-Digest`, `linkedin`, `Ourbus`, `shop`,
     `recruit`, `receipt`. Sample recent threads per label rather than reading
     them all. **This list is user-editable, so treat it as configuration and
     do not add to it on your own.**

   Collect distinct sender addresses and domains. Seeding this way is what
   stops the first weeks behaving worse than the later ones.
2. Fetch the work:

   ```
   in:inbox after:2026/10/27 -label:"triage/done"
   ```

   Quote the label, since an unquoted `/` is not parsed as nesting. Page with
   `pageSize: 50`, the maximum.

   The `after:` date is the **triage epoch**, fixed at setup. It is what makes
   everything older than it permanently out of scope, instead of bulk-labeling
   a backlog of hundreds of threads. Keep it a literal date and **never change
   it to a rolling `newer_than:`**, which would silently drop any message the
   cap deferred for longer than the window. An old thread that receives a new
   reply still surfaces, because the reply's own date clears the epoch.

   This returns every thread
   holding at least one unlabeled message, including long-settled threads that
   just received a reply. Within each thread, **the unlabeled messages are the
   work.** Ignore the labeled ones except as context.
3. Reject unlabeled messages whose sender or sending domain is on the learned
   noise list. This is a string match rather than a judgement, so it is
   effectively free and is **not subject to the cap below**. Mark each
   `triage/noise` plus `triage/done`. Gmail's own `category:` buckets are
   unreliable here and must not be the only filter, which is why the learned
   list exists.
4. **Skip messages less than 15 minutes old.** Leave them unlabeled for the
   next run. A burst of fast replies judged mid-flight fragments one
   conversation into several tasks, and the settling window lets the burst land
   as a unit. This costs nothing, since an unlabeled message is just queued.
5. Classify what survives, reading the full thread for context and judging each
   unlabeled message on its own as exactly one of task, event, or noise. A
   thread can yield a task in March having yielded one in January, and that is
   correct, not a duplicate.

### The cap

Cap **classifications in step 5** at 50 per run, not threads examined, since
step 3 already absorbed the cheap rejections. Order by directly-addressed first
(`to:me` and not a mailing list), then oldest first within that, which bounds
how long anything waits without letting list mail starve a real request.

Nothing is dropped by the cap. Uncapped messages stay unlabeled and are picked
up by the next run, so a backlog drains in order rather than vanishing. But
report the backlog depth in the digest every time, because a backlog that never
drains means inflow exceeds the cap and the **noise list is the thing that
needs fixing**, not the cap. Say so explicitly in the digest above 150.

Write the result to `proposal.json` in the scratch directory. No Todoist or
calendar writes happen in this phase.

```json
{
  "items": [{
    "message_id": "...",
    "thread_id": "...",
    "kind": "task | event | noise",
    "from": "sender@example.com",
    "subject": "...",
    "evidence": "the sentence that creates the obligation",
    "title": "...",
    "due_date": "YYYY-MM-DD | null",
    "deadline": "YYYY-MM-DD | null",
    "priority": 1,
    "project": "...",
    "labels": ["ai"],
    "permalink": "https://mail.google.com/..."
  }]
}
```

### What earns a task

The bar: would I be annoyed to find this sat in my inbox unhandled? Err toward
dropping. Two real tasks beats twenty I have to re-triage. Create one only when
the message implies an action I personally own.

- A person asks me a direct question or is waiting on my reply
- A dated commitment I have to act on
- Something that breaks or expires unless I act, like a payment due, an
  expiring credential, a failing renewal, an account action required
- A review, signature, approval, or form explicitly assigned to me
- A reply on a thread I started where the ball is back with me
- Anything the user labeled `action` by hand, which is an explicit signal and
  outranks every heuristic here. Never classify an `action` message as noise.

### What earns an event

Only a dated commitment that arrives as prose, such as an appointment
confirmation or a "we expect you at 3pm" message. **Skip anything carrying a
real calendar invite**, because Google has already put it on the calendar and a
second copy is a duplicate. Partial details are fine. Create it with what the
email gives and say what was missing in the digest.

## Phase 2: adversarial review

**If no items survived phase 1, stop here.** Do not spawn a reviewer, do not
enter phase 3, and emit no digest at all. This skill is designed to be run
often, so the common outcome is an empty run, and an empty run must be free and
silent. A reviewer invoked on an empty proposal is pure waste, and a digest
saying nothing happened recreates in notifications exactly the noise the label
hiding was meant to remove.

Hand `proposal.json` to a **fresh** subagent. Not a fork. The reviewer must not
inherit the reasoning that produced the proposal, since that reasoning is the
thing under review.

```
Agent(subagent_type: "general-purpose", description: "Review inbox triage proposal")
```

The reviewer's prompt must carry the proposal, the raw sender and subject and
evidence for each item, and the task and event criteria above. Its mandate:

- You are reviewing a proposal to write into a real task list and calendar. You
  have no authority to write anything. Return a verdict only.
- Bias toward dropping. A false task costs the user more than a missed one,
  because it has to be triaged by hand. If an item's evidence does not plainly
  show an obligation the user personally owns, drop it.
- Catch specifically: marketing or newsletter copy dressed up as a request,
  an FYI with no action, two items that are the same underlying task, which is
  most likely when they share a `thread_id`,
  a date read off the email's own timestamp rather than its content,
  a deadline inferred from nothing, an event that has a real invite attached.
- Flag senders that should join the learned noise list.

It returns one verdict per `message_id`, machine-applicable, no prose. Key on
the message and not the thread, since one thread can contribute two items in a
single run and thread-keyed verdicts would be ambiguous:

```json
{
  "verdicts": [{"message_id": "...", "verdict": "keep | drop | amend",
                "fields": {}, "reason": "..."}],
  "noise_senders": ["..."],
  "missed": [{"message_id": "...", "why": "..."}]
}
```

A verdict for every proposed `message_id` is required. A missing or unmatched
id is unparseable output, which means the fail-closed rule below applies.

**One round.** Apply the verdicts and move on. Do not argue with the reviewer
and do not send a revised proposal back, because an unbounded critique loop
burns tokens and converges on nothing.

If the reviewer fails or returns unparseable output, **write nothing** and
report. Do not fall through to applying an unreviewed proposal.

## Phase 3: apply

Order matters. Write the records first and label last, so that a crash
re-triages the thread rather than silently losing it.

1. For each surviving item, search Todoist for `gmail:<message_id>`. A hit
   means a previous run already handled that message, so skip it. This stamp is
   what makes the retry in the sentence above safe. It is keyed on the message
   and **never on the thread**, because a thread-keyed stamp would suppress a
   real new task on a thread that produced one months ago.
2. Check for an open task from the same conversation. Search Todoist for the
   item's `thread_id` among **incomplete** tasks only. If one exists, the new
   message is almost certainly the same obligation still outstanding, so skip
   creating a second task and say so in the digest. This is deliberately not
   the same as the message stamp in step 1: that one is a hard dedupe on an
   exact message, while this is a soft check scoped to unresolved work. A
   *completed* task must never suppress anything, because a new message on a
   settled thread is genuinely new work.
3. Resolve conventions live. Call `find-projects` and `find-labels` once and map
   onto what exists. Follow established patterns, like `@assignment` for
   coursework. Never invent a project.
4. Create the task. The description carries the permalink to the specific
   message, the literal stamp `gmail:<message_id>`, and `gmail-thread:<thread_id>`
   so the check in step 2 can find it. Always add the `@ai` label to mark it
   AI-generated and untriaged.
5. Create events on the `ai` calendar only, with the permalink and the same
   stamps in the description.
6. Label every examined **message** `triage/done`, and additionally
   `triage/noise` for noise and for senders the reviewer flagged. Never label
   the thread, and never label a message the cap deferred or the settling
   window skipped.
7. Emit the digest.

### Dates

- `deadline` is the hard external date the thing must be done by.
- `due_date` is when I intend to work on it.
- When the email gives only a hard date, set both.
- To move an existing task use `reschedule-tasks`, never `update-tasks`, which
  replaces the whole due string and destroys recurrence.

### Priority

Pin the mapping and do not reason about it per item. The Todoist API number and
the UI label run in opposite directions, so write the API number.

| Situation | API `priority` | Shows as |
|---|---|---|
| Money or access lost today | 4 | P1 |
| Hard deadline inside 3 days | 3 | P2 |
| Everything else | 1 | P4 |

## Digest

Emit nothing when the run created nothing and learned nothing. Silence is the
correct output for an empty run. Otherwise end with this and nothing else, as
it is the only thing the user reads.

```
Triaged N threads.
Created: <title> (due, project) <permalink>
Dropped by review: <subject> -- <reason>
Noise senders learned: <addresses>
Open questions: <anything undecidable>
Backlog: N messages awaiting classification (<flag if above 150>)
```

Keep it short and factual. Report only lines that have content.

# Personal Preferences & AI Assistant Guidelines

## Communication & Response Style

- Be concise, practical, straightforward, and realistic. Keep technical
  explanations short and simple.
- Do not include pleasantries, introductory filler, or concluding summaries.
  Get straight to the point.
- Avoid "Great choice!", "That's a smart approach!", or undue validation. Focus
  purely on technical evaluation and execution.
- Keep explanations brief and focused on the *why*. Code should largely speak
  for itself.
- If a task is straightforward, provide the solution immediately. If a request
  is ambiguous, ask brief clarifying questions first.
- Point out potential edge cases or performance bottlenecks directly and
  objectively.

## Coding Style

- Plan code changes first.
- Follow the existing style in the codebase.
- Favor early returns, guard clauses, and early exits. Avoid heavily nested
  `if-else` blocks or deeply indented logic.
- Write clean, readable code that minimizes cognitive load.
- Minimize scope creep; solve the task in front of you first.
- Always add plans OUTSIDE the runtime and universe repositories.

### Commenting

- Be conservative on how many comments you add. Name variables, functions, etc.,
  so the code speaks for itself.
- Comment only where a reader of the code could reasonably be confused, and keep
  comments concise and short.

Bad Example 1 (AI written, over-explained):

```java
/**
 * Abort fetching: cancel in-flight fetch requests where possible and wait for them to
 * settle. After this returns, `emit` is not invoked again. The connection remains usable
 * for [[ack]]/[[nack]]/[[extendLease]] until [[close]].
 * Idempotent and must not throw.
 */
```

Fixed (pruned for unnecessary details):

```java
/**
 * Abort fetching. Cancel in-flight fetch requests where possible and wait for them to
 * settle. After this returns, `emit` is not invoked again.
 * Idempotent and must not throw.
 */
```

Bad Example 2:

```java
// Create a subscriber which will be used to pull messages in current partition.
// The coordinator's fetcher takes ownership and releases it on close().
```

Fixed:

```java
// Create a subscriber which will be used to pull messages in current partition.
```

Bad Example 3:

```java
/** Stateless top-level object so it serializes by module reference when captured into executor
 *  closures (mirrors how `PubSubErrors` is captured today).
 */
```

Fixed: do not even write a comment like this. It sounds like it belongs in the
output of a reasoning thought chain, not in production code.

### Committing

- Never add yourself as a co-author.
- Keep the body of commit messages short, and most commits do not even need one.
- Use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/). If
  there is a Jira ticket ID, use it as the scope, e.g. `refactor(SC-232683): ...`

## Voice Style

When asked to write a description (e.g. a Jira ticket) or a comment (e.g. on a
PR), keep things straightforward.

Example (BAD):

> Description: The shared QueueFetchWriteCoordinator inherited Pub/Sub's polling fetch loop, which wastes up to 500ms detecting client halt/errors and flush-ready buffers, and overshoots maxFetchPeriodMs by up to one wait tick. Replace QueueClient.isFetching/getException with startFetching(emit): Future[Unit] (behavior-neutral) and gate the timing fixes behind a DBR conf defaulting to legacy semantics, ramped via SAFE before removing the old path.

Example (GOOD/FIXED):

> Description: The shared queue fetch loop polls on a fixed 500ms timer, so it can be half a second late to notice that fetching finished or failed, that buffered messages are ready to write, or that the fetch period is up. Rework the QueueClient interface so the client signals these events directly and the loop reacts immediately, with the new timing behind a config flag (off by default) so existing Pub/Sub streams keep their current behavior until we ramp it up.

## Formatting Rules

- Use straight apostrophes and quotation marks as opposed to curly.
- Avoid the overuse of em-dashes and semicolons.

@work-context.md

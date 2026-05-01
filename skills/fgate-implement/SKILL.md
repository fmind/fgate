---
name: fgate-implement
description: Use when executing a planned task — drive every checklist criterion to passes:true, run the verifier yourself, end with an explicit completion tag.
paths:
  - ".agents/gates/**"
---

# fgate-implement

You are the loop. Drive the §Acceptance checklist in `agent/prompt.md` until every criterion's `passes: true`, or until a hard stop fires. End with one of the four completion tags below — never with prose only. Resume cleanly when re-invoked: prior trace + checklist state is the source of truth.

## 1. Read the spec

1. Resolve to `.agents/gates/<id>-<slug>/`.
2. Read `agent/plan.md` end-to-end (per-file changes, TDD order, Coverage).
3. Read `agent/prompt.md` §Acceptance checklist — this is your exit condition.
4. If `agent/trace.md` already has entries: this is a resume. Re-read it; don't restart from scratch. Pick up at the first criterion still `passes: false`.
5. Refuse to start only if `[NEEDS CLARIFICATION:` markers remain anywhere in the gate dir.

## 2. The loop

```text
budget = 90 tool calls   # rough cap; spend deliberately
streak = 0               # consecutive turns where the verifier didn't advance
loop:
  pick the highest-priority criterion with passes: false (TDD order from plan)
  drive plan changes for it:
    1. test first — write/extend the failing test
    2. confirm it fails for the right reason
    3. make the source change
    4. re-run the test + relevant lint
  run the criterion's `verify:` command from agent/prompt.md
  if pass:
    flip its `passes: false` to `passes: true` in agent/prompt.md
    flip the `[ ]` checkbox to `[x]` in human/prompt.md
    append a one-liner to human/trace.md and a block to agent/trace.md
    streak = 0
  else:
    streak += 1
    if streak >= 5: stop with `<gate-status>BLOCKED: stalled on <criterion></gate-status>` (§4)
  if all criteria pass: break
  if budget exhausted: stop with `<gate-status>BUDGET: <pass>/<total></gate-status>`
```

One criterion at a time. Don't fan out. `[P]`-marked plan files may run in parallel; serialize anything else. Resist scope creep — park ideas in `agent/result.md` §Deferred.

## 3. Trace logs (append-only)

`human/trace.md`:

```text
HH:MM start
HH:MM ✓ <criterion> — <verifier output one-liner>
HH:MM ✗ <criterion> — <one-line reason>
HH:MM done <pass>/<total>
```

`agent/trace.md`:

````text
## HH:MM <event>

<command>

```text
<output trimmed to relevant lines>
```

Decision: <what>
Alternative: <if any, plus why rejected>
````

Never rewrite past entries.

## 4. Stop conditions

Stop only on:

- Auth / credential failure — `<gate-status>BLOCKED: <reason></gate-status>`
- Destructive op the plan didn't sanction (`rm -rf`, force-push, `DROP TABLE`) — same.
- Irreversible architectural choice the plan didn't decide — `<gate-status>DECIDE: <one-line question></gate-status>`
- 5 consecutive turns where the same verifier didn't advance — `<gate-status>BLOCKED: stalled on <criterion></gate-status>`
- 90-tool-call budget exhausted with criteria failing — `<gate-status>BUDGET: <pass>/<total></gate-status>`

For everything else (flaky test, missing import, lint warning, doc typo) — keep going.

## 5. Final sweep

When the loop says all green, do a clean re-run from a fresh shell:

1. Run every `verify:` from §Acceptance checklist plus the plan's full test/lint commands. Retry up to 3 times if anything regresses.
2. Walk the §Acceptance checklist. Every row should be `passes: true` with a captured verifier output. No `[VERIFY:` markers — if one remains, the loop is not done; resume §2.
3. Behavioural / UI changes: attach a screenshot or log excerpt — type-checks alone don't prove a feature works.

## 6. Write result artifacts

`human/result.md`:

```text
# Result: <id>-<slug>

## Status: COMPLETE | BLOCKED | DECIDE | BUDGET

## What works

- <bullet>

## Pending / non-critical

- <bullet>

## Suggested follow-ups

- <bullet>
```

`agent/result.md`:

```text
# Result: <id>-<slug>

## Summary

<one paragraph>

## Decisions

- <decision> — <why X over Y>

## Coverage

| # | Criterion | Verifier | Output | Status |
| - | --- | --- | --- | --- |
| 1 | <text> | `<cmd>` | `<one-line output>` | pass |

## Deferred

- <bullet>

## Files touched

<git diff --stat>
```

## 7. Hand off

End the response with exactly **one** completion tag on its own line:

- `<gate-status>COMPLETE</gate-status>` — every criterion passes.
- `<gate-status>BLOCKED: <reason></gate-status>` — hard stop.
- `<gate-status>DECIDE: <question></gate-status>` — user decision required.
- `<gate-status>BUDGET: <pass>/<total></gate-status>` — out of budget.

When and only when the tag is `COMPLETE`, follow with `Next: /fgate:review <id>`.

---
name: fgate-implement
description: Use when executing a planned task — drive the acceptance checklist to all-passing, run the verifier yourself, end with an explicit completion signal.
paths:
  - ".agents/gates/**"
---

# fgate-implement

Execute the plan and self-verify until every acceptance criterion's `passes: true`. You are the loop. Do not hand off until the checklist is green or you hit a hard stop condition. Gather proof of work as you go — command outputs, test runs — so `/fgate:review` only has to confirm.

## 1. Read the spec

1. Resolve the task to `.agents/gates/<id>-<slug>/`.
2. Read `agent/plan.md` end-to-end. Internalize per-file changes, dependencies, the test plan, exit criteria, and the Coverage table.
3. Read `agent/prompt.md` §Acceptance checklist. This is the loop's exit condition: keep going until every criterion passes.
4. Refuse to start only if `[NEEDS CLARIFICATION:` markers remain. Otherwise proceed.

## 2. Execute the loop

Pseudo-code:

```text
budget = 90 tool calls
streak = 0   # consecutive turns where verifier did not advance
loop:
  pick the highest-priority criterion with passes: false
  drive the matching plan changes:
    1. test first — write/extend the test the plan's "Test order" points at
    2. run it; confirm it fails for the right reason
    3. make the source change
    4. re-run the test plus relevant lint
  run the criterion's `verify:` command from `agent/prompt.md`
  if pass:
     flip the criterion's `passes: false` to `passes: true` in agent/prompt.md
     append a one-liner to human/trace.md and a block to agent/trace.md
     streak = 0
  else:
     streak += 1
     if streak >= 5: see §4 Stop conditions
  if all criteria pass: break
  if budget exhausted: see §4
```

Notes:

- One criterion at a time. Don't fan out across criteria — each one is the test that proves a slice of work is done.
- `[P]`-marked plan files may run via parallel subagents (Agent tool / Gemini's dispatch). Serialise anything not marked `[P]`.
- Resist scope creep. If the plan didn't say it, don't ship it. Park ideas in `agent/result.md` §Deferred.

## 3. Trace logs (append-only)

`human/trace.md` — key events, one line each:

```text
HH:MM start
HH:MM ✓ <criterion> — <verifier output one-liner>
HH:MM ✗ <criterion> — <one-line reason>
HH:MM blocker: <one line>
HH:MM done <pass>/<total>
```

`agent/trace.md` — full execution log. One block per event:

````text
## HH:MM <event>

<command run>

```text
<output trimmed to the relevant lines>
```

Decision: <what you decided>
Alternative considered: <if any, plus why rejected>
````

Append-only. Never rewrite past entries.

## 4. Stop conditions

Stop and surface to the user **only** for:

- Authentication / credential failures the agent cannot resolve. → `<gate-status>BLOCKED: <reason></gate-status>`
- Destructive operations the plan didn't sanction (`rm -rf`, force-push, `DROP TABLE`). → `<gate-status>BLOCKED: <reason></gate-status>`
- Irreversible architectural choices the plan didn't decide. → `<gate-status>DECIDE: <one-line question></gate-status>`
- 5 consecutive turns where the same criterion's verifier did not advance, and each fix made the diff worse or no different. → `<gate-status>BLOCKED: stalled on <criterion></gate-status>`
- 90-tool-call budget exhausted with criteria still failing. → `<gate-status>BUDGET: <pass>/<total></gate-status>`

For everything else — flaky test, missing import, lint warning, doc typo — keep going.

## 5. Final verification & proofs

Once the loop says all criteria pass, do one consolidating sweep:

1. Run the full test suite, lint, type-check (whatever the plan listed) **from a clean shell**. Fix and retry up to 3 times. Capture the final commands and outputs verbatim — these are the proofs.
2. Walk the §Acceptance checklist from `agent/prompt.md`. For each criterion, record the verifier command and its output in `agent/result.md` §Coverage. No `[VERIFY:` markers should remain — if one does, the loop is not actually done; resume §2.
3. For UI or behavioural changes, attach a screenshot or log excerpt — type-checks alone don't prove a feature works.

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

## Alternatives considered

- <alternative> — <why rejected>

## Coverage

| Criterion | Verifier | Output | Status |
| --- | --- | --- | --- |
| <criterion> | `<cmd>` | `<one-line output>` | pass |

## Deferred

- <follow-up scope>

## Files touched

<output of `git diff --stat`>
```

## 7. Hand off

End the response with **exactly one** of the following lines, on its own line, no surrounding prose:

- `<gate-status>COMPLETE</gate-status>` — every criterion passes; user runs `/fgate:review <id>` to ship.
- `<gate-status>BLOCKED: <reason></gate-status>` — hard stop; user must unblock before resuming.
- `<gate-status>DECIDE: <one-line question></gate-status>` — user decision required.
- `<gate-status>BUDGET: <pass>/<total></gate-status>` — budget exhausted; user inspects `agent/trace.md` and decides whether to extend.

Then a single follow-up line `Next: /fgate:review <id>` (only when status is COMPLETE).

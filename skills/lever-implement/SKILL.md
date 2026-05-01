---
name: lever-implement
description: Use when executing a planned task — drive every checklist criterion to passes:true, run the verifier yourself, end with an explicit completion tag.
---

# lever-implement

You are the loop. Drive the §Acceptance checklist in `agent/prompt.md` until every criterion's `passes: true`, or until a hard stop fires.

Close `agent/result.md` with one of the four completion tags from §7 — never with prose only. Resume cleanly when re-invoked: prior trace + checklist state is the source of truth.

## 1. Read the spec

Resolve to the lever dir at `.agents/levers/<id>-<slug>/`. Read `agent/plan.md` end-to-end (per-file changes, TDD order, Coverage) and `agent/prompt.md` §Acceptance checklist (your exit condition). If `agent/trace.md` already has entries this is a resume — re-read and pick up at the first `passes: false` criterion. Refuse to start only if `[NEEDS CLARIFICATION:` markers remain anywhere in the lever dir.

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
    if streak >= 5: stop with `<lever-status>BLOCKED: stalled on <criterion></lever-status>` (§4)
  if all criteria pass: break
  if budget exhausted: stop with `<lever-status>BUDGET: <pass>/<total></lever-status>`
```

One criterion at a time. Don't fan out. `[P]`-marked plan files may run in parallel; serialize anything else. Resist scope creep — park ideas in `agent/result.md` §Deferred.

Do not introduce verification steps beyond what the §Acceptance checklist requires. If a `verify:` is grep-based, do not run a build, type-check, or extra test suite the verifier doesn't ask for.

## 3. Trace logs (append-only)

`human/trace.md` — one line per event: `HH:MM start` / `HH:MM ✓ <criterion> — <verifier output>` / `HH:MM ✗ <criterion> — <reason>` / `HH:MM done <pass>/<total>`.

`agent/trace.md` — one block per event: `## HH:MM <event>`, the command, output (trimmed to relevant lines, in a code fence), then `Decision:` and optional `Alternative:`.

Never rewrite past entries.

## 4. Stop conditions

Stop only on:

- Auth / credential failure — `<lever-status>BLOCKED: <reason></lever-status>`
- Destructive op the plan didn't sanction (`rm -rf`, force-push, `DROP TABLE`) — same.
- Irreversible architectural choice the plan didn't decide — `<lever-status>DECIDE: <one-line question></lever-status>`
- 5 consecutive turns where the same verifier didn't advance — `<lever-status>BLOCKED: stalled on <criterion></lever-status>`
- 90-tool-call budget exhausted with criteria failing — `<lever-status>BUDGET: <pass>/<total></lever-status>`

For everything else (flaky test, missing import, lint warning, doc typo) — keep going.

## 5. Final sweep

When the loop says all green, do a clean re-run from a fresh shell:

1. Run every `verify:` from §Acceptance checklist plus the plan's full test/lint commands. Retry up to 3 times if anything regresses.
2. Walk the §Acceptance checklist. Every row should be `passes: true` with a captured verifier output; if any row is still `passes: false`, the loop is not done — resume §2.
3. Behavioural / UI changes: attach a screenshot or log excerpt — type-checks alone don't prove a feature works.

## 6. Write result artifacts

`human/result.md` — sections: §Status (COMPLETE | BLOCKED | DECIDE | BUDGET), §What works, §Pending / non-critical, §Suggested follow-ups.

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

The last line of `agent/result.md` is exactly one of:

- `<lever-status>COMPLETE</lever-status>` — every criterion passes.
- `<lever-status>BLOCKED: <reason></lever-status>` — hard stop.
- `<lever-status>DECIDE: <question></lever-status>` — user decision required.
- `<lever-status>BUDGET: <pass>/<total></lever-status>` — out of budget.

The chat reply ends with the same line, so a streaming host can chain without reading the artifact. When and only when the tag is `COMPLETE`, include `Next: /lever-review <id>` on the line directly above the tag. Optionally precede `Next:` with an `Other options: /lever-improve <id> (<lesson>)` line if a meta-process learning surfaced during the loop.

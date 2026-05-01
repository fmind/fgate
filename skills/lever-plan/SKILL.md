---
name: lever-plan
description: Use when turning a captured prompt into a per-file specification — investigate the codebase, sharpen the acceptance checklist, resolve clarifications by reading not asking.
---

# lever-plan

Convert `agent/prompt.md` into a per-file spec and a TDD-ordered test plan. Resolve `[NEEDS CLARIFICATION:` markers through investigation; only the truly irreducible ones get escalated.

## 1. Locate and read

Argument is `<id>` or a slug fragment. Resolve to `.agents/levers/<id>-<slug>/`. If multiple match, pick the lowest `<id>` and note it in `agent/plan.md`.

Read `agent/prompt.md` end-to-end (each `verify:` is a fixed contract) plus `AGENTS.md` §Conventions.

## 2. Investigate (parallel where possible)

- **Existing code.** Grep / Glob the modules and tests touched by the change. Read each file you intend to modify.
- **External docs.** Read URLs the prompt references. Summarize the load-bearing facts inline in `agent/plan.md`.
- **Cross-task knowledge.** If the project already installs a docs/memory skill that owns shared notes, defer to it; otherwise inline the fact in `agent/plan.md`. Don't invent new top-level folders here.

## 3. Sharpen, don't expand

For each criterion in §Acceptance checklist:

1. Confirm its `verify:` runs from the workspace root. Fix if it doesn't.
2. Map it to file(s) and test(s) (see §Coverage table below).
3. Decide TDD order — which failing test gates which source change.

Don't silently add criteria. If investigation surfaces a missing one, append it to `agent/prompt.md` §Acceptance checklist with `passes: false` AND list it in `human/plan.md` §New criteria so the human spots the addition.

## 4. Surface blockers

Escalate only when the choice is irreversible and the prompt didn't decide it. Otherwise advance.

## 5. Write artifacts

`human/plan.md` (skim in 30s) — sections: §Changes (one bullet per file), §Risks (risk → mitigation), §New criteria (added during plan, if any).

`agent/plan.md`:

```text
# Plan: <id>-<slug>

## Goal

<one sentence>

## Per-file changes

### `<path>` `[P]?`

- Add: <function/section>
- Modify: <function/section>
- Why: <one line>
- Test order: <test name in §Test plan, or "n/a">

## Dependencies

- <new package> (version, why)

## Test plan (TDD order)

1. <test name / file>: <what it verifies>
   Run: `<exact command>`

## Coverage

| Criterion (from agent/prompt.md) | Verifier | Files / tests |
| --- | --- | --- |
| <criterion> | `<verify cmd>` | `<file>`, `<test>` |

Every checklist item maps to ≥ 1 row.

## Risks & mitigations

- <bullet>

## Deferred

- <bullet>
```

`[P]` marks a file whose change touches no shared state and may run in parallel with other `[P]` files.

## 6. Hand off

The last line of `agent/plan.md` is exactly one of:

- `<lever-status>COMPLETE</lever-status>` — plan written, every checklist item covered, no escalations.
- `<lever-status>BLOCKED: <reason></lever-status>` — codebase reality conflicts with the prompt and the conflict is not resolvable here.
- `<lever-status>DECIDE: <topic></lever-status>` — irreducible clarification surfaced in §4.

The chat reply ends with the same line, so a streaming host can chain without reading the artifact. When and only when the tag is `COMPLETE`, include `Next: /lever-implement <id>` on the line directly above the tag.

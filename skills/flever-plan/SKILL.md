---
name: flever-plan
description: Use when turning a captured prompt into a per-file specification — investigate the codebase, sharpen the acceptance checklist, resolve clarifications by reading not asking.
paths:
  - ".agents/levers/**"
---

# flever-plan

Convert `agent/prompt.md` into a per-file spec and a TDD-ordered test plan. Resolve `[NEEDS CLARIFICATION:` markers through investigation; only the truly irreducible ones get escalated.

## 1. Locate the task

Argument is `<id>` or a slug fragment. Resolve to `.agents/levers/<id>-<slug>/`. If multiple match, pick the lowest `<id>` and note the choice in `agent/plan.md`.

## 2. Read

1. `agent/prompt.md` end-to-end. Pay attention to the §Acceptance checklist — each `verify:` is a fixed contract.
2. `AGENTS.md` §Conventions and §Commands.
3. `[NEEDS CLARIFICATION:` markers — default behaviour: resolve in §3 by investigation. Only escalate one in §5 if the decision is irreversible AND no defensible default exists.

## 3. Investigate (parallel where possible)

- **Existing code.** Grep / Glob the modules and tests touched by the change. Read each file you intend to modify.
- **External docs.** Read URLs the prompt references; persist a digest in `.agents/docs/external/<topic>.md` for reuse.
- **Cross-task knowledge.** Capture facts other tasks will need (auth flow, schema, deploy steps) in `.agents/docs/<topic>.md`. One topic per file, ≤ 200 lines, optional `last-updated:` front matter.

## 4. Sharpen, don't expand

For each criterion in §Acceptance checklist:

1. Confirm its `verify:` runs from the workspace root. Fix if it doesn't.
2. Map it to file(s) and test(s) (see §Coverage table below).
3. Decide TDD order — which failing test gates which source change.

Don't silently add criteria. If investigation surfaces a missing one, append it to `agent/prompt.md` §Acceptance checklist with `passes: false` AND list it in `human/plan.md` §New criteria so the human spots the addition.

## 5. Surface blockers (rare)

Only escalate when:

- An irreversible architectural choice is required and the prompt didn't decide it.
- A capability or credential is missing that the agent genuinely cannot provision.
- A criterion conflicts with codebase reality (file doesn't exist, feature already shipped).

Otherwise advance.

## 6. Write artifacts

`human/plan.md` (skim in 30s):

```text
# Plan: <id>-<slug>

## Changes

- `<file path>`: <one-line summary>

## Risks

- <risk> → <mitigation>

## New criteria (added during plan, if any)

- <criterion> — why
```

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

`[P]` marks a file whose change touches no shared state and may run in parallel with other `[P]` files.

## Dependencies

- <new package> (version, why)

## Test plan (TDD order)

1. <test name / file>: <what it verifies>
   Run: `<exact command>`
2. ...

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

## 7. Hand off

End with exactly one tag on its own line, then `Next:` when applicable:

- `<gate-status>COMPLETE</gate-status>` — plan written, every checklist item covered, no escalations.
- `<gate-status>BLOCKED: <reason></gate-status>` — codebase reality conflicts with the prompt and the conflict is not resolvable here.
- `<gate-status>DECIDE: <topic></gate-status>` — irreducible clarification surfaced in §5.

```text
Next: /flever:implement <id>
```

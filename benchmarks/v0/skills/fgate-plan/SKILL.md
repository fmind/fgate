---
name: fgate-plan
description: Use when investigating the codebase to turn a captured prompt into a per-file spec with refined criteria.
paths:
  - ".agents/gates/**"
---

# fgate-plan

Convert `agent/prompt.md` into a precise specification. Advance silently when the prompt is concrete; surface only blocking decisions.

## 1. Locate the task

The argument is `<id>` or a slug fragment. Resolve to `.agents/gates/<id>-<slug>/`. If multiple match, ask which one.

## 2. Read the prompt

1. Read `agent/prompt.md` end-to-end. Note every criterion, scope boundary, and clarification marker.
2. Re-read `AGENTS.md` — especially `## Conventions` — for rules that constrain the change.
3. Scan for `[NEEDS CLARIFICATION:` markers. Each one must be resolved before §6: either by investigation in §3 (the codebase or external docs answer it) or by escalating in §5. Never silently guess.

## 3. Investigate

Investigate in parallel where possible (parallel subagents / parallel tool calls):

- **Existing code**: Grep / Glob the modules and tests touched by the change. Read each file you intend to modify or extend.
- **External docs**: read URLs the prompt references. Persist a digest in `.agents/docs/external/<topic>.md` so future tasks can reuse it.
- **Cross-task knowledge**: when you uncover a fact other tasks will need (auth flow, schema, deploy steps), capture it in `.agents/docs/<topic>.md`. Per-task scratch stays in `agent/plan.md`, not `.agents/docs/`.

`.agents/docs/` constraints:

- One topic per file.
- ≤ 200 lines each — split when longer.
- Optional `last-updated: YYYY-MM-DD` front matter so the next task knows whether to refresh.

## 4. Refine criteria

Sharpen each criterion from the prompt with file-level granularity. Do **not** introduce new criteria the user has not sanctioned. If a new one is necessary, ask first.

## 5. Surface blockers (only when needed)

Surface a decision to the user only for:

- Irreversible architectural choices not decided in the prompt (data migration, schema rename, public-API break).
- Missing capability or credential the agent cannot resolve.
- Conflict between the criteria and the codebase reality (the feature is already implemented; the file does not exist).

Otherwise advance silently.

## 6. Write artifacts

`human/plan.md` — skim in 30 seconds:

```text
# Plan: <id>-<slug>

## Changes

- `<file path>`: <one-line summary>

## Risks

- <risk> → <mitigation>

## Criteria

- [ ] <refined criterion>
```

`agent/plan.md` — precise spec:

```text
# Plan: <id>-<slug>

## Goal

<one sentence>

## Per-file changes

### `<relative/path/to/file.ext>` `[P]?`

- Add: <function/section>
- Modify: <function/section>
- Why: <one line>
- Test order: <which test in §Test plan gates this change; or "n/a — refactor of covered code">
- Notes: <invariants, edge cases, references>

Append `[P]` to the file path when the change touches no shared state and may run concurrently with other `[P]` files. Without `[P]`, assume serial.

## Dependencies

- <new package or service> (version, why)

## Test plan

- <test name / file>: <what it verifies>
- Run: `<exact command>`

List tests in the order `/fgate:implement` should write them (TDD): each test entry is paired with a "Test order" line in §Per-file changes, so the failing test always precedes the source change that turns it green.

## Exit criteria

<refined, file-level — what proves the task is done>

## Coverage

| Criterion | Files / tests that satisfy it |
| --- | --- |
| <criterion 1> | `<file>`, `<test name>` |
| <criterion 2> | `<file>`, `<test name>` |

Every criterion in `agent/prompt.md` maps to at least one row. A criterion with no row means the plan is incomplete — fill the gap before committing.

## Risks & mitigations

- <bullet>

## Deferred

<scope explicitly out of this task>
```

## 7. Hand off

End with exactly:

```text
Next: /fgate:implement <id>
```

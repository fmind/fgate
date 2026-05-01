---
name: fgate-plan
description: Use when turning a captured prompt into a per-file specification — investigate the codebase, sharpen the acceptance checklist, never escalate what investigation can resolve.
paths:
  - ".agents/gates/**"
---

# fgate-plan

Convert `agent/prompt.md` into a precise per-file spec and a TDD-ordered test plan. Resolve every `[NEEDS CLARIFICATION:` marker through investigation; only the truly irreducible ones get escalated.

## 1. Locate the task

The argument is `<id>` or a slug fragment. Resolve to `.agents/gates/<id>-<slug>/`. If multiple match, pick the lowest `<id>` and note the disambiguation in `agent/plan.md`.

## 2. Read the prompt

1. Read `agent/prompt.md` end-to-end. Note every criterion (with its `verify:` command), scope boundary, assumption, and clarification marker.
2. Re-read `AGENTS.md` — especially `## Conventions` and `## Commands` — for rules that constrain the change.
3. Scan for `[NEEDS CLARIFICATION:` markers. Default behaviour: resolve them in §3 by investigating. Only escalate one in §5 if all three of these hold: irreversible decision, no defensible default, conflicting context.

## 3. Investigate

Investigate in parallel where possible (parallel subagents / parallel tool calls):

- **Existing code.** Grep / Glob the modules and tests touched by the change. Read each file you intend to modify or extend.
- **External docs.** Read URLs the prompt references. Persist a digest in `.agents/docs/external/<topic>.md` so future tasks can reuse it.
- **Cross-task knowledge.** When you uncover a fact other tasks will need (auth flow, schema, deploy steps), capture it in `.agents/docs/<topic>.md`. Per-task scratch stays in `agent/plan.md`, not `.agents/docs/`.

`.agents/docs/` constraints:

- One topic per file.
- ≤ 200 lines each — split when longer.
- Optional `last-updated: YYYY-MM-DD` front matter so the next task knows whether to refresh.

## 4. Sharpen the acceptance checklist

For each criterion in `agent/prompt.md` §Acceptance checklist:

1. Confirm its `verify:` command is concrete and runs from the workspace root. If not, fix it.
2. Map it to the file(s) and the test(s) that will satisfy it (Coverage table below).
3. Decide TDD order — which failing test gates which source change.

Do not silently add new criteria. If investigation surfaces a missing one (e.g., a security requirement the prompt didn't mention), add it to `agent/prompt.md` §Acceptance checklist with `passes: false` and note it in `human/plan.md` §New criteria so the user can spot the addition.

## 5. Surface blockers (rare)

Surface a decision to the user only when:

- An irreversible architectural choice is required and the prompt did not decide it.
- A missing capability or credential the agent genuinely cannot resolve (no install path, no config, no fixture).
- A conflict between the criteria and the codebase reality (the feature is already implemented; the file does not exist).

Otherwise advance silently. Most "I'm not sure" moments resolve themselves once you've grep'd the codebase.

## 6. Write artifacts

`human/plan.md` — skim in 30 seconds:

```text
# Plan: <id>-<slug>

## Changes

- `<file path>`: <one-line summary>

## Risks

- <risk> → <mitigation>

## Criteria (mirrors agent/prompt.md)

- [ ] <criterion>

## New criteria (added during plan, if any)

- <criterion> — why
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

## Test plan (TDD order)

1. <test name / file>: <what it verifies>
   Run: `<exact command>`
2. ...

List tests in the order `/fgate:implement` writes them: failing test → source change that turns it green → next test.

## Coverage

| Criterion (from agent/prompt.md) | Verifier | Files / tests |
| --- | --- | --- |
| <criterion 1> | `<verify cmd>` | `<file>`, `<test name>` |
| <criterion 2> | `<verify cmd>` | `<file>`, `<test name>` |

Every checklist item in `agent/prompt.md` maps to at least one row. A criterion with no row means the plan is incomplete — fill the gap before handing off.

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

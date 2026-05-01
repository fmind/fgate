---
name: flever-prompt
description: Use when capturing user intent for a new task — turn the ask into a runnable acceptance checklist, log assumptions, never ask the user.
---

# flever-prompt

Lock down a checklist of mechanically verifiable criteria. Default aggressively from project context; assumptions go in the artifact, not the chat.

## 1. Resolve workspace

1. New `<id>` = max of `.agents/levers/<id>-*` + 1, starting at 1.
2. Slug the title (lower snake_case, ≤ 40 chars). On collision pick the next free slug.
3. `mkdir -p .agents/levers/<id>-<slug>/{human,agent}`.

## 2. Ground in context

Read in order: `AGENTS.md` (and nested ones), `README.md`, the user ask, any spec file the ask points at (`TASK.md`, design doc, link). For every gap, pick a sensible default and **log it in §Assumptions**. Never block on a question. The human reviews the checklist + assumptions in `human/prompt.md` — that's the feedback channel.

A gap escalates as `[NEEDS CLARIFICATION:` only when the decision is irreversible (data migration, public-API break, security posture) AND the project context offers no defensible default AND picking wrong invalidates the whole task. Otherwise: pick a default, log it, move on.

## 3. Build the checklist

Each criterion is a one-liner whose `verify:` resolves to a single shell exit code from the workspace root. Aim for 4–8. Mechanical only — no "works", "looks good", "robust".

Examples of acceptable verifiers:

- `pytest -q` → exit 0 with ≥ 5 tests.
- `[ "$(printf '... ' | mytool)" = "$(printf '...')" ]`
- `ruff check .` → exit 0.
- `Given/When/Then` whose verifier is one named test (`pytest tests/x.py::test_y`).

## 4. Write artifacts

`human/prompt.md` (≤ 35 lines):

```text
# <id>-<slug>: <title>

## Ask

<one paragraph>

## Acceptance checklist

- [ ] <criterion>

## Assumptions

- <assumption defaulted from <source>>
```

`agent/prompt.md`:

```text
# <id>-<slug>: <title>

## Ask

<full intent, paraphrased only when ambiguous>

## Context sources

- <file>: <relevant fact>

## Acceptance checklist

- [ ] criterion: <text>
  verify: `<exact shell command>`
  passes: false

## Assumptions

- <assumption> — defaulted from <source>; flip in `human/prompt.md` to override.

## Scope boundaries

- in scope: <bullets>
- explicitly deferred: <bullets>

## Clarifications needed

<one `[NEEDS CLARIFICATION: <topic> — <ask>]` per genuinely-blocking gap, or "None">
```

## 5. Hand off

End the response with exactly:

```text
Next: /flever:plan <id>
```

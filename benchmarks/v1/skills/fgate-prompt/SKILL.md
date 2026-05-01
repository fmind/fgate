---
name: fgate-prompt
description: Use when capturing user intent for a new task — pin success criteria as a checklist and prepare the gate workspace. Default aggressively from project context; never block on questions.
---

# fgate-prompt

Capture user intent and lock down a verifiable acceptance checklist. Run autonomously: read the project, infer reasonable defaults, log assumptions, never wait on the user.

## 1. Resolve the task ID and workspace

1. List `.agents/gates/<id>-*` directories. New `<id>` = max + 1, no zero-padding. Start at `1`. Gate dirs follow `<id>-<slug>` (e.g. `1-social_auth`).
2. Slug the title from the user's input: lowercase, snake_case, alphanumeric and underscores only, ≤ 40 chars.
3. `mkdir -p .agents/gates/<id>-<slug>/{human,agent}`. If the directory already exists, pick the next free slug and proceed — never refuse.

## 2. Ground the prompt in project context (no questions)

Read, in order, before drafting anything:

- `AGENTS.md` (and any nested `AGENTS.md` in directories the task plausibly touches).
- `README.md` if present.
- The user's literal ask.
- Any task brief file the user pointed at (e.g. `TASK.md`, a linked spec).

Do **not** ask the user clarifying questions. For every gap, decide a default from the project's conventions or the surrounding context, and log it in §4 under **Assumptions**. The user reviews assumptions in `human/prompt.md`; that's the feedback channel.

A gap is only a `[NEEDS CLARIFICATION:` marker if **all three** are true:

- The decision is irreversible (data migration, public-API break, security posture).
- The project context offers no defensible default.
- Picking wrong would invalidate the whole task.

Otherwise: pick a default, log it, move on.

## 3. Build the acceptance checklist

The checklist is a list of mechanically verifiable criteria — each one is a shell command, a file-content predicate, or a `Given/When/Then` whose verifier is a single command. Each criterion gets a `passes: false` flag that `/fgate:implement` and `/fgate:review` flip to `true` once verified.

Aim for 4–8 criteria. Examples (the mechanical bit is mandatory):

- `pytest -q` exits 0 with ≥ 5 tests collected.
- `printf 'a b a' | wordfreq` outputs exactly `2\ta\n1\tb\n`.
- `ruff check .` exits 0.
- `POST /login` with valid creds returns 200 and a `Set-Cookie` header (covered by `tests/test_login.py::test_valid_creds`).

Vague criteria ("works", "looks good", "is robust") are forbidden. Sharpen them before writing.

## 4. Write artifacts

`human/prompt.md` — terse, ≤ 35 lines:

```text
# <id>-<slug>: <title>

## Ask

<one paragraph — what the user wants>

## Acceptance checklist

- [ ] <criterion 1>
- [ ] <criterion 2>

## Assumptions

- <assumption defaulted from context>
```

`agent/prompt.md` — full detail:

```text
# <id>-<slug>: <title>

## Ask

<full statement of intent, paraphrased only when the user was ambiguous>

## Context sources

- AGENTS.md: <relevant bullets>
- TASK.md / spec file: <path, if any>
- Other: <file:line refs>

## Acceptance checklist

- [ ] criterion: <text>
  verify: `<exact shell command or predicate>`
  passes: false
- [ ] criterion: <text>
  verify: `<...>`
  passes: false

## Assumptions

- <assumption> — defaulted from <source>; flip in `human/prompt.md` to override.

## Scope boundaries

- in scope: <bullets>
- explicitly deferred: <bullets>

## Clarifications needed

<one `[NEEDS CLARIFICATION: <topic> — <one-line ask>]` per genuinely-blocking gap, or "None">
```

## 5. Hand off

End the response with exactly:

```text
Next: /fgate:plan <id>
```

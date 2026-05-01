---
name: fgate-prompt
description: Use when capturing user intent for a new task — define success criteria and prepare the gate workspace.
---

# fgate-prompt

Capture user intent. The human's attention is highest here — spend it well.

## 1. Resolve the task ID and workspace

1. List `.agents/gates/<id>-*` directories. New `<id>` = max + 1, no zero-padding. Start at `1`. Gate dir names follow `<id>-<slug>` (e.g. `1-social_auth`, `42-session_cookies`).
2. Slug the title: lowercase, snake_case, alphanumeric and underscores only, ≤ 40 chars.
3. `mkdir -p .agents/gates/<id>-<slug>/{human,agent}`. If the directory already exists, refuse and ask for a different title.

## 2. Challenge the prompt

The user gave you a title and maybe a sentence of context. Do **not** start writing yet. You may ask up to **3 targeted questions**. Stop earlier when criteria are concrete.

Use one question at a time. Each question must extract context the user has not volunteered AND would change the implementation.

Bad questions (skip these):

- "Should I add tests?" — defaults exist; read the repo.
- "What style guide?" — read `AGENTS.md`.
- "Anything else?" — open-ended; surfaces nothing.

Good questions:

- "OAuth, magic-link, or password sign-in?"
- "Drop the v1 schema or keep it backwards-compatible?"
- "What proves this is done — failing tests pass, or also a manual UI check?"

If after 3 questions the criteria are still vague, **stop**. Tell the user the task is not ready, list what is still ambiguous, and do not advance.

## 3. Define success criteria

Write **at least 2 concrete criteria** with the user. Concrete means a third party can run a check and see pass or fail. Examples:

- `pkg/auth/*_test.go` all pass.
- `POST /login` returns 200 with a `Set-Cookie` header for valid creds.
- Lighthouse a11y score ≥ 95 on `/dashboard`.

Vague criteria ("works", "looks good") are not acceptable. When a behavioural criterion is not obviously file-checkable, sharpen it as **Given X, when Y, then Z** so the verifier is mechanical:

- Given a logged-in user, when they POST `/logout`, then the response clears the session cookie and a fresh GET `/me` returns 401.

If the 3-question budget runs out before every input is resolved, do **not** invent answers. Carry the gaps forward as `[NEEDS CLARIFICATION: <topic> — <one-line ask>]` markers in `agent/prompt.md`. `/fgate:plan` resolves them via investigation or surfaces them back to you.

## 4. Write artifacts

`human/prompt.md` — terse skim, ≤ 30 lines:

```text
# <id>-<slug>: <title>

## Ask

<one paragraph — what the user wants>

## Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
```

`agent/prompt.md` — full detail:

```text
# <id>-<slug>: <title>

## Ask

<full statement of intent, paraphrased only where the user was ambiguous>

## Context

<every fact the user volunteered or confirmed during Q&A>

## Criteria

<criteria with the reasoning that made each one concrete>

## Scope boundaries

<in scope / explicitly deferred>

## Clarifications needed

<one `[NEEDS CLARIFICATION: <topic> — <ask>]` per unresolved input, or "None" if the prompt is fully concrete>
```

## 5. Hand off

End with exactly:

```text
Next: /fgate:plan <id>
```

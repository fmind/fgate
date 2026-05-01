---
name: flever-review
description: Use when finalizing an implemented task — re-run every verifier yourself, confirm the checklist is green, summarize the diff, pick one next action.
paths:
  - ".agents/levers/**"
---

# flever-review

Re-run the acceptance checklist's verifiers in a clean environment, confirm each one matches what `agent/result.md` claims, and pick exactly one primary action. Trust the artifacts as a starting point; trust the verifiers as ground truth.

## 1. Read the artifacts

1. Resolve the task to `.agents/levers/<id>-<slug>/`.
2. Skim `human/result.md`. Read `agent/result.md` end-to-end.
3. Re-open `agent/prompt.md` §Acceptance checklist and `agent/plan.md` §Coverage.
4. Re-read `AGENTS.md` §Conventions for rules the diff must respect.
5. Run `git status` and `git diff --stat` so you can summarize what changed.

## 2. Re-run the verifiers

For each criterion in `agent/prompt.md` §Acceptance checklist, run its `verify:` command **yourself** and capture the output. Do not trust `agent/result.md` blindly — it can drift from reality.

Render a one-screen tally:

```text
| # | Criterion | Verifier | Result | Note |
| - | --------- | -------- | ------ | ---- |
| 1 | <text>    | `<cmd>`  | pass   |      |
| 2 | <text>    | `<cmd>`  | fail   | <one-line> |
```

Plus the meta-checks:

- **Clarifications** — zero `[NEEDS CLARIFICATION:` markers in the lever dir.
- **Lint / format** — `markdownlint`, `prettier`, and any language-specific lint listed in `AGENTS.md` §Commands run clean (or n/a).
- **Conventions** — diff respects every `AGENTS.md` §Conventions bullet.

Any red row blocks **Ship it**. Either propose the smallest fix and apply it (when fix is obvious and ≤ 5 lines), or hand back with the failing rollup so `/flever:implement` can resume.

## 3. Pick one primary action

### a) Ship it (default)

Use this when every rollup row is pass and there are no blocking open questions.

1. Summarize the change in one line — what shipped and which criteria it satisfies.
2. Hand the diff back to the user. They decide how to integrate (commit, PR, merge, squash — flever stays out of that).

### b) Resume

Use this when one or more verifiers fail. Hand back to `/flever:implement <id>` with the failing rows pinpointed so it can pick up exactly where it stalled.

### c) Improve

Use this when the task surfaced a meta-process learning worth keeping (a recurring mistake, a missing AGENTS.md rule, an ambiguous skill step). Suggest `/flever:improve <id>`.

### d) Follow-up

Use this when `result.md` lists deferred scope that should become a new task. Suggest `/flever:prompt <follow-up-title>`.

## 4. Project-level overrides

Honor these if present:

- A user-side skill at `.agents/skills/flever-review/SKILL.md` → its body replaces this lever's end-game wholesale.

## 5. Hand off

End with exactly one completion tag on its own line, then a single-line `Other options:` footer:

- `<gate-status>SHIP: <pass>/<total></gate-status>` — every verifier passed; diff staged for the user.
- `<gate-status>RESUME: <pass>/<total> failing=<criterion></gate-status>` — at least one verifier failed; hand back to `/flever:implement <id>`.
- `<gate-status>IMPROVE: <one-line lesson></gate-status>` — task surfaced a meta-process learning worth `/flever:improve`.

Example:

```text
<gate-status>SHIP: 6/6</gate-status>

Other options: /flever:improve 1 (deferred-error pattern) · /flever:prompt session_cookies (follow-up).
```

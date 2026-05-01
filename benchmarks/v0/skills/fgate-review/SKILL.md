---
name: fgate-review
description: Use when finalizing an implemented task — confirm criteria, summarize the diff, surface follow-ups.
paths:
  - ".agents/gates/**"
---

# fgate-review

Read `agent/result.md`, align with the user, finalize the task. Pick exactly one primary action; mention alternatives in a single-line `Other options:` footer.

## 1. Read the artifacts

1. Resolve the task to `.agents/gates/<id>-<slug>/`.
2. Skim `human/result.md`. Read `agent/result.md` end-to-end.
3. Re-open `agent/plan.md` and verify each exit criterion mechanically where possible.
4. Re-read `AGENTS.md` `## Conventions` for rules the change must respect.
5. Run `git status` and `git diff --stat` so you can summarize what changed.

## 2. Run the checks rollup

Materialize a one-screen tally before picking an action. Each row resolves to pass / fail / n/a:

- **Coverage** — every row in `agent/plan.md` §Coverage has a matching row in `agent/result.md` §Coverage with no `[VERIFY:` notes.
- **Clarifications** — zero `[NEEDS CLARIFICATION:` markers anywhere in the gate dir.
- **Tests** — every command in `agent/plan.md` §Test plan reports green in `agent/result.md`.
- **Lint / format** — `markdownlint`, `prettier`, and any language-specific lint listed in `AGENTS.md` §Commands run clean (or n/a).
- **Conventions** — diff respects every `AGENTS.md` `## Conventions` bullet.

Render the rollup verbatim in the response. Any red row blocks **Ship it** — propose the fix or hand back to the user before continuing to §3.

## 3. Pick one primary action

### a) Ship it (default)

Use this when every rollup row is pass and there are no blocking open questions.

1. Summarize the change in one line — what shipped and which criteria it satisfies.
2. Hand the diff back to the user. They decide how to integrate it (commit, PR, merge, squash — fgate stays out of that).

### b) Improve

Use this when the task surfaced a meta-process learning worth keeping (a recurring mistake, a missing AGENTS.md rule, an ambiguous skill step). Suggest:

```text
Next: /fgate:improve <id>
```

### c) Follow-up

Use this when `result.md` lists deferred scope that should become a new task. Suggest:

```text
Next: /fgate:prompt <follow-up-title>
```

## 4. Project-level overrides

Honor these if present:

- A user-side skill at `.agents/skills/fgate-review/SKILL.md` → its body replaces this gate's end-game wholesale.

## 5. Hand off

End with the chosen primary action, then a single-line `Other options:` footer naming the alternatives.

Example:

```text
Ship it — `feat(auth): add password sign-in` is ready for review. Diff staged for the user.

Other options: /fgate:improve 1 (capture deferred-error pattern) · /fgate:prompt session_cookies (follow-up).
```

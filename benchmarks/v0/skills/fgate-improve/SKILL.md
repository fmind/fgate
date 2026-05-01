---
name: fgate-improve
description: Use when a task surfaced a meta-process lesson — emit a reviewable diff to AGENTS.md and/or skill bodies.
---

# fgate-improve

Produce a reviewable diff to the user-project `AGENTS.md` and/or one or more fgate `skills/fgate-<name>/SKILL.md` files. The diff is the deliverable; keep it as small as the lesson allows but as wide as it genuinely spans — restructuring is allowed when warranted.

## 1. Read the source material

1. Resolve the task to `.agents/gates/<id>-<slug>/`.
2. Read `agent/result.md` and the open-questions block in `human/result.md`.
3. Re-read `agent/trace.md` for `blocker:` and decision entries that suggest a reusable rule.

## 2. Pick the target

| Symptom                                                          | Target                                           |
| ---------------------------------------------------------------- | ------------------------------------------------ |
| Project convention drift, recurring mistake, missing fact        | Project `AGENTS.md`                              |
| Gate procedure flaw, ambiguous step, missing precondition        | `skills/fgate-<name>/SKILL.md` (fgate src)       |
| Cross-task project knowledge (auth, schema, deploy, conventions) | `.agents/docs/<topic>.md` — do in plan, not here |

A single improve may span any combination of these targets. `improve` mutates the meta-process only — project-domain knowledge belongs in `.agents/docs/` and should have been captured during plan.

## 3. Make the change

- AGENTS.md target → add, edit, or restructure bullets and sections as the lesson requires.
- skill body target → edit or restructure sections, bullets, or steps as the lesson requires.
- Span multiple files when the lesson genuinely spans them; the user gates the diff at review.
- If AGENTS.md feels at capacity, identify stale bullets to evict in the same diff and explain why.

## 4. Write artifacts

`human/improve.md` — one paragraph: what changed and why.

`agent/improve.md` — full detail:

```text
# Improve: <id>-<slug>

## Symptom

<what went wrong / what was unclear>

## Root cause

<one paragraph>

## Change

<diff summary — file + lines added/removed>

## Alternatives considered

- <bullet>

## Verification

<how the change will be validated next time it triggers>
```

## 5. Hand off

End the cycle. The diff sits in the working tree; the user decides how to integrate it.

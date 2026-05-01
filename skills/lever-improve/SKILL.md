---
name: lever-improve
description: Use when a task surfaced a meta-process lesson — emit a reviewable diff to the right context file (AGENTS.md by default) and/or skill bodies.
---

# lever-improve

Produce a reviewable diff that captures the lesson the task taught. The diff is the deliverable; keep it as small as the lesson allows but as wide as it genuinely spans — restructuring is allowed when warranted.

`improve` mutates the meta-process only — durable project-domain knowledge belongs in whatever notes/docs/memory mechanism the project already uses, captured during plan, not here.

## 1. Read the source material

1. Resolve the task to `.agents/levers/<id>-<slug>/`.
2. Read `agent/result.md` and the open-questions block in `human/result.md`.
3. Re-read `agent/trace.md` for `blocker:` and decision entries that suggest a reusable rule.

## 2. Pick the target

Two questions, in order:

1. **Is the lesson about how an `agent-levers` step should behave?** → edit the relevant `skills/lever-<step>/SKILL.md`. This is the only target for step-procedure changes.
2. **Otherwise, where does cross-cutting agent guidance live in this project?** Pick the first that exists:
   - A dedicated rules/memory skill installed in the project (e.g., a sibling `*-agent-docs` or memory skill the user has wired in) — defer to its conventions.
   - `AGENTS.md` at the repo root — **the default** when no specialized skill claims the surface.
   - `CLAUDE.md` / `GEMINI.md` only when they hold real content (not the `@AGENTS.md` one-liner shim).

| Symptom                                                          | Target                                                                                         |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Step procedure flaw, ambiguous instruction, missing precondition | `skills/lever-<step>/SKILL.md`                                                                 |
| Project convention drift, recurring mistake, missing fact        | Default: `AGENTS.md`. Override only if a more specific skill in the project owns this surface. |

A single improve may span any combination of these targets. Note the chosen target (and why, if it isn't the default) in `agent/improve.md` §Change.

## 3. Make the change

Edit, add, or restructure bullets/sections as the lesson requires. Span multiple files when the lesson genuinely spans them; the user gates the diff at review. If the chosen file feels at capacity, evict stale bullets in the same diff and explain why.

## 4. Write artifacts

`human/improve.md` — one paragraph: what changed and why.

`agent/improve.md` — sections: §Symptom, §Root cause, §Target (file + reason it was chosen over alternatives), §Change (diff summary, file + lines added/removed), §Alternatives considered, §Verification (how the change will be validated next time it triggers).

## 5. Hand off

The last line of `agent/improve.md` is exactly one of:

- `<lever-status>IMPROVE: <files touched></lever-status>` — diff staged for the user.
- `<lever-status>SKIP: <reason></lever-status>` — the trace yielded no reusable rule worth a meta-process change.

The chat reply ends with the same line, so a streaming host can chain without reading the artifact. The diff sits in the working tree; the user decides how to integrate it.

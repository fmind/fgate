---
name: lever-init
description: Use when bootstrapping a new repo for agent-levers — scaffold .agents/levers/, generate AGENTS.md, wire CLAUDE.md and GEMINI.md.
---

# lever-init

Bootstrap this repo for agent-levers. Idempotent: if a target file already exists, leave it. `init` writes no per-step artifact; the chat reply is the only artifact, so the marker binds the chat reply.

## 1. Pre-flight

1. Confirm the cwd is a git repo: `git rev-parse --is-inside-work-tree`. Refuse if not.
2. Run `git status --porcelain`. If non-empty, list the dirty paths inline in the chat reply under a "Pre-existing changes:" heading and proceed — `lever-init` only adds files, it never touches existing ones.
3. Confirm `.agents/` is not in `.gitignore` — levers are tracked. If it is, surface the offending line and stop with `<lever-status>BLOCKED: .agents/ is gitignored</lever-status>`.

## 2. Workspace skeleton

```bash
mkdir -p .agents/levers
touch .agents/levers/.gitkeep
```

## 3. Generate `AGENTS.md` (skip if it exists)

Inspect the repo without running anything; then write a single Markdown file with these sections, in this order. Each section is a short bullet list — one fact per bullet, never a label.

- `# AGENTS.md` — top-level title.
- `## Project` — what the project does and the primary stack. 1–3 bullets.
- `## Conventions` — coding style, lint/format choices, test framework, naming rules.
- `## Workflow` — branch naming, commit format, PR rules.
- `## Layout` — every first-level directory and what it holds. One bullet per directory. `ls -la` plus `git ls-files | head -50` is enough.

Rules for the bullets:

- Single-level lists. No nested lists, no headers inside a bullet body.
- Each bullet is a complete fact (`Test with bun test --watch`), not a label (`Test`).
- No design-diary content — rationales, alternatives considered, internal preferences. The file is a guide for collaborators, not a notebook.
- 20–50 bullets is a reasonable starting point; grow over time via `/lever-improve`.

## 4. Wire host context files (skip each if it exists)

```bash
printf '@AGENTS.md\n'   > CLAUDE.md
printf '@./AGENTS.md\n' > GEMINI.md
```

## 5. Hand off

The last line of the response is exactly one of:

- `<lever-status>COMPLETE</lever-status>` — files written.
- `<lever-status>BLOCKED: <reason></lever-status>` — pre-flight refused.

When and only when the tag is `COMPLETE`, include `Next: /lever-prompt <short-title-of-first-task>` on the line directly above the tag.

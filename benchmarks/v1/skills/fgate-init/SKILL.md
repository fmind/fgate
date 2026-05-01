---
name: fgate-init
description: Use when bootstrapping a new repo for fgate — scaffold .agents/, generate AGENTS.md, wire CLAUDE.md and GEMINI.md.
---

# fgate-init

Bootstrap this repo for fgate. Idempotent: if a target file already exists, leave it.

## 1. Pre-flight

1. Confirm the cwd is a git repo: `git rev-parse --is-inside-work-tree`. Refuse if not.
2. Run `git status --porcelain`. If non-empty, surface the dirty paths and ask whether to proceed or commit/stash first. Never proceed silently with uncommitted work.
3. Confirm `.agents/` is not in `.gitignore` — gates and docs are tracked.

## 2. Workspace skeleton

```bash
mkdir -p .agents/gates .agents/docs
touch .agents/gates/.gitkeep .agents/docs/.gitkeep
```

## 3. Generate `AGENTS.md` (skip if it exists)

Inspect the repo without running anything; then write a single Markdown file with these sections, in this order. Each section is a short bullet list — one fact per bullet, never a label.

- `# AGENTS.md` — top-level title.
- `## Project` — what the project does and the primary stack. 1–3 bullets.
- `## Layout` — every first-level directory and what it holds. One bullet per directory. `ls -la` plus `git ls-files | head -50` is enough.
- `## Conventions` — coding style, lint/format choices, test framework, naming rules. Pull from `.editorconfig`, `.prettierrc*`, `eslint.config.*`, `pyproject.toml`, `Cargo.toml`, `package.json` scripts, `CONTRIBUTING.md` (if any).
- `## Commands` — install / build / test / lint / format / run. One bullet per command. Use whatever package manager owns the lock file; do not guess.
- `## Workflow` — branch naming, commit format, PR rules. Pull from `.github/`, `git log --oneline -20`, or leave a minimal default.

Rules for the bullets:

- Single-level lists. No nested lists, no headers inside a bullet body.
- Each bullet is a complete fact (`Test with bun test --watch`), not a label (`Test`).
- No design-diary content — rationales, alternatives considered, internal preferences. The file is a guide for collaborators, not a notebook.
- 20–50 bullets is a reasonable starting point; grow over time via `/fgate:improve`.

## 4. Wire host context files (skip each if it exists)

```bash
printf '@AGENTS.md\n'   > CLAUDE.md
printf '@./AGENTS.md\n' > GEMINI.md
```

## 5. Hand off

End the response with exactly:

```text
Next: /fgate:prompt <short-title-of-first-task>
```

---
name: init
description: Use when bootstrapping a new repo for fgate — set up .agents/ skeleton, AGENTS.md, CLAUDE.md, GEMINI.md, then suggest the first task.
---

Bootstrap this repo for fgate.

1. Create `.agents/gates/` and `.agents/docs/`. Confirm `.agents/` is NOT gitignored (gates and docs commit to the task branch).
2. Generate `AGENTS.md` (~30 bullets) by inspecting the repo: purpose, stack, layout, conventions, build/test/lint commands, key paths. Bullets only — single-level list, no headers, no paragraphs. Skip if `AGENTS.md` already exists; do not overwrite.
3. Write `CLAUDE.md` containing one line: `@AGENTS.md`. Skip if it exists.
4. Write `GEMINI.md` containing one line: `@./AGENTS.md`. Skip if it exists.
5. Stage and commit on `main`: `chore(fgate): initialize agentic workflow`. Skip the commit if there were uncommitted changes before init ran — surface them and ask first.

Format rules for AGENTS.md bullets:

- Each bullet is a complete fact, not a label. Write `Build with bun run build`, not `Build`.
- Order: purpose → stack → layout → conventions → commands.
- No hard cap on count or line length — the agent needs room to be expressive.

End by telling the user to run:

```
/fgate:prompt <short-title-of-first-task>
```

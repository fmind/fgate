# fgate

> An agentic coding workflow toolkit. Six gates (`init` → `prompt` → `plan` → `implement` → `review` → `improve`), portable across **Gemini CLI** and **Claude Code**, with files-as-state and a self-improvement loop that ships reviewable diffs.

fgate is a personal-first toolkit (OSS as a bonus, MIT) that closes the loop between human intent and agent execution. Same canonical skills, two thin manifests.

## Why fgate?

Three load-bearing pillars (the moat):

1. **Files as I/O.** Every agent input and output is a markdown file under `.agents/gates/<id>/`. No sidecar DB, no `state.json`, no LLM scratchpad. Branch + file presence = state.
2. **Amplify the user.** Minimum attention per step, maximum work between steps. Each command suggests the next; the human approves hand-offs, doesn't synthesize.
3. **Alignment via self-improvement.** `/fgate:improve` is the only command that mutates the meta-process (`AGENTS.md` or one `skills/<n>/SKILL.md`). Every invocation produces a reviewable git diff.

Stays simpler than spec-kit / BMad / superpowers / gstack: 6 skills, ≤ 200 words per skill body, no enterprise theatre.

## The six gates

| Gate                       | What it does                                                                            |
| -------------------------- | --------------------------------------------------------------------------------------- |
| `/fgate:init`              | Bootstrap a fresh repo: `.agents/`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`.              |
| `/fgate:prompt <title>`    | Capture user intent. Set initial success criteria. Hard cap of 3 questions.             |
| `/fgate:plan <id>`         | Investigate codebase + relevant docs to produce a precise per-file specification.       |
| `/fgate:implement <id>`    | Execute the plan to the success criteria. Stop only on critical blockers.               |
| `/fgate:review <id>`       | Confirm criteria, propose merge to `main`, optionally surface follow-ups or learnings.  |
| `/fgate:improve <id>`      | (Optional) ship a reviewable diff to `AGENTS.md` or one skill body.                     |

## Install

### Claude Code

Local dev (in-place, no install):

```bash
claude --plugin-dir /path/to/fgate
```

Or, install via the bundled marketplace:

```text
/plugin marketplace add /path/to/fgate
/plugin install fgate@fgate
```

After publishing to GitHub, anyone can run:

```text
/plugin marketplace add fmind/fgate
/plugin install fgate@fgate
```

### Gemini CLI

Live-dev symlink (edits reload on next session):

```bash
gemini extensions link /path/to/fgate
```

Public install:

```bash
gemini extensions install fmind/fgate
```

## Layout

```
fgate/
├── AGENTS.md                       # canonical context — single source of truth
├── CLAUDE.md                       # one-liner: @AGENTS.md
├── GEMINI.md                       # one-liner: @./AGENTS.md
├── .claude-plugin/
│   ├── plugin.json                 # Claude Code plugin manifest
│   └── marketplace.json            # bundles fgate as a single-plugin marketplace
├── gemini-extension.json           # Gemini CLI extension manifest
├── skills/                         # canonical Agent Skills (open standard)
│   ├── init/SKILL.md
│   ├── prompt/SKILL.md
│   ├── plan/SKILL.md
│   ├── implement/SKILL.md
│   ├── review/SKILL.md
│   └── improve/SKILL.md
├── commands/fgate/                 # Gemini TOML shells; Claude Code reads skills/ directly
│   └── *.toml                      # 5-line files; @{...}-embed the canonical SKILL.md
├── scripts/
│   └── check-skill-words.sh        # CI: enforce ≤ 200 words per skill body
├── .github/workflows/ci.yml        # word-cap + manifest validation
└── .agents/skills -> ../skills/    # committed symlink (only on the fgate repo itself)
```

In an end-user project after `/fgate:init`:

```
.agents/
├── gates/<N>_<slug>/
│   ├── human/{prompt,plan,trace,result,improve}.md
│   └── agent/{prompt,plan,trace,result,improve}.md
└── docs/                           # cross-task knowledge curated by /fgate:plan
```

## Conventions

- **Skill body ≤ 200 words.** Enforced by `scripts/check-skill-words.sh` in CI. Heavy reference material lives in sibling files under each skill directory.
- **`description` starts with "Use when…"** Trigger-rich, never workflow-summarizing.
- **AGENTS.md is bullets only.** Single-level list. No headers, no paragraphs.
- **Branch per task.** `/fgate:prompt` creates `gates/<N>_<slug>` from `main`. `/fgate:review` proposes the merge.
- **Conventional commits.** `<type>(<scope>): <subject>`.
- **No Python, no PyPI, minimal bash.** Everything is plain markdown plus standard CLI tooling.

## Inspiration & counter-positioning

Borrows from [obra/superpowers](https://github.com/obra/superpowers) (hard gates between stages, predictable artifact paths, name-the-next-skill ending) and [garrytan/gstack](https://github.com/garrytan/gstack) (specialist sub-checklists, file-based learning loops).

Avoids superpowers' moralizing tone, gstack's role-playing personae, and any 9-step linear processes. Under-engineered on purpose.

## License

MIT — see [LICENSE](./LICENSE).

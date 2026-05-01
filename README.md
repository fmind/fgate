# flever

> **Amplify the agent loop <> Simplify the human loop.**
>
> Six levers that capture agent work as reviewable artifacts.
>
> `init` → `prompt` → `plan` → `implement` → `review` → `improve`

**NOTE — local clones may live at `~/fgate`.** The project name is `flever`, but the repository on disk can stay at `~/fgate` to avoid breaking active sessions. The path is intentional — only the project name and metadata changed.

## What you get

- **State is just files.** Every lever writes markdown under `.agents/levers/<id>/`. Skills inspect git state to orient themselves but never modify it — staging, commits, branches, and merges stay with you.
- **One source, every coding agent.** Skills live under `skills/flever-<name>/SKILL.md` (the open Agent Skills format) and are auto-discovered everywhere.
- **30-second skim, full record.** `human/<lever>.md` is a one-screen brief; `agent/<lever>.md` is the full decision log. You read what you need; the agent reads what it needs.
- **Self-improvement as a diff.** When a task exposes a recurring gap, `/flever:improve` proposes a reviewable change to the relevant skill or AGENTS.md to align with your expectation.

## The six levers

| Lever                    | What it does                                                                  |
| ------------------------ | ----------------------------------------------------------------------------- |
| `/flever:init`           | Bootstrap a repo: `.agents/`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`.          |
| `/flever:prompt <title>` | Capture intent. Define success criteria.                                      |
| `/flever:plan <id>`      | Investigate the codebase and external docs. Produce a per-file specification. |
| `/flever:implement <id>` | Execute the plan. Stop only on critical blockers.                             |
| `/flever:review <id>`    | Confirm criteria, summarize the diff, optionally surface follow-ups.          |
| `/flever:improve <id>`   | Optional. Reviewable diff to `AGENTS.md` and/or skill bodies.                 |

Two contracts hold the levers together:

- **Checklist contract** — every acceptance criterion carries a runnable `verify:` shell command and a `passes: false` flag. `/flever:implement` flips the flag on success; `/flever:review` re-runs the verifier as the final ground truth.
- **Chaining contract** — every lever ends with exactly one `<gate-status>...</gate-status>` tag (`COMPLETE`, `BLOCKED`, `DECIDE`, `BUDGET`, `SHIP`, `RESUME`, `IMPROVE`, `SKIP`) on its own line. A wrapper or CI job greps for the tag to route the next lever without human reading. (The tag retains the `<gate-status>` name for backward-compat — see `AGENTS.md`.)

## Example walkthrough

A typical task on a fresh flever-enabled repo:

```text
$ /flever:prompt add password sign-in
  → creates .agents/levers/1-add_password_sign_in/
  → writes {human,agent}/prompt.md
  → "Next: /flever:plan 1"

$ /flever:plan 1
  → reads agent/prompt.md, investigates the codebase
  → writes plan.md (per-file spec, refined criteria)
  → "Next: /flever:implement 1"

$ /flever:implement 1
  → executes the plan, appends to trace.md
  → writes result.md
  → "Next: /flever:review 1"

$ /flever:review 1
  → confirms each criterion, summarizes the diff
  → "ready to ship — diff is staged, integrate it however you like."
```

Run `/flever:improve 1` only if the task surfaced a meta-process gap worth keeping.

## Install

### Claude Code

Local development (no install):

```bash
claude --plugin-dir /path/to/flever
```

Via the bundled marketplace:

```text
/plugin marketplace add /path/to/flever
/plugin install flever@flever
```

After publishing to GitHub:

```text
/plugin marketplace add fmind/flever
/plugin install flever@flever
```

### Gemini CLI

Local development (live-link, edits reload on next session):

```bash
gemini extensions link /path/to/flever
```

Public install:

```bash
gemini extensions install fmind/flever
```

### GitHub Copilot

Local development (VS Code) — point `chat.pluginLocations` at the repo:

```jsonc
// settings.json
"chat.pluginLocations": {
  "/path/to/flever": true
}
```

Copilot CLI / VS Code marketplace:

```bash
copilot plugin marketplace add fmind/flever
```

## Layout

```text
flever/
├── AGENTS.md                       # canonical context — read natively by Copilot; @-included by CLAUDE.md and GEMINI.md
├── CLAUDE.md                       # one-liner: @AGENTS.md
├── GEMINI.md                       # one-liner: @./AGENTS.md
├── plugin.json                     # GitHub Copilot agent-plugin manifest
├── .claude-plugin/
│   ├── plugin.json                 # Claude Code plugin manifest
│   └── marketplace.json            # bundles flever as a single-plugin marketplace
├── gemini-extension.json           # Gemini CLI extension manifest
├── skills/                         # canonical Agent Skills (open standard) — auto-discovered by every supported tool
│   ├── flever-init/SKILL.md
│   ├── flever-prompt/SKILL.md
│   ├── flever-plan/SKILL.md
│   ├── flever-implement/SKILL.md
│   ├── flever-review/SKILL.md
│   └── flever-improve/SKILL.md
├── commands/                       # optional slash-command shells — resolve to /flever:<name>
│   ├── <name>.md                   # Claude Code: plugin name auto-prefixes
│   └── flever/<name>.toml          # Gemini CLI: subdir provides the namespace
└── .github/workflows/ci.yml        # lint + format + manifest validation
```

In an end-user project after `/flever:init`:

```text
.agents/
├── levers/<id>_<slug>/
│   ├── human/{prompt,plan,trace,result,improve}.md
│   └── agent/{prompt,plan,trace,result,improve}.md
└── docs/                           # cross-task knowledge curated by /flever:plan
```

## Conventions

- **`description` starts with "Use when…"** Trigger-rich, never workflow-summarizing.
- **AGENTS.md is sectioned bullet lists.** Single-level bullets, one fact per bullet.
- **Markdown lint and format enforced in CI.** `markdownlint-cli2` + `prettier`.

## License

MIT — see [LICENSE](./LICENSE).

# fgate

> **Amplify the agent loop <> Simplify the human loop.**
>
> Six gates that capture agent work as reviewable artifacts.
>
> `init` → `prompt` → `plan` → `implement` → `review` → `improve`

## What you get

- **State is just files.** Every gate writes markdown under `.agents/gates/<id>/`. Skills inspect git state to orient themselves but never modify it — staging, commits, branches, and merges stay with you.
- **One source, every coding agent.** Skills live under `skills/fgate-<name>/SKILL.md` (the open Agent Skills format) and are auto-discovered everywhere.
- **30-second skim, full record.** `human/<gate>.md` is a one-screen brief; `agent/<gate>.md` is the full decision log. You read what you need; the agent reads what it needs.
- **Self-improvement as a diff.** When a task exposes a recurring gap, `/fgate:improve` proposes a reviewable change to the relevant skill or AGENTS.md to align with your expectation.

## The six gates

| Gate                    | What it does                                                                  |
| ----------------------- | ----------------------------------------------------------------------------- |
| `/fgate:init`           | Bootstrap a repo: `.agents/`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`.          |
| `/fgate:prompt <title>` | Capture intent. Define success criteria.                                      |
| `/fgate:plan <id>`      | Investigate the codebase and external docs. Produce a per-file specification. |
| `/fgate:implement <id>` | Execute the plan. Stop only on critical blockers.                             |
| `/fgate:review <id>`    | Confirm criteria, summarize the diff, optionally surface follow-ups.          |
| `/fgate:improve <id>`   | Optional. Reviewable diff to `AGENTS.md` and/or skill bodies.                 |

Two contracts hold the gates together:

- **Checklist contract** — every acceptance criterion carries a runnable `verify:` shell command and a `passes: false` flag. `/fgate:implement` flips the flag on success; `/fgate:review` re-runs the verifier as the final ground truth.
- **Chaining contract** — every gate ends with exactly one `<gate-status>...</gate-status>` tag (`COMPLETE`, `BLOCKED`, `DECIDE`, `BUDGET`, `SHIP`, `RESUME`, `IMPROVE`, `SKIP`) on its own line. A wrapper or CI job greps for the tag to route the next gate without human reading.

## Example walkthrough

A typical task on a fresh fgate-enabled repo:

```text
$ /fgate:prompt add password sign-in
  → creates .agents/gates/1-add_password_sign_in/
  → writes {human,agent}/prompt.md
  → "Next: /fgate:plan 1"

$ /fgate:plan 1
  → reads agent/prompt.md, investigates the codebase
  → writes plan.md (per-file spec, refined criteria)
  → "Next: /fgate:implement 1"

$ /fgate:implement 1
  → executes the plan, appends to trace.md
  → writes result.md
  → "Next: /fgate:review 1"

$ /fgate:review 1
  → confirms each criterion, summarizes the diff
  → "ready to ship — diff is staged, integrate it however you like."
```

Run `/fgate:improve 1` only if the task surfaced a meta-process gap worth keeping.

## Install

### Claude Code

Local development (no install):

```bash
claude --plugin-dir /path/to/fgate
```

Via the bundled marketplace:

```text
/plugin marketplace add /path/to/fgate
/plugin install fgate@fgate
```

After publishing to GitHub:

```text
/plugin marketplace add fmind/fgate
/plugin install fgate@fgate
```

### Gemini CLI

Local development (live-link, edits reload on next session):

```bash
gemini extensions link /path/to/fgate
```

Public install:

```bash
gemini extensions install fmind/fgate
```

### GitHub Copilot

Local development (VS Code) — point `chat.pluginLocations` at the repo:

```jsonc
// settings.json
"chat.pluginLocations": {
  "/path/to/fgate": true
}
```

Copilot CLI / VS Code marketplace:

```bash
copilot plugin marketplace add fmind/fgate
```

## Layout

```text
fgate/
├── AGENTS.md                       # canonical context — read natively by Copilot; @-included by CLAUDE.md and GEMINI.md
├── CLAUDE.md                       # one-liner: @AGENTS.md
├── GEMINI.md                       # one-liner: @./AGENTS.md
├── plugin.json                     # GitHub Copilot agent-plugin manifest
├── .claude-plugin/
│   ├── plugin.json                 # Claude Code plugin manifest
│   └── marketplace.json            # bundles fgate as a single-plugin marketplace
├── gemini-extension.json           # Gemini CLI extension manifest
├── skills/                         # canonical Agent Skills (open standard) — auto-discovered by every supported tool
│   ├── fgate-init/SKILL.md
│   ├── fgate-prompt/SKILL.md
│   ├── fgate-plan/SKILL.md
│   ├── fgate-implement/SKILL.md
│   ├── fgate-review/SKILL.md
│   └── fgate-improve/SKILL.md
├── commands/                       # optional slash-command shells — resolve to /fgate:<name>
│   ├── <name>.md                   # Claude Code: plugin name auto-prefixes
│   └── fgate/<name>.toml           # Gemini CLI: subdir provides the namespace
└── .github/workflows/ci.yml        # lint + format + manifest validation
```

In an end-user project after `/fgate:init`:

```text
.agents/
├── gates/<id>_<slug>/
│   ├── human/{prompt,plan,trace,result,improve}.md
│   └── agent/{prompt,plan,trace,result,improve}.md
└── docs/                           # cross-task knowledge curated by /fgate:plan
```

## Conventions

- **`description` starts with "Use when…"** Trigger-rich, never workflow-summarizing.
- **AGENTS.md is sectioned bullet lists.** Single-level bullets, one fact per bullet.
- **Markdown lint and format enforced in CI.** `markdownlint-cli2` + `prettier`.

## License

MIT — see [LICENSE](./LICENSE).

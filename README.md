# agent-levers

> **Levers for AI coding agents — multiply the agent's force, divide the human's effort.**
>
> Six steps that capture agent work as reviewable artifacts.
>
> `init` → `prompt` → `plan` → `implement` → `review` → `improve`

## What you get

- **State is just files.** A lever is a task workflow at `.agents/levers/<id>-<slug>/`; each step writes its markdown inside. Skills inspect git state to orient themselves but never modify it — staging, commits, branches, and merges stay with you.
- **One source, every coding agent.** Skills live under `skills/lever-<name>/SKILL.md` (the open Agent Skills format) and are auto-discovered everywhere — each one shows up as `/lever-<name>` in chat.
- **30-second skim, full record.** `human/<name>.md` is a one-screen brief; `agent/<name>.md` is the full decision log. You read what you need; the agent reads what it needs.
- **Self-improvement as a diff.** When a task exposes a recurring gap, `/lever-improve` proposes a reviewable change to the relevant skill or `AGENTS.md` (the default — overridable when the project installs a more specific docs/memory skill).

## The six steps

| Step                    | What it does                                                                  |
| ----------------------- | ----------------------------------------------------------------------------- |
| `/lever-init`           | Bootstrap a repo: `.agents/levers/`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`.   |
| `/lever-prompt <title>` | Capture intent. Define success criteria.                                      |
| `/lever-plan <id>`      | Investigate the codebase and external docs. Produce a per-file specification. |
| `/lever-implement <id>` | Execute the plan. Stop only on critical blockers.                             |
| `/lever-review <id>`    | Confirm criteria, summarize the diff, optionally surface follow-ups.          |
| `/lever-improve <id>`   | Optional. Reviewable diff to `AGENTS.md` (default) and/or skill bodies.       |

Two contracts hold the steps together:

- **Checklist contract** — every acceptance criterion carries a runnable `verify:` shell command and a `passes: false` flag. `/lever-implement` flips the flag on success; `/lever-review` re-runs the verifier as the final ground truth.
- **Chaining contract** — every step ends with exactly one `<lever-status>...</lever-status>` tag (`COMPLETE`, `BLOCKED`, `DECIDE`, `BUDGET`, `SHIP`, `RESUME`, `IMPROVE`, `SKIP`) on its own line. A wrapper or CI job greps for the tag to route the next step without human reading. (Pre-rename runs used `<gate-status>` — kept verbatim under `.agents/evolutions/` for fidelity, no longer emitted by current skills.)

## Example walkthrough

A typical task on a fresh agent-levers-enabled repo:

```text
$ /lever-prompt add password sign-in
  → creates .agents/levers/1-add_password_sign_in/
  → writes {human,agent}/prompt.md
  → "Next: /lever-plan 1"

$ /lever-plan 1
  → reads agent/prompt.md, investigates the codebase
  → writes {human,agent}/plan.md (per-file spec, refined criteria)
  → "Next: /lever-implement 1"

$ /lever-implement 1
  → executes the plan, appends to {human,agent}/trace.md
  → writes {human,agent}/result.md
  → "Next: /lever-review 1"

$ /lever-review 1
  → re-runs verifiers, confirms each criterion, summarizes the diff
  → "ready to ship — diff is staged, integrate it however you like."
```

Run `/lever-improve 1` only if the task surfaced a meta-process gap worth keeping.

## Install

### Claude Code

Local development (no install):

```bash
claude --plugin-dir /path/to/agent-levers
```

Via the bundled marketplace:

```text
/plugin marketplace add /path/to/agent-levers
/plugin install lever@agent-levers
```

After publishing to GitHub:

```text
/plugin marketplace add fmind/agent-levers
/plugin install lever@agent-levers
```

### Gemini CLI

Local development (live-link, edits reload on next session):

```bash
gemini extensions link /path/to/agent-levers
```

Public install:

```bash
gemini extensions install fmind/agent-levers
```

### GitHub Copilot

Local development (VS Code) — point `chat.pluginLocations` at the repo:

```jsonc
// settings.json
"chat.pluginLocations": {
  "/path/to/agent-levers": true
}
```

Copilot CLI:

```bash
copilot plugin marketplace add fmind/agent-levers
copilot plugin install lever@agent-levers
```

The first command registers the marketplace; the second installs the `lever` plugin from it.

## Layout

```text
agent-levers/
├── AGENTS.md                       # canonical context — read natively by Copilot; @-included by CLAUDE.md and GEMINI.md
├── CLAUDE.md                       # one-liner: @AGENTS.md
├── GEMINI.md                       # one-liner: @AGENTS.md
├── plugin.json                     # GitHub Copilot agent-plugin manifest
├── .claude-plugin/
│   ├── plugin.json                 # Claude Code plugin manifest
│   └── marketplace.json            # bundles agent-levers as a single-plugin marketplace
├── gemini-extension.json           # Gemini CLI extension manifest
├── skills/                         # canonical Agent Skills (open standard) — auto-discovered everywhere, each surfaced as `/lever-<name>`
│   ├── lever-init/SKILL.md
│   ├── lever-prompt/SKILL.md
│   ├── lever-plan/SKILL.md
│   ├── lever-implement/SKILL.md
│   ├── lever-review/SKILL.md
│   └── lever-improve/SKILL.md
└── .github/workflows/ci.yml        # lint (prettier + markdownlint)
```

In an end-user project after `/lever-init`:

```text
.agents/
└── levers/<id>-<slug>/             # one lever = one task workflow
    ├── human/{prompt,plan,trace,result,improve}.md
    └── agent/{prompt,plan,trace,result,improve}.md
```

agent-levers owns levers and nothing else. Cross-task project knowledge (auth flow, schema, shared notes) belongs in whatever docs/memory skill the project already uses — install one alongside agent-levers if you need that surface.

## Conventions

- **`description` starts with "Use when…"** Trigger-rich, never workflow-summarizing.
- **AGENTS.md is sectioned bullet lists.** Single-level bullets, one fact per bullet.
- **Markdown lint and format enforced in CI.** `markdownlint-cli2` + `prettier`.

## License

MIT — see [LICENSE](./LICENSE).

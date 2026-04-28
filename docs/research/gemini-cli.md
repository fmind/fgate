# Gemini CLI Extensibility — Research Brief for fgate

Scope: how to ship the six fgate gates (prompt → plan → implement → review → improve, plus orchestrator) as a single Gemini CLI extension. Sources: official docs at `geminicli.com/docs/*` (extensions, custom commands, skills) and the user's local skills under `~/.claude/skills/configure-gemini-extensions/`, `create-gemini-command/`, `create-agent-skill/`, `create-gemini-subagent/`, `configure-gemini-cli/`, `setup-gemini-cli-on-new-project/`. Cross-checked April 2026.

---

## 1. Extensions

### Disk locations

- **Installed snapshot:** `~/.gemini/extensions/<name>/` (per-user, machine-local). Source: `geminicli.com/docs/extensions/reference/` and `configure-gemini-extensions` skill ("Extensions are installed globally to `~/.gemini/extensions/<id>/` — there is no per-repo `extensions.json` manifest").
- **Linked dev copy:** symlink created by `gemini extensions link <path>`; edits in the source dir take effect on the next session.
- **Source repo:** any Git repo that contains a `gemini-extension.json` at the root.

### `gemini-extension.json` — every field

Cross-checked from `geminicli.com/docs/extensions/reference/`. Required marked with `*`.

| Field | Type | Purpose |
|---|---|---|
| `name`* | string | Unique id, lowercase + dashes. Becomes the install dir. |
| `version`* | string | Semver string. |
| `description`* | string | Short blurb shown in the marketplace / `gemini extensions list`. |
| `mcpServers` | object | Map of MCP server configs, merged into the active config. Per-entry keys: `command`, `args` (supports `${extensionPath}`), `cwd` (supports `${extensionPath}`), plus the standard MCP transport fields (`env`, `httpUrl`, `headers`, `authProviderType`, `includeTools`, `timeout`). |
| `contextFileName` | string | Override the context filename. Defaults to `GEMINI.md` if present at the extension root. |
| `excludeTools` | string[] | Tool names to hide from the model. |
| `migratedTo` | string | Redirect URL when the extension repo moves; clients auto-migrate. |
| `plan` | object | `{ "directory": "<path>" }` — fallback plan-mode artifact dir. |
| `settings` | object[] | User-configurable settings; each entry: `name`, `description`, `envVar`, `sensitive` (boolean — store in OS keychain). |
| `themes` | object[] | Custom UI themes shipped by the extension. |

Notes from the user's local `configure-gemini-extensions` skill that are not in the published reference table but are observed in real extensions: `author` (`{ name, email }`), `license`, `commands` (array of toml paths), `agents` (array of `.md` paths), `skills` (array of skill dir paths), `tools.exclude`. Treat these as observed-but-unverified — the published reference does not list them; the writing-extensions guide instead implies that `commands/` and `skills/` are picked up by **directory convention** (no array enumeration needed). When in doubt, rely on the directory convention.

### Bundle layout (verified from `geminicli.com/docs/extensions/writing-extensions/`)

```
my-first-extension/
├── gemini-extension.json     # manifest (required, root)
├── GEMINI.md                 # context file, referenced via contextFileName
├── commands/                 # .toml slash commands (subdirs become namespaces)
│   └── fs/
│       └── grep-code.toml    # invoked as /fs:grep-code
└── skills/                   # SKILL.md bundles (one dir per skill)
    └── security-audit/
        └── SKILL.md
```

The `configure-gemini-extensions` skill adds two more conventional dirs that real extensions use: `agents/` (subagent `.md` files) and a per-server config under `mcpServers`. Hooks live in `hooks/` and are referenced from manifest paths or `settings.json` `hooks` blocks.

### Installation flow

```bash
# from a public repo
gemini extensions install <github-org>/<repo>

# from a local path (snapshot copy)
gemini extensions install ./my-first-extension

# live-dev symlink — re-reads on session start, no re-install needed
gemini extensions link ./my-first-extension

# lifecycle
gemini extensions list
gemini extensions update --all
gemini extensions disable <name>      # keep on disk, deactivate
gemini extensions enable <name>
gemini extensions uninstall <name>
gemini extensions config <name>       # per-extension settings UI
```

Full subcommand surface (no `search`, `info`, `init`): `config, disable, enable, explore, install, link, list, restart, uninstall, update`.

### Concrete minimal manifest for fgate

```json
{
  "name": "fgate",
  "version": "0.1.0",
  "description": "Personal-first agentic coding gates: prompt, plan, implement, review, improve.",
  "contextFileName": "GEMINI.md",
  "mcpServers": {},
  "excludeTools": []
}
```

Drop `commands/*.toml` and `skills/*/SKILL.md` next to it — they are auto-discovered by directory convention.

### What the user invokes

- After install, the six commands appear as `/fgate:prompt`, `/fgate:plan`, `/fgate:implement`, `/fgate:review`, `/fgate:improve`, `/fgate:run` (assuming the toml files live under `commands/fgate/*.toml`).
- Skills load lazily via progressive disclosure when their `description` matches the current task.

---

## 2. Custom commands

### Disk locations

Source: `geminicli.com/docs/cli/custom-commands/` and `create-gemini-command` skill.

- **Project:** `<repo>/.gemini/commands/<name>.toml`
- **User-global:** `~/.gemini/commands/<name>.toml`
- **Inside an extension:** `<ext>/commands/<name>.toml` (auto-discovered after install)

Project commands override global commands of the same name. Subdirectories become `:`-namespaced groups: `commands/git/commit.toml` → `/git:commit`.

### TOML schema — every recognised field

Only **two** keys are recognised (verified by both the official docs and the `create-gemini-command` skill):

| Field | Type | Required | Purpose |
|---|---|---|---|
| `prompt` | string (single- or multi-line) | yes | Body sent to the model. |
| `description` | string | no (auto-generated if omitted) | One-liner shown in `/help` and autocomplete. |

There are **no named arguments, no positional argument schema, no allowed-tools field**. Argument handling is purely string substitution.

### Argument handling

1. `{{args}}` — replaced with everything the user typed after the command name. Outside `!{...}`, raw injection. Inside `!{...}`, shell-escaped automatically.
2. If the prompt contains no `{{args}}`, any user input is appended to the prompt with two newlines as separator.
3. `@{path}` — embeds the contents of a file or directory; respects `.gitignore` / `.geminiignore`; supports images, PDFs, audio, video.
4. `!{shell command}` — runs the command (with confirmation by default) and inlines stdout.

Processing order documented at `geminicli.com/docs/cli/custom-commands/`: file injection (`@{...}`) → shell execution (`!{...}`) → argument substitution (`{{args}}`).

Reload after editing a `.toml` without restarting: in-session `/commands reload`.

### Concrete minimal example (the `prompt` gate)

`commands/fgate/prompt.toml`:

```toml
description = "Refine a rough idea into a deep, actionable prompt."

prompt = """
You are the fgate Prompt gate. Turn the user's rough idea into a precise,
testable prompt.

Repo context:
@{AGENTS.md}
@{README.md}

Rough idea from the user:
{{args}}

Output a single self-contained prompt block. No preamble.
"""
```

Invocation: `/fgate:prompt build a CLI that wraps gh and jq`.

### Invocation patterns

- Interactive session: type `/<group>:<name> <free-form args>`.
- From the shell (headless): `gemini -p "/fgate:plan refactor the auth layer"` — slash commands work in `-p` mode because they are expanded before the prompt is sent.
- Pipe stdin: `git diff --cached | gemini -p "/fgate:review"` — stdin appears as `{{args}}` (or appended after the prompt body).

---

## 3. Skills support (Anthropic-style `SKILL.md`)

### Verdict

**Yes** — Gemini CLI is a first-class consumer of the Agent Skills standard (per `agentskills.io`). Source: `geminicli.com/docs/cli/skills/` and the `create-agent-skill` skill ("Agent Skills are an open standard … adopted by Claude Code, Gemini CLI, Cursor, OpenCode").

### Discovery paths (three tiers, verified)

1. **Workspace:** `<repo>/.gemini/skills/` or `<repo>/.agents/skills/` (the `.agents/` alias takes precedence — used by `npx skills add` for cross-tool installs).
2. **User:** `~/.gemini/skills/` (or `~/.agents/skills/`).
3. **Extension:** `<ext>/skills/` inside any installed extension (verified from `writing-extensions`).

### Layout per skill

```
<slug>/
├── SKILL.md       # required — frontmatter + body
├── scripts/       # optional executable helpers
├── references/    # optional grep-able docs
└── assets/        # optional templates / fixtures
```

### Frontmatter — required fields

From the `create-agent-skill` skill (the published Gemini docs do not pin the schema, they defer to the agentskills.io standard):

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | Slug. Must match the folder name. Lowercase, hyphens. |
| `description` | yes | Single-sentence trigger. The body is **not loaded** until this matches; make it concrete and trigger-rich. |

### Progressive disclosure (verified by official docs)

Quote from `geminicli.com/docs/cli/skills/`: *"Only skill metadata (name and description) is loaded initially. Detailed instructions and resources are only disclosed when the model explicitly activates the skill."* On activation: *"The `SKILL.md` body and folder structure is added to the conversation history."*

### Can a `.toml` command delegate to a `SKILL.md` body?

**Not directly via a "load this skill" directive.** The TOML command schema has no skill-reference field. But **two viable workarounds** exist:

1. **Embed via `@{...}`** — the official file-injection mechanism. A command can hardcode `@{skills/<slug>/SKILL.md}` (extension-relative) or `@{.gemini/skills/<slug>/SKILL.md}` (workspace-relative) to inline the body unconditionally. This is deterministic but defeats progressive disclosure: the body always loads.
2. **Rely on progressive disclosure** — write the command's `prompt` to *describe the task* and let the runtime auto-activate any matching skill based on its description. This is the idiomatic path: ship one skill per gate alongside the command, and the model loads the skill when relevant.

For fgate's use case, **option 1 is the better fit**: each gate has a deterministic procedure, so each `commands/fgate/<gate>.toml` should `@{skills/fgate-<gate>/SKILL.md}` to guarantee the gate's playbook is in context. Then the prompt body stays short; the SKILL.md holds the procedure, and updating the procedure means editing one file.

### Concrete minimal example

`skills/fgate-plan/SKILL.md`:

```markdown
---
name: fgate-plan
description: Decompose a deep prompt into a numbered, ordered implementation plan with explicit gates and exit criteria.
---

# fgate Plan Gate

You are the Plan gate. Turn the input prompt into:

1. A numbered list of changes (file-level granularity).
2. For each change: rationale, dependencies, exit criteria.
3. A "risks" section.
4. A "ready to implement?" yes/no with reasoning.

Refuse to plan if inputs are ambiguous; ask one targeted question instead.
```

Paired `commands/fgate/plan.toml`:

```toml
description = "fgate Plan gate — turn a deep prompt into an ordered implementation plan."
prompt = """
@{skills/fgate-plan/SKILL.md}

Deep prompt to plan:
{{args}}
"""
```

### Installation of third-party skill packs

The `vercel-labs/skills` CLI handles distribution: `npx skills add <owner>/<repo> --skill <name>` writes to `.agents/skills/` (project) or `~/.gemini/skills/` (with `--global`). For fgate this is irrelevant — we ship our skills inside the extension itself.

---

## Bundling all six fgate gates in a single extension

Final layout (one extension, six commands, six skills, zero MCP servers required):

```
fgate/
├── gemini-extension.json
├── GEMINI.md                          # extension-level persona / house rules
├── commands/
│   └── fgate/
│       ├── prompt.toml                # /fgate:prompt
│       ├── plan.toml                  # /fgate:plan
│       ├── implement.toml             # /fgate:implement
│       ├── review.toml                # /fgate:review
│       ├── improve.toml               # /fgate:improve
│       └── run.toml                   # /fgate:run (orchestrator)
└── skills/
    ├── fgate-prompt/SKILL.md
    ├── fgate-plan/SKILL.md
    ├── fgate-implement/SKILL.md
    ├── fgate-review/SKILL.md
    └── fgate-improve/SKILL.md
```

Each `.toml` is ~5 lines: a `description`, then a `prompt` that `@{...}`-embeds its sibling `SKILL.md` and tail-appends `{{args}}`. The procedural truth lives in `SKILL.md`, so editing a gate is a single-file change. The orchestrator (`run.toml`) chains the gates by emitting their slash names; the runtime expands them in order.

Distribution: push to a public GitHub repo, then `gemini extensions install fmind/fgate`. For local iteration: `gemini extensions link ./fgate` — edits to the source dir reload on the next session.

---

## Open questions / unclear from sources

1. **Whether extension-bundled `agents/*.md` subagents auto-discover** — the writing-extensions example only shows `commands/` and `skills/`. The user's `configure-gemini-extensions` skill claims `agents/` works, but the official reference does not list it. Test before relying on it; fallback is to ship subagents via the project `.gemini/agents/` after install.
2. **Whether the `commands`, `agents`, `skills` arrays in the manifest are honoured** — observed in the user's notes but absent from the published reference. The directory convention works regardless; treat the array form as best-effort.
3. **Whether `/commands reload` also reloads bundled SKILL.md frontmatter** — the docs only mention command reload. Restart the session to be safe after editing a SKILL.md description.

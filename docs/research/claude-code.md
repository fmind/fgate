# Claude Code Extensibility — Research Brief for fgate

Sources fetched 2026-04-28:

- <https://code.claude.com/docs/en/skills> (canonical; `docs.claude.com/en/docs/claude-code/skills` 301-redirects here)
- <https://code.claude.com/docs/en/plugins>
- <https://code.claude.com/docs/en/plugin-marketplaces>
- <https://code.claude.com/docs/en/plugins-reference>
- Local example: `/home/fmind/.claude/skills/create-agent-skill/SKILL.md` (Gemini-flavored but the SKILL.md format is the open Agent Skills standard, identical to Claude Code's).

Important top-level note from the docs:
> "**Custom commands have been merged into skills.** A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way." (skills page)

So Claude Code now has two extensibility primitives in practice — **skills** (and their legacy `commands/` form) and **plugins** that bundle them. fgate should treat the **skill** as the unit of work and the **plugin** as the distribution unit.

---

## 1. Plugins / marketplaces

### Manifest: `.claude-plugin/plugin.json`

The manifest is **optional**: "If omitted, Claude Code auto-discovers components in default locations and derives the plugin name from the directory name." If included, **only `name` is required**.

Quoted shape (from plugins-reference, "Complete schema"):

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": { "name": "Author Name", "email": "author@example.com", "url": "https://github.com/author" },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "skills": "./custom/skills/",
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "themes": "./themes/",
  "lspServers": "./.lsp.json",
  "monitors": "./monitors.json",
  "dependencies": ["helper-lib", { "name": "secrets-vault", "version": "~2.1.0" }]
}
```

Version semantics (verbatim): "Setting this pins the plugin to that version string, so users only receive updates when you bump it. If omitted, Claude Code falls back to the git commit SHA, so every commit is treated as a new version. If also set in the marketplace entry, `plugin.json` wins."

Other manifest extras worth knowing: `userConfig` (typed values prompted at enable time, referenced as `${user_config.<key>}` in MCP/LSP/monitor commands), `channels`, `dependencies`.

### Plugin directory layout (default locations)

Quoted from plugins-reference, "File locations reference":

| Component     | Default Location             | Purpose                                                |
| :------------ | :--------------------------- | :----------------------------------------------------- |
| Manifest      | `.claude-plugin/plugin.json` | Plugin metadata and configuration (optional)           |
| Skills        | `skills/`                    | Skills with `<name>/SKILL.md` structure                |
| Commands      | `commands/`                  | Skills as flat Markdown files (legacy; prefer skills/) |
| Agents        | `agents/`                    | Subagent Markdown files                                |
| Output styles | `output-styles/`             | Output style definitions                               |
| Themes        | `themes/`                    | Color theme definitions                                |
| Hooks         | `hooks/hooks.json`           | Hook configuration                                     |
| MCP servers   | `.mcp.json`                  | MCP server definitions                                 |
| LSP servers   | `.lsp.json`                  | Language server configurations                         |
| Monitors      | `monitors/monitors.json`     | Background monitor configurations                      |
| Executables   | `bin/`                       | Added to Bash tool's PATH while plugin is enabled      |
| Settings      | `settings.json`              | Default config (only `agent` + `subagentStatusLine`)   |

> Warning quoted verbatim: "The `.claude-plugin/` directory contains the `plugin.json` file. All other directories (commands/, agents/, skills/, output-styles/, themes/, monitors/, hooks/) must be at the plugin root, not inside `.claude-plugin/`."

So a single plugin **can absolutely bundle many skills + many commands + agents + hooks + MCP servers** in one ship — exactly fgate's shape.

Cache path: "Once a plugin is cloned or copied into the local machine, it is copied into the local versioned plugin cache at `~/.claude/plugins/cache`."

Skill namespacing once installed via plugin: `/<plugin-name>:<skill-name>` (e.g. `/fgate:plan`). Project-level skills keep the bare `/<skill-name>`.

### Marketplace: `.claude-plugin/marketplace.json`

Required fields: `name` (kebab-case), `owner` (object with required `name`, optional `email`), `plugins` (array). Reserved names blocked include `anthropic-marketplace`, `claude-code-plugins`, etc.

Each plugin entry needs `name` + `source`. Source can be:

- Relative path string (`"./plugins/foo"`) — must start with `./`, resolved from the marketplace root, only works when users add the marketplace via git.
- `{ "source": "github", "repo": "owner/repo", "ref"?, "sha"? }`
- `{ "source": "url", "url": "...", "ref"?, "sha"? }`
- `{ "source": "git-subdir", "url": "...", "path": "...", "ref"?, "sha"? }` (sparse clone — useful for monorepos)
- `{ "source": "npm", "package": "...", "version"?, "registry"? }`

### How a project distributes a plugin

Two viable shapes for fgate:

1. **Single-plugin repo** = the repo *is* the plugin. Layout: `<repo-root>/.claude-plugin/plugin.json` + `skills/`, `commands/`, etc. Distribute via a thin marketplace repo elsewhere, or have users `claude --plugin-dir ./fgate` for dev.
2. **Marketplace repo bundling several plugins**. Layout:
   ```
   fgate-marketplace/
   ├── .claude-plugin/marketplace.json
   └── plugins/
       └── fgate/
           ├── .claude-plugin/plugin.json
           ├── skills/{prompt,plan,implement,review,improve}/SKILL.md
           └── commands/...
   ```

User flow (verbatim from marketplaces page):

```shell
/plugin marketplace add ./my-marketplace          # or owner/repo, or URL
/plugin install quality-review-plugin@my-plugins
```

Non-interactive equivalent: `claude plugin install <plugin>@<marketplace> [--scope user|project|local]`. Default scope is `user` (`~/.claude/settings.json`); `project` writes to `.claude/settings.json` (committable); `local` writes to `.claude/settings.local.json` (gitignored).

For local dev, **`claude --plugin-dir ./fgate`** loads the plugin without installing; `/reload-plugins` picks up edits in-session.

---

## 2. Skills

> "Skills extend what Claude can do. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with `/skill-name`."

### File location

| Location   | Path                                    | Applies to              |
| :--------- | :-------------------------------------- | :---------------------- |
| Personal   | `~/.claude/skills/<name>/SKILL.md`      | All your projects       |
| Project    | `.claude/skills/<name>/SKILL.md`        | This project only       |
| Plugin     | `<plugin>/skills/<name>/SKILL.md`       | Where plugin is enabled |
| Enterprise | via managed settings                    | Org-wide                |

Precedence: enterprise > personal > project. Plugin skills are namespaced (`plugin-name:skill-name`) so they cannot collide. Live change detection: edits under any of these directories take effect within the current session without restart; creating a brand-new top-level skills directory mid-session requires a restart.

### Skill directory layout

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Optional - referenced from SKILL.md
├── examples/sample.md # Optional
└── scripts/validate.sh # Optional - executed, not loaded
```

> Tip from docs: "Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files."

### Frontmatter — required vs optional

Verbatim: "All fields are optional. Only `description` is recommended so Claude knows when to use the skill."

| Field                      | Notes (quoted/paraphrased) |
| :------------------------- | :------------------------- |
| `name`                     | Optional. Defaults to directory name. **Lowercase letters, numbers, and hyphens only (max 64 characters).** |
| `description`              | **Recommended.** What the skill does and when to use it. Combined with `when_to_use` it is **truncated at 1,536 characters in the skill listing**. |
| `when_to_use`              | Appended to `description` in listing; same 1,536-char cap. |
| `argument-hint`            | Autocomplete hint, e.g. `[issue-number]`. |
| `arguments`                | Named positional args for `$name` substitution. Space-separated string or YAML list. |
| `disable-model-invocation` | `true` = only the user can invoke it. Removes description from auto-context. |
| `user-invocable`           | `false` = hidden from `/` menu; only Claude can invoke. |
| `allowed-tools`            | Tools Claude can use without prompting while skill is active. Does NOT restrict — only pre-approves. |
| `model`                    | Override model for the rest of the current turn. |
| `effort`                   | `low`/`medium`/`high`/`xhigh`/`max`. |
| `context: fork`            | Run skill in a forked subagent context (clean slate). |
| `agent`                    | Subagent type to use when `context: fork` (e.g. `Explore`, `Plan`, `general-purpose`, or any from `.claude/agents/`). |
| `hooks`                    | Hooks scoped to this skill's lifecycle. |
| `paths`                    | Glob patterns that limit when skill auto-activates. |
| `shell`                    | `bash` (default) or `powershell` for `` !`...` `` blocks. |

### How the agent loads / triggers a skill

Verbatim: "skill descriptions are loaded into context so Claude knows what's available, but full skill content only loads when invoked."

Three ways a skill becomes "active":

1. **Model-invoked** (default): Claude reads the description, decides it fits, loads the full `SKILL.md` into the conversation. This is why a sharp, trigger-rich `description` is the load-bearing field.
2. **User-invoked**: typed as `/skill-name [args]` from the slash menu.
3. **Preloaded into a subagent** via the subagent's `skills:` field (full content injected at startup).

When invoked, "the rendered `SKILL.md` content enters the conversation as a single message and stays there for the rest of the session. Claude Code does not re-read the skill file on later turns" — so write standing instructions, not one-time steps. After auto-compaction Claude Code re-attaches the most recent invocation of each skill (first 5,000 tokens; combined budget 25,000 tokens).

### Substitutions inside SKILL.md

`$ARGUMENTS` (full string), `$ARGUMENTS[N]` / `$N` (positional, 0-indexed, shell-quoted), `$<name>` (named per `arguments:` frontmatter), `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}` (the skill's own directory — use this to reference bundled scripts portably). Inline `` !`<command>` `` and fenced ` ```! ` blocks run **before** content reaches Claude and inline their stdout — useful for fgate's "fetch git diff / PR data" step.

### Naming conventions

- Folder name = canonical name (used as `/skill-name` if `name:` is omitted).
- Lowercase, digits, hyphens only; max 64 chars.
- Verb-first slugs read best (`prompt`, `plan`, `implement`, `review`, `improve`).

### Minimal example (verbatim style from docs)

`~/.claude/skills/explain-code/SKILL.md`:

```yaml
---
name: explain-code
description: Explains code with visual diagrams and analogies. Use when explaining how code works, teaching about a codebase, or when the user asks "how does this work?"
---

When explaining code, always include:

1. **Start with an analogy**: Compare the code to something from everyday life
2. **Draw a diagram**: Use ASCII art to show the flow, structure, or relationships
3. **Walk through the code**: Explain step-by-step what happens
4. **Highlight a gotcha**: What's a common mistake or misconception?

Keep explanations conversational. For complex concepts, use multiple analogies.
```

A skill that should only be user-triggered (fgate `/implement`, `/review`) adds `disable-model-invocation: true`.

### Shipping skills

- **Project**: commit `.claude/skills/` to the repo.
- **Plugin**: drop the same directory under `<plugin>/skills/` — same SKILL.md, just namespaced as `/<plugin>:<skill>` once installed.
- **Personal**: `~/.claude/skills/`.

User invokes: `/<skill-name>` (project/personal) or `/<plugin-name>:<skill-name>` (plugin).

---

## 3. Slash commands

Per the skills page note: **slash commands and skills are now the same primitive.** A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both produce `/deploy` and accept the same frontmatter. The `commands/` form is "still works" / legacy; the recommended path forward is **skills**, because skills support a directory with supporting files.

What this means in practice for fgate:

- File path for a flat command: `.claude/commands/<name>.md` (project) or `~/.claude/commands/<name>.md` (personal) or `<plugin>/commands/<name>.md` (plugin).
- The file body is plain markdown; YAML frontmatter is the **same set of fields** documented for skills (`description`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `model`, `effort`, `context`, `agent`, `paths`, `shell`, `hooks`).
- Argument substitution is identical: `$ARGUMENTS`, `$0..$N`, `$<name>`, plus `!`...`` shell injection and `${CLAUDE_SKILL_DIR}` etc.
- Subdirectories under `commands/` do **not** create namespaces in Claude Code (unlike Gemini CLI's `git/commit.toml` → `/git:commit`). Plugin namespacing is the only `:` form Claude Code uses.
- Invocation: `/command-name [args]`, exactly as for skills.

Minimal example, `.claude/commands/commit.md`:

```markdown
---
description: Stage and commit the current changes
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)
---

Stage all current modifications and write a conventional-commits message
for them. Run `git status` first, then `git add -p`-equivalent staging,
then `git commit`.

Context:
- Status: !`git status --short`
- Diff: !`git diff --cached`

$ARGUMENTS
```

User invokes: `/commit fix: drop dead code`.

> Recommendation for fgate: ship the gates as **skills** (`prompt`, `plan`, `implement`, `review`, `improve`) under `<plugin>/skills/`. Keep `commands/` only if there's a reason to land an existing flat-file command. Skills win because (a) they support `scripts/` and `references/` siblings, (b) the SKILL.md format is the cross-tool Agent Skills standard, so the same files port to Gemini CLI's skill loader.

---

## fgate-specific takeaways

1. **Distribute as a single Claude Code plugin** named `fgate`, listed in a small `fgate-marketplace` repo. Users run `/plugin marketplace add fmind/fgate-marketplace` then `/plugin install fgate@fgate-marketplace`. Bare-clone dev path: `claude --plugin-dir ./fgate`.
2. **One skill per gate** under `fgate/skills/{prompt,plan,implement,review,improve}/SKILL.md`. Set `disable-model-invocation: true` on `implement`, `review`, `improve` (side-effect-y); leave `prompt` and `plan` model-invocable so Claude can pull them in when the user describes work informally.
3. **Use `${CLAUDE_SKILL_DIR}/scripts/...`** for any helper scripts so they resolve regardless of cwd.
4. **Pin `version` in `plugin.json`** from day one — without it, every commit on `main` becomes a forced upgrade for users.
5. **Cross-tool reuse**: the SKILL.md format is the [Agent Skills](https://agentskills.io) open standard, so the same `skills/<gate>/SKILL.md` files load from Gemini CLI under `~/.gemini/skills/` or `.gemini/skills/` — confirmed by the local `create-agent-skill` skill at `/home/fmind/.claude/skills/create-agent-skill/SKILL.md` (which uses the identical two-field frontmatter `name` + `description`). Slash-command syntax differs (Gemini CLI uses TOML); skills are the portable layer.
6. **Open question / unclear from sources**: whether plugin-level `userConfig` values are usable inside a SKILL.md body via `${user_config.X}` substitution. The docs only show `${user_config.*}` for MCP/LSP/monitor `command` strings — extending it to skill content is unclear from sources.

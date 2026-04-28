# Research: obra/superpowers

Source: <https://github.com/obra/superpowers> (fetched 2026-04-28). All paths and quotes
below come from real fetched files. Plugin version at fetch time: `5.0.7`.

## What it is

`superpowers` is a Claude Code plugin (with parallel `.codex-plugin/`, `.cursor-plugin/`,
`.opencode/` directories) that ships a library of "skills" — reusable, gated workflow
documents that the agent is expected to load and follow before acting. The plugin
manifest describes itself as "Core skills library for Claude Code: TDD, debugging,
collaboration patterns, and proven techniques." Author: Jesse Vincent (`jesse@fsck.com`).

The framework's thesis is that agents should pause and invoke a *skill* before any
non-trivial reply. Skills enforce a multi-stage pipeline — brainstorm/spec → write-plan
→ execute (TDD) → request-review → finish-branch — with explicit gates between stages.
Commands (`/commands/*.md`) exist but are now thin deprecation shims pointing at skills.

## File / folder structure

Top-level (from the repo root):

- `.claude-plugin/` — `plugin.json`, `marketplace.json`
- `.codex-plugin/`, `.cursor-plugin/`, `.opencode/` — per-host adapters
- `agents/`, `assets/`, `commands/`, `docs/`, `hooks/`, `scripts/`, `skills/`, `tests/`
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` — host-specific entry points
- `package.json`, `LICENSE` (MIT)

`/skills/` (14 skills, each a folder with `SKILL.md` + optional companions):

- `brainstorming/` — `SKILL.md`, `spec-document-reviewer-prompt.md`, `visual-companion.md`, `scripts/`
- `writing-plans/` — `SKILL.md`, `plan-document-reviewer-prompt.md`
- `test-driven-development/` — `SKILL.md`, `testing-anti-patterns.md`
- `systematic-debugging/` — `SKILL.md`, `root-cause-tracing.md`, `defense-in-depth.md`,
  `condition-based-waiting.md`, `condition-based-waiting-example.ts`, `find-polluter.sh`,
  `test-pressure-1.md`, `test-pressure-2.md`, `test-pressure-3.md`, `test-academic.md`,
  `CREATION-LOG.md`
- `writing-skills/` — `SKILL.md`, `anthropic-best-practices.md`, `persuasion-principles.md`,
  `testing-skills-with-subagents.md`, `graphviz-conventions.dot`, `render-graphs.js`,
  `examples/`
- `using-superpowers/` — `SKILL.md`, `references/`
- `requesting-code-review/` — `SKILL.md`, `code-reviewer.md`
- Other skills (each with their own `SKILL.md`): `dispatching-parallel-agents`,
  `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`,
  `subagent-driven-development`, `using-git-worktrees`, `verification-before-completion`

`/commands/` (deprecated; all three files just tell the agent to use the skill instead):

- `brainstorm.md`, `write-plan.md`, `execute-plan.md`

## Plugin manifest (verbatim from `.claude-plugin/plugin.json`)

```json
{
  "name": "superpowers",
  "description": "Core skills library for Claude Code: TDD, debugging, collaboration patterns, and proven techniques",
  "version": "5.0.7",
  "keywords": ["skills", "tdd", "debugging", "collaboration", "best-practices", "workflows"]
}
```

`marketplace.json` wraps a single plugin entry with `"source": "./"`.

## Skill / prompt patterns worth borrowing for fgate

1. **Skill = folder with `SKILL.md` + optional companions.** Heavy reference material
   (100+ lines), example code, and reviewer prompts live as siblings, kept out of the
   main file to control token cost. See `writing-skills/SKILL.md`'s rule: supporting
   files belong in separate directories "only for heavy reference material (100+ lines)
   or reusable tools."

2. **YAML frontmatter is the discoverability surface.** Two fields only — `name` and
   `description`. The description starts with "Use when..." and lists triggers, not the
   workflow. Examples (verbatim):
   - `name: test-driven-development` / `description: Use when implementing any feature or bugfix, before writing implementation code`
   - `name: brainstorming` / `description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."`
   `writing-skills/SKILL.md` is explicit: "Never summarize the skill's workflow" in the
   description, because that lets agents skip reading the body.

3. **Hard gates between stages.** `brainstorming/SKILL.md`: *"Do NOT invoke any
   implementation skill, write any code, scaffold any project, or take any
   implementation action until you have presented a design and the user has approved
   it."* Each skill ends by naming the *one* allowed next skill (brainstorming → writing-plans
   → executing-plans). This maps cleanly to fgate's prompt → plan → implement → review → improve.

4. **Specs/plans written to predictable paths.** Brainstorming writes to
   `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. fgate could mirror this with
   `docs/fgate/specs/` and `docs/fgate/plans/` for cheap traceability.

5. **Self-review prompts as separate companion files.** `spec-document-reviewer-prompt.md`
   and `plan-document-reviewer-prompt.md` are dispatched against the just-written doc.
   This is a clean way to implement fgate's "review" gate without bloating the main skill.

6. **TDD as a rigid skill.** `test-driven-development/SKILL.md` uses a "Iron Law" block,
   a Red/Green/Refactor graphviz diagram, Good/Bad code pairs, a rationalization table,
   and a final verification checklist. The pattern (law → diagram → examples → anti-patterns
   → checklist) is highly reusable as a fgate skill template.

7. **Two execution modes per workflow.** `writing-plans/SKILL.md` ends by offering
   "Subagent-Driven" vs "Inline Execution". Useful for fgate: a single skill can declare
   how it can be run rather than forcing one mode.

8. **`using-superpowers/SKILL.md` as the bootstrapper.** Frontmatter: *"Use when
   starting any conversation - establishes how to find and use skills, requiring Skill
   tool invocation before ANY response including clarifying questions."* Acts as the
   dispatcher that routes to other skills — fgate's entry skill should do the same.

9. **Multi-host parity via parallel dirs.** `.claude-plugin/`, `.codex-plugin/`,
   `.cursor-plugin/`, `.opencode/`, plus `CLAUDE.md`/`GEMINI.md`/`AGENTS.md` at root.
   For fgate's Gemini-CLI-and-Claude-Code targeting, this layout is directly usable.

## Anti-patterns / things to avoid for a personal-first, less-verbose tool

1. **Heavy moralizing tone.** TDD skill repeats "Iron Law", "not negotiable", "rationalization",
   "Delete means delete" dozens of times. Effective for adversarial setups, but for a
   personal tool it adds noise. Keep the rules; drop the sermon.

2. **Deprecated `/commands/` shims left in tree.** `commands/brainstorm.md`,
   `write-plan.md`, `execute-plan.md` all just say "this command is deprecated, use the
   skill instead." Don't ship dead surface area — collapse commands into skills from day
   one, or version them out cleanly.

3. **Long rationalization tables.** TDD skill has a ~12-row "Common Rationalizations"
   table plus a separate "Red Flags" list overlapping it. For fgate, one short list is enough.

4. **9-step linear processes.** Brainstorming's 9-step flow (explore → visual offer →
   one-question-at-a-time → 3 approaches → section approvals → write doc → self-review →
   user-review → next skill) is too ceremonial for solo work. Compress to 3-4 gates.

5. **"1% chance applicability → still invoke" rule** (`using-superpowers/SKILL.md`). This
   maximizes safety at the cost of latency and token spend; for a personal tool, prefer
   explicit user invocation or a lightweight router.

6. **Duplicated host adapters.** Four near-parallel plugin dirs is a maintenance tax.
   fgate should pick one canonical skill format and generate host-specific manifests if
   needed, not hand-maintain four.

7. **Sub-200-word target violated repeatedly.** `writing-skills/SKILL.md` recommends
   "under 200 words total" for frequently-loaded skills, yet most skills are far longer.
   fgate should actually enforce the budget it claims.

## Direct links

- Repo root: <https://github.com/obra/superpowers>
- Plugin manifest: <https://raw.githubusercontent.com/obra/superpowers/main/.claude-plugin/plugin.json>
- Marketplace: <https://raw.githubusercontent.com/obra/superpowers/main/.claude-plugin/marketplace.json>
- Bootstrapper skill: <https://raw.githubusercontent.com/obra/superpowers/main/skills/using-superpowers/SKILL.md>
- Brainstorming (gate pattern): <https://raw.githubusercontent.com/obra/superpowers/main/skills/brainstorming/SKILL.md>
- Writing plans (plan template): <https://raw.githubusercontent.com/obra/superpowers/main/skills/writing-plans/SKILL.md>
- TDD skill (rigid-skill template): <https://raw.githubusercontent.com/obra/superpowers/main/skills/test-driven-development/SKILL.md>
- Writing skills (meta-skill, frontmatter rules): <https://raw.githubusercontent.com/obra/superpowers/main/skills/writing-skills/SKILL.md>
- Deprecated command shim example: <https://raw.githubusercontent.com/obra/superpowers/main/commands/brainstorm.md>
- Skills index (browse): <https://github.com/obra/superpowers/tree/main/skills>

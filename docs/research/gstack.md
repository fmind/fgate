# gstack — Research Brief for fgate

Source: <https://github.com/garrytan/gstack> (real, fetched 2026-04-28). MIT licensed. Author: Garry Tan.

## What it is

gstack is "a collection of SKILL.md files that give AI agents structured roles for
software development. Each skill is a specialist: CEO reviewer, eng manager,
designer, QA lead, release engineer, debugger, and more." (`AGENTS.md`). It targets
Claude Code primarily, but `./setup --host <name>` adapts the same skill bodies to
"OpenAI Codex CLI, OpenCode, Cursor, Factory Droid, Slate, Kiro, Hermes, GBrain,
and others" (`README.md`). Install lands the repo at `~/.claude/skills/gstack/`.

The opinionated workflow is a seven-stage sprint: **Think -> Plan -> Build -> Review
-> Test -> Ship -> Reflect**, where each stage is a slash command (`/office-hours`,
`/plan-ceo-review`, `/plan-eng-review`, `/review`, `/qa`, `/ship`, `/retro`). Skills
chain by writing artifacts (design docs, test plans, plan-completion records) that
downstream skills read. Self-improvement is operational: "At the end of every skill
session, the agent reflects on what went wrong... and logs operational learnings to
`~/.gstack/projects/{slug}/learnings.jsonl`. Future sessions surface these learnings
automatically" (`CONTRIBUTING.md`).

## File / folder structure (verbatim from repo root)

Top-level layout (from `https://github.com/garrytan/gstack/tree/main`):

- One folder per skill, each containing a generated `SKILL.md` plus its source
  `SKILL.md.tmpl`. Examples actually present: `office-hours/`, `plan-ceo-review/`,
  `plan-eng-review/`, `plan-design-review/`, `plan-devex-review/`, `review/`,
  `qa/`, `qa-only/`, `ship/`, `retro/`, `browse/`, `cso/`, `codex/`, `careful/`,
  `freeze/`, `guard/`, `unfreeze/`, `learn/`, `investigate/`, `pair-agent/`,
  `gstack-upgrade/`, `land-and-deploy/`, `canary/`, `health/`, `autoplan/`,
  `context-save/`, `context-restore/`, `design-consultation/`, `design-review/`,
  `design-shotgun/`, `design-html/`, `devex-review/`, `document-release/`,
  `office-hours/`, `make-pdf/`, `model-overlays/`, `landing-report/`,
  `plan-tune/`, `setup-deploy/`, `setup-browser-cookies/`, `open-gstack-browser/`,
  `agents/`, `claude/`, `extension/`, `hosts/`, `openclaw/`, `supabase/`,
  `benchmark/`, `benchmark-models/`, `contrib/`, `test/`.
- Shared infra: `lib/` (`worktree.ts`), `scripts/` (build, eval, skill validation,
  e.g. `gen-skill-docs.ts`, `discover-skills.ts`, `skill-check.ts`,
  `eval-select.ts`, `host-config.ts`), `bin/` (executables incl. `dev-setup`,
  `dev-teardown`).
- Root docs: `README.md`, `AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `ETHOS.md`,
  `DESIGN.md`, `BROWSER.md`, `SKILL.md`, `SKILL.md.tmpl`, `CHANGELOG.md`,
  `CONTRIBUTING.md`, `TODOS.md`, `VERSION`, `LICENSE`.
- Config: `package.json`, `bun.lock`, `conductor.json`, `slop-scan.config.json`,
  `actionlint.yaml`, `.env.example`, `.gitlab-ci.yml`, `.github/`.
- Sub-structure inside a skill (example `review/`): `SKILL.md`, `SKILL.md.tmpl`,
  `checklist.md`, `design-checklist.md`, `greptile-triage.md`, `TODOS-format.md`,
  and `specialists/` containing `api-contract.md`, `data-migration.md`,
  `maintainability.md`, `performance.md`, `red-team.md`, `security.md`,
  `testing.md`. The `qa/` skill mirrors this with `references/` and `templates/`.
- Docs hub: `docs/` with `skills.md`, `ADDING_A_HOST.md`, `ON_THE_LOC_CONTROVERSY.md`,
  `OPENCLAW.md`, `REMOTE_BROWSER_ACCESS.md`, `gbrain-sync.md`, plus `designs/`,
  `evals/`, `images/`.

## Skill / prompt / command patterns worth borrowing

1. **One skill = one folder = one `SKILL.md` with YAML frontmatter.** Verbatim
   header from `plan-eng-review/SKILL.md.tmpl`:
   ```yaml
   ---
   name: plan-eng-review
   preamble-tier: 3
   interactive: true
   version: 1.0.0
   description: |
     Eng manager-mode plan review. Lock in the execution plan...
   voice-triggers: ["tech review", "technical review", "plan engineering review"]
   benefits-from: [office-hours]
   allowed-tools: [Read, Write, Grep, Glob, AskUserQuestion, Bash, WebSearch]
   triggers: [review architecture, eng plan review, check the implementation plan]
   ---
   ```
   Useful fields for fgate: `allowed-tools` (least-privilege per gate),
   `benefits-from` (declares upstream artifacts, enabling chain validation),
   `voice-triggers` vs `triggers` (natural-language vs slash-command surfaces),
   `preamble-tier` (lets skills opt out of heavy shared prose).

2. **Templates compile to outputs.** "SKILL.md files are **generated** from `.tmpl`
   templates. Edit the template, not the output." (`AGENTS.md`). Template tokens
   like `{{PREAMBLE}}` and `{{GBRAIN_CONTEXT_LOAD}}` are substituted by
   `bun run gen:skill-docs`, with per-host variants via
   `bun run gen:skill-docs --host codex`. fgate could keep one source-of-truth and
   render Gemini CLI + Claude Code variants the same way.

3. **Gated, ordered workflow.** The Think -> Plan -> Build -> Review -> Test -> Ship
   pipeline maps cleanly to fgate's prompt -> plan -> implement -> review -> improve.
   Each stage produces a persisted artifact in `~/.gstack/projects/{slug}/` that the
   next stage reads — no in-memory chaining.

4. **Specialist sub-checklists.** `review/specialists/security.md` shows a tight
   contract: scope condition, JSON-line output schema, `NO FINDINGS` sentinel,
   then categorized checks. Skills dispatch specialists "based on diff scope"
   (`review/SKILL.md`). For fgate's review gate, this is a lean way to grow
   coverage without bloating one prompt.

5. **Operational self-improvement, file-based.** Per-project
   `learnings.jsonl` plus a dedicated `/learn` skill is a no-MCP, no-DB way to
   close the feedback loop. Trivially portable to fgate.

6. **Routing rules in the host preamble.** `SKILL.md.tmpl` (root) tells the agent:
   "When you see these patterns, INVOKE the skill via the Skill tool... User
   describes a new idea -> invoke `/office-hours`". Centralized routing beats
   per-skill cross-references.

7. **Confidence calibration + one-question-at-a-time.** "One issue = one
   AskUserQuestion — never combine findings" and "Confidence calibration required
   (1-10) on every finding" (`plan-eng-review/SKILL.md`). Cheap, high-signal
   discipline for review/improve gates.

8. **Per-skill version + `preamble-tier`.** Lets fgate ship breaking changes to
   one gate without invalidating the whole toolchain.

## Anti-patterns to avoid (for a personal-first, less-verbose tool)

- **Surface sprawl.** ~50 top-level skill folders is too many for a personal
  toolkit. fgate's five gates plus a self-improve loop is the right scope; resist
  the urge to grow `/canary`, `/freeze`, `/make-pdf`, `/openclaw` style siblings.
- **Heavy ethos preambles.** `ETHOS.md` is "injected into every workflow skill's
  preamble automatically" — a multi-page essay on every invocation. Personal-first
  means the user already shares the ethos; keep preambles short or opt-in.
- **Marketing voice in source files.** README opens with productivity claims
  ("~810x my 2013 pace", "10,000+ usable lines of code per day"). Useful for
  growth, distracting in tooling. Keep fgate docs factual.
- **Hard runtime dependency on Bun + Conductor + Supabase + 22MB ML
  classifier.** gstack's "Prompt injection defense: 22MB ML classifier + Claude
  Haiku transcript validation... Optional 721MB DeBERTa ensemble" is overkill for
  a personal CLI. Stay scriptable and dependency-light.
- **Custom config CLI for everything.** `gstack-config set checkpoint_mode
  continuous` etc. — for a personal tool, a single TOML/YAML beats a bespoke CLI.
- **Role-playing as a corporate team.** "/office-hours (CEO/Founder)",
  "/cso (Security Officer)", "/plan-ceo-review". Personae are fun branding but
  add prompt tokens with no behavioral lift Gemini/Claude don't already give from
  a clear instruction. Prefer task-named gates (`plan`, `review`).
- **Telemetry plumbing.** Even opt-in telemetry adds maintenance. Skip entirely
  for a personal tool.
- **Long single-file skills.** `plan-eng-review` enumerates 15 cognitive patterns
  plus four review sections plus outputs in one `SKILL.md`. Better: short skill
  body + linked sub-files (which gstack itself does in `review/specialists/`).

## Direct links

- Repo root: <https://github.com/garrytan/gstack>
- Workflow overview / skill index: <https://github.com/garrytan/gstack/blob/main/AGENTS.md>
- Builder ethos (preamble): <https://github.com/garrytan/gstack/blob/main/ETHOS.md>
- Root SKILL template (host preamble + routing): <https://github.com/garrytan/gstack/blob/main/SKILL.md.tmpl>
- Example gated skill (template + frontmatter): <https://github.com/garrytan/gstack/blob/main/plan-eng-review/SKILL.md.tmpl>
- Generated skill output: <https://github.com/garrytan/gstack/blob/main/plan-eng-review/SKILL.md>
- Multi-stage review skill with specialists: <https://github.com/garrytan/gstack/tree/main/review>
- Specialist sub-checklist (output schema worth copying): <https://github.com/garrytan/gstack/blob/main/review/specialists/security.md>
- Self-improvement loop and dev workflow: <https://github.com/garrytan/gstack/blob/main/CONTRIBUTING.md>
- Build / template tooling: <https://github.com/garrytan/gstack/tree/main/scripts> (`gen-skill-docs.ts`, `discover-skills.ts`, `skill-check.ts`)
- Per-host adapters: <https://github.com/garrytan/gstack/tree/main/scripts/host-adapters>
- Docs hub: <https://github.com/garrytan/gstack/tree/main/docs>

# fgate — Plan

> An agentic coding workflow toolkit. Six gates (init → prompt → plan → implement → review → improve), portable across Gemini CLI and Claude Code, with files-as-state and a self-improvement loop that ships reviewable diffs.

## 1. Vision & Moat

fgate is a personal-first toolkit (OSS as a bonus, MIT) that closes the loop between human intent and agent execution. Daily-driver-first for **Gemini CLI** and **Claude Code** — same canonical skills, two thin manifests.

Three load-bearing pillars (the moat):

1. **Files as I/O.** Every agent input and output is a markdown file under `.agents/gates/<id>/`. No sidecar DB, no `state.json`, no LLM scratchpad. Branch + file presence = state. (Counter to the field's compaction-as-magic stance — a real pain point per HN 47338664, 45923974.)
2. **Amplify the user.** Minimum attention per step, maximum work between steps. Each command suggests the next; the human approves hand-offs, doesn't synthesize. Stops only on critical blockers; non-critical issues land in review.
3. **Alignment via self-improvement.** `/fgate:improve` is the only command that mutates the meta-process (AGENTS.md or `skills/<n>/SKILL.md`). Every invocation produces a reviewable git diff. (Most "self-improving" frameworks ship retros that go nowhere — superpowers retros, gstack `learnings.jsonl`, BMad `*retro` all dump into chat history or agent-only state. Verified in pain-points §4.)

Stays simpler than spec-kit / BMad / superpowers / gstack: 6 skills, ≤ 200 words per skill body, no enterprise theatre.

## 2. Principles

- **File presence is state.** No `state.json`, no in-memory chaining.
- **Two artifacts per gate**: `human/<gate>.md` (terse skim) + `agent/<gate>.md` (full detail). Different attention budgets, different files. Both committed; effectively read-only after write (the next gate writes new files, not edits).
- **AGENTS.md is the single source of truth**; `CLAUDE.md` and `GEMINI.md` are one-line `@AGENTS.md` imports (no symlinks). Both tools natively expand `@file.md` in their context files.
- **Branch per task.** Each `<id>_<slug>` lives on its own branch; gates progress on that branch; merge to `main` happens at `/fgate:review`'s suggestion.
- **Each command suggests the next.** Hand-off is the contract.
- **Self-improvement only via `/fgate:improve`.** Keeps the meta-surface tight and reviewable.
- **Native plugin systems first.** Markdown-first. No Python, no PyPI, minimal bash.
- **Common-denominator design.** Anything that doesn't work cleanly in BOTH Gemini CLI and Claude Code doesn't ship in v1.

## 3. Commands

Six skills under one plugin/extension namespace. Skill folders are bare verbs (`init/`, `prompt/`, `plan/`, `implement/`, `review/`, `improve/`); the `fgate` plugin/extension namespace supplies the prefix on invocation. So the user types `/fgate:init`, `/fgate:prompt`, etc. — Claude Code forces this namespace for plugin-installed skills, and Gemini CLI matches it via the `commands/fgate/` subdirectory convention.

Note on Claude Code: `disable-model-invocation: true` is set on `implement`, `review`, and `improve` (side-effect-y gates the user must trigger explicitly). Left unset on `init`, `prompt`, and `plan` so Claude can auto-invoke them when the user describes work informally.

### `/fgate:init`

Bootstrap a fresh repo for fgate use.

- Create `.agents/{skills,gates,docs}/` skeleton (Agent Skills cross-tool standard root).
- Generate `AGENTS.md` from scratch by inspecting the repo (~30 bullets initially; can grow over time). Reusing an external AGENTS.md from a path/URL is v0.2.
- Write `CLAUDE.md` containing `@AGENTS.md` and `GEMINI.md` containing `@./AGENTS.md` (each tool natively expands the import). Optional tool-specific notes can follow the import line.
- Suggest `/fgate:prompt <title>`.

### `/fgate:prompt <short-title>`

Capture user intent. **Set initial success criteria** — this is where the human's attention is highest, so spend it here.

- Resolves a new task ID `<N>_<slug>`; creates branch `gates/<N>_<slug>` from `main`.
- Challenges the prompt — asks targeted questions to extract context up-front. **Hard cap: 3 questions** (or stop earlier when criteria are concrete). If criteria can't be made concrete, fail loud — don't advance to `/fgate:plan`.
- Defines initial success criteria (tests pass, lint clean, behavior X observed). The human signs off here.
- Writes `human/prompt.md` (terse) + `agent/prompt.md` (full, including criteria).
- Commits on the task branch. Suggests `/fgate:plan <id>`.

### `/fgate:plan <id>`

Investigate codebase + relevant docs to produce a precise specification.

- Surfaces only **blocking** decisions; otherwise advances silently.
- Refines the criteria from `/fgate:prompt` — does NOT introduce new criteria the user hasn't sanctioned.
- Writes `human/plan.md` (summary) + `agent/plan.md` (precise spec).
- Commits. Suggests `/fgate:implement <id>`.

### `/fgate:implement <id>`

Execute the plan to the success criteria.

- Continuously appends to `human/trace.md` (key events) + `agent/trace.md` (full execution log).
- Tests + lint inside this gate; targets defined in plan.
- Stops only on **critical blockers** (e.g., not authenticated to a CLI). Non-critical issues finish and surface in review.
- On completion writes `human/result.md` (summary, open questions) + `agent/result.md` (decisions, alternatives considered).
- Commits. Suggests `/fgate:review <id>`.

### `/fgate:review <id>`

Read `result.md`, align with the user, and finalize the task.

- **Default**: propose a conventional-commit message + a merge plan; ask Y/N before committing and merging the task branch back to `main`.
- May also propose follow-up work (`/fgate:prompt ...`) or meta-process tweaks (`/fgate:improve <id>`).
- **Override the commit-mode** by either: (a) adding an AGENTS.md bullet that names the desired mode (e.g., "review auto-commits without asking" or "review only suggests; user runs `git commit` manually"), or (b) shipping a project-specific review skill at `.agents/skills/review/SKILL.md` to replace the gate end-game wholesale.

### `/fgate:improve <id>`

**Optional, user-triggered.** Convert improvement notes into changes to **AGENTS.md** (in the user's project, in-place) or a **`skills/<name>/SKILL.md`** (proposed as a diff against fgate's source for the user to PR upstream).

- The only command that mutates the meta-process. Diffs must be small and reviewable: bullet additions/edits in AGENTS.md OR targeted edits to a single skill body — never both at once.
- **Two output modes** (asked at invocation):
  - **Branch / worktree** (default): create `improve/<task-id>_<topic>`, write the diff there, leave merge to the user. Best for non-trivial changes that warrant a review beat.
  - **In place**: edit AGENTS.md (or the skill body) on the current task branch directly. Best for confirmed, small tweaks.
- Skipping is fine. Most tasks won't earn an `improve` step; that's a feature, not a bug.

## 4. Folder Structure

The fgate repo root is **simultaneously** a Claude Code plugin AND a Gemini CLI extension. Both tools auto-discover skills from the manifest's default `./skills/` location — verified: Claude Code's `plugin.json` `skills` field defaults to `./skills/`; Gemini CLI's extension loader hardcodes the path to `<extension-root>/skills/` (per `extension-manager.ts` in `google-gemini/gemini-cli`). So `./skills/` is canonical here; no manifest override is needed.

`.agents/` is the cross-tool open standard for **end-user projects** (per agentskills.io and `npx skills`, the Vercel-maintained installer that drops SKILL.md files at `.agents/skills/` for non-Claude tools and `.claude/skills/` for Claude Code). Inside fgate's own repo, `.agents/skills/` is a committed symlink → `../skills/` so the author's `.agents/skills/`-based personal workflow can reach fgate's skills while editing fgate itself.

```
fgate/
  AGENTS.md                           # canonical context (~30 bullets after init; grows over time)
  CLAUDE.md                           # one-line: `@AGENTS.md` (Claude Code expands it natively)
  GEMINI.md                           # one-line: `@./AGENTS.md` (Gemini CLI expands it natively)
  PLAN.md, README.md, LICENSE         # MIT

  .claude-plugin/
    plugin.json                       # plugin manifest (version pinned; default ./skills/, no override)
    marketplace.json                  # single-plugin marketplace ("source": "./")

  gemini-extension.json               # Gemini CLI extension manifest (skills auto-discovered from ./skills/)

  skills/                             # CANONICAL — Agent Skills (open standard, agentskills.io)
    init/SKILL.md
    prompt/SKILL.md
    plan/SKILL.md
    implement/SKILL.md
    review/SKILL.md
    improve/SKILL.md

  commands/                           # Gemini TOML shells (Claude Code does not need these)
    fgate/
      init.toml                       # /fgate:init — body: @{skills/init/SKILL.md}\n{{args}}
      prompt.toml
      plan.toml
      implement.toml
      review.toml
      improve.toml

  docs/research/                      # Phase 0 outputs (not loaded at runtime)
    superpowers.md, gstack.md, claude-code.md, gemini-cli.md, pain-points.md

  scripts/
    check-skill-words.sh              # CI: enforce ≤ 200 words per SKILL.md body

  .agents/                            # cross-tool .agents/ root (this layout is what /fgate:init creates in user projects)
    skills -> ../skills/              # symlink (committed in fgate; in user projects this is a real dir)
    gates/                            # task workspace (committed on task branches)
      <N>_<slug>/
        human/{prompt,plan,trace,result,review}.md
        agent/{prompt,plan,trace,result,review}.md
    docs/                             # external research the agent gathers during gates
```

**Invocation surface:**

- **Claude Code** — after `/plugin install fgate@<marketplace>` (or `claude --plugin-dir ./fgate` for dev), each skill is invocable as `/fgate:prompt`, `/fgate:plan`, etc. Slash commands and skills are now the same primitive in Claude Code, so no `commands/*.md` shells needed. Plugin-installed skills are namespaced by the plugin manager — bare invocations like `/prompt` are not available from a plugin install (would require manual install into `~/.claude/skills/` instead).
- **Gemini CLI** — after `gemini extensions install fmind/fgate` (or `gemini extensions link ./fgate`), TOML shells under `commands/fgate/` give `/fgate:prompt`, `/fgate:plan`, etc. Each shell is ~5 lines and `@{skills/<name>/SKILL.md}`-embeds the canonical body, so the procedure lives in one place. The `commands/fgate/` subfolder is what creates the `fgate:` namespace.
- **Tool-agnostic** — `npx skills add fmind/fgate` (Vercel-maintained, agentskills.io) is a third install path that symlinks SKILL.md files into the user's `.claude/skills/` (Claude Code) or `.agents/skills/` (every other agent in its install table). Useful for tools without a native plugin/extension surface; loses the `/fgate:` slash namespace and the TOML shells.

## 5. State Management

- Task ID = numeric prefix; resolver accepts `1` or `social_auth` (slug match).
- **Branch per task.** `/fgate:prompt` creates `gates/<N>_<slug>` off `main`. All gate files commit on that branch. `/fgate:review` suggests the merge back. Concurrent tasks = concurrent branches = no collisions.
- File presence determines the gate within a task:
  - `prompt.md` exists, no `plan.md` → ready for `/fgate:plan`.
  - `plan.md` exists, no `trace.md` → ready for `/fgate:implement`.
  - `result.md` exists → ready for `/fgate:review`.
- Worktrees per task are an optional accelerator (`git worktree add ../fgate-<id> gates/<id>_<slug>`); not required for v1. Useful for true parallel execution; defer enforcement.

## 6. Cross-Tool Common Denominator

Both Claude Code and Gemini CLI consume **Agent Skills** (open standard at agentskills.io: `SKILL.md` + YAML frontmatter `name`+`description`). The ONLY canonical artifact set is the six `skills/<name>/SKILL.md`. Every other layer is a thin manifest.

| Layer       | Form                                                                       | Path                                              |
| ----------- | -------------------------------------------------------------------------- | ------------------------------------------------- |
| Canonical   | Agent Skills SKILL.md (`name` + `description` frontmatter)                 | `skills/<name>/SKILL.md`                          |
| Claude Code | Plugin manifest (skills auto-discovered, namespaced as `/fgate:<name>`)    | `.claude-plugin/plugin.json` + `marketplace.json` |
| Gemini CLI  | Extension manifest + TOML shells embedding skill body via `@{...}`         | `gemini-extension.json` + `commands/fgate/*.toml` |
| Copilot     | Deferred — limited custom-command capability                               |                                                   |

**What works in both** (verified in `docs/research/`):

- SKILL.md folder layout (`skills/<n>/SKILL.md` + optional siblings under `<n>/`).
- Frontmatter `name` + `description` (the two-field portable subset of the Agent Skills standard).
- Markdown body with the gate's contract; references in sibling files.
- A repo-level context file (`AGENTS.md` is the open-standard name; `CLAUDE.md` and `GEMINI.md` are tool-specific aliases — each is a one-line `@AGENTS.md` import, so AGENTS.md stays the only source of truth).

**What does NOT cross over** (avoid in canonical bodies):

- Claude Code's `${CLAUDE_SKILL_DIR}`, `!`...``, `${user_config.X}` substitutions — Gemini CLI doesn't expand them.
- Gemini CLI's `!{shell}` and `@{path}` substitutions — only valid in TOML shells, not in SKILL.md bodies.
- Claude Code's `paths`, `allowed-tools`, `argument-hint`, `disable-model-invocation` frontmatter — Gemini CLI ignores them. Keep them as documentation only; do not rely on them for behavior.

**Rule**: anything that needs a tool-specific feature lives in the manifest layer (TOML shell or plugin.json), not in the canonical SKILL.md.

## 7. Conventions (enforced or recommended)

- **Skill body ≤ 200 words.** CI-checked via `scripts/check-skill-words.sh`. Heavy reference material lives in sibling files (`skills/<n>/references/`, `skills/<n>/templates/`).
- **Skill `description` starts with "Use when…"** Trigger-rich, not workflow-summarizing (per superpowers' writing-skills rule).
- **AGENTS.md is a list of bullets**: ~30 bullets after `/fgate:init`; grows organically as `/fgate:improve` adds learnings. No hard cap on count or line length — the agent needs room to be expressive.
- **`/fgate:improve` only edits AGENTS.md OR one skill body per invocation, never both.** No structural rearrangement; if the system needs a re-architecture, that's a manual decision.
- **Each skill ends by suggesting the next command.** Most gates suggest exactly one next step; `/fgate:review` is the explicit exception — it may branch (merge to `main`, `/fgate:prompt` for follow-up work, or `/fgate:improve` for meta-process tweaks).
- **`/fgate:prompt` Q&A capped at 3 questions.** If criteria still aren't concrete, fail loud — don't advance.
- **Pin `version` in `plugin.json` and `gemini-extension.json` from day one.** Without it, Claude Code uses git SHA → every commit is a forced upgrade.
- **`trace.md` is append-only during `/fgate:implement`.** Don't rewrite past entries; record events as they happen so the log reflects actual execution order.

## 8. Implementation Phases

### Phase 0 — Research (DONE)

Outputs in `docs/research/`: `superpowers.md`, `gstack.md`, `claude-code.md`, `gemini-cli.md`, `pain-points.md`. Pinned comparison points: superpowers v5.0.7, spec-kit v0.0.91+. Differentiation thesis (3 pillars in §1) verified against HN, GitHub issues, and the Anthropic Agent Skills standard.

### Phase 1 — Author canonical skills

Six `skills/<name>/SKILL.md`. Each:

- YAML frontmatter: `name` (matching folder), `description` ("Use when…").
- Body ≤ 200 words: read X, write Y, suggest exactly one next step.
- Sibling reference files (templates, examples) under the skill folder if needed.

Borrow patterns from superpowers (hard gates between stages, predictable artifact paths, name-the-next-skill ending) and gstack (specialist sub-checklists for `/fgate:review`). Avoid superpowers' moralizing tone, gstack's role-playing personae, and any 9-step linear processes.

### Phase 2 — Plugin / extension manifests

- `.claude-plugin/plugin.json` (with `version` pinned; default `./skills/`, no override needed) + `.claude-plugin/marketplace.json` (single-repo install, `"source": "./"`).
- `gemini-extension.json` at repo root (minimal: `name`, `version`, `description`, `contextFileName: "GEMINI.md"`). Skills auto-discovered from `./skills/` (path is hardcoded in Gemini's loader).
- Six TOML shells under `commands/fgate/<name>.toml`. Each ~5 lines: a `description`, a `prompt` that `@{skills/<name>/SKILL.md}`-embeds and tail-appends `{{args}}`.
- Commit a `.agents/skills` symlink → `../skills/` so the author's `.agents/skills/`-based personal workflow resolves fgate's skills while editing fgate. End users never see this; they get a real `.agents/skills/` directory via `/fgate:init`.

### Phase 3 — Context files & CI

- `AGENTS.md` (canonical) starts ~30 bullets from `/fgate:init`; grows over time via `/fgate:improve`. No hard cap on count or line length.
- `CLAUDE.md` = `@AGENTS.md`; `GEMINI.md` = `@./AGENTS.md`. Both tools natively expand `@file.md` in their context files (verified: code.claude.com/docs/en/memory shows the AGENTS.md interop pattern; geminicli.com/docs/cli/gemini-md documents `@file.md` imports). Optional tool-specific notes go below the import.
- `scripts/check-skill-words.sh` (pure bash, no deps) — only the SKILL.md word cap is enforced. AGENTS.md size is left to human judgement.
- A pre-commit hook (or GitHub Action) running the check.

### Phase 4 — Dogfood

Run `/fgate:init` on a fresh sample repo, then drive a real task through `/fgate:prompt` → `/fgate:plan` → `/fgate:implement` → `/fgate:review`. Test on **both** Gemini CLI and Claude Code — the "common denominator" claim holds only if both work end-to-end. Capture friction via `/fgate:improve`.

### Phase 5 — Announce (optional, after Phase 4 succeeds)

Draft a Show HN post leaning on pain-points pitches #1 (tool-portability: "one skill set, two CLIs") and #3 (minimalism: "6 skills × 200 words"). Don't publish until both Gemini CLI and Claude Code paths run cleanly on a non-fgate repo.

## 9. Open Questions / Deferred

- **Worktrees per task**: convention vs. enforced. Useful for true parallel execution; deferred to v0.2 unless dogfooding demands it.
- **Marketplace listings** (Claude plugin marketplace, gemini-extensions repo): timing depends on dogfood quality.
- **Reference AGENTS.md source for `/fgate:init`**: local path, URL, or both. v1 generates from scratch; reuse-from-source is v0.2.
- **`/fgate:improve` mutation target when fgate is plugin-installed**: edit user's project `AGENTS.md`? Mutate the cached plugin? Open a PR against fgate's source? **Default for v1**: mutate user's project `AGENTS.md`; fgate-source mutations need a manual PR (or are produced as a diff in the branch/worktree mode for the user to PR).
- **Copilot support**: revisit when Copilot's custom-command surface matures.

## 10. Non-Goals (v1)

- Python or PyPI distribution.
- Heavy bash scripting.
- Replacing built-in plan modes; fgate sits alongside them.
- Multi-repo / team-level coordination.
- Telemetry of any kind.
- LLM-classifier safety layers (gstack-style 22MB model). Trust the host CLI's defaults.

## 11. Risk Register (from pain-points §6)

Top failure modes the plan actively mitigates:

1. **Skill bodies bloat past 200 words.** → Mitigated by `scripts/check-skill-words.sh` in Phase 3 (CI-enforced).
2. **`/fgate:improve` produces ugly, unmergeable diffs.** → Mitigated by the rule that `/fgate:improve` edits AGENTS.md OR one skill body per invocation, never both, and never structural rearrangements. Reviewability comes from small scope, not a line-length cap.
3. **Gemini CLI half silently broken in dogfooding.** → Mitigated by Phase 4 mandate to test both tools before announce.
4. **superpowers/gstack already cover 80%.** → Counter-positioning is explicit (3-pillar moat, ≤ 200-word bodies, files-as-state). Differentiation is verifiable in 30 seconds of README.
5. **No-name solo OSS gets ignored.** → Phase 5 ships a blog post first; the repo is the artifact, not the pitch.

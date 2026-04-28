# TLDR — fgate v0.1 implementation review

> Written for you (Médéric) to skim before merging the implementation. What's
> in the box, what to verify, what I left for you to decide.

## What shipped

- **Six canonical skills** at `skills/<n>/SKILL.md` — `init`, `prompt`, `plan`, `implement`, `review`, `improve`. All bodies under 200 words (range 142–175). `description` fields all start with "Use when…".
- **`disable-model-invocation: true`** set on `implement`, `review`, `improve` (per the §2.1 split in `docs/final-check.md`); left auto-invocable on `init`, `prompt`, `plan`.
- **Claude Code plugin** — `.claude-plugin/plugin.json` (version pinned `0.1.0`, MIT, full author/repo metadata) and `.claude-plugin/marketplace.json` (single-plugin marketplace, `"source": "./"` — same pattern as superpowers).
- **Gemini CLI extension** — `gemini-extension.json` at root (version pinned, `contextFileName: "GEMINI.md"`). Six TOML shells under `commands/fgate/` (5 lines each, `@{skills/<n>/SKILL.md}` + `{{args}}`).
- **Context files** — `AGENTS.md` is the canonical context (~30 bullets covering purpose, stack, conventions, install, layout). `CLAUDE.md` and `GEMINI.md` are one-line `@AGENTS.md` imports.
- **Symlink** — `.agents/skills` → `../skills/` (committed, per `PLAN.md` §4 and §B-2).
- **CI** — `.github/workflows/ci.yml` runs three jobs on every push/PR: word-cap (`scripts/check-skill-words.sh`), JSON+TOML manifest validation (Python), and a check that `CLAUDE.md`/`GEMINI.md` are exactly the one-line imports. **All three passed** on the first push (run 25076238145, 9s).
- **README, LICENSE (MIT), `.gitignore`.**
- **GitHub repo configured** — description, topics (`agentic-coding`, `agent-skills`, `claude-code`, `gemini-cli`, `skills`, `plugin`, `workflow`, `gates`, `files-as-state`, `markdown`), homepage set to `https://fmind.github.io/fgate/`. Wiki and Projects disabled. Discussions enabled.
- **GitHub Pages** — enabled from `main` branch root. Will serve the `README.md` automatically. URL: `https://fmind.github.io/fgate/`.

## Verification I ran locally

- `bash scripts/check-skill-words.sh` — all six bodies under cap (142–175).
- `gemini extensions validate /home/fmind/fgate` — exit 0.
- `gemini extensions link /home/fmind/fgate` — registered (record at `~/.gemini/extensions/fgate/.gemini-extension-install.json`, type=link).
- `gemini -p '/fgate:plan a tiny demo'` — slash command resolved, expanded `@{skills/plan/SKILL.md}`, the agent followed the gate workflow (created `.agents/gates/001_demo/{human,agent}/` files and a `demo-app/` it then suggested `/fgate:implement 001` for). Smoke-test artifacts removed before commit.
- All three CI jobs green on push.

## What I did NOT verify (and why)

1. **Claude Code `--plugin-dir`** — I'm running *inside* a Claude Code session right now, so I can't open a separate session to test loading the plugin. The plugin manifest follows the documented spec verbatim (`name` + `version` + the rest as optional metadata), and the `skills/` layout is what Claude Code auto-discovers from the default location. **You should test**: in a fresh terminal, `claude --plugin-dir /home/fmind/fgate` and confirm `/fgate:init`, `/fgate:prompt`, etc. appear in the slash menu.
2. **Real end-to-end gate flow on a non-fgate repo** — Phase 4 of `PLAN.md`. I ran the smoke test above, but didn't drive `init → prompt → plan → implement → review` on a fresh sample repo through both CLIs. **Recommended next**: pick a tiny sandbox repo and run the loop end-to-end.
3. **Marketplace install via `/plugin marketplace add fmind/fgate`** — works only after the repo is public-fetchable, which it now is. You can test it.
4. **`gemini extensions install fmind/fgate`** — same: verify after the push lands. Should "just work" since the manifest and structure are valid.

## Known dev-time annoyance (cosmetic, end users unaffected)

When you `gemini extensions link ./` from inside the fgate repo itself, Gemini scans both:

- `<workspace>/.agents/skills/` (workspace tier)
- `<extension-root>/skills/` (extension tier)

Since `.agents/skills` is a symlink to `../skills/`, it resolves to the same files, and Gemini logs six `Skill conflict detected` warnings on every session start. **Cosmetic only** — the files are byte-identical, no behavior change. End users in their own projects don't see this (their `.agents/skills/` is a real directory of their own skills, separate from fgate's source).

If it bothers you, the cleanest fix is to drop the symlink. The cost: your personal `.agents/skills/`-based tooling won't see fgate's skills when editing fgate itself. I left it in per `PLAN.md` §4. **Your call.**

## Things I want you to review before declaring v0.1 "done"

1. **AGENTS.md content** (`AGENTS.md`, 33 bullets) — I wrote it from the PLAN. Read it and tell me if you'd phrase any bullet differently. Especially the install paths (Claude Code and Gemini CLI sections) — they're the most likely place for me to have hallucinated a small detail.
2. **README pitch** (`README.md`, ~120 lines) — the three-pillars section, gate table, and counter-positioning paragraph. Tone is "factual, no marketing voice" per your global rule. Worth a once-over.
3. **The six SKILL.md bodies** — the `description` fields are the load-bearing part (they're what triggers auto-invocation in both tools). Every one starts with "Use when…". The bodies are tight; if any feels too tight, we can swap heavy reference material into a sibling file under `skills/<n>/references/`.
4. **`/fgate:improve` output modes** — I implemented branch/worktree (default) and in-place per PLAN.md. The in-place mode warning ("changes don't propagate to other in-flight branches until merged") is in the SKILL body. If you want this to default to in-place instead, it's a one-line edit.
5. **CI is bash + Python only (no Node, no Bun)** — uses Python's stdlib `tomllib` (3.11+). GitHub Actions ubuntu-latest ships Python 3.12+, so this is fine. If you want to lift the Python dependency entirely, the TOML check can be done with `awk` but the JSON check can't easily be done without `python3` or `jq`.
6. **`actions/checkout@v5`** in CI — I started with v4, then bumped to v5 to silence the Node 20 deprecation warning. Confirm with the next push that the warning is gone.

## Open questions for you

1. **Marketplace strategy.** Right now the same repo is both the plugin AND a single-plugin marketplace (`.claude-plugin/marketplace.json` with `"source": "./"`). When you decide to submit to **Anthropic's marketplace** or **gemini-extensions** registries, do you want me to:
   - keep this single-repo bundling, OR
   - split into a separate `fgate-marketplace` repo (more conventional for multi-plugin maintainers)?
   No work needed today — just flagging the choice.
2. **Reference-AGENTS.md feature for `/fgate:init`.** PLAN.md §9 marked "reuse from path/URL" as v0.2. Confirm you want this deferred. If yes, I'll leave a note in the open-questions of AGENTS.md.
3. **Worktrees in `/fgate:improve`.** PLAN.md §3 says "branch / worktree (default)". Right now my SKILL body says "create `improve/<N>_<topic>` branch". I did NOT auto-`git worktree add` — the user does that themselves if they want isolation. Tell me if you want the skill to do `git worktree add` automatically.
4. **`/fgate:improve` mutating fgate's source vs. user's project.** PLAN.md §9 default: mutate user's project `AGENTS.md`; mutating fgate's source needs a manual PR (or branch/worktree mode for the user to PR). My SKILL body says exactly that. Confirm this is the intended default.
5. **GitHub Pages.** Enabled from `main` branch root. The README will be the homepage at `https://fmind.github.io/fgate/`. If you'd rather Pages serve `docs/` (research dump + final-check), or build something custom, say so — easy to change with `gh api`.
6. **Show HN draft.** PLAN.md Phase 5 calls for a draft Show HN post leaning on pitches #1 (tool-portability) and #3 (minimalism). I did NOT draft this — that's a Phase 5 deliverable after dogfooding. Want me to ghost-write it as a follow-up task?

## Files & locations cheat-sheet

| What                        | Where                                         |
| --------------------------- | --------------------------------------------- |
| Six canonical skills        | `skills/<n>/SKILL.md`                         |
| Gemini TOML shells          | `commands/fgate/<n>.toml`                     |
| Claude Code plugin manifest | `.claude-plugin/plugin.json`                  |
| Marketplace manifest        | `.claude-plugin/marketplace.json`             |
| Gemini extension manifest   | `gemini-extension.json`                       |
| Single source of truth      | `AGENTS.md`                                   |
| One-line imports            | `CLAUDE.md`, `GEMINI.md`                      |
| Word-cap CI                 | `scripts/check-skill-words.sh`, `.github/workflows/ci.yml` |
| Research / pre-implementation review | `docs/research/`, `docs/final-check.md` |
| Implementation thesis       | `PLAN.md`                                     |

## Quick re-test commands

```bash
# Word cap + manifest validity (mirrors CI)
bash scripts/check-skill-words.sh

# Validate Gemini extension structure
gemini extensions validate .

# Live-link in Gemini CLI (from any directory)
gemini extensions link /home/fmind/fgate

# Slash-command smoke test
gemini -p '/fgate:plan a tiny demo'   # creates .agents/gates/<N>/...

# Live-load in Claude Code (separate terminal)
claude --plugin-dir /home/fmind/fgate
# Then in the slash menu: /fgate:init, /fgate:prompt, etc.
```

## Suggested next steps (when you're ready)

1. Skim **AGENTS.md** + **README.md** + the six **SKILL.md** files. Either approve or open issues / a `/fgate:improve` cycle for the rough edges.
2. Open a fresh sample repo, run `/fgate:init` (Claude Code or Gemini CLI), then drive a real first task through the loop. This is Phase 4 of `PLAN.md`.
3. Review the six **open questions** in §"Open questions for you" above. Answers are small one-line edits, but they shape v0.2.
4. Decide on the **Show HN** timing per `PLAN.md` Phase 5.

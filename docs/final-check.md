# fgate — Final Check Before Implementation

> Pre-implementation review of `PLAN.md`. Verifies the load-bearing technical
> claims, calls out the real issues, and challenges design choices that would
> bite during dogfooding. Sources fetched 2026-04-28; citations inline. Where
> Phase 0 docs already verified a claim, this file just points back instead of
> re-pasting the proof.

---

## 1. Verified — load-bearing claims hold

These are the claims the rest of fgate's design rests on. All confirmed against
primary sources fetched today.

| Claim                                                          | Status | Evidence |
|----------------------------------------------------------------|:------:|----------|
| Both tools auto-discover `skills/<name>/SKILL.md`              | ✅     | Claude Code: plugins doc table ("Skills" row, "default location: skills/"); Gemini CLI: `geminicli.com/docs/extensions/reference/` ("`skills/security-audit/SKILL.md` exposes a `security-audit` skill") |
| `commands/fgate/<name>.toml` produces `/fgate:<name>` (Gemini) | ✅     | Gemini CLI: `commands/gcs/sync.toml` → `/gcs:sync` (extensions reference, verbatim) |
| Plugin-installed skills forced into `<plugin>:<skill>` namespace | ✅   | Claude Code plugins doc: "Plugin skills are always namespaced (like `/my-first-plugin:hello`) to prevent conflicts" |
| `disable-model-invocation: true` is a real Claude Code field   | ✅     | Used verbatim in the marketplace walkthrough's `quality-review` SKILL.md example |
| `CLAUDE.md` natively expands `@AGENTS.md`                      | ✅     | Claude Code memory doc has a verbatim AGENTS.md example: "create a `CLAUDE.md` that imports it… `@AGENTS.md`" |
| `GEMINI.md` natively expands `@./AGENTS.md`                    | ✅     | Gemini CLI memory doc: "`@file.md` syntax… supports both relative and absolute paths" |
| Single-repo plugin+marketplace works with `"source": "./"`     | ✅     | superpowers' real `marketplace.json` uses `"source": "./"` (live verified); also superpowers ships `.claude-plugin/plugin.json` in the same repo (path 200 from raw source) |
| `claude --plugin-dir ./fgate` for local dev                    | ✅     | Claude Code plugins doc, "Test your plugins locally" section |
| Pinning `version` avoids "every commit = forced upgrade"       | ✅     | Claude Code plugins-reference, version semantics block (verbatim warning) |
| Gemini extension `version` is required                         | ✅     | `gemini-extension.json` reference table marks `version*` required |
| Gemini extension auto-discovers `skills/`, no manifest array   | ✅     | "Place skill definitions in a `skills/` directory" (extensions reference) |

**Bottom line:** every cross-tool claim in `PLAN.md` §6 ("Cross-Tool Common
Denominator") is real. The plan is buildable as written.

---

## 2. Needs fixing — concrete corrections to PLAN.md

These are unambiguous bugs in the current PLAN. Fix before authoring skills.

### 2.1 `.agents/` reservation contradicts the new `.agents/docs/` ask

**Where:** §4, the comment block "`.agents/` is reserved for `gates/` only".
**Issue:** You now want `.agents/docs/` for agent research notes. The plan must
either drop the reservation or list `docs/` alongside `gates/`.
**Fix:** Replace the comment with: "`.agents/` holds task workspaces (`gates/`)
and shared agent knowledge (`docs/`). Nothing else." See §4 below for the
recommended `.agents/docs/` shape.

### 2.2 `review.md` is overloaded

**Where:** §3 (`/fgate:implement`), §4 (folder structure), §5 (file presence as
state).
**Issue:** `/fgate:implement` writes `human/review.md` + `agent/review.md` (the
implementation outcome), and `/fgate:review` is the *gate* that consumes them.
Same word, two meanings — confusing for a "files-as-state" project where file
names ARE the contract.
**Fix:** Rename the implementation outcome files to `result.md`. Lifecycle
becomes:

| Gate         | Reads                  | Writes                              |
|--------------|------------------------|-------------------------------------|
| prompt       | —                      | `prompt.md`                         |
| plan         | `prompt.md`            | `plan.md`                           |
| implement    | `plan.md`              | `trace.md`, `result.md`             |
| review       | `result.md`            | nothing (just merges + suggests)    |
| improve      | `result.md`            | `improve.md` + diff to AGENTS/skills|

State-resolver rule (§5) updates accordingly: "`result.md` exists → ready for
`/fgate:review`."

### 2.3 "Exactly one next command" rule contradicts `/fgate:review`

**Where:** §7 ("Each skill ends by suggesting exactly one next command…") vs
§3 (`/fgate:review` proposes prompt OR improve OR a merge).
**Issue:** Internal contradiction. Review is a fork point by design.
**Fix:** Two options, pick one:
1. **Force a primary.** Review picks ONE next command based on its conclusion
   (e.g. "ship it: run `git merge`" or "lock learnings: `/fgate:improve <id>`")
   and only mentions alternatives as a one-line `Other options:` footer.
2. **Document the exception.** Carve out review as the only branching gate;
   reword §7 to "Each non-review skill suggests exactly one next command."

Option 1 is more disciplined and matches the "minimum attention per step"
pillar. Recommend it.

### 2.4 Phase 4 dogfood prompt presumes init already ran

**Where:** §8 Phase 4: "Run `/fgate:prompt 'install fgate in a sample repo'`".
**Issue:** You can't `/fgate:prompt` until `/fgate:init` has run there. The
prompt is also tautological (fgate installing itself).
**Fix:** "Run `/fgate:init` in a fresh sample repo, then `/fgate:prompt 'add a
README'` (or any concrete first feature) and let the loop drive end-to-end.
Repeat on Gemini CLI."

### 2.5 "Anthropic Agent Skills standard" mislabeled

**Where:** §6 ("Both Claude Code and Gemini CLI consume **Anthropic Agent
Skills**…"), §1 (3rd pillar mentions same).
**Issue:** The standard at `agentskills.io` is open and adopted by Claude Code,
Gemini CLI, Cursor, OpenCode (per `create-agent-skill` skill). Calling it
"Anthropic" is sticky-but-wrong, and weakens the cross-tool pitch.
**Fix:** Use "Agent Skills (open standard, agentskills.io)". Keeps the
pitch credible to non-Anthropic-aligned readers.

### 2.6 `init` reuse-from-source already half-deferred but listed inline

**Where:** §3 (`/fgate:init`) says "Reusing an external AGENTS.md from a path/URL
is v0.2", and §9 lists the same as an open question.
**Issue:** Redundant.
**Fix:** Drop from §3, keep only in §9.

---

## 3. Open design questions — genuine tradeoffs to decide before authoring

These are not bugs. They're design choices where the current PLAN takes a
position I'd push back on. Each lists the tradeoff so you can decide.

### 3.1 `disable-model-invocation` left OFF for ALL six gates — too aggressive

**Current PLAN (§3 note):** "the `disable-model-invocation` field is intentionally
NOT set… Claude can auto-invoke a gate when its description matches an informal
request."

**Risk:** Side-effect-y gates (`implement`, `review`, `improve`) being
model-invocable means Claude can fire them on an informal "let's add auth"
without you explicitly typing `/fgate:implement 1`. Loses the branch-per-task
discipline; pollutes the trace; possibly merges code you didn't sanction.

**Counter-argument** (your case): minimum-attention loops, you want auto-fire.

**Recommendation — split decision:**
- Auto-invocable: `init`, `prompt`, `plan` (low-blast-radius, all reversible).
- `disable-model-invocation: true`: `implement`, `review`, `improve`
  (file/branch/AGENTS.md mutation; user must explicitly trigger).

Rationale: this is the same split superpowers and gstack converged on after
real-world use. You can change later via `/fgate:improve` if dogfooding shows
it's too cautious.

### 3.2 `/fgate:init` generating AGENTS.md from scratch is a hidden coding task

**Current PLAN (§3):** init "Generate[s] `AGENTS.md` from scratch by inspecting
the repo (≤ 30 bullets, ~100 chars each, focused on collaboration in this
repo)."

**Risk:** AGENTS.md generation is itself a non-trivial agentic task. It deserves
the prompt → plan → implement → review loop, not a one-shot inside init.
First-run AGENTS.md will be either bloated or empty boilerplate.

**Recommendation:** Make `/fgate:init` **structural-only**: write the skeleton
(`.agents/gates/`, `.agents/docs/`, `CLAUDE.md`, `GEMINI.md`, an empty
templated `AGENTS.md` with the bullet-format header). Then **suggest as the
first task**: `/fgate:prompt "populate AGENTS.md from the current repo"`.

This eats your own dogfood: the very first action a fgate user takes is the
fgate loop. Best possible smoke test.

### 3.3 `human/` vs `agent/` audience naming

**Current PLAN:** every gate writes a `human/<gate>.md` (terse) and
`agent/<gate>.md` (full). Two different audiences, two different attention
budgets.

**Concern:** when a future you reads `human/plan.md` six months later, will you
remember which audience that file targets? The names describe the *reader*, not
the *purpose*. Alternatives: `tldr/` + `detail/`, `brief/` + `full/`,
`summary/` + `spec/`.

**Recommendation:** keep `human/` and `agent/` — the audience IS the contract,
and the IDEA.md draft uses these names. But add to §7 a one-line definition:
"`human/<gate>.md` is the file a human can skim in 30 seconds. `agent/<gate>.md`
is what an agent (or future-you) needs to reproduce decisions."

### 3.4 AGENTS.md eviction policy when 30-bullet cap is hit

**Current PLAN:** AGENTS.md ≤ 30 bullets, CI-enforced via
`scripts/check-agents-bullets.sh`.

**Gap:** what happens on the 31st bullet from `/fgate:improve`? CI fails, the
improve gate has to choose: drop a stale bullet, merge two, or refuse. Without
guidance, the agent will either fail loud (good) or stochastically delete a
useful bullet (bad).

**Recommendation:** Add to §7: "`/fgate:improve` when AGENTS.md is at cap MUST
identify a bullet to evict in the same diff, with `# Replaces:` rationale in the
commit message." This makes the budget enforce *prioritization*, which is the
whole point of caps.

### 3.5 "In-place" mode of `/fgate:improve` mutates the task branch

**Current PLAN (§3):** improve's "in place" mode edits AGENTS.md on the current
task branch directly.

**Subtle issue:** changes don't propagate to other branches until the task is
merged to main. If you're juggling 3 task branches and improve runs on
branch A, branches B and C don't see the new bullet until A is merged. For
"alignment via self-improvement" this is a long lag.

**Recommendation:** explicitly call this out in §3 — "In-place mode bakes the
improvement into the task branch's merge. Other in-flight branches see it only
after merging main back into them. Use branch/worktree mode if you want the
improvement to land on main independently."

### 3.6 `human/` and `agent/` files: edit vs append-only?

**Current PLAN:** "Both committed; effectively read-only after write (the next
gate writes new files, not edits)."

**Edge case:** `human/trace.md` and `agent/trace.md` are continuously appended
during `/fgate:implement`. So they're not write-once. Worth clarifying:
**non-trace files are write-once; trace files are append-only during their
gate, then sealed.**

### 3.7 Six skills: too many or right size?

**Counter-thought:** could `improve` be a flag on `review` instead of its own
skill? `/fgate:review --improve` instead of `/fgate:improve`?

**Why I'd keep them separate:** improve is the only command that mutates the
meta-process. Conflating it with review erodes the §1 third-pillar guarantee
("`/fimprove` is the only command that mutates the meta-process"). Keep
separate. Six is right.

---

## 4. `.agents/docs/` — concrete proposal

Your new ask: "I want an `.agents/docs/` to store the agent docs during its
research." Here's how to integrate it without bloating the design.

### 4.1 Purpose

Cross-task knowledge the agent uncovers and wants to reuse. Examples:
- `auth-flow.md` — how the repo's auth currently works (referenced by every
  task touching auth).
- `external/stripe-api.md` — Stripe API quirks discovered during a task.
- `decisions/2026-04-database-choice.md` — ADR-style record, agent-authored.

This is distinct from `.agents/gates/<id>/agent/` which is *task-scoped* and
sealed once that task ends.

### 4.2 Recommended layout

```
.agents/
  docs/                      # cross-task knowledge base, agent-curated
    <topic>.md               # e.g. auth-flow.md, build-system.md
    external/<topic>.md      # third-party docs the agent distilled
    decisions/<YYYY-MM-DD>-<slug>.md   # ADR-style decisions
  gates/<id>/
    human/{prompt,plan,trace,result,improve}.md
    agent/{prompt,plan,trace,result,improve}.md
```

### 4.3 Who writes what, and when

- **`/fgate:plan`** is the primary writer. When it investigates the codebase
  and surfaces a reusable insight ("auth lives in `src/auth/middleware.ts` and
  uses JWT"), it MAY write `.agents/docs/auth-flow.md` if no such doc exists,
  or update it if outdated. This is a side-effect of planning, not a deliverable.
- **`/fgate:implement`** MAY append to `.agents/docs/` when it discovers
  something the plan missed (e.g. a Stripe API gotcha). It MUST NOT create new
  topics willy-nilly — same constraints as AGENTS.md (focused, evictable).
- **`/fgate:improve`** MAY consolidate, dedupe, or evict stale `.agents/docs/`
  entries. Same diff-discipline as AGENTS.md mutations: small, reviewable.

### 4.4 Constraints (mirror AGENTS.md philosophy)

- **One topic per file.** Filenames are the index.
- **≤ 200 lines per file.** Anything longer splits into siblings.
- **Front-matter optional but recommended:** `--- last-updated: 2026-04-28
  ---` so staleness is visible.
- **CI check:** `scripts/check-docs-size.sh` enforces the 200-line cap.
  Phase 3.
- **No CI cap on file count** — the topic taxonomy is more important than the
  bullet count of AGENTS.md.

### 4.5 What NOT to put in `.agents/docs/`

- Anything derivable from `git log`, `README.md`, or the code itself. No
  "module-X.md" that just paraphrases module X's source.
- Per-task scratch (goes under `.agents/gates/<id>/agent/`).
- Personal notes (those go in `~/.claude/projects/<project>/memory/` via
  Claude Code's auto-memory).

### 4.6 Trade-off acknowledged

This adds a third state surface (alongside AGENTS.md and `gates/`). Risk:
sprawl if `/fgate:plan` writes a doc per task. Mitigation: file the constraint
above into the `plan` SKILL.md body (≤ 200 words still holds), and make
`/fgate:improve`'s curator role explicit.

---

## 5. Updated state-resolver (consequence of §2.2)

If §2.2 is adopted (`result.md` instead of `review.md`), §5 becomes:

- `prompt.md` exists, no `plan.md` → ready for `/fgate:plan`.
- `plan.md` exists, no `result.md` → ready for `/fgate:implement`.
- `result.md` exists → ready for `/fgate:review`.
- `improve.md` exists → improvement landed; gate cycle complete.

(The trace.md presence doesn't gate anything; it's purely a log.)

---

## 6. Recommended PLAN.md edits (summary, in priority order)

1. **Rename `review.md` → `result.md`** in §3, §4, §5 (the §2.2 fix).
2. **`disable-model-invocation: true`** for `implement`, `review`, `improve`
   (the §3.1 split). Update §3 note accordingly.
3. **Make `/fgate:init` structural-only**; suggest "populate AGENTS.md" as the
   first user task (§3.2).
4. **Add `.agents/docs/` to §4 folder structure**; drop "`.agents/` is reserved
   for gates/" comment (§2.1, §4 above).
5. **Resolve "exactly one next command" vs review branching** — pick option 1
   from §2.3.
6. **Fix Phase 4 dogfood prompt** to start from init, not from prompt (§2.4).
7. **Re-label "Anthropic Agent Skills" → "Agent Skills (agentskills.io)"**
   throughout (§2.5).
8. **Add AGENTS.md eviction discipline** to §7 (§3.4).
9. **Clarify trace.md is the only append-only artifact** (§3.6).
10. **Add `scripts/check-docs-size.sh`** to Phase 3 (§4.4 above).

None of these change the architecture. They're sharpening, not redesigning.

---

## 7. What did NOT need fixing

For the record — these elements I considered challenging but decided are right
as written:

- **6 skills (not 5).** Adding `init` was correct; without it, first-run UX is
  "manually create AGENTS.md before fgate works."
- **Skill body ≤ 200 words.** Aggressive but enforceable. Holds the line on
  PLAN.md's pillar #2.
- **Branch-per-task.** Concurrent tasks need concurrent branches. Worktrees
  remain a v0.2 accelerator, correctly.
- **Plugin + marketplace in the same repo with `"source": "./"`** —
  unconventional vs the docs walkthrough but proven by superpowers.
- **`CLAUDE.md` and `GEMINI.md` as one-line `@AGENTS.md` imports** — both
  tools natively expand. Verified.
- **Pin `version` in both manifests from day one** — prevents the "every
  commit is a forced upgrade" trap; documented behavior.
- **No Python, minimal bash.** Right call for a plugin-first toolkit.
- **No telemetry, no LLM-classifier safety layer.** Correctly scoped out.

---

**Ready to implement after applying §6 edits.** The architecture is sound; the
edits are surface-level. No re-research needed — Phase 0 docs cover everything
the implementation will reference.

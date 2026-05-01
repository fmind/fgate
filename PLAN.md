# PLAN — apply benchmark findings to fgate skills

Driver: the v0/v1/v2 prompt benchmark under `benchmarks/`. Full results in `benchmarks/RESULTS.md`. Both v0 and v1 reach 11/11 on the harder mdtoc task, but v1's implement gate is **3× faster** (176 s vs 530 s), end-state-resumable, and machine-routable. v2 hardens edge cases. This PLAN ports the v2 wins back to `skills/fgate-*/SKILL.md`.

## Sequence (two separate coding sessions, manually triggered by the user)

1. **Session A — this PLAN.md.** A coding agent executes steps 1–10 below, in order, committing directly to `main` (the project has not been released; no branches, no version tags, no PRs are required). When step 10 is done, this session ends. The agent does **not** start BENCHMARK-2.
2. **User review.** The user inspects the diff, runs the regression check from step 8 by hand, and decides whether the port is good. If yes, proceeds to session B. If no, opens a follow-up PLAN.
3. **Session B — `BENCHMARK-2.md`.** A _different_, _clean_ coding session is started by the user. That agent reads `BENCHMARK-2.md` from scratch, confirms §0 Prerequisites against the live repo, and runs the benchmark.

The two sessions must not be merged. The PLAN.md agent's job ends at step 10; it must not advance into BENCHMARK-2 even when the work would be straightforward. BENCHMARK-2 is a long-running, statistically-grounded benchmark and gets a fresh context window for it.

The four wins to port:

1. **`verify:` + `passes: false` on every acceptance criterion.**
2. **Implement is a loop with a budget and a `<gate-status>` tag.**
3. **Prompt makes assumptions explicit instead of asking questions.**
4. **Init / Review / Improve emit their own `<gate-status>` tags.**

## Step 1 — fgate-prompt: drop Q&A, add machine-readable checklist

`skills/fgate-prompt/SKILL.md`

- Delete §2 ("Challenge the prompt" — the up-to-3-questions block, lines 16–34).
- Replace with a "Ground in context" step: read `AGENTS.md`, `README.md`, the user ask, any spec file the ask points at; for every gap, pick a defensible default and log it in §Assumptions of both artifacts.
- Keep `[NEEDS CLARIFICATION: ...]` for the rare irreversible-and-no-defensible-default case (data migration, public-API break, security posture).
- Change the acceptance-checklist shape in `agent/prompt.md` from:

      - [ ] <criterion>

  to:

      - [ ] criterion: <text>
        verify: `<exact shell command>`
        passes: false

- Add an `## Assumptions` section to both `human/prompt.md` and `agent/prompt.md` so the human can override defaults.
- Source: `benchmarks/v2/skills/fgate-prompt/SKILL.md`.

## Step 2 — fgate-implement: explicit loop, budget, completion tag

`skills/fgate-implement/SKILL.md`

- Add §"Read the spec" with a resume rule: _if `agent/trace.md` already has entries, this is a resume — pick up at the first `passes: false`._
- Replace the prose execution section with an explicit pseudocode loop: pick highest-priority `passes: false`, drive plan changes, run `verify:`, flip the flag on success, log to trace, repeat.
- Add hard caps: 90 tool calls (rough), 5 consecutive non-advancing turns.
- Replace the prose ending with exactly one machine-parseable tag:
  - `<gate-status>COMPLETE</gate-status>`
  - `<gate-status>BLOCKED: <reason></gate-status>`
  - `<gate-status>DECIDE: <question></gate-status>`
  - `<gate-status>BUDGET: <pass>/<total></gate-status>`
- Source: `benchmarks/v2/skills/fgate-implement/SKILL.md`.

## Step 3 — fgate-plan: investigate, don't escalate

`skills/fgate-plan/SKILL.md`

- Add a default-behaviour line in §"Read": _resolve `[NEEDS CLARIFICATION:` markers by investigation; only escalate if the decision is irreversible AND no defensible default exists._
- In §"Sharpen", confirm every criterion's `verify:` runs from the workspace root — fix it if it doesn't (the prompt skill may produce a verifier that doesn't run from cwd).
- Allow the plan to _append_ a missing criterion to `agent/prompt.md` §Acceptance checklist with `passes: false`, and list it in `human/plan.md` §New criteria so the human spots the addition. Don't silently add criteria.
- Source: `benchmarks/v2/skills/fgate-plan/SKILL.md`.

## Step 4 — fgate-review: re-run verifiers, emit tag

`skills/fgate-review/SKILL.md`

- Strengthen §"Re-run the verifiers" so it is the canonical pass/fail authority (treats `agent/result.md` as a hint, not the truth).
- Replace the prose ending with one tag:
  - `<gate-status>SHIP: <pass>/<total></gate-status>`
  - `<gate-status>RESUME: <pass>/<total> failing=<criterion></gate-status>`
  - `<gate-status>IMPROVE: <one-line lesson></gate-status>`
- Source: `benchmarks/v2/skills/fgate-review/SKILL.md`.

## Step 5 — fgate-init: stop asking on dirty repo

`skills/fgate-init/SKILL.md`

- §"Pre-flight" currently asks the user when `git status --porcelain` is non-empty. Change to: list dirty paths in `human/init.md` §Pre-existing changes and proceed. fgate-init is additive-only (creates `.agents/`, writes `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` only when missing) so dirty state is safe.
- The only hard refusal stays: if `.agents/` is gitignored, emit `<gate-status>BLOCKED: .agents/ is gitignored</gate-status>` and stop.
- Add an end-of-skill tag (`<gate-status>COMPLETE</gate-status>` or `<gate-status>BLOCKED: ...</gate-status>`) before the `Next:` line.
- Source: `benchmarks/v2/skills/fgate-init/SKILL.md`.

## Step 6 — fgate-improve: emit tag

`skills/fgate-improve/SKILL.md`

- Add an end-of-skill tag:
  - `<gate-status>IMPROVE: <files touched></gate-status>` — diff staged.
  - `<gate-status>SKIP: <reason></gate-status>` — trace yielded no reusable rule.
- Source: `benchmarks/v2/skills/fgate-improve/SKILL.md`.

## Step 7 — wiring docs

- `AGENTS.md` §Skill authoring: add a bullet — "Every gate ends with exactly one `<gate-status>...</gate-status>` tag on its own line. Hosts grep for it to chain gates."
- `AGENTS.md` §Workflow: add a bullet — "Acceptance criteria carry a runnable `verify:` shell command and a `passes: false` flag. Implement flips the flag; review re-runs the verifier."
- `README.md` §Six gates: mention `<gate-status>` tags as the chaining contract and `verify:`/`passes:` as the checklist contract.

## Step 8 — verify the port

After steps 1–7 land:

1. Re-run `bash benchmarks/_lib/run-version.sh main run1 task-b` (after temporarily linking `benchmarks/main/skills` → `skills/`). Target: ≤ 200 s implement, 11/11 verify.
2. Check that every gate's stdout contains a `<gate-status>` tag (`grep -oE '<gate-status>[^<]*</gate-status>' .bench/*.stdout`).
3. Resume test — kill implement halfway, re-invoke `/fgate:implement <id>`, confirm it picks up at the first `passes: false` row.

## Step 9 — preserve benchmark scaffolding as a regression suite

Once steps 1–8 ship, **keep `benchmarks/` in-tree** — BENCHMARK-2 reuses its harness (`_lib/run-gate.sh`, `_lib/run-version.sh`, `_lib/verify*.sh`) and its three frozen variant snapshots (`v0/`, `v1/`, `v2/`) as historical baselines. Specifically:

- `benchmarks/v0/skills/` is the **frozen pre-port baseline**. BENCHMARK-2 references it as reference variant `R1`. Do not delete or modify after the port lands.
- `benchmarks/v1/skills/` and `benchmarks/v2/skills/` are referenced as `R2` and `R3`. Same rule: frozen.
- `benchmarks/sandbox/` can be removed if it contains nothing valuable (it was a scratch dir during BENCHMARK-1).

Splitting `benchmarks/` into a separate `flever-bench` repo is deferred until BENCHMARK-2 finishes — moving it now invalidates the variant snapshots that BENCHMARK-2 anchors to.

## Step 10 — rename `fgate` → `flever`

The lever metaphor (small input, large output) describes the project's promise more accurately than "gate" (which only describes one mechanism). Rename everything except the local working directory, which stays `~/fgate` for now to avoid breaking active sessions.

**Terminology**:

- `fgate` → `flever` (project + skill-prefix + plugin name).
- "gates" → "levers" (the six steps that move the workflow forward).
- `.agents/gates/` → `.agents/levers/` (workspace state directory).

**Rename map** (every occurrence):

| Path                                                                                                    | Change                                                                                                                                                                                                                                                                                                  |
| ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `skills/fgate-*/SKILL.md`                                                                               | rename dirs to `skills/flever-*/`; `name:` frontmatter to `flever-<gate>`; body text "fgate" → "flever" and "gate"/"gates" → "lever"/"levers" where the meaning is the workflow step (NOT in `<gate-status>` tag — keep that name as-is for backward-compat through one release; deprecate in the next) |
| `commands/fgate/*.toml`                                                                                 | rename dir to `commands/flever/`; update any `description`/`prompt` body referencing the old name                                                                                                                                                                                                       |
| `.agents/gates/`                                                                                        | rename to `.agents/levers/` in all docs and skill bodies; provide a one-shot migration note in `fgate-init` (`mv .agents/gates .agents/levers` if present)                                                                                                                                              |
| `gemini-extension.json`, `plugin.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | rename keys `name`, `id`, `slug` from `fgate` → `flever`; bump version                                                                                                                                                                                                                                  |
| `package.json` / `package-lock.json`                                                                    | rename `name`                                                                                                                                                                                                                                                                                           |
| `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `BENCHMARK-2.md`                                           | replace `fgate` with `flever`, `gate` (workflow-step sense) with `lever`; keep historical references in changelog                                                                                                                                                                                       |
| `benchmarks/v2/skills/...`                                                                              | leave for traceability; add a one-line note in `benchmarks/RESULTS.md` that v2 was the seed for the renamed `flever-*` skills                                                                                                                                                                           |

**Tag-name decision** — `<gate-status>` stays. Renaming the tag would break every host integration (CI greps, hooks). Document it as "the lever-status tag, named `<gate-status>` for historical reasons" in `AGENTS.md`. Ship a parallel `<lever-status>` alias in the next minor release; deprecate `<gate-status>` one release after that with a clear migration window.

**GitHub repo**:

- Rename `github.com/<owner>/fgate` → `github.com/<owner>/flever` via the GitHub UI (preserves redirects). Update remote in any clones with `git remote set-url origin git@github.com:<owner>/flever.git`.
- Update repository description, homepage URL, topics.
- Update README badges and links.
- No "renamed" notice / changelog entry / version bump is needed — the project has not been released.

**Local working directory**: stays `~/fgate` per the user's instruction. The project name and metadata change; the path does not. Add a `# NOTE` in the top-level README explaining the local-path/project-name divergence is intentional.

**Order**: do step 10 _after_ steps 1–9 are committed on `main`. Renaming during a port produces a noisy diff and obscures intent. Step 10 is the last thing this PLAN does.

## Step 11 — end the session

When step 10 is committed on `main`:

1. Run the regression check from step 8 one more time on the renamed surface; commit any fixes.
2. Stop. The PLAN.md agent's job is done. Do **not** open or read `BENCHMARK-2.md` from this session.
3. Print a short summary to the user: "PLAN.md done. Step 11 complete. Awaiting your review before BENCHMARK-2."

The user reviews the diff and, if satisfied, starts a new clean session for `BENCHMARK-2.md`. This PLAN does not chain into BENCHMARK-2.

## Out of scope for this PLAN

- Multi-task chaining, parallel gate execution, sub-agent spawning. The current single-thread loop is fast enough at 176 s; orchestration is a bigger design and not load-bearing for the benchmark wins.
- Replacing `verify:` with a richer DSL (timeouts, expected-output matchers). Plain shell exit codes are enough for the cases observed in the benchmark.
- Auto-pushing the `<gate-status>` tag into a CI job. The skill must never mutate git state per `AGENTS.md` §Workflow.

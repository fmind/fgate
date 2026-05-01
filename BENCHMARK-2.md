# BENCHMARK-2 — wider, longer, statistically grounded

The first round (`benchmarks/RESULTS.md`) compared 3 hand-rolled versions on 2 tasks with 1–2 runs per cell, judged mostly on a single binary pass/fail and qualitative artifact reading. Both old and new skills hit 11/11 on the harder task, so the discriminator collapsed to one number — implement-gate wall time. That is *signal*, not *evidence*: with one run per cell, a 3× gap could be noise.

BENCHMARK-2 is engineered to stop being satisfied with that. Goal: pick the lever-skill design that maximizes **leverage** = (agent-autonomous-progress) ÷ (human-intervention-required), with statistical confidence and on tasks the previous round was too narrow to stress.

## 0. Prerequisites — read this first, in a fresh coding session

**This benchmark runs in its own coding session, started manually by the user after `PLAN.md` is committed on `main` and reviewed.** The agent that wrote `PLAN.md` does not start BENCHMARK-2; the agent that runs BENCHMARK-2 does not edit `PLAN.md`. They share the repo on `main` and nothing else.

Before spinning up any harness, audit the live repo against the post-PLAN state. Run each check; if any fails, stop and tell the user — do not paper over a half-renamed surface, every cell would fail for the wrong reason.

- [ ] `skills/flever-*/SKILL.md` exists for all six levers (init, prompt, plan, implement, review, improve). The old `skills/fgate-*/` directories are gone.
- [ ] `commands/flever/*.toml` exists; `commands/fgate/` is gone.
- [ ] `.agents/levers/` is the workspace state directory (not `.agents/gates/`); `flever-init` performs the one-shot migration `mv .agents/gates .agents/levers` if encountered.
- [ ] Every lever's `SKILL.md` ends with one `<gate-status>...</gate-status>` tag on its own line. (Tag name kept for compat per PLAN.md §10; alias `<lever-status>` may be present.)
- [ ] Every acceptance-checklist row produced by `flever-prompt` carries a runnable `verify:` shell command and a `passes: false` flag.
- [ ] `benchmarks/v0/skills/`, `benchmarks/v1/skills/`, `benchmarks/v2/skills/` directories are present and untouched since the port — BENCHMARK-2 references them as frozen historical baselines.
- [ ] GitHub repo renamed to `<owner>/flever`; local working dir stays `~/fgate` (intentional per PLAN.md).

The repo is single-branch (`main`) and unreleased — there is no version tag, no release branch, no changelog gate to wait on. The audit above is the only gate.

## 1. Concrete objectives (must hit all)

| # | Objective                                                                                         | Pass condition                                                                                                                      |
| - | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 1 | Reach SOTA on a public, agreed-upon harness                                                       | Beat published baselines on SWE-bench-Verified-Mini OR MLE-bench Lite by ≥ 5 percentage points using the winning lever-skill set    |
| 2 | Discriminate variants with statistical confidence                                                 | Top-3 variants ranked with p < 0.05 on the primary metric over ≥ 5 runs each                                                        |
| 3 | Test long-running stability                                                                       | At least one project takes ≥ 30 min implement gate; winner completes ≥ 80 % of those runs without `BLOCKED`/`BUDGET` exits           |
| 4 | Test resume safety empirically                                                                    | Inject SIGTERM at 50 % of estimated implement runtime; on second invocation winner finishes ≥ 90 % of cells with same final pass-set |
| 5 | Test cross-agent portability                                                                      | Same skill bodies hit ≥ 90 % of pass-rate on Claude Code AND Gemini CLI; gap ≤ 10 points                                            |
| 6 | Quantify human-touch reduction                                                                    | Winner needs zero clarifying questions on ≥ 95 % of cells; baseline can be > 0                                                       |

Anything below all six is a partial result and the benchmark recommends iteration, not adoption.

## 2. Primary metric — leverage score

Per-cell (one run, one variant, one project, one agent):

```
leverage = (passed_criteria × autonomy_bonus) / (wall_minutes + 5 × human_touches + 0.1 × tool_calls)
```

Where:

- `passed_criteria` — count of acceptance-checklist `verify:` rows with exit 0 on the *final* run by the project's own verifier (`verify-*.sh`).
- `autonomy_bonus` — `1.0` if zero `[NEEDS CLARIFICATION:` markers AND zero question-mark sentences in the gate stdouts AND every gate ended with a `<gate-status>` tag; else `0.5`.
- `wall_minutes` — `prompt + plan + implement + review` summed.
- `human_touches` — count of times a hypothetical human would have to read+respond (questions in stdout, `[NEEDS CLARIFICATION:` markers, `BLOCKED`/`DECIDE` tags).
- `tool_calls` — total tool invocations across gates (parsed from agent telemetry where available, else estimated from trace.md entries).

Higher is better. The denominator is the cost of doing the task; the numerator is the value delivered. Five-minute pause for a human question costs as much as five minutes of agent runtime — that's the lever metaphor in numbers.

## 3. Secondary metrics (collected per cell, never tie-broken alone)

- Variance: stddev of leverage across the N runs of a cell.
- Recovery: leverage on the *resumed* run after SIGTERM injection, normalized by the no-interrupt run on the same cell.
- Tag coverage: fraction of gates that emitted exactly one `<gate-status>` tag.
- Artifact-quality rubric (5 axes × 3 levels each, scored by an LLM-as-judge using a fixed rubric):
  - `human/*.md` skim-friendly (≤ 30 lines, no jargon).
  - `agent/*.md` reproducible (every command quoted, every output captured).
  - Coverage table present and consistent with the checklist.
  - Trace.md entries are append-only and include `Decision:` lines.
  - No prose-only completion on any gate (must end with structured tag).

The rubric is automated by feeding each artifact + the rubric to a third-party model with `temperature=0`; agreement between two independent judges must be ≥ 0.7 Cohen's κ on a 30-cell calibration set or the rubric is rejected as unreliable.

## 4. Variant matrix (target 24 variants, organized by axis)

Each variant is a complete `skills/flever-*/SKILL.md` set. They are generated by combining axis values so that each axis is well-sampled. The seed is v2 from BENCHMARK-1.

| Axis (independent variable)                         | Levels                                                                                  | Why test                                                                              |
| --------------------------------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **A. Skill body length**                            | A1 = ≤ 60 lines · A2 = ≈ 100 lines · A3 = ≈ 160 lines · A4 = ≈ 240 lines                | Long bodies risk dilution; short ones risk under-specification                        |
| **B. Verifier shape**                               | B1 = shell exit-only · B2 = shell + expected stdout · B3 = TAP/junit-XML structured     | Does richer verifier output let implement debug failures faster?                      |
| **C. Checklist size**                               | C1 = 4–6 criteria · C2 = 8–10 · C3 = 12–16                                              | Bigger checklists give more signal but raise false-fail risk                          |
| **D. Implement loop discipline**                    | D1 = strict (one criterion at a time) · D2 = batched (parallel `[P]`) · D3 = freestyle   | Ordering matters; v2 was D1                                                           |
| **E. Plan→implement coupling**                      | E1 = full handoff (read-only plan) · E2 = plan can re-edit during implement · E3 = no plan, prompt → implement directly | Whether the plan gate adds value or is overhead                                       |
| **F. Trace verbosity**                              | F1 = passes-only · F2 = + decisions · F3 = + commands+output · F4 = + alternatives      | Trade traceability against context bloat                                              |
| **G. Stop conditions**                              | G1 = 5-stall, 90-tool-call · G2 = 10-stall, 200-tool-call · G3 = no caps                | Caps protect against runaway; do they harm long tasks?                                |
| **H. Q&A discipline in prompt**                    | H1 = forbid · H2 = allow up to 1 · H3 = allow up to 3                                    | The 0/3 question gap was the biggest win in BENCHMARK-1; confirm with bigger N        |
| **I. Tag scheme**                                   | I1 = single-line `<gate-status>` · I2 = YAML block · I3 = none                          | Confirm the tag actually pulls weight                                                 |

Total combinations = 4 × 3 × 3 × 3 × 3 × 4 × 3 × 3 × 3 = ~70 k. Sample 24 via Plackett-Burman / fractional-factorial design so each axis × level appears ≥ 3 times. Add 4 fixed reference variants:

- **R1** = `benchmarks/v0/skills/` — frozen pre-port baseline (the BENCHMARK-1 v0 snapshot, *not* the post-port `skills/flever-*/`). Lives on disk after PLAN.md so it can be referenced verbatim.
- **R2** = `benchmarks/v1/skills/` — BENCHMARK-1 winner (mid-iteration snapshot).
- **R3** = `benchmarks/v2/skills/` — the seed BENCHMARK-1 left for the port; identical in shape to the production `skills/flever-*/` after PLAN.md plus the rename.
- **R4** = SpecKit-style external baseline (see §6) for cross-system anchoring.

R1 / R2 / R3 names use the historical `fgate-*` skill names (frozen). The 24 generated variants use the new `flever-*` names. The harness (`benchmarks2/_lib/run-cell.sh`) accepts both prefixes so reference variants run unchanged.

24 sampled + 4 reference = **28 variants**.

## 5. Project portfolio (3 projects, picked for orthogonal stress)

Each project ships with: a self-contained TASK.md, a deterministic `verify-<project>.sh` that exits 0 on full pass, ≥ 8 mechanical criteria, and a known-good reference implementation hidden behind `.solution/` so we can compute pass-rate ground truth.

### P1 — `mdtoc` (Python CLI, ≈ 15 min budget)

Already exists at `benchmarks/task-b/`. Acts as the smoke test — every variant must hit ≥ 9/11 here or it is dropped from the bracket before P2/P3 (saves compute).

### P2 — `linkcheck` (Python + HTTP, ≈ 30–45 min budget)

A Python CLI that walks a markdown tree, fetches every link concurrently, respects `robots.txt` and rate limits, and exits 1 on broken links. Tests:

- Async / concurrency primitives (`asyncio`, `httpx`).
- Mocked HTTP test harness (no real network — `respx` fixtures).
- File system traversal with ignore patterns.
- 14 acceptance criteria including timeout, redirect, fragment-only, mailto skipping, anchor-existence checks.
- Long enough to satisfy objective 3 (≥ 30 min).

### P3 — `bug-fix-in-an-existing-app` (Flask + SQLite, ≈ 30 min budget)

Provided: a small, working Flask app with one user-visible bug (e.g., cookies cleared on logout but session row not deleted; or off-by-one in pagination). Provided: 4 *failing* tests pinpointing the bug + 12 *passing* tests that must stay passing. Tests:

- Comprehension of pre-existing code, not greenfield generation.
- Discipline against scope creep (don't refactor what isn't broken).
- Resume safety — interrupt mid-fix, see if state recovers.
- Cross-file edits (route + model + template).

The three projects together cover **{greenfield · concurrency · brownfield-fix}**, which approximates the workload distribution in `SWE-bench-Verified-Mini`.

## 6. External anchors — pin our scale

Run two independent published benchmarks unmodified, with R1 and the BENCHMARK-2 winner, on the same two agents (Claude Code + Gemini CLI):

- **SWE-bench-Verified-Mini** (50 issues, real Python repos). Run via the upstream harness; report resolved-instance %.
- **MLE-bench Lite** (10 ML coding tasks). Reports passed-task % and submission scores.

This is the only step that lets us claim "SOTA". Without it, we can only claim "best of our internal variants".

## 7. Methodology

### Cell schedule

| Phase                  | Variants            | Projects              | Agents            | Runs/cell | Cells | Avg minutes/cell | Hours |
| ---------------------- | ------------------- | --------------------- | ----------------- | --------- | ----- | ---------------- | ----- |
| Round 1 — smoke        | all 28              | P1                    | Gemini            | 1         | 28    | 7                | 3.3   |
| Round 2 — round of 16  | top 16 by leverage  | P1, P2                | Gemini            | 3         | 32 × 3 = 96 | 18         | 28.8  |
| Round 3 — quarterfinal | top 8               | P1, P2, P3            | Gemini + Claude   | 5         | 8×3×2×5 = 240 | 22       | 88.0  |
| Round 4 — final        | top 3               | P1, P2, P3 + SIGTERM  | Gemini + Claude   | 5         | 3×3×2×5 = 90 (+ resumes) | 30 | 45.0  |
| External anchor        | R1, winner          | SWE-Mini, MLE-Lite    | Gemini + Claude   | 1         | 4 × 60 ≈ 240 | 8         | 32.0  |

Total ≈ 200 hours of agent time. At ~$0.05/min (rough mixed Gemini + Claude), ≈ $600. Spread across 5 days of mostly-unattended runs = realistic.

### Run isolation

- Each cell runs in its own ephemeral git worktree at `benchmarks2/runs/<round>/<variant>/<project>/<agent>/<run>/`.
- Verifier runs in a fresh `python -m venv` per cell — no leakage.
- Agent `--approval-mode yolo` (Gemini) / `--permission-mode bypassPermissions` (Claude). Workspace trust is pre-granted in setup.
- All stdout/stderr/timing/tool-count captured to `.bench/`. Tool count is parsed from agent JSON telemetry where available; otherwise it is the number of `## ` headers in `agent/trace.md` (proxy).

### Statistical analysis

- Welch's t-test pairwise on leverage between top variants per project.
- Multiple-comparison correction: Holm-Bonferroni at α = 0.05.
- Variance reported as IQR not stddev (leverage is non-Gaussian, has long tails on `BLOCKED`/`BUDGET` exits).
- Bayesian alternative: BEST (Bayesian estimation supersedes the t-test) reported alongside for the final 3.

### Variant generation

24 sampled variants are produced by a small generator script (`benchmarks2/_lib/gen-variant.py`) that takes the axis-level mapping and emits a complete `skills/flever-*/SKILL.md` set by stitching parameterised templates. This keeps variants comparable (no accidental wording drift) and reproducible.

The 4 reference variants are hand-curated and committed verbatim under `benchmarks2/variants/{R1,R2,R3,R4}/`.

## 8. Resume safety test (objective 4)

For each Round-4 cell, run twice:

- **A**: implement gate runs to completion with no interruption.
- **B**: implement gate gets `kill -TERM <pid>` at `0.5 × estimate(P)` minutes; immediately re-invoked with the same `<id>` and no operator hints.

Compare:

- Final pass-set match: `passes_A == passes_B`.
- Wall-time overhead: `(time_B − time_A) / time_A` — ≤ 30 % is good.
- Tool-call overhead: same ratio.
- Trace continuity: B's `agent/trace.md` must contain A's pre-interrupt entries unchanged.

A variant that scores ≥ 90 % match across all Round-4 cells passes objective 4.

## 9. Cross-agent portability test (objective 5)

Round 3 is the cross-agent round. Same variant, same project, two agents (Gemini CLI 0.x, Claude Code 1.x) on five runs each. Compute portability gap:

```
gap = | mean_leverage(claude) − mean_leverage(gemini) | / max(mean_leverage(...))
```

Acceptance: gap ≤ 0.10 for the winner. Skill bodies must avoid agent-specific syntax (`!{shell}`, `${CLAUDE_SKILL_DIR}`, etc.) — that is already an `AGENTS.md` rule. The benchmark enforces it empirically.

## 10. Deliverables

Land under `benchmarks2/`:

```
benchmarks2/
├── BENCHMARK-2.md            # this file (or symlink to root)
├── TLDR.md                   # 30-second human skim of the winner + numbers
├── RESULTS.md                # full evidence: per-cell tables, plots, sig tests
├── _lib/
│   ├── gen-variant.py        # parameterised skill-set generator
│   ├── run-cell.sh           # one (variant, project, agent, run) tuple
│   ├── run-round.sh          # tournament round runner
│   ├── verify-p1.sh          # mdtoc verifier (reuses task-b)
│   ├── verify-p2.sh          # linkcheck verifier
│   ├── verify-p3.sh          # bug-fix verifier
│   ├── leverage.py           # primary-metric calculator + statistical tests
│   └── judge.py              # rubric scorer (LLM-as-judge with κ check)
├── variants/                 # 28 SKILL.md sets, by id
│   ├── R1-baseline/
│   ├── R2-v1/
│   ├── R3-v2/
│   ├── R4-speckit/
│   ├── 01-A1B2C2D1.../
│   └── …
├── projects/
│   ├── p1-mdtoc/
│   ├── p2-linkcheck/
│   └── p3-flask-bugfix/
├── runs/<round>/<variant>/<project>/<agent>/<run>/
└── PLAN.md                   # follow-up plan once results land (port, deprecate, etc.)
```

The winning variant's `SKILL.md` set replaces `skills/flever-*/SKILL.md` directly; the diff is the deliverable.

## 11. Risks + mitigations

| Risk                                                                                                | Mitigation                                                                                                                            |
| --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Rate-limited mid-run by Gemini quota (happened in BENCHMARK-1)                                      | Spread runs over ≥ 24 h, exponential backoff on 429, fall back to Claude when Gemini throttles, cache prompt-context where possible    |
| Variants are too similar — no signal                                                                | Plackett-Burman design forces wide axis coverage; reject any pair of variants whose pairwise-diff is < 5 % of mean SKILL.md tokens     |
| Project P3 (Flask bug-fix) too easy — every variant solves it                                       | Pre-pilot: run all 28 once on P3; if pass-rate variance < 0.1, swap in a harder bug from a curated bank                                |
| Judge model bias inflates artifact-quality rubric                                                   | Two independent judges; require κ ≥ 0.7; report rubric only when calibration holds                                                    |
| Cost overrun                                                                                        | Pre-flight estimate at end of Round 1 (extrapolate to Round 4 hours and $); abort/replan if > 1.5× budget                              |
| BENCHMARK-2 itself takes > 1 week                                                                   | Round 1 is the cheap filter — drop bad variants aggressively; Round 4 with N=5 is the only expensive step                              |

## 12. Out of scope

- Multi-agent orchestration (sub-agent fanout, parallel gates). Handled in a future BENCHMARK-3 if and only if BENCHMARK-2 winner is single-thread-bound.
- Non-coding agents (research, write-only, etc.).
- Cost-optimised model picking (cheap first, expensive only on retry). Worth doing but not a benchmark question.

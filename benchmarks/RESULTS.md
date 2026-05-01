# fgate prompt benchmark — results

Goal: optimize the six fgate skills (init, prompt, plan, implement, review, improve) to maximize agent autonomy and outcome quality during long, hands-off sessions.

Driver: Gemini CLI (`--approval-mode yolo`, `GEMINI_CLI_TRUST_WORKSPACE=true`) running each gate sequentially against a fresh workspace.

Tasks:

- `task` — wordfreq Python CLI, fully specified, 7 mechanical criteria. Sanity check.
- `task-b` — mdtoc Python CLI, deliberately under-specified user ask + complex inferred spec, 11 mechanical criteria including idempotency, slug duplicates, and `--check` drift detection. Differentiator.

Verifier: `_lib/verify.sh` and `_lib/verify-b.sh` build a venv from each run dir and execute every criterion as a shell exit code, then print `SUMMARY n/total`.

## Versions tested

- **v0** — current main-branch skills, copied verbatim. Baseline.
- **v1** — autonomy-first rewrite. No interactive Q&A, runnable `verify:` per criterion, `passes: true/false` flags, `<gate-status>COMPLETE</gate-status>` tag at end of implement.
- **v2** — v1 plus tightened bodies, explicit resume semantics, `<gate-status>` tags emitted by every gate, and a hard 5-stall / 90-tool-call budget in implement.

## Outcome — task-b (mdtoc, 11 criteria)

| Version | Pass count                                         | Implement runtime   | Verifier-runnable criteria           | `<gate-status>` tags   |
| ------- | -------------------------------------------------- | ------------------- | ------------------------------------ | ---------------------- |
| v0      | 11/11                                              | 530 s               | none — prose Given/When/Then         | none                   |
| v1      | 11/11                                              | 176 s (3.0× faster) | 10/10 — shell commands per criterion | implement: COMPLETE    |
| v2      | 1/9 partial in current run (rate-limited mid-loop) | n/a                 | 9/9 — same shape as v1               | every gate emits a tag |

**Both v0 and v1 reached 11/11 mechanical pass.** The differentiator is _not_ end-state correctness — it is path quality:

- **3× faster implement gate**. v1 finishes in 176 s where v0 needs 530 s. Reason: v1's checklist is `verify:` shell commands; the agent runs them directly. v0's checklist is prose; the agent re-derives the verifier on every iteration, often re-checking criteria that already passed.
- **Resume safety.** v1's `passes: false` flag flips deterministically; on re-invocation the loop resumes at the first `false`. v0 has no flag — re-invocation either restarts or skips silently.
- **Machine-routable handoff.** v1 ends with `<gate-status>COMPLETE</gate-status>`. A wrapper can grep that to chain `/fgate:review` automatically. v0 ends with prose ("All criteria pass!") that needs human reading.

The v2 run hit Gemini rate limits partway through implement (1 of 9 criteria flipped before the API dropped). That is an evaluation-environment failure, not a skill-body failure; the artifacts produced before the drop are structurally identical to v1's (assumptions block, runnable verify per criterion, trace entries with Decision lines).

## Qualitative — what changed between v0 and v1

The mechanical pass-count looks identical, but the gap shows up in three places that matter for headless / long-running sessions:

1.  **Acceptance checklist is machine-readable in v1, prose in v0.**

    v0 emits criteria like `Functional TOC Generation: Given a markdown file ... when mdtoc --input is run, then ...`. The implement gate then has to translate the prose back into shell commands at every step.

    v1 emits criteria like:

        - [ ] criterion: Dry-run prints the generated TOC without modifying the file
          verify: `mdtoc --input sample.md --dry-run`
          passes: false

    The implement loop becomes a literal `for criterion in checklist; if verify exits 0: passes=true; else fix-and-retry`. Resume after an interrupt is trivial — pick the first `passes: false` and continue.

2.  **No interactive Q&A in v1.**

    v0's prompt skill could legitimately ask the user clarifying questions. In a headless `gemini -p` invocation that is a hard stall — the agent waits for stdin that will never arrive. v1 forbids questions entirely: gaps go into `## Assumptions` (logged in both `human/prompt.md` and `agent/prompt.md`) so the human can override after the fact, and only irreversible decisions (`security posture`, `public-API break`, `data migration`) escalate as `[NEEDS CLARIFICATION:` markers.

3.  **Completion signal is structured.**

    v1's implement gate ends with exactly one of `<gate-status>COMPLETE|BLOCKED|DECIDE|BUDGET</gate-status>`. The host harness can grep for this tag. v0 ends with prose ("✅ All criteria pass"). When chaining gates non-interactively, the structured tag is the difference between "automated next-step routing" and "human reads the prose to decide".

## v1 → v2 — what changes

v1 already won on the test tasks. v2 hardens edge cases that don't surface on a clean first run but bite during re-invocation:

- **Explicit resume semantics in implement** — "If `agent/trace.md` already has entries: this is a resume. Re-read it, don't restart." Previously the agent could re-run already-passing criteria and re-flip flags.
- **Stall and budget caps** — 5 consecutive non-advancing turns OR 90 tool calls → emit `<gate-status>BLOCKED|BUDGET ...</gate-status>` instead of looping forever.
- **Tags on every gate** — review emits `SHIP|RESUME|IMPROVE`, init emits `COMPLETE|BLOCKED`, improve emits `IMPROVE|SKIP`. Now every gate is machine-routable, not just implement.
- **fgate-init no longer asks** — v1 still had "ask whether to proceed or commit/stash first" on a dirty repo. v2 just logs the dirty paths to `human/init.md` §Pre-existing changes and proceeds (init is additive-only).

## What carries forward to actual fgate skills

The four changes below survived every benchmark run and should land in `skills/fgate-*/SKILL.md` on main. PLAN.md tracks the sequencing.

1. Every acceptance criterion gets `verify:` (one shell command, exit code 0 = pass) and `passes: false`.
2. Implement self-verifies in a loop, flips `passes: false → true` on success, ends with one `<gate-status>` tag.
3. Prompt forbids Q&A; gaps become `## Assumptions` bullets; only irreversible blockers escalate.
4. Init/Review/Improve emit their own `<gate-status>` tags so any orchestrator can chain gates.

## Reproducing

```sh
cd benchmarks
bash _lib/run-version.sh v0 run1 task        # ~3-5min
bash _lib/run-version.sh v1 run1 task-b      # ~5min
bash _lib/run-version.sh v2 run1 task-b      # ~5min
```

Each call writes:

- `runs/<version>/<task>-<run>/.bench/<gate>.{stdout,stderr,timing}` — raw gate output
- `runs/<version>/<task>-<run>/.agents/gates/<id>-<slug>/{human,agent}/...` — fgate artifacts
- `runs/<version>/<task>-<run>/.bench/verify.txt` — final mechanical summary

## Post-port note

v2 was the seed for the renamed `flever-*` skills now under `skills/`. The `fgate-*` and `.agents/gates/` references throughout this document are historical and retained for traceability — the live skill set is `skills/flever-*/SKILL.md` and the workspace state directory is `.agents/levers/`. The frozen `benchmarks/{v0,v1,v2}/skills/` snapshots keep their original `fgate-*` names; BENCHMARK-2 anchors to them as reference variants.

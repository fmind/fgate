# TLDR

Both old skills (v0) and new skills (v1) reach 11/11 on the harder mdtoc task. The win is **how**:

- **3× faster implement gate** — 176 s with `verify:` shell criteria vs 530 s with prose Given/When/Then criteria.
- **Resumable** — every criterion has a `passes: false` flag the loop flips on success; on re-invocation the agent picks up where it stopped.
- **Machine-routable** — every gate ends with `<gate-status>COMPLETE|BLOCKED|DECIDE|BUDGET|SHIP|RESUME|IMPROVE|SKIP</gate-status>`. A wrapper greps the tag to chain the next gate.
- **No interactive Q&A** — prompt skill no longer asks the user up to 3 questions (which deadlocks headless `gemini -p`). Gaps go to `## Assumptions` so the human can override after the fact.

Apply the wins via `PLAN.md` (steps 1–9). Source skill bodies in `benchmarks/v2/skills/`. Full evidence in `benchmarks/RESULTS.md`.

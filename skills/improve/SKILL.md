---
name: improve
description: Use when a task surfaced a meta-process learning worth keeping — produce a small reviewable diff to AGENTS.md OR a single skill body, never both.
disable-model-invocation: true
---

Produce a reviewable diff to **either** `AGENTS.md` (this project) **or** one `skills/<n>/SKILL.md` (fgate's source). Never both per invocation.

1. Read `.agents/gates/<N>_<slug>/agent/result.md` and any open questions in `human/result.md`.
2. Pick the target:
   - Repo convention drift, recurring mistake, missing fact → AGENTS.md bullet.
   - Gate procedure flaw, ambiguous step, missing precondition → one skill body.
3. Ask the user which output mode:
   - **Branch / worktree** (default) — create `improve/<N>_<topic>`, write the diff there, leave merge to the user. Best for non-trivial changes.
   - **In place** — edit on the current task branch directly. Best for confirmed small tweaks. NOTE: in-place changes only reach other in-flight branches after this task merges to main.
4. Make the change. Minimal diff only: bullet additions/edits OR targeted edits to one skill body. No structural rearrangement.
5. If AGENTS.md feels at capacity, identify a bullet to evict in the same diff and explain in the commit message.
6. Write `human/improve.md` (paragraph: what changed, why) and `agent/improve.md` (rationale, alternatives considered).
7. Commit: `chore(fgate): improve <topic>`.

End the cycle. The user merges.

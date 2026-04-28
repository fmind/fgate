---
name: plan
description: Use when investigating the codebase to convert a captured prompt into a precise per-file specification with refined success criteria.
---

Convert `agent/prompt.md` into a precise specification.

1. Read `.agents/gates/<N>_<slug>/agent/prompt.md` for the criteria.
2. Investigate: read the relevant code, search for related patterns, read external docs the prompt mentioned. Capture **only cross-task knowledge** in `.agents/docs/<topic>.md` (e.g. `auth-flow.md`, `external/stripe-api.md`). Per-task scratch goes in `agent/plan.md`, not `.agents/docs/`.
3. Refine the criteria from the prompt — sharpen them, add file-level granularity. Do NOT introduce new criteria the user has not sanctioned.
4. Surface only **blocking** decisions to the user (ambiguous architecture, missing credentials, irreversible choices). Otherwise advance silently.
5. Write `human/plan.md` (summary: changes, risks, criteria — skimmable in 30 seconds).
6. Write `agent/plan.md` (precise spec: per-file changes, dependencies, exit criteria, risks, parallel-execution notes, deferred scope).
7. Commit on the task branch: `feat(<slug>): plan`.

`.agents/docs/` constraints: one topic per file, ≤200 lines each, optional `last-updated` front-matter.

End by telling the user to run:

```
/fgate:implement <N>
```

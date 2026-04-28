---
name: implement
description: Use when executing a planned task — read agent/plan.md and ship the changes to the success criteria, stopping only on critical blockers.
disable-model-invocation: true
---

Execute the plan. Move objectives forward; stop only on critical blockers.

1. Read `.agents/gates/<N>_<slug>/agent/plan.md` for the spec and criteria.
2. Implement per the plan. Run tests, lint, type-check inside this gate; targets are in the plan. Keep going on non-critical issues — surface them at review time, not now.
3. Append to `human/trace.md` (key events: started, milestone, blocker, completed) and `agent/trace.md` (full execution log: each command, output, decision, alternative considered). `trace.md` files are append-only — never rewrite past entries.
4. Stop ONLY on critical blockers: not authenticated to a CLI, destructive operation needs sanction, irreversible architectural choice. Surface and wait for the user.
5. On completion: re-run tests and lint. If green, write `human/result.md` (summary, what works, open questions, follow-ups) and `agent/result.md` (decisions, alternatives considered, why X over Y, deferred items).
6. Commit on the task branch: `feat(<slug>): implement`.

End by telling the user to run:

```
/fgate:review <N>
```

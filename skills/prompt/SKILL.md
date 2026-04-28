---
name: prompt
description: Use when capturing user intent for a new task — define success criteria up-front, create a task workspace under .agents/gates/, and a task branch.
---

Capture user intent. The human's attention is highest here — spend it.

1. Resolve task ID `<N>` = max existing `.agents/gates/<N>_*` + 1 (start at 1). Slug the title (kebab-case, lowercased). Create branch `gates/<N>_<slug>` from `main` and check it out.
2. Create `.agents/gates/<N>_<slug>/human/` and `.agents/gates/<N>_<slug>/agent/`.
3. Challenge the prompt. Ask **at most 3 targeted questions** to extract context the user hasn't volunteered. Stop earlier if criteria are already concrete. If after 3 questions criteria still aren't concrete, fail loud — do NOT advance to plan.
4. Define success criteria together: tests pass, lint clean, observable behavior X. The user signs off.
5. Write `human/prompt.md` (terse: title, ask, criteria — under 30 lines).
6. Write `agent/prompt.md` (full: ask, criteria, the user's context, why this matters, scope boundaries, deferred items).
7. Commit on the task branch: `feat(<slug>): capture prompt`.

End by telling the user to run:

```
/fgate:plan <N>
```

---
name: review
description: Use when finalizing an implemented task — read result.md, confirm criteria, propose merge or surface follow-ups.
disable-model-invocation: true
---

Read `human/result.md` + `agent/result.md`, align with the user, finalize the task.

1. Skim `human/result.md`. Read `agent/result.md` for decisions and deferred items.
2. Confirm the criteria from `agent/plan.md` are met. If not, stop — do not propose a merge; suggest re-running `/fgate:implement`.
3. Pick ONE primary next action. Mention alternatives in a single-line `Other options:` footer.
   - **Ship it** — propose a conventional-commit message + merge plan; ask Y/N before merging `gates/<N>_<slug>` back to `main`.
   - **Improve** — if the task surfaced a meta-process learning, suggest `/fgate:improve <N>`.
   - **Follow-up** — if `result.md` lists deferred scope, suggest `/fgate:prompt <title>`.
4. On Y to ship-it: `git checkout main && git merge --no-ff gates/<N>_<slug>`. Ask before pushing.

Override the commit-mode by adding an AGENTS.md bullet (`review auto-commits without asking`, `review only suggests; user runs git commit`) or shipping `.agents/skills/review/SKILL.md` to replace this gate's end-game wholesale.

End by stating the chosen primary next command, with a one-line `Other options:` footer.

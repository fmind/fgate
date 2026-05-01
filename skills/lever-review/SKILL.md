---
name: lever-review
description: Use when finalizing an implemented task — re-run every verifier yourself, confirm the checklist is green, summarize the diff, pick one next action.
---

# lever-review

Re-run the acceptance checklist's verifiers in a clean environment, confirm each one matches what `agent/result.md` claims, and pick exactly one primary action. Trust the artifacts as a starting point; trust the verifiers as ground truth.

## 1. Read the artifacts

1. Resolve the task to `.agents/levers/<id>-<slug>/`.
2. Skim `human/result.md`. Read `agent/result.md` end-to-end.
3. Re-open `agent/prompt.md` §Acceptance checklist and `agent/plan.md` §Coverage.
4. Re-read `AGENTS.md` §Conventions for rules the diff must respect.
5. Run `git status` and `git diff --stat` so you can summarize what changed.

## 2. Re-run the verifiers

For each criterion in `agent/prompt.md` §Acceptance checklist, run its `verify:` command **yourself** and capture the output. Do not trust `agent/result.md` blindly — it can drift from reality.

Render a one-screen rollup table in `agent/review.md`:

```text
| # | Criterion | Verifier | Result | Note |
| - | --------- | -------- | ------ | ---- |
| 1 | <text>    | `<cmd>`  | pass   |      |
| 2 | <text>    | `<cmd>`  | fail   | <one-line> |
```

Any red row blocks **Ship it**. Either propose the smallest fix and apply it (when ≤ 5 lines and obvious), or hand back with the failing rollup so `/lever-implement` can resume.

## 3. Pick one primary action

- **Ship it (default).** Every rollup row is pass. Summarize the change in one line and hand the diff back to the user.
- **Resume.** One or more verifiers fail. Hand back to `/lever-implement <id>` with failing rows pinpointed.
- **Improve.** The task surfaced a meta-process learning. Suggest `/lever-improve <id>`.
- **Follow-up.** `result.md` lists deferred scope worth a new task. Suggest `/lever-prompt <follow-up-title>`.

## 4. Write `agent/review.md`

The artifact is short (≤ 30 lines): one-line summary, the rollup table from §2, an `Other options:` footer, and the marker on the last line.

A user-side override at `.agents/skills/lever-review/SKILL.md` replaces this step's end-game wholesale.

## 5. Hand off

The last line of `agent/review.md` is exactly one of:

- `<lever-status>SHIP: <pass>/<total></lever-status>` — every verifier passed; diff staged for the user.
- `<lever-status>RESUME: <pass>/<total> failing=<criterion></lever-status>` — at least one verifier failed; hand back to `/lever-implement <id>`.
- `<lever-status>IMPROVE: <one-line lesson></lever-status>` — task surfaced a meta-process learning worth `/lever-improve`.

The chat reply ends with the same line, so a streaming host can chain without reading the artifact. When the tag is `SHIP`, optionally precede it with an `Other options: /lever-improve <id> (<lesson>) · /lever-prompt <follow-up-title> (<deferred>)` line listing real parallel actions; skip it when the diff is the only sensible move.

```text
Other options: /lever-improve 1 (deferred-error pattern) · /lever-prompt session_cookies (follow-up).

<lever-status>SHIP: 6/6</lever-status>
```

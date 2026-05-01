---
name: fgate-implement
description: Use when executing a planned task — ship the changes to the success criteria, stopping only on critical blockers.
paths:
  - ".agents/gates/**"
---

# fgate-implement

Execute the plan. Push objectives forward; stop only on critical blockers. Gather proof of work as you go — command outputs, test runs, screenshots — so `/fgate:review` can verify what actually happened, not just what you claim.

## 1. Read the spec

1. Resolve the task to `.agents/gates/<id>-<slug>/`.
2. Read `agent/plan.md` end-to-end. Internalize per-file changes, dependencies, the test plan, exit criteria, and the Coverage table.
3. Skim `agent/prompt.md` for context the plan compressed.
4. Refuse to start if `[NEEDS CLARIFICATION:` appears anywhere in the gate dir. Hand back to the user with the list of markers — `/fgate:plan` should have resolved them.

## 2. Execute

Follow the per-file changes in dependency order. For each unit of work:

1. **Test first.** Write or extend the test the plan's "Test order" line points at. Run it and confirm it fails for the right reason. Skip only when the change is a pure refactor on already-covered code.
2. Make the source change.
3. Re-run the test plus relevant lint. If green, move on. If red on the change you just made, fix before moving on.
4. Append a one-liner to `human/trace.md` and a full block to `agent/trace.md` (see §3).

Run `[P]`-marked file changes via parallel subagents (the Agent tool / Gemini's dispatch). Serialize anything not marked.

## 3. Trace logs (append-only)

`human/trace.md` — key events only, one line each:

```text
HH:MM started
HH:MM milestone: <one line>
HH:MM blocker: <one line>
HH:MM completed
```

`agent/trace.md` — full execution log. One block per event:

````text
## HH:MM <event>

<command run>

```text
<output trimmed to the relevant lines>
```

Decision: <what you decided>
Alternative considered: <if any, plus why rejected>
````

`trace.md` is **append-only**. Never rewrite past entries — the log must reflect actual execution order, not a tidy retrospective.

## 4. Stop conditions

Stop and surface to the user **only** for:

- Authentication / credential failures the agent cannot resolve.
- Destructive operations not sanctioned in the plan (`rm -rf`, force-push, `DROP TABLE`, deleting branches).
- Irreversible architectural choices the plan didn't decide.
- ≥ 3 consecutive failed fix attempts where each makes things worse.

For everything else — flaky test, missing import, lint warning, doc typo — keep going. Surface non-critical issues at review time, not now.

## 5. Final verification & proofs

Consolidate the proofs you've been gathering in `agent/trace.md`:

1. Run the full test suite, lint, type-check (whatever the plan listed). Fix and retry up to 3 times. Capture the final commands and outputs verbatim — these are the proofs.
2. Walk the Coverage table from `agent/plan.md`. For each criterion, record the test name or command output that proves it. A criterion you cannot mechanically prove gets a `[VERIFY: <how>]` note so `/fgate:review` picks it up.
3. For UI or behavioral changes, attach a screenshot or log excerpt — type-checks alone don't prove a feature works.

## 6. Write result artifacts

`human/result.md` — what the user will skim:

```text
# Result: <id>-<slug>

## What works

- <bullet>

## Pending / non-critical

- <bullet>

## Open questions

- <bullet>

## Suggested follow-ups

- <bullet>
```

`agent/result.md` — decisions log:

```text
# Result: <id>-<slug>

## Summary

<one paragraph>

## Decisions

- <decision> — <why X over Y>

## Alternatives considered

- <alternative> — <why rejected>

## Test outputs

<final pass/fail of every test command, trimmed>

## Coverage

| Criterion | Verified by |
| --- | --- |
| <criterion> | `<command output>`, `<test name>`, or `[VERIFY: <how>]` |

## Deferred

- <follow-up scope>

## Files touched

<output of `git diff --stat`>
```

## 7. Hand off

End with exactly:

```text
Next: /fgate:review <id>
```

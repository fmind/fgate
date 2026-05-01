# AGENTS.md

**Levers for AI coding agents — multiply the agent's force, divide the human's effort.**

Six steps (`init` → `prompt` → `plan` → `implement` → `review` → `improve`) run as Agent Skills across Claude Code, Gemini CLI, and GitHub Copilot from a single source. A lever is one task workflow under `.agents/levers/<id>-<slug>/`; the steps execute inside it.

README has the project tour; this file is operational rules only.

## Skill authoring

- `description` starts with "Use when…" and is trigger-rich, not workflow-summarizing.
- Skill names use the `lever-` prefix (the plugin/extension slug doubles as the slash prefix, so `lever-implement` is invoked as `/lever-implement` across every tool); heavy reference material lives in sibling files, not the skill body.
- Skill bodies must run across every supported agent. Keep them tool-agnostic — tool-specific syntax (`${CLAUDE_SKILL_DIR}`, `!{shell}`, `@{path}`, `${user_config.X}`, `${input:x}`) belongs in the manifest, never in the skill body.
- Each step ends with exactly one `<lever-status>...</lever-status>` tag on its own line. When the step writes artifacts, the tag is the last line of the agent-side artifact and is repeated as the last line of the chat reply (so a streaming host can chain without reading the artifact). When a step writes none, the tag binds the chat reply only. The legacy `<gate-status>` alias is no longer emitted; old runs under `.agents/evolutions/` keep it for historical fidelity.

## Workflow

- A lever is `.agents/levers/<id>-<slug>/`. Each step writes its artifacts inside; presence of `prompt.md` → `plan.md` → `result.md` advances the workflow.
- Artifacts come in pairs: `human/<name>.md` (30-second skim) and `agent/<name>.md` (reproducible detail). A step may write zero, one, or many such pairs (e.g., `implement` writes both `trace.md` and `result.md`). Once written, treat them as read-only.
- Skills may read git state (`git status`, `git diff`, `git log`) but must never mutate it. No `git add`, no commits, no branch or merge operations.
- Acceptance criteria carry a runnable `verify:` shell command and a `passes: false` flag. Implement flips the flag; review re-runs the verifier.
- agent-levers owns the levers surface only. Cross-task project notes belong in a separate docs/memory skill if the project installs one; otherwise inline the fact in `agent/plan.md`. Don't introduce new top-level folders from inside these skills.

## Status vocabulary

Each step emits exactly one `<lever-status>...</lever-status>` tag. Tags are step-specific:

- `init` — `COMPLETE` (files written) or `BLOCKED: <reason>` (pre-flight refused).
- `prompt` — `COMPLETE` (checklist locked) or `DECIDE: <topic>` (irreducible clarification needed before plan).
- `plan` — `COMPLETE`, `BLOCKED: <reason>`, or `DECIDE: <topic>`.
- `implement` — `COMPLETE`, `BLOCKED: <reason>`, `DECIDE: <question>`, or `BUDGET: <pass>/<total>` (out of tool-call budget with criteria failing).
- `review` — `SHIP: <pass>/<total>` (every verifier green), `RESUME: <pass>/<total> failing=<criterion>` (back to implement), or `IMPROVE: <one-line lesson>` (meta-process learning).
- `improve` — `IMPROVE: <files touched>` (diff staged for the user) or `SKIP: <reason>` (no reusable rule).

A `Next: /lever-<step> <args>` line appears on the line **above** the tag, only when the tag is `COMPLETE` (or `SHIP` for review). All other tags hand back to the human without a forward action.

An optional `Other options: /lever-<alt1> <args> · /lever-<alt2> <args>` line — single line, dot-separated — sits above `Next:` when there are real parallel actions to surface (e.g., `improve` after a meta-lesson, a follow-up `prompt` for deferred scope). Skip it when the only sensible move is the primary `Next:`.

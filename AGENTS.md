# AGENTS.md

**Amplify the agent loop <> Simplify the human loop.**

Six levers (`init` → `prompt` → `plan` → `implement` → `review` → `improve`) run as Agent Skills across Claude Code, Gemini CLI, and GitHub Copilot from a single source.

README has the project tour; this file is operational rules only.

## Skill authoring

- `description` starts with "Use when…" and is trigger-rich, not workflow-summarizing.
- Skill names use the `flever-` prefix; heavy reference material lives in sibling files, not the skill body.
- Skill bodies must run across every supported agent. Tool-specific syntax (`${CLAUDE_SKILL_DIR}`, `!{shell}`, `@{path}`, `${user_config.X}`, `${input:x}`) belongs in the manifest or shell layer.
- Every lever ends with exactly one `<gate-status>...</gate-status>` tag on its own line. Hosts grep for it to chain levers. The tag is named `<gate-status>` for historical reasons (the project was originally called `fgate`); a parallel `<lever-status>` alias may ship in a future release with a deprecation window.

## Workflow

- State is files: presence of `prompt.md` → `plan.md` → `result.md` under `.agents/levers/<id>/` advances the workflow.
- Two artifacts per lever: `human/<lever>.md` (30-second skim) and `agent/<lever>.md` (reproducible detail). Once written, treat them as read-only.
- Skills may read git state (`git status`, `git diff`, `git log`) but must never mutate it. No `git add`, no commits, no branch or merge operations.
- Acceptance criteria carry a runnable `verify:` shell command and a `passes: false` flag. Implement flips the flag; review re-runs the verifier.

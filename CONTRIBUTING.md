# Contributing to flever

## Ground rules

- **One change per PR.** A skill-body edit and a manifest change should be separate PRs unless they're causally linked.
- **Open an issue first** for anything beyond a typo, a clarifying sentence, or a CI tweak. flever's value is in being minimal; new sections, new levers, or new dependencies need a discussion.
- **Conventional commits.** `<type>(<scope>): <subject>`. Common types: `feat`, `fix`, `chore`, `docs`, `refactor`. Scope is the lever name (`init`, `prompt`, `plan`, `implement`, `review`, `improve`) or `flever` for cross-cutting changes.

## Local checks

Install dev dependencies once:

```bash
npm install
pre-commit install   # optional: runs format + lint on every commit
```

Before pushing, run what CI runs:

```bash
npm run lint
```

Auto-fix formatting and markdown:

```bash
npm run format
```

## Skill-body edits

- Each non-review skill ends by suggesting exactly one next command.
- `description` must start with `Use when…` and be trigger-rich, not workflow-summarizing.
- Keep heavy reference material in sibling files under `skills/<name>/` (e.g. `references/`, `templates/`).

## Pull requests

- Reference the issue you're closing.
- Describe what changed in one paragraph and why.
- Confirm `npm run lint` passes locally.

## License

By contributing, you agree your contributions are licensed under the project's [MIT License](./LICENSE).

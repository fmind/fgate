# Benchmark task B: `mdtoc` — Markdown TOC injector

A harder, partially-underspecified task. The user's surface ask is one sentence; the spec below is what a good agent should _infer or default_ without asking the human. The mechanical verifier still gives a deterministic pass/fail score.

## User-surface ask

> "Build me a small Python CLI `mdtoc` that injects a table of contents into a markdown file."

That's all the user says in `/flever:prompt`. Everything below is what the agent must figure out from convention or default — without asking.

## Inferred spec

`mdtoc` parses ATX headings (`#` … `######`), generates a GitHub-flavoured table of contents with markdown links to anchor slugs, and writes it back into the file between two sentinel comments.

### Behaviour

1. Reads markdown from `--input <path>` (required).
2. Locates the TOC region delimited by:

   ```text
   <!-- mdtoc:start -->
   ...existing TOC, replaced...
   <!-- mdtoc:end -->
   ```

   If the sentinels are missing, exits 1 with `error: TOC sentinels not found in <path>`.

3. Generates a TOC: one `- [<heading text>](#<slug>)` per heading, indented by 2 spaces per level beyond `--min-level` (default 2 — so `##` is depth 0).
4. Writes the file in place. With `--check`, exits 0 if the file is already up to date or 1 if it would change (no write). With `--dry-run`, prints the new TOC to stdout, no write.
5. GitHub slug rules: lowercase; spaces → hyphens; drop characters not in `[a-z0-9-]`; collapse consecutive hyphens; strip leading/trailing hyphens. Duplicate slugs get `-1`, `-2`, … suffixes (1-based).
6. The first heading at `--min-level` ≤ 1 (i.e. an `# H1` title) is excluded from the TOC even when present.

### Flags

- `--input <path>` (required).
- `--min-level <int>` (default `2`) — the smallest heading level included.
- `--max-level <int>` (default `4`) — the largest heading level included. Levels deeper than this are dropped.
- `--check` — exit 1 on diff, no write.
- `--dry-run` — print TOC to stdout, no write.
- `--help` / `-h`.

### Errors

- Missing `--input`: argparse exit 2.
- File not found: exit 1, `error: file not found: <path>`.
- Sentinels missing: exit 1, `error: TOC sentinels not found in <path>`.
- `--check` finds drift: exit 1, no stderr message required.

## Project shape

- `pyproject.toml` declares `mdtoc` console_script.
- `src/mdtoc/{__init__.py,cli.py}`.
- `tests/test_mdtoc.py` covers ≥ 8 tests across slug rules, TOC generation, sentinel injection, --check, --dry-run, error paths.
- `README.md`.

## Acceptance criteria (mechanical)

The verifier is `benchmarks/_lib/verify-b.sh`. It runs (in a venv):

1. **Installable.** `python -m pip install -e .` exits 0.
2. **Help works.** `mdtoc --help` exits 0; stdout contains `--input`, `--min-level`, `--check`, `--dry-run`.
3. **Generates TOC.** Given a fixture `sample.md` (defined inline in the verifier) with `## Alpha`, `### Alpha sub`, `## Beta`, `### Beta-One` between sentinels, `mdtoc --input sample.md --dry-run` prints the expected TOC verbatim.
4. **In-place write.** Running `mdtoc --input sample.md` updates the file; the new content matches the expected file fixture verbatim.
5. **Idempotent.** Running it a second time leaves the file byte-identical.
6. **--check detects drift.** After mutating the TOC region, `mdtoc --input sample.md --check` exits 1.
7. **--check on clean file passes.** On the freshly-written file, `mdtoc --input sample.md --check` exits 0.
8. **Sentinels missing.** On a file without sentinels, the command exits 1 and stderr contains `TOC sentinels not found`.
9. **Slug duplicates.** Two `## Foo` headings produce slugs `foo` and `foo-1`.
10. **Tests pass.** `pytest -q` exits 0 with ≥ 8 tests collected.
11. **Lint clean.** `ruff check .` exits 0.

## Why this task

- **Ambiguous user ask.** Tests autonomy: does the agent default sensibly or stop and ask?
- **Multi-step verifier.** Tests whether implement loops back when one criterion fails.
- **Edge cases that bite.** Slug duplicate suffixing, idempotency, --check semantics — all easy to miss on the first pass.
- **More criteria (11).** A bigger surface for the checklist machinery to prove its worth.

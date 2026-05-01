# Benchmark task: `wordfreq` Python CLI

A small, self-contained Python CLI tool. Chosen because every acceptance criterion resolves to a shell exit code, so success/failure is mechanical — no subjective judgement required when comparing prompt versions.

## User-facing behaviour

`wordfreq` reads UTF-8 text and prints a frequency table of words.

A "word" is a maximal run of `[A-Za-z0-9_]` characters, lowercased. Everything else is a separator. Empty input is allowed (no output, exit 0).

### Default output

`<count>\t<word>` lines, sorted by count desc, then word asc, one entry per line, trailing newline.

### Flags

- `--input <path>` — read from file (default: stdin).
- `--top <N>` — keep only the N most frequent words (after sort). `N >= 0`. Default: no limit.
- `--format {table,json}` — `table` is the default (above). `json` is a JSON array of `{"word": str, "count": int}` objects in the same order, written with `json.dumps(..., indent=2)`.
- `--help` / `-h` — usage; exit 0.

### Exit codes

- `0` on normal completion.
- `2` on argument errors (argparse default).

## Project shape

- `pyproject.toml` declares the project, the `wordfreq` console_script entry point, and pytest config (`testpaths = ["tests"]`).
- `src/wordfreq/__init__.py` and `src/wordfreq/cli.py` (or equivalent module layout).
- `tests/test_wordfreq.py` covers at least the criteria below.
- `README.md` with one-paragraph description and usage examples.

## Acceptance criteria (mechanical)

Each is a shell command with an expected exit code or output. The verification script (`benchmarks/_lib/verify.sh`) executes them in order and returns 0 only if all pass.

1. **Installable.** `python -m pip install -e .` exits 0.
2. **Help works.** `wordfreq --help` exits 0 and stdout contains `--input`, `--top`, `--format`.
3. **Default counts.** `printf 'hello world hello\n' | wordfreq` prints exactly `2\thello\n1\tworld\n`.
4. **Top-N.** `printf 'a b a c b a\n' | wordfreq --top 2` prints exactly `3\ta\n2\tb\n`.
5. **JSON output.** `printf 'a b a\n' | wordfreq --format json` is valid JSON equal to `[{"word":"a","count":2},{"word":"b","count":1}]` (whitespace-insensitive comparison via `python -c 'import json,sys; ...'`).
6. **Tests pass.** `pytest -q` exits 0, reports ≥ 5 tests collected.
7. **Lint clean.** `ruff check .` exits 0 (rules: pyflakes + pycodestyle defaults; no extra strictness required).

## Out of scope

- Streaming for huge files; in-memory is fine.
- Locale-aware tokenisation; ASCII alphanumeric is enough.
- Performance benchmarking.
- CI workflow files.

## Why this task

- **Mechanically verifiable.** Every criterion is a shell exit code. Removes evaluator subjectivity.
- **All gates exercised.** `prompt` captures the spec, `plan` produces a per-file layout, `implement` does TDD across 3-4 files, `review` runs the verification script.
- **15-30 minutes.** Small enough for one context window, big enough that prompt drift shows up.
- **Stable.** Same task across versions ⇒ measured variance is prompt-quality, not task variance.

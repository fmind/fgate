#!/usr/bin/env bash
# Drive an entire fgate cycle (prompt → plan → implement → review) for one version,
# then verify acceptance criteria. Produces a self-contained run dir.
#
# Usage: run-version.sh <version> <run-id> [task-name] [task-arg]
#   task-name defaults to "task" (uses benchmarks/task/TASK.md and verify.sh).
#   Other supported task-name: "task-b" (uses benchmarks/task-b/TASK.md and verify-b.sh).

set -u

VERSION="${1:?need version}"
RUN_ID="${2:?need run-id}"
TASK_NAME="${3:-task}"
TASK_ARG="${4:-build the project specified in TASK.md}"

REPO="/home/fmind/fgate"
TASK_DIR="$REPO/benchmarks/$TASK_NAME"
[[ -d "$TASK_DIR" ]] || { echo "task dir not found: $TASK_DIR"; exit 1; }
case "$TASK_NAME" in
  task)   VERIFIER="$REPO/benchmarks/_lib/verify.sh" ;;
  task-b) VERIFIER="$REPO/benchmarks/_lib/verify-b.sh" ;;
  *) echo "unknown task: $TASK_NAME"; exit 1 ;;
esac

RUN_DIR="$REPO/benchmarks/runs/$VERSION/$TASK_NAME-$RUN_ID"

if [[ -e "$RUN_DIR" ]]; then
  echo "Run already exists: $RUN_DIR — choose a different RUN_ID."
  exit 1
fi

mkdir -p "$RUN_DIR"
cd "$RUN_DIR" || exit 1
git init -q
git -c user.email=bench@example.com -c user.name=bench commit --allow-empty -q -m "init"

# Wire host AGENTS.md so the agent can read it.
cp "$TASK_DIR/TASK.md" .
cat >AGENTS.md <<AGENTS
# AGENTS.md

## Project
- Python CLI tool benchmark workspace. Build the project specified in TASK.md.
- Primary stack: Python 3 + pyproject.toml + pytest + ruff.

## Layout
- \`TASK.md\`: full task spec — read first.
- \`.agents/\`: workspace state files (gates, docs).

## Commands
- Install editable: \`python -m pip install -e .\`
- Tests: \`pytest -q\`
- Lint: \`ruff check .\`

## Conventions
- Source layout under \`src/<package>/\`.
- Tests under \`tests/\`.
- Code formatting: ruff defaults.
AGENTS
git add -A && git -c user.email=bench@example.com -c user.name=bench commit -q -m "scaffold"

run_gate() {
  local gate="$1" arg="$2"
  local started rc
  started=$(date +%s)
  echo ">>> [$VERSION/$TASK_NAME-$RUN_ID] gate=$gate arg=$arg start=$(date -Iseconds)"
  bash "$REPO/benchmarks/_lib/run-gate.sh" "$VERSION" "$gate" "$arg" "$RUN_DIR"
  rc=$?
  echo "<<< [$VERSION/$TASK_NAME-$RUN_ID] gate=$gate rc=$rc duration=$(( $(date +%s) - started ))s"
  return $rc
}

run_gate prompt "$TASK_ARG"            || { echo "PROMPT FAILED"; exit 2; }
run_gate plan "1"                      || { echo "PLAN FAILED"; exit 2; }
run_gate implement "1"                 || { echo "IMPLEMENT FAILED"; exit 2; }
run_gate review "1"                    || { echo "REVIEW FAILED"; exit 2; }

echo ">>> verifying acceptance criteria"
bash "$VERIFIER" "$RUN_DIR" >"$RUN_DIR/.bench/verify.txt" 2>&1
verify_rc=$?
echo "<<< verify rc=$verify_rc"
cat "$RUN_DIR/.bench/verify.txt"
exit $verify_rc

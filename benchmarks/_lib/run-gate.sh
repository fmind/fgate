#!/usr/bin/env bash
# Drive a single flever lever through Gemini CLI in a clean workspace.
# Usage: run-gate.sh <version> <lever> <task-arg> <workspace-dir>
# - version:    v0|v1|v2|main (skill set under benchmarks/<version>/skills/).
#               Frozen v0/v1/v2 use the historical fgate- prefix; main uses
#               flever- (the live skills/). The script tries flever- first,
#               falls back to fgate- so the same harness drives both.
# - lever:      prompt|plan|implement|review|improve
# - task-arg:   argument passed to the lever (e.g. "build wordfreq cli" or "1")
# - workspace-dir: where to run gemini (cwd)
#
# Writes:
#   <workspace>/.bench/<lever>.stdout
#   <workspace>/.bench/<lever>.stderr
#   <workspace>/.bench/<lever>.timing
# Returns gemini's exit code.

set -u
VERSION="${1:?need version}"
GATE="${2:?need lever}"
ARG="${3:-}"
WORKSPACE="${4:?need workspace}"

REPO="/home/fmind/fgate"
SKILL_FILE="$REPO/benchmarks/$VERSION/skills/flever-$GATE/SKILL.md"
[[ -f "$SKILL_FILE" ]] || SKILL_FILE="$REPO/benchmarks/$VERSION/skills/fgate-$GATE/SKILL.md"
[[ -f "$SKILL_FILE" ]] || { echo "Skill not found: $SKILL_FILE"; exit 99; }

mkdir -p "$WORKSPACE/.bench"
SKILL_BODY=$(cat "$SKILL_FILE")

# Inject task brief once (only on first lever per workspace).
TASK_BRIEF=""
if [[ "$GATE" == "prompt" || "$GATE" == "init" ]]; then
  TASK_BRIEF="$(cat "$REPO/benchmarks/task/TASK.md")

The user's literal ask is: \"$ARG\"
"
fi

# Determine the slash-command namespace from the skill name (flever-X or fgate-X).
SKILL_NAME="$(basename "$(dirname "$SKILL_FILE")")"   # e.g. flever-implement
NS="${SKILL_NAME%%-*}"                                  # e.g. flever

PROMPT="You are operating inside the project workspace at \`$WORKSPACE\`.
Your job is to execute the $NS lever \`$GATE\` end-to-end, autonomously, using the SKILL body below as your operating manual. Use file/shell/grep tools as needed. Do not ask the user any questions — make reasonable assumptions and proceed. End your response when the lever's artifacts are written.

----- SKILL: $SKILL_NAME -----
$SKILL_BODY
----- END SKILL -----

LEVER INPUT (the argument the user typed after the slash command): \"$ARG\"

$TASK_BRIEF
Now perform the lever end-to-end."

start=$(date +%s)
cd "$WORKSPACE" || exit 98
GEMINI_CLI_TRUST_WORKSPACE=true gemini --approval-mode yolo -p "$PROMPT" -o text \
  >"$WORKSPACE/.bench/$GATE.stdout" \
  2>"$WORKSPACE/.bench/$GATE.stderr"
rc=$?
end=$(date +%s)
echo "rc=$rc duration=$((end-start))s gate=$GATE version=$VERSION arg=$ARG" \
  >"$WORKSPACE/.bench/$GATE.timing"
exit $rc

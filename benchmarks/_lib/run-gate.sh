#!/usr/bin/env bash
# Drive a single fgate gate through Gemini CLI in a clean workspace.
# Usage: run-gate.sh <version> <gate> <task-arg> <workspace-dir>
# - version:  v0|v1|... (skill set under benchmarks/<version>/skills/)
# - gate:     prompt|plan|implement|review|improve
# - task-arg: argument passed to the gate (e.g. "build wordfreq cli" or "1")
# - workspace-dir: where to run gemini (cwd)
#
# Writes:
#   <workspace>/.bench/<gate>.stdout
#   <workspace>/.bench/<gate>.stderr
#   <workspace>/.bench/<gate>.timing
# Returns gemini's exit code.

set -u
VERSION="${1:?need version}"
GATE="${2:?need gate}"
ARG="${3:-}"
WORKSPACE="${4:?need workspace}"

REPO="/home/fmind/fgate"
SKILL_FILE="$REPO/benchmarks/$VERSION/skills/fgate-$GATE/SKILL.md"
[[ -f "$SKILL_FILE" ]] || { echo "Skill not found: $SKILL_FILE"; exit 99; }

mkdir -p "$WORKSPACE/.bench"
SKILL_BODY=$(cat "$SKILL_FILE")

# Inject task brief once (only on first gate per workspace).
TASK_BRIEF=""
if [[ "$GATE" == "prompt" || "$GATE" == "init" ]]; then
  TASK_BRIEF="$(cat "$REPO/benchmarks/task/TASK.md")

The user's literal ask is: \"$ARG\"
"
fi

PROMPT="You are operating inside the project workspace at \`$WORKSPACE\`.
Your job is to execute the fgate gate \`$GATE\` end-to-end, autonomously, using the SKILL body below as your operating manual. Use file/shell/grep tools as needed. Do not ask the user any questions — make reasonable assumptions and proceed. End your response when the gate's artifacts are written.

----- SKILL: fgate-$GATE -----
$SKILL_BODY
----- END SKILL -----

GATE INPUT (the argument the user typed after the slash command): \"$ARG\"

$TASK_BRIEF
Now perform the gate end-to-end."

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

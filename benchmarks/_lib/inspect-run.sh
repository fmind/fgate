#!/usr/bin/env bash
# Print quality metrics for a single benchmark run.
# Usage: inspect-run.sh <run-dir>
set -u
run="${1:?need run-dir}"
[[ -d "$run" ]] || { echo "no such run: $run"; exit 1; }

echo "=== $run ==="
gate_dir=$(find "$run/.agents/levers" "$run/.agents/gates" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
if [[ -z "$gate_dir" ]]; then
  echo "no lever/gate dir found"; exit 0
fi
echo "lever=$gate_dir"

# Timing
total=0
for t in "$run/.bench/"*.timing; do
  [[ -f "$t" ]] || continue
  d=$(grep -Eo 'duration=[0-9]+' "$t" | head -1 | grep -Eo '[0-9]+')
  echo "  timing $(basename "$t" .timing)=${d}s"
  total=$((total + ${d:-0}))
done
echo "  total=${total}s"

# Verify
if [[ -f "$run/.bench/verify.txt" ]]; then
  echo "verify:"
  grep -E '^(PASS|FAIL|SUMMARY)' "$run/.bench/verify.txt" | sed 's/^/  /'
fi

# Autonomy signals
clarif=$(grep -rl 'NEEDS CLARIFICATION' "$gate_dir" 2>/dev/null | wc -l)
asked=$(grep -Ec '\?\s*$' "$run/.bench/implement.stdout" 2>/dev/null || echo 0)
trace_lines=$(wc -l <"$gate_dir/agent/trace.md" 2>/dev/null || echo 0)
status_signal=$(grep -Ec '<gate-status>' "$run/.bench/implement.stdout" 2>/dev/null || echo 0)

echo "autonomy:"
echo "  needs_clarification_markers=$clarif"
echo "  question_marks_in_stdout=$asked"
echo "  trace_lines=$trace_lines"
echo "  gate_status_tags=$status_signal"

# Artifact size
echo "artifact sizes:"
for f in prompt plan trace result; do
  for variant in agent human; do
    p="$gate_dir/$variant/$f.md"
    [[ -f "$p" ]] && echo "  $variant/$f.md=$(wc -l <"$p")L"
  done
done

# Code shipped
echo "code shipped:"
cd "$run" && git diff --stat HEAD 2>/dev/null | tail -10 | sed 's/^/  /'

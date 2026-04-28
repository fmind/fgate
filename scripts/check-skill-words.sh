#!/usr/bin/env bash
# Enforce a per-SKILL.md word cap on the body (frontmatter excluded).
# Usage: bash scripts/check-skill-words.sh [cap]
# Default cap: 200 words. Exits non-zero if any skill body exceeds the cap.

set -euo pipefail

CAP="${1:-200}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EXIT=0

shopt -s nullglob
for skill in "$ROOT"/skills/*/SKILL.md; do
  name="$(basename "$(dirname "$skill")")"

  # Strip YAML frontmatter (anything between the first two --- lines on its own).
  body="$(awk '
    BEGIN { state = 0 }
    NR == 1 && /^---[[:space:]]*$/ { state = 1; next }
    state == 1 && /^---[[:space:]]*$/ { state = 2; next }
    state == 1 { next }
    state == 0 { print }
    state == 2 { print }
  ' "$skill")"

  count="$(printf '%s' "$body" | wc -w | tr -d '[:space:]')"

  if [ "$count" -gt "$CAP" ]; then
    printf 'FAIL skills/%s/SKILL.md: %d words (cap %d)\n' "$name" "$count" "$CAP"
    EXIT=1
  else
    printf 'OK   skills/%s/SKILL.md: %d words\n' "$name" "$count"
  fi
done

exit "$EXIT"

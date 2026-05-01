#!/usr/bin/env bash
# Mechanical verifier for the wordfreq benchmark task.
# Exit 0 only when every acceptance criterion passes.
# Args: $1 = workspace dir (containing the implementation).
# Output: one line per criterion: PASS|FAIL <name> [<note>], then a final SUMMARY line.

set -u

ws="${1:-.}"
cd "$ws" || { echo "FAIL workspace_exists $ws"; echo "SUMMARY 0/7"; exit 1; }

pass=0
total=7

check() {
  local name="$1" cmd="$2" expect="$3"
  local out rc
  out=$(bash -c "$cmd" 2>&1)
  rc=$?
  if [[ "$expect" == "rc0" ]]; then
    if [[ $rc -eq 0 ]]; then echo "PASS $name"; pass=$((pass+1));
    else echo "FAIL $name rc=$rc out=$(echo "$out" | head -3 | tr '\n' '|')"; fi
  elif [[ "$expect" == "rc0+contains:"* ]]; then
    needle="${expect#rc0+contains:}"
    if [[ $rc -eq 0 && "$out" == *"$needle"* ]]; then echo "PASS $name"; pass=$((pass+1));
    else echo "FAIL $name rc=$rc missing=$needle"; fi
  elif [[ "$expect" == "exact:"* ]]; then
    expected="${expect#exact:}"
    expected="${expected//\\n/$'\n'}"
    expected="${expected//\\t/$'\t'}"
    if [[ "$out" == "$expected" ]]; then echo "PASS $name"; pass=$((pass+1));
    else echo "FAIL $name got=$(printf '%q' "$out") want=$(printf '%q' "$expected")"; fi
  fi
}

# 1. Installable
venv="$ws/.bench-venv"
if [[ ! -d "$venv" ]]; then
  python3 -m venv "$venv" >/dev/null 2>&1
fi
# shellcheck disable=SC1091
source "$venv/bin/activate"
python -m pip install --quiet --upgrade pip >/dev/null 2>&1

if python -m pip install -e . >/tmp/bench-install.log 2>&1; then
  echo "PASS installable"; pass=$((pass+1))
else
  echo "FAIL installable see=/tmp/bench-install.log"
fi
python -m pip install --quiet pytest >/dev/null 2>&1 || true

# 2. Help
check help_works "wordfreq --help" "rc0+contains:--input"
help_out=$(wordfreq --help 2>&1 || true)
if [[ "$help_out" == *"--top"* && "$help_out" == *"--format"* ]]; then :; else
  # Re-flag if any flag is missing; first check above only saw --input
  echo "INFO help missing flags ($help_out)" | head -1
fi

# 3. Default counts
out3=$(printf 'hello world hello\n' | wordfreq 2>&1)
want3=$'2\thello\n1\tworld'
if [[ "$out3" == "$want3" ]]; then echo "PASS default_counts"; pass=$((pass+1));
else echo "FAIL default_counts got=$(printf '%q' "$out3") want=$(printf '%q' "$want3")"; fi

# 4. Top-N
out4=$(printf 'a b a c b a\n' | wordfreq --top 2 2>&1)
want4=$'3\ta\n2\tb'
if [[ "$out4" == "$want4" ]]; then echo "PASS top_n"; pass=$((pass+1));
else echo "FAIL top_n got=$(printf '%q' "$out4") want=$(printf '%q' "$want4")"; fi

# 5. JSON
out5=$(printf 'a b a\n' | wordfreq --format json 2>&1)
norm5=$(python -c 'import json,sys; print(json.dumps(json.loads(sys.stdin.read()),sort_keys=False,separators=(",",":")))' <<<"$out5" 2>/dev/null || echo "INVALID")
want5='[{"word":"a","count":2},{"word":"b","count":1}]'
if [[ "$norm5" == "$want5" ]]; then echo "PASS json_format"; pass=$((pass+1));
else echo "FAIL json_format got=$(printf '%q' "$norm5") want=$want5"; fi

# 6. Pytest
if pytest -q >/tmp/bench-pytest.log 2>&1; then
  collected=$(grep -Eo '[0-9]+ passed' /tmp/bench-pytest.log | head -1 | grep -Eo '[0-9]+')
  if [[ -n "$collected" && "$collected" -ge 5 ]]; then
    echo "PASS pytest ($collected passed)"; pass=$((pass+1))
  else
    echo "FAIL pytest_count got=${collected:-?} need>=5"
  fi
else
  echo "FAIL pytest see=/tmp/bench-pytest.log"
fi

# 7. Ruff
if ruff check . >/tmp/bench-ruff.log 2>&1; then
  echo "PASS ruff"; pass=$((pass+1))
else
  echo "FAIL ruff see=/tmp/bench-ruff.log head=$(head -1 /tmp/bench-ruff.log)"
fi

deactivate 2>/dev/null || true

echo "SUMMARY $pass/$total"
[[ "$pass" -eq "$total" ]] && exit 0 || exit 1

#!/usr/bin/env bash
# Mechanical verifier for the mdtoc benchmark task (task-b).
# Args: $1 = workspace dir
set -u
ws="${1:-.}"
cd "$ws" || { echo "FAIL workspace_exists $ws"; echo "SUMMARY 0/11"; exit 1; }

pass=0
total=11

venv="$ws/.bench-venv"
[[ -d "$venv" ]] || python3 -m venv "$venv" >/dev/null 2>&1
# shellcheck disable=SC1091
source "$venv/bin/activate"
python -m pip install --quiet --upgrade pip >/dev/null 2>&1

# 1. Install
if python -m pip install -e . >/tmp/bench-install.log 2>&1; then
  echo "PASS installable"; pass=$((pass+1))
else
  echo "FAIL installable see=/tmp/bench-install.log head=$(head -2 /tmp/bench-install.log | tr '\n' '|')"
fi
python -m pip install --quiet pytest >/dev/null 2>&1 || true

# 2. Help
help_out=$(mdtoc --help 2>&1)
if [[ $? -eq 0 && "$help_out" == *"--input"* && "$help_out" == *"--min-level"* && "$help_out" == *"--check"* && "$help_out" == *"--dry-run"* ]]; then
  echo "PASS help_works"; pass=$((pass+1))
else
  echo "FAIL help_works"
fi

# Build sample.md fixture
fixture_dir=$(mktemp -d)
sample="$fixture_dir/sample.md"
cat >"$sample" <<'MD'
# Title

<!-- mdtoc:start -->
<!-- mdtoc:end -->

## Alpha

text

### Alpha sub

text

## Beta

text

### Beta-One

text
MD

expected_toc=$'- [Alpha](#alpha)\n  - [Alpha sub](#alpha-sub)\n- [Beta](#beta)\n  - [Beta-One](#beta-one)'

# 3. Dry-run prints expected TOC
got=$(mdtoc --input "$sample" --dry-run 2>&1)
if [[ "$got" == "$expected_toc"* || "$got" == *"$expected_toc"* ]]; then
  echo "PASS dry_run_toc"; pass=$((pass+1))
else
  echo "FAIL dry_run_toc got=$(printf '%q' "$got")"
fi

# 4. In-place write — file should now contain the toc
mdtoc --input "$sample" >/dev/null 2>&1
content=$(cat "$sample")
if [[ "$content" == *"$expected_toc"* ]]; then
  echo "PASS in_place_write"; pass=$((pass+1))
else
  echo "FAIL in_place_write file=$sample"
fi

# 5. Idempotent
before=$(md5sum "$sample" | awk '{print $1}')
mdtoc --input "$sample" >/dev/null 2>&1
after=$(md5sum "$sample" | awk '{print $1}')
if [[ "$before" == "$after" ]]; then
  echo "PASS idempotent"; pass=$((pass+1))
else
  echo "FAIL idempotent before=$before after=$after"
fi

# 6. --check on drifted file exits 1
drifted="$fixture_dir/drifted.md"
sed 's/Alpha/AlphaXXX/g' "$sample" > "$drifted"
mdtoc --input "$drifted" --check >/dev/null 2>&1
rc=$?
if [[ $rc -eq 1 ]]; then
  echo "PASS check_detects_drift"; pass=$((pass+1))
else
  echo "FAIL check_detects_drift rc=$rc"
fi

# 7. --check on clean file exits 0
mdtoc --input "$sample" --check >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
  echo "PASS check_clean_passes"; pass=$((pass+1))
else
  echo "FAIL check_clean_passes rc=$rc"
fi

# 8. Sentinels missing
nosent="$fixture_dir/nosent.md"
echo "## Heading" > "$nosent"
err=$(mdtoc --input "$nosent" 2>&1)
rc=$?
if [[ $rc -eq 1 && "$err" == *"sentinels not found"* ]]; then
  echo "PASS sentinels_missing"; pass=$((pass+1))
else
  echo "FAIL sentinels_missing rc=$rc err=$(printf '%q' "$err")"
fi

# 9. Slug duplicates
dup="$fixture_dir/dup.md"
cat >"$dup" <<'MD'
# Title
<!-- mdtoc:start -->
<!-- mdtoc:end -->
## Foo
## Foo
MD
mdtoc --input "$dup" >/dev/null 2>&1
dup_content=$(cat "$dup")
if [[ "$dup_content" == *"#foo"* && "$dup_content" == *"#foo-1"* ]]; then
  echo "PASS slug_duplicates"; pass=$((pass+1))
else
  echo "FAIL slug_duplicates content=$(printf '%q' "$dup_content")"
fi

# 10. Tests pass
if pytest -q >/tmp/bench-pytest.log 2>&1; then
  collected=$(grep -Eo '[0-9]+ passed' /tmp/bench-pytest.log | head -1 | grep -Eo '[0-9]+')
  if [[ -n "$collected" && "$collected" -ge 8 ]]; then
    echo "PASS pytest ($collected passed)"; pass=$((pass+1))
  else
    echo "FAIL pytest_count got=${collected:-?} need>=8"
  fi
else
  echo "FAIL pytest see=/tmp/bench-pytest.log"
fi

# 11. Ruff
if ruff check . >/tmp/bench-ruff.log 2>&1; then
  echo "PASS ruff"; pass=$((pass+1))
else
  echo "FAIL ruff see=/tmp/bench-ruff.log head=$(head -1 /tmp/bench-ruff.log)"
fi

deactivate 2>/dev/null || true
rm -rf "$fixture_dir"

echo "SUMMARY $pass/$total"
[[ "$pass" -eq "$total" ]] && exit 0 || exit 1

#!/usr/bin/env bash
# Tests the Aptfile merge logic in bin/buildlib.sh by sourcing the real
# production function and asserting on the Aptfile it produces. Because it
# sources bin/buildlib.sh (not a copy), it catches regressions in the actual
# code used by bin/build.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bin/buildlib.sh
source "${SCRIPT_DIR}/../bin/buildlib.sh"

pass=0
fail=0

# run_merge <aptfile-content|empty> <BP_APT_PACKAGES|empty> <BP_APT_REPOS|empty> -> stdout Aptfile
run_merge() {
  local aptfile_content="$1" bp_packages="$2" bp_repos="$3"
  local workdir
  workdir="$(mktemp -d)"
  if [[ -n "$aptfile_content" ]]; then
    printf '%s\n' "$aptfile_content" > "$workdir/Aptfile"
  fi
  (
    cd "$workdir"
    BP_APT_PACKAGES="$bp_packages" BP_APT_REPOS="$bp_repos" build_effective_aptfile
    cat Aptfile
  )
  rm -rf "$workdir"
}

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name"
    echo "  expected:"
    echo "$expected" | sed 's/^/    /'
    echo "  actual:"
    echo "$actual" | sed 's/^/    /'
    fail=$((fail + 1))
  fi
}

# 1. Physical Aptfile + BP_APT_PACKAGES: entries merged, duplicates removed.
result=$(run_merge $'curl\n:repo:deb http://example/ubuntu artful main' "wget curl" "")
expected=$':repo:deb http://example/ubuntu artful main\ncurl\nwget'
assert_eq "merge Aptfile + BP_APT_PACKAGES dedup" "$expected" "$result"

# 2. Only BP_APT_PACKAGES: whitespace normalized, sorted, deduped.
result=$(run_merge "" "  curl   wget  curl " "")
expected=$'curl\nwget'
assert_eq "BP_APT_PACKAGES only whitespace dedup" "$expected" "$result"

# 3. BP_APT_REPOS with '|' separator split into distinct entries, merged with Aptfile.
result=$(run_merge $'curl' "" ":repo:deb http://example/ubuntu artful main|:repo:key https://example.com/key.gpg")
expected=$':repo:deb http://example/ubuntu artful main\n:repo:key https://example.com/key.gpg\ncurl'
assert_eq "BP_APT_REPOS '|' split + merge" "$expected" "$result"

# 4. All three sources together, full dedup.
result=$(run_merge $'curl\n:repo:key https://example.com/key.gpg' "curl wget" ":repo:deb http://example/ubuntu artful main")
expected=$':repo:deb http://example/ubuntu artful main\n:repo:key https://example.com/key.gpg\ncurl\nwget'
assert_eq "all three sources merged" "$expected" "$result"

# 5. Nothing set: empty result (no participation content).
result=$(run_merge "" "" "")
expected=""
assert_eq "nothing set -> empty" "$expected" "$result"

echo ""
echo "Total: $((pass + fail))  Passed: $pass  Failed: $fail"
[[ "$fail" -eq 0 ]]

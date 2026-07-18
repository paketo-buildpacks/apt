#!/usr/bin/env bash
# Shared buildpack logic, sourced by bin/build and the test suite.
# Not executed directly.

# build_effective_aptfile
# Builds the effective Aptfile in the current working directory by merging a
# physical Aptfile (if present) with the BP_APT_PACKAGES and BP_APT_REPOS
# environment variables, then sorting and de-duplicating the result.
#
# Entries are combined so that a physical Aptfile and the env vars can be used
# together safely:
#   * Physical Aptfile lines are kept as-is.
#   * BP_APT_PACKAGES is a space-separated list of packages.
#   * BP_APT_REPOS is a pipe-separated list ('|' separates entries) of
    #     ':repo:deb' / ':repo:key' lines.
# Blank lines are stripped and the result is sorted + uniq'd.
build_effective_aptfile() {
  local merged_aptfile
  merged_aptfile=$(mktemp)

  # 1. Physical Aptfile (if present)
  if [[ -f Aptfile ]]; then
    cat Aptfile >> "$merged_aptfile"
  fi

  # 2. Packages from BP_APT_PACKAGES (space-separated)
  if [[ -n "${BP_APT_PACKAGES:-}" ]]; then
    echo "${BP_APT_PACKAGES}" | tr -s '[:space:]' '\n' >> "$merged_aptfile"
  fi

  # 3. Repositories/keys from BP_APT_REPOS (pipe-separated; '|' separates entries)
  if [[ -n "${BP_APT_REPOS:-}" ]]; then
    echo "${BP_APT_REPOS}" | tr '|' '\n' >> "$merged_aptfile"
  fi

  # 4. Combine, strip blank lines, sort, and de-duplicate, then write the Aptfile.
  grep -v -s -e '^$' "$merged_aptfile" | sort | uniq > Aptfile
  rm -f "$merged_aptfile"
}

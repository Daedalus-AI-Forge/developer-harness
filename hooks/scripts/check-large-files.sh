#!/usr/bin/env bash
# check-large-files.sh — block commits that stage files over a size threshold.
#
# Measures the STAGED blob (`git cat-file -s :<path>`), not the working-tree
# file, so files tracked by Git LFS pass naturally: their staged blob is the
# tiny LFS pointer, not the asset.
#
# Dependency-free: bash + git (no jq, no stat — `stat` flags differ BSD/GNU).
#
# Env overrides:
#   LARGE_FILE_KB   threshold in KB (default 1024 = 1 MB)
#
# Two ways to run it (same dual-use wiring as secret-scan.sh):
#
#   1. Git pre-commit hook: call it from .git/hooks/pre-commit.
#      Any non-zero exit aborts the commit.
#
#   2. PreToolUse-style agent hook (Claude Code / Codex / Cursor):
#      The agent pipes the hook event JSON to stdin. This script does not
#      parse it — it just drains stdin and inspects the index directly.
#      Exit 2 + stderr = block.
#
# Exit codes: 0 = clean, 2 = a staged file exceeds the threshold (blocking).

set -u

# Drain stdin when piped (agent hooks send JSON); never hang on a terminal.
if [ ! -t 0 ]; then
  cat > /dev/null || true
fi

# Outside a git repo, or nothing staged: nothing to check.
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

threshold_kb="${LARGE_FILE_KB:-1024}"
case "$threshold_kb" in
  ''|*[!0-9]*)
    echo "check-large-files: LARGE_FILE_KB must be a positive integer (got '${threshold_kb}')" >&2
    exit 2
    ;;
esac
limit_bytes=$((threshold_kb * 1024))

found=0
while IFS= read -r -d '' path; do
  # Size of the blob as staged in the index (LFS-tracked files stage a pointer).
  size="$(git cat-file -s ":${path}" 2>/dev/null || echo 0)"
  if [ "$size" -gt "$limit_bytes" ]; then
    if [ "$found" -eq 0 ]; then
      echo "check-large-files: staged files exceed ${threshold_kb} KB:" >&2
      found=1
    fi
    echo "  ${path} ($(( (size + 1023) / 1024 )) KB)" >&2
  fi
done < <(git diff --cached --name-only --diff-filter=ACMR -z 2>/dev/null)

if [ "$found" -ne 0 ]; then
  echo "check-large-files: blocking. Options:" >&2
  echo "  - keep large assets out of git (build artifacts, data dumps belong elsewhere)" >&2
  echo "  - track big binaries with Git LFS: git lfs track '<pattern>' (then re-add)" >&2
  echo "  - if this size is intended, raise the limit: LARGE_FILE_KB=<kb>" >&2
  exit 2
fi

exit 0

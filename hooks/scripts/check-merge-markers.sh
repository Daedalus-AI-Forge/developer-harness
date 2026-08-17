#!/usr/bin/env bash
# check-merge-markers.sh — block commits that stage merge-conflict markers.
#
# Scans only lines being ADDED by this commit for git's conflict markers at
# the start of a line: `<<<<<<< ...` and `>>>>>>> ...` (seven chars, then a
# blank or end of line). A bare `=======` line is deliberately NOT matched —
# it is a legitimate setext/rst heading underline — and every real conflict
# block always contains a `<<<<<<<` and a `>>>>>>>` line, so matching those
# two forms catches any unresolved conflict without that false positive.
# (Same reasoning covers the diff3 `|||||||` base marker: it only ever
# appears between `<<<<<<<` and `>>>>>>>`.)
#
# Dependency-free: bash + git + awk + grep + sed + tr (POSIX awk only; no jq).
#
# Two ways to run it (same dual-use wiring as secret-scan.sh):
#
#   1. Git pre-commit hook: call it from .git/hooks/pre-commit.
#      Any non-zero exit aborts the commit.
#
#   2. PreToolUse-style agent hook (Claude Code / Codex / Cursor):
#      The agent pipes the hook event JSON to stdin. The script reads it just
#      far enough for one narrowing decision (shared logic in
#      lib/commit-payload.sh): a payload whose command is not an actual
#      `git commit` invocation passes immediately, instead of blocking
#      unrelated shell calls on an already-staged conflict marker. No
#      payload, an empty payload, or a payload with no extractable command
#      still scans the staged diff — fail-closed toward checking, which is
#      also what keeps mode 1 working. Exit 2 + stderr = block.
#
# Exit codes: 0 = clean, 2 = conflict markers staged (blocking).

set -u

# Narrow to `git commit` payloads via the shared helper (it reads stdin and
# never hangs on a terminal). If the helper is missing — e.g. this file was
# symlinked into .git/hooks/ or copied out alone — fall back to the old
# drain-and-scan: wrong only in the noisy direction, never the unsafe one.
if . "${BASH_SOURCE[0]%/*}/lib/commit-payload.sh" 2>/dev/null; then
  commit_payload_wants_scan || exit 0
elif [ ! -t 0 ]; then
  cat > /dev/null || true
fi

# Outside a git repo, or nothing staged: nothing to scan.
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

# Walk the staged diff, remembering the current file from the +++ header, and
# print any added line that starts with a conflict marker.
hits="$(
  git diff --cached --unified=0 --no-color 2>/dev/null | awk '
    /^\+\+\+ / { file = substr($0, 5); sub(/^b\//, "", file); next }
    /^\+(<<<<<<<|>>>>>>>)([ \t]|$)/ {
      printf "  %s: %s\n", file, substr($0, 2, 100)
    }
  ' | head -10
)"

if [ -n "$hits" ]; then
  echo "check-merge-markers: staged changes contain merge-conflict markers:" >&2
  printf '%s\n' "$hits" >&2
  echo "check-merge-markers: blocking. Resolve the conflict (edit the file, keep the intended side, delete the marker lines), then re-stage." >&2
  exit 2
fi

exit 0

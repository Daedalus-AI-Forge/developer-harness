#!/usr/bin/env bash
# secret-scan.sh — block commits that stage common credential patterns.
#
# Dependency-free: bash + git + grep (POSIX ERE only; no grep -P, no jq).
#
# Two ways to run it:
#
#   1. Git pre-commit hook:
#        ln -s ../../hooks/scripts/secret-scan.sh .git/hooks/pre-commit
#      Any non-zero exit aborts the commit.
#
#   2. PreToolUse-style agent hook (Claude Code / Codex):
#      The agent pipes the hook event JSON to stdin. This script does not
#      parse it — it just drains stdin and scans the staged diff, which is
#      what a `git commit` is about to publish. Exit 2 + stderr = block.
#
# Exit codes: 0 = clean, 2 = credential-looking content found (blocking).

set -u

# Drain stdin when piped (agent hooks send JSON); never hang on a terminal.
if [ ! -t 0 ]; then
  cat > /dev/null || true
fi

# Outside a git repo, or nothing staged: nothing to scan.
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

# Only lines being ADDED by this commit (strip the +++ file headers).
additions="$(
  git diff --cached --unified=0 --no-color 2>/dev/null \
    | grep -E '^\+' \
    | grep -Ev '^\+\+\+'
)"
[ -n "$additions" ] || exit 0

# One check per label/regex pair (POSIX ERE). q holds a single-quote char so
# the password regex can match both quote styles without escaping gymnastics.
q="'"
labels=(
  "AWS access key ID"
  "Secret key (sk-...)"
  "GitHub token (ghp_...)"
  "PEM private key header"
  "Hardcoded password assignment"
)
regexes=(
  'AKIA[0-9A-Z]{16}'
  'sk-[A-Za-z0-9_-]{20,}'
  'ghp_[A-Za-z0-9]{36}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  "(password|passwd)[[:space:]]*=[[:space:]]*[\"$q][^\"$q]{4,}"
)

found=0
for i in "${!regexes[@]}"; do
  hits="$(printf '%s\n' "$additions" | grep -E -n -e "${regexes[$i]}" | head -5)"
  if [ -n "$hits" ]; then
    if [ "$found" -eq 0 ]; then
      echo "secret-scan: staged changes look like they contain credentials:" >&2
      found=1
    fi
    echo "  [${labels[$i]}]" >&2
    printf '%s\n' "$hits" | cut -c1-120 | sed 's/^/    /' >&2
  fi
done

if [ "$found" -ne 0 ]; then
  echo "secret-scan: blocking. Unstage the secret (git restore --staged <file>) or move it to an ignored env file." >&2
  exit 2
fi

exit 0

#!/usr/bin/env bash
# done-authority-gate.sh — OPT-IN stop gate: refuse "done" until the team's
# declared done-authority has recorded a verdict.
#
# It mechanizes exactly one invariant from the `## Teams` template — "exactly
# one role declares work done" — and nothing else. It does not judge the work,
# read the diff, or run tests; it checks that the one role entitled to say
# "done" has said it, in writing, in the team's status file.
#
# NOT WIRED BY DEFAULT, deliberately: agent teams are experimental, and a gate
# on the stop event of a repo that has no team declared is pure friction. See
# hooks/README.md for the wiring example, and turn it on per repo, per team.
#
# ---------------------------------------------------------------------------
# The convention it greps for — one line, appended to the team's status file
# (the `## Teams` entry's team-memory file, `<team-log>` by default):
#
#     verdict: <role>: <accepted|rejected|blocked> - <one-line reason>
#
# Real examples:
#     verdict: qa-reviewer: accepted - 14 cases executed, evidence in docs/qa/2026-08-16.md
#     verdict: qa-reviewer: rejected - empty-state case fails; see finding 3
#     verdict: release-validator: blocked - no rollback path for the migration
#
# A leading Markdown bullet (`- `, `* `) and backticks or asterisks around the
# words are tolerated, so the line can live inside a normal Markdown log. The
# LAST matching line in the file wins — the log is append-only, and a later
# verdict supersedes an earlier one.
#
# Three outcomes, no synonyms: `accepted` passes, `rejected` and `blocked`
# fail, and any other word is a misconfiguration the gate reports rather than
# guesses at.
# ---------------------------------------------------------------------------
#
# Env (the gate is configuration-driven; there are no defaults to guess):
#   DONE_AUTHORITY_FILE     REQUIRED — path to the team status / handoff file
#   DONE_AUTHORITY_ROLE     REQUIRED — the role holding the done-verdict,
#                           exactly as the `## Teams` entry names it
#   DONE_AUTHORITY_SUBJECT  optional — a literal string the verdict line must
#                           also contain (a branch name, task id, or ticket).
#                           Without it, a stale verdict from a previous round
#                           satisfies the gate; with it, the verdict has to
#                           name what it is a verdict ABOUT.
#   DONE_AUTHORITY_GATE=off explicit disable, for a repo that wires the hook
#                           globally and turns it off per worktree
#
# A missing REQUIRED variable is a BLOCK, not a pass: this script only runs
# where someone wired it on purpose, so "wired but unconfigured" means the
# check did not run, and a check that did not run is never a pass.
#
# Dependency-free: bash + grep + sed + tr.
#
# Exit codes: 0 = the done-authority accepted, 2 = no verdict, a negative
#             verdict, or the gate could not run.

set -u

for tool in grep sed tr; do
  command -v "$tool" > /dev/null 2>&1 || {
    echo "done-authority-gate: CANNOT CHECK — '$tool' not found on PATH; the gate did not run." >&2
    exit 2
  }
done

# Drain stdin when piped (stop-event hooks send JSON); never hang on a terminal.
if [ ! -t 0 ]; then
  cat > /dev/null || true
fi

case "${DONE_AUTHORITY_GATE:-on}" in
  off|OFF|0|false) exit 0 ;;
esac

file="${DONE_AUTHORITY_FILE:-}"
role="${DONE_AUTHORITY_ROLE:-}"
subject="${DONE_AUTHORITY_SUBJECT:-}"

if [ -z "$file" ] || [ -z "$role" ]; then
  echo "done-authority-gate: CANNOT CHECK — this hook is wired but unconfigured." >&2
  echo "  set DONE_AUTHORITY_FILE to the team's status file and DONE_AUTHORITY_ROLE to the role holding the done-verdict," >&2
  echo "  or set DONE_AUTHORITY_GATE=off if this repo declares no team." >&2
  exit 2
fi

if [ ! -f "$file" ]; then
  echo "done-authority-gate: no verdict — the team status file '$file' does not exist." >&2
  echo "  '$role' has not recorded anything, so the work is not done. Append:" >&2
  echo "      verdict: $role: accepted - <one-line reason>" >&2
  exit 2
fi
if [ ! -r "$file" ]; then
  echo "done-authority-gate: CANNOT CHECK — '$file' is not readable; the gate did not run." >&2
  exit 2
fi

# Escape everything that is not alphanumeric/underscore/hyphen so a role name
# is matched literally whatever characters it carries.
esc_role="$(printf '%s' "$role" | sed 's/[^[:alnum:]_-]/\\&/g')"
bullet='([-*+][[:space:]]+)?'
deco='[`*]*'
line_re="^[[:space:]]*${bullet}${deco}verdict${deco}:[[:space:]]*${deco}${esc_role}${deco}[[:space:]]*:[[:space:]]*[[:alpha:]]+"

matches="$(grep -E -e "$line_re" -- "$file" 2>/dev/null)"
grep_rc="$?"
if [ "$grep_rc" -gt 1 ]; then
  echo "done-authority-gate: CANNOT CHECK — grep failed reading '$file'; the gate did not run." >&2
  exit 2
fi

# Any verdict at all, from anyone — used only to make the feedback specific.
others="$(grep -E -e "^[[:space:]]*${bullet}${deco}verdict${deco}:" -- "$file" 2>/dev/null | head -3)"

if [ -n "$subject" ] && [ -n "$matches" ]; then
  matches="$(printf '%s\n' "$matches" | grep -F -e "$subject" || true)"
  if [ -z "$matches" ]; then
    echo "done-authority-gate: no verdict for this subject — '$role' has verdicts on file, but none mentioning '$subject'." >&2
    echo "  A verdict from an earlier round is not a verdict on this one. Append:" >&2
    echo "      verdict: $role: accepted - $subject: <one-line reason>" >&2
    exit 2
  fi
fi

if [ -z "$matches" ]; then
  echo "done-authority-gate: no verdict from the done-authority '$role' in '$file'." >&2
  if [ -n "$others" ]; then
    echo "  Verdicts present from other roles — no other role's verdict substitutes for the done-authority's:" >&2
    printf '%s\n' "$others" | cut -c1-140 | sed 's/^/      /' >&2
  fi
  echo "  Append the verdict line (the LAST one in the file wins):" >&2
  echo "      verdict: $role: accepted - <one-line reason>" >&2
  exit 2
fi

last="$(printf '%s\n' "$matches" | tail -1)"
outcome="$(
  printf '%s' "$last" \
    | sed -E "s/^[[:space:]]*${bullet}${deco}verdict${deco}:[[:space:]]*${deco}${esc_role}${deco}[[:space:]]*:[[:space:]]*//" \
    | sed -E 's/^([[:alpha:]]+).*/\1/' \
    | tr '[:upper:]' '[:lower:]'
)"

case "$outcome" in
  accepted)
    exit 0
    ;;
  rejected|blocked)
    echo "done-authority-gate: '$role' recorded '$outcome' — the work is not done." >&2
    printf '%s\n' "$last" | cut -c1-200 | sed 's/^/      /' >&2
    echo "  Fix what the verdict names, then have '$role' re-run and append a new verdict line. Do not append one on its behalf." >&2
    exit 2
    ;;
  *)
    echo "done-authority-gate: CANNOT CHECK — '$role' recorded an outcome outside the vocabulary (accepted / rejected / blocked):" >&2
    printf '%s\n' "$last" | cut -c1-200 | sed 's/^/      /' >&2
    echo "  Rewrite the line as: verdict: $role: <accepted|rejected|blocked> - <one-line reason>" >&2
    exit 2
    ;;
esac

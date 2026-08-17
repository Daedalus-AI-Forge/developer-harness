# lib/commit-payload.sh — shared payload narrowing for the commit-hygiene
# guards (secret-scan.sh, check-large-files.sh, check-merge-markers.sh,
# quality-gate.sh). Sourced, never executed; defines commit_payload_wants_scan.
#
# Problem this solves: those guards scan the STAGED INDEX, not the payload, so
# under a runtime with no per-hook command narrowing (Codex's PreToolUse has
# only a tool-name matcher and no `if` field —
# https://learn.chatgpt.com/docs/hooks) they used to fire on EVERY shell call.
# With a secret staged, that blocked `git status` and even the
# `git restore --staged <file>` that secret-scan's own remediation text
# recommends: a wedged session with no in-session recovery path. The fix is to
# read the hook payload here and skip the scan for any command that is not an
# actual `git commit`.
#
# Decision table for commit_payload_wants_scan (0 = run the scan, 1 = skip):
#
#   stdin is a tty                     -> scan  (git pre-commit / manual run;
#                                                nothing is read, so no hang)
#   no stdin / empty stdin             -> scan  (pre-commit mode pipes nothing)
#   payload with no extractable        -> scan  (unknown shape: fail closed
#     "command"/"cmd"/"shell_command"            toward checking)
#   command that invokes `git commit`  -> scan
#   command that does not              -> SKIP  (the only skip there is)
#
# "Invokes `git commit`" means: in some `;` / `&&` / `||` / `|` / newline
# separated segment, after env-assignment prefixes (FOO=bar), wrappers (sudo,
# env, xargs, ...) and flags, the command word is `git` (any path to it —
# /usr/bin/git counts), and some later bare token of that segment is exactly
# `commit`. Quoted regions are dropped BEFORE deciding, so prose never
# matches: `echo "time to commit"` and `cat notes-about-commit.md` skip, while
# `git commit -m "fix the commit guard"` still scans. Dropping quotes also
# eats the value of git's value-taking globals (`git -C "a dir" commit`),
# which is why `commit` is accepted anywhere in the git segment rather than
# only in argv[1] position: over-matching (`git log --grep commit` scans)
# costs one needless scan of a clean index; under-matching would let a real
# commit through unscanned. Chosen accordingly.
#
# Known limitation, stated rather than hidden: a commit smuggled inside a
# quoted string (`sh -c "git commit"`) is dropped with the quotes and skips
# the scan. Claude Code's own `"if": "Bash(git commit*)"` narrowing has the
# same blind spot; these guards are a hygiene layer, not an access-control
# boundary (see hooks/README.md), and the git pre-commit wiring — mode 1 in
# each guard's header — still catches whatever actually commits.
#
# Dependency-free: bash + grep + sed + tr (POSIX ERE only; no jq).

# Pull the first "command"-like JSON string out of the payload and decode it.
# Same parking technique as dangerous-command-guard.sh: \\ goes onto a control
# byte first so the later rules cannot re-consume the backslash it produced.
# One deliberate difference: \n and \r decode to NEWLINES, not spaces — in a
# payload command "git status\ngit commit -m x", flattening the newline would
# hide the `git commit` line behind the `git status` command word and cause a
# false SKIP, which is the one direction this helper must never be wrong in.
__cp_extract_command() { # $1 = raw payload; prints the decoded command string
  __cp_raw="$(
    printf '%s' "$1" | tr '\n' ' ' \
      | grep -Eo "\"(command|cmd|shell_command)\"[[:space:]]*:[[:space:]]*\"([^\"\\]|\\\\.)*\"" \
      | head -1
  )"
  [ -n "$__cp_raw" ] || return 0
  __cp_val="$(printf '%s' "$__cp_raw" | sed -e 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//' -e 's/"$//')"
  __cp_esc=$'\001'
  printf '%s' "$__cp_val" | sed \
    -e "s/\\\\\\\\/$__cp_esc/g" \
    -e 's/\\"/"/g' \
    -e 's/\\r\\n/\\n/g' \
    -e 's/\\[nr]/\
/g' \
    -e 's/\\t/ /g' \
    -e 's|\\/|/|g' \
    -e "s/$__cp_esc/\\\\/g"
}

# One already-word-split segment as arguments; 0 iff it is a git-commit shape.
__cp_segment_is_git_commit() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      sudo|doas|env|nohup|nice|ionice|setsid|stdbuf|time|command|builtin|exec|xargs) shift ;;
      -*) shift ;;
      *=*) shift ;;
      *) break ;;
    esac
  done
  [ "$#" -gt 0 ] || return 1
  __cp_name="$1"; __cp_name="${__cp_name##*/}"; shift
  [ "$__cp_name" = git ] || return 1
  while [ "$#" -gt 0 ]; do
    [ "$1" = commit ] && return 0
    shift
  done
  return 1
}

__cp_command_is_git_commit() { # $1 = decoded command string
  # Drop quoted regions wholesale (prose is not a command), then split into
  # segments on newlines and shell separators. `&&`/`||` fall out of the
  # single-char classes; splitting on `(){}` and backticks only ever yields
  # MORE segments to inspect, never fewer.
  __cp_cleaned="$(
    printf '%s\n' "$1" \
      | sed -e 's/"[^"]*"/ /g' -e "s/'[^']*'/ /g" \
      | tr ';|&`(){}' '\n\n\n\n\n\n\n\n'
  )"
  # Globbing off while word-splitting, so a token like `*` stays a token.
  case $- in *f*) __cp_had_f=1 ;; *) __cp_had_f=0; set -f ;; esac
  __cp_hit=1
  while IFS= read -r __cp_seg; do
    [ -n "$__cp_seg" ] || continue
    if __cp_segment_is_git_commit $__cp_seg; then
      __cp_hit=0
      break
    fi
  done <<EOF
$__cp_cleaned
EOF
  [ "$__cp_had_f" -eq 1 ] || set +f
  return "$__cp_hit"
}

# The one entry point. Reads stdin itself (replacing the guards' old
# drain-only block); see the decision table in the header.
commit_payload_wants_scan() {
  [ -t 0 ] && return 0
  __cp_payload="$(cat 2>/dev/null || true)"
  [ -n "$__cp_payload" ] || return 0
  __cp_cmd="$(__cp_extract_command "$__cp_payload")"
  [ -n "$__cp_cmd" ] || return 0
  __cp_command_is_git_commit "$__cp_cmd"
}

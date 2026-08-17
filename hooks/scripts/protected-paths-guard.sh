#!/usr/bin/env bash
# protected-paths-guard.sh — two-tier path protection for file-touching tool
# calls and for shell commands.
#
# Tier 1, ZERO ACCESS (read, write, copy, move — anything): credential stores
# and environment files — ~/.ssh, ~/.aws, ~/.gnupg, ~/.kube, .env, .env.* .
# An agent has no business opening these; a `cat .env` is how a secret gets
# into a transcript, a log, and a model provider in one step. The shipped
# defaults spell the credential stores as bare directory names (.ssh, .aws,
# …) rather than ~/.ssh, so the tier still holds when the hook runtime hands
# the script no HOME — and it then covers a stray .ssh directory anywhere,
# which is the safe direction to be wrong in.
#
# Tier 2, NO DELETE: paths whose components look like a test suite.
# Defaults: test, tests, spec, specs, __tests__ . Deleting a failing test is
# the cheapest way to make a suite green, and this harness's whole method is
# TDD from a failing test — a rule that was previously prose-only. Writes and
# edits to tests are untouched; only deletion is blocked.
#
# Everything else passes. Both tiers are pattern lists, colon-separated, fully
# replaceable per repo (an empty value disables that tier — explicit config,
# not a bypass).
#
# Pattern matching (shell globs, no regex):
#   - a pattern with NO slash matches any single path COMPONENT
#     (`tests` matches src/tests/x.py and tests; `.env.*` matches .env.local)
#   - a pattern WITH a slash matches the path or any prefix-directory of it,
#     and — when the pattern is relative — also any suffix of the path
#     (`a/b` matches a/b, a/b/c, x/a/b)
#   - a leading ~ or $HOME is expanded before matching
#
# Env overrides (colon-separated pattern lists):
#   PPG_ZERO_ACCESS  default: .ssh:.aws:.gnupg:.kube:.env:.env.*
#   PPG_NO_DELETE    default: test:tests:spec:specs:__tests__
#   PPG_ALLOW        exemptions applied to BOTH tiers, default:
#                    .env.example:.env.sample:.env.template:.env.dist:
#                    node_modules:.venv:venv:__pycache__:dist:build:target:
#                    coverage:.git
#                    (env templates carry no secrets; the rest are generated
#                    trees whose test directories are build output, not suite)
#
# Dependency-free: bash + grep + sed + tr (no jq).
#
# Wiring: PreToolUse-style agent hook on BOTH the shell tool and the
# file-touching tools (Read/Write/Edit/NotebookEdit). The agent pipes the hook
# event JSON to stdin; paths are extracted with grep/sed rather than a JSON
# parser. Direct invocation for scripts and tests:
#     protected-paths-guard.sh <path>...
#     protected-paths-guard.sh --command '<shell command>'
#
# FAIL-OPEN on unparseable input, by design and mirroring the platforms: no
# stdin, empty stdin, or a payload with no extractable path or command means
# there is nothing to judge, and the guard exits 0. Treat it as a policy
# layer, never as an access-control boundary — that is the permission
# system's job (see hooks/README.md).
#
# FAIL-LOUD on its own malfunction: a missing core utility means the check did
# not run, which is reported as a block (exit 2), never as a clean pass.
#
# Known limitation, stated rather than hidden: for shell commands, quoted
# regions containing whitespace are dropped before tokenizing, so that prose
# ("git commit -m 'document the .env layout'") does not trip the guard. A path
# that genuinely contains a space is therefore not seen in a shell command;
# the file-tool path is unaffected.
#
# Exit codes: 0 = allowed (or nothing to inspect), 2 = blocked / cannot check.

set -uf   # -f: no pathname expansion, so unquoted word-splitting is safe

for tool in grep sed tr; do
  command -v "$tool" > /dev/null 2>&1 || {
    echo "protected-paths-guard: CANNOT CHECK — '$tool' not found on PATH; the guard did not run." >&2
    exit 2
  }
done

ZERO_ACCESS="${PPG_ZERO_ACCESS-.ssh:.aws:.gnupg:.kube:.env:.env.*}"
NO_DELETE="${PPG_NO_DELETE-test:tests:spec:specs:__tests__}"
ALLOW="${PPG_ALLOW-.env.example:.env.sample:.env.template:.env.dist:node_modules:.venv:venv:__pycache__:dist:build:target:coverage:.git}"

# --- matching --------------------------------------------------------------

expand_home() {
  s="$1"
  case "$s" in
    "~")            [ -n "${HOME:-}" ] && s="$HOME" ;;
    "~/"*)          [ -n "${HOME:-}" ] && s="$HOME/${s#\~/}" ;;
    '$HOME')        [ -n "${HOME:-}" ] && s="$HOME" ;;
    '$HOME/'*)      [ -n "${HOME:-}" ] && s="$HOME/${s#\$HOME/}" ;;
    '${HOME}')      [ -n "${HOME:-}" ] && s="$HOME" ;;
    '${HOME}/'*)    [ -n "${HOME:-}" ] && s="$HOME/${s#\$\{HOME\}/}" ;;
  esac
  printf '%s' "$s"
}

normalize_path() {
  s="$(expand_home "$1")"
  while :; do
    case "$s" in
      ./?*) s="${s#./}" ;;
      *) break ;;
    esac
  done
  case "$s" in
    /) ;;
    */) s="${s%/}" ;;
  esac
  printf '%s' "$s"
}

matches_pattern() { # $1 = normalized path, $2 = single pattern
  mp_path="$1"
  mp_pat="$(expand_home "$2")"
  case "$mp_pat" in
    */) mp_pat="${mp_pat%/}" ;;
  esac
  [ -n "$mp_pat" ] || return 1
  case "$mp_pat" in
    /*)
      case "$mp_path" in $mp_pat|$mp_pat/*) return 0 ;; esac
      ;;
    */*)
      case "$mp_path" in $mp_pat|$mp_pat/*|*/$mp_pat|*/$mp_pat/*) return 0 ;; esac
      ;;
    *)
      mp_old_ifs="$IFS"
      IFS=/
      for mp_c in $mp_path; do
        case "$mp_c" in $mp_pat) IFS="$mp_old_ifs"; return 0 ;; esac
      done
      IFS="$mp_old_ifs"
      ;;
  esac
  return 1
}

matches_list() { # $1 = normalized path, $2 = colon-separated pattern list
  ml_path="$1"; ml_list="$2"
  [ -n "$ml_list" ] || return 1
  ml_old_ifs="$IFS"
  IFS=:
  for ml_pat in $ml_list; do
    if [ -n "$ml_pat" ] && matches_pattern "$ml_path" "$ml_pat"; then
      IFS="$ml_old_ifs"
      MATCHED_PATTERN="$ml_pat"
      return 0
    fi
  done
  IFS="$ml_old_ifs"
  return 1
}

MATCHED_PATTERN=""
reasons=""
block() { reasons="${reasons}  - $1
"; }

check_zero_access() { # $1 = raw path, $2 = short context label
  cza_p="$(normalize_path "$1")"
  [ -n "$cza_p" ] || return 0
  matches_list "$cza_p" "$ALLOW" && return 0
  if matches_list "$cza_p" "$ZERO_ACCESS"; then
    block "$2 '$cza_p' — zero-access tier (\$PPG_ZERO_ACCESS pattern '$MATCHED_PATTERN'); credentials and environment files must not enter an agent transcript"
  fi
}

check_no_delete() { # $1 = raw path, $2 = short context label
  cnd_p="$(normalize_path "$1")"
  [ -n "$cnd_p" ] || return 0
  matches_list "$cnd_p" "$ALLOW" && return 0
  if matches_list "$cnd_p" "$NO_DELETE"; then
    block "$2 '$cnd_p' — no-delete tier (\$PPG_NO_DELETE pattern '$MATCHED_PATTERN'); a failing test is evidence, not an obstacle"
  fi
}

# --- input -----------------------------------------------------------------

unquote() {
  s="$1"
  case "$s" in
    \"*\") s="${s#\"}"; s="${s%\"}" ;;
    \'*\') s="${s#\'}"; s="${s%\'}" ;;
  esac
  printf '%s' "$s"
}

extract_json_strings() { # $1 = payload, $2 = ERE alternation of key names
  printf '%s' "$1" | tr '\n' ' ' \
    | grep -Eo "\"($2)\"[[:space:]]*:[[:space:]]*\"([^\"\\]|\\\\.)*\"" \
    | sed -e 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//' -e 's/"$//' \
    | sed -e 's/\\"/"/g' -e 's|\\/|/|g' -e 's/\\\\/\\/g'
}

paths=""
command_string=""

if [ "$#" -gt 0 ]; then
  case "$1" in
    --command) shift; command_string="$*" ;;
    *) for a in "$@"; do paths="${paths}${a}
"; done ;;
  esac
elif [ ! -t 0 ]; then
  payload="$(cat 2>/dev/null || true)"
  [ -n "$payload" ] || exit 0
  command_string="$(extract_json_strings "$payload" 'command|cmd|shell_command' | head -1)"
  paths="$(extract_json_strings "$payload" 'file_path|filePath|notebook_path|notebookPath|target_file|absolute_path|path')"
fi

# --- file-tool paths -------------------------------------------------------

while IFS= read -r p; do
  [ -n "$p" ] || continue
  check_zero_access "$p" "tool call touches"
done <<EOF
$paths
EOF

# --- shell command ---------------------------------------------------------

if [ -n "$command_string" ]; then
  # Drop quoted regions that contain whitespace: prose in a commit message or
  # an echo is not a path reference. Path-shaped quoted tokens survive.
  cleaned="$(
    printf '%s' "$command_string" | tr '\n\t' '  ' \
      | sed -e 's/"[^"]*[[:space:]][^"]*"/ /g' -e "s/'[^']*[[:space:]][^']*'/ /g"
  )"

  # Sets SCRUBBED rather than echoing: this runs per token on every shell
  # call the agent makes, and a command substitution per token is a fork per
  # token. Strips redirections, --flag= prefixes, and surrounding quotes;
  # blanks anything that is only a flag.
  scrub_token() {
    SCRUBBED="$1"
    case "$SCRUBBED" in
      \"*\") SCRUBBED="${SCRUBBED#\"}"; SCRUBBED="${SCRUBBED%\"}" ;;
      \'*\') SCRUBBED="${SCRUBBED#\'}"; SCRUBBED="${SCRUBBED%\'}" ;;
    esac
    while :; do
      case "$SCRUBBED" in
        '>'*|'<'*) SCRUBBED="${SCRUBBED#?}" ;;
        *) break ;;
      esac
    done
    case "$SCRUBBED" in
      --*=*) SCRUBBED="${SCRUBBED#*=}" ;;
      -*) SCRUBBED="" ;;
    esac
  }

  # Tier 1 applies to every token in the command, whatever the verb.
  for tok in $cleaned; do
    scrub_token "$tok"
    [ -n "$SCRUBBED" ] || continue
    check_zero_access "$SCRUBBED" "command references"
  done

  # Tier 2 applies only to delete-shaped segments.
  check_delete_segment() {
    while [ "$#" -gt 0 ]; do
      tok="$(unquote "$1")"
      case "$tok" in
        sudo|doas|env|nohup|nice|time|command|exec|xargs) shift ;;
        -*) shift ;;
        *=*) shift ;;
        *) break ;;
      esac
    done
    [ "$#" -gt 0 ] || return 0
    name="$(unquote "$1")"; name="${name##*/}"; shift

    deleting=0
    case "$name" in
      rm|unlink|shred|srm) deleting=1 ;;
      git)
        if [ "$#" -gt 0 ] && [ "$(unquote "$1")" = "rm" ]; then deleting=1; shift; fi
        ;;
      find)
        # `-delete`, or `-exec rm …` / `-execdir rm …` — not every -exec.
        prev=""
        for a in "$@"; do
          a="$(unquote "$a")"
          case "$a" in
            -delete) deleting=1 ;;
            rm|/bin/rm|/usr/bin/rm)
              case "$prev" in -exec|-execdir|-ok) deleting=1 ;; esac
              ;;
          esac
          prev="$a"
        done
        ;;
    esac
    [ "$deleting" -eq 1 ] || return 0

    for a in "$@"; do
      scrub_token "$a"
      [ -n "$SCRUBBED" ] || continue
      case "$SCRUBBED" in
        rm) continue ;;
      esac
      check_no_delete "$SCRUBBED" "delete targets"
    done
  }

  segments="$(printf '%s' "$cleaned" | tr ';|&`(){}' '\n\n\n\n\n\n\n\n')"
  while IFS= read -r seg; do
    [ -n "$seg" ] || continue
    check_delete_segment $seg
  done <<EOF
$segments
EOF
fi

# --- verdict ---------------------------------------------------------------

if [ -n "$reasons" ]; then
  echo "protected-paths-guard: blocking this tool call:" >&2
  printf '%s' "$reasons" >&2
  echo "protected-paths-guard: blocking. Read the value from the environment or a secret manager instead of the file; fix the failing test instead of deleting it. Widen \$PPG_ZERO_ACCESS/\$PPG_NO_DELETE/\$PPG_ALLOW deliberately in the repo's config if a default is wrong for this project — do not route around the guard." >&2
  exit 2
fi

exit 0

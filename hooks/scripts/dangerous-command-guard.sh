#!/usr/bin/env bash
# dangerous-command-guard.sh — block the practitioner-consensus "never run
# this" set of shell commands BEFORE the agent executes them.
#
# Blocked classes (each one costs a machine, not a commit):
#   1. rm -r against /, ~, $HOME, ., .., a bare *, a top-level system
#      directory, or a wildcard at root depth (`/*`, `/usr/*`, `~/*`);
#      any `rm --no-preserve-root`; any `sudo rm`.
#   2. chmod recursive 777 / a+rwx, and any 777 on a dangerous root.
#   3. mkfs / mkfs.* / mke2fs — filesystem creation over a live device.
#   4. dd writing to a /dev/ device (of=/dev/...) other than the harmless
#      pseudo-devices (null, zero, random, urandom, std*, tty, fd/*).
#   5. Fork bombs — a function whose body pipes into itself and backgrounds.
#   6. curl/wget piped straight into a shell (`| sh`, `| sudo bash`), or fed
#      to one via `<(curl …)` / `sh -c "$(curl …)"` / `eval "$(wget …)"`.
#
# Precision over reach: patterns are deliberately narrow. A guard that cries
# wolf gets disabled, and a disabled guard protects nothing. Everything else
# — including plain `rm -rf build/`, `chmod 755`, `dd of=./image.iso` — passes.
#
# Dependency-free: bash + grep + sed + tr (POSIX ERE only; no jq, no grep -P).
#
# Wiring: PreToolUse-style agent hook on shell/Bash tool calls. The agent
# pipes the hook event JSON to stdin; this script extracts the command string
# with grep/sed rather than a JSON parser. It can also be called directly with
# the command as arguments — `dangerous-command-guard.sh "rm -rf /"` — which
# is how the OpenCode shim and the tests drive it.
#
# FAIL-OPEN on unparseable input, by design and mirroring the platforms: no
# stdin, empty stdin, or a payload with no extractable command string means
# there is nothing to judge, and the guard exits 0. That is why this script is
# a policy layer, not an access-control boundary — hard allow/deny belongs in
# the runtime's permission system (see hooks/README.md).
#
# FAIL-LOUD on its own malfunction: a missing core utility means the check did
# not run, which is reported as a block (exit 2), never as a clean pass.
#
# Env overrides (additive only — there is deliberately no "off" switch):
#   DCG_EXTRA_PATTERNS   extra POSIX EREs to block, ONE PER LINE — newline
#                        separated, never colon-separated, because a colon is
#                        load-bearing inside classes like [[:space:]]. E.g.
#                        DCG_EXTRA_PATTERNS='terraform[[:space:]]+destroy'
#
# Exit codes: 0 = allowed (or nothing to inspect), 2 = blocked / cannot check.

set -uf   # -f: no pathname expansion, so unquoted word-splitting is safe

for tool in grep sed tr; do
  command -v "$tool" > /dev/null 2>&1 || {
    echo "dangerous-command-guard: CANNOT CHECK — '$tool' not found on PATH; the guard did not run." >&2
    exit 2
  }
done

# --- input -----------------------------------------------------------------

unquote() { # strip one layer of surrounding quotes from a token
  s="$1"
  case "$s" in
    \"*\") s="${s#\"}"; s="${s%\"}" ;;
    \'*\') s="${s#\'}"; s="${s%\'}" ;;
  esac
  printf '%s' "$s"
}

extract_json_string() { # $1 = payload, $2 = ERE alternation of key names
  raw="$(
    printf '%s' "$1" | tr '\n' ' ' \
      | grep -Eo "\"($2)\"[[:space:]]*:[[:space:]]*\"([^\"\\]|\\\\.)*\"" \
      | head -1
  )"
  [ -n "$raw" ] || return 0
  val="$(printf '%s' "$raw" | sed -e 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//' -e 's/"$//')"
  # Unescape enough JSON for pattern matching. \\ is parked on a control byte
  # first so the later rules cannot re-consume the backslash it produced.
  esc=$'\001'
  printf '%s' "$val" | sed \
    -e "s/\\\\\\\\/$esc/g" \
    -e 's/\\"/"/g' \
    -e 's/\\n/ /g' \
    -e 's/\\t/ /g' \
    -e 's/\\r/ /g' \
    -e 's|\\/|/|g' \
    -e "s/$esc/\\\\/g"
}

cmd=""
if [ "$#" -gt 0 ]; then
  cmd="$*"
elif [ ! -t 0 ]; then
  payload="$(cat 2>/dev/null || true)"
  [ -n "$payload" ] || exit 0
  # If the payload names a tool and it is not a shell tool, this guard has no
  # opinion — protected-paths-guard.sh covers the file-touching tools.
  tool_name="$(extract_json_string "$payload" 'tool_name|toolName|tool')"
  if [ -n "$tool_name" ]; then
    case "$tool_name" in
      Bash|bash|Shell|shell|Terminal|terminal|run_terminal_cmd|execute_command|BashOutput) ;;
      *) exit 0 ;;
    esac
  fi
  cmd="$(extract_json_string "$payload" 'command|cmd|shell_command|script')"
fi
[ -n "$cmd" ] || exit 0

norm="$(printf '%s' "$cmd" | tr '\n\t' '  ')"

# --- findings --------------------------------------------------------------

reasons=""
block() { reasons="${reasons}  - $1
"; }

# --- per-segment analysis --------------------------------------------------

DANGEROUS_ROOTS_HELP="/ ~ \$HOME . .. * and top-level system directories"

is_dangerous_target() { # $1 = an unquoted rm/chmod target
  p="$1"
  case "$p" in
    /|/.|/..|"/*"|"/."|.|./|..|../|"*"|"./*"|"../*"|".*") return 0 ;;
    "~"|"~/"|"~/*"|'$HOME'|'$HOME/'|'${HOME}'|'${HOME}/') return 0 ;;
    /bin|/bin/|/sbin|/sbin/|/usr|/usr/|/etc|/etc/|/var|/var/|/lib|/lib/) return 0 ;;
    /lib64|/lib64/|/boot|/boot/|/dev|/dev/|/proc|/proc/|/sys|/sys/) return 0 ;;
    /root|/root/|/home|/home/|/opt|/opt/|/srv|/srv/) return 0 ;;
    /Users|/Users/|/Applications|/Applications/|/Library|/Library/) return 0 ;;
    /System|/System/|/Volumes|/Volumes/) return 0 ;;
  esac
  # $HOME itself, resolved.
  if [ -n "${HOME:-}" ]; then
    case "$p" in "$HOME"|"$HOME/"|"$HOME/*") return 0 ;; esac
  fi
  # A wildcard at root depth: /*, /usr/*, ~/*, $HOME/* — one component deep.
  printf '%s' "$p" | grep -Eq '^(/|~/|\$\{?HOME\}?/)([^/]*/)?\*+/?$' && return 0
  return 1
}

check_rm() {
  recursive=0; nopreserve=0; targets=""
  while [ "$#" -gt 0 ]; do
    a="$(unquote "$1")"; shift
    case "$a" in
      --no-preserve-root) nopreserve=1 ;;
      --recursive|--dir) recursive=1 ;;
      --) : ;;
      --*) : ;;
      -*) case "$a" in *[rR]*) recursive=1 ;; esac ;;
      *) targets="${targets}${a}
" ;;
    esac
  done

  [ "$nopreserve" -eq 1 ] && block "rm --no-preserve-root — the only reason to pass this flag is to delete /"
  if [ "$sudo_used" -eq 1 ]; then
    block "sudo rm — a privileged delete; run the delete unprivileged, or have a human do it deliberately"
  fi

  [ "$recursive" -eq 1 ] || return 0
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    if is_dangerous_target "$t"; then
      block "rm -r '$t' — recursive delete of $DANGEROUS_ROOTS_HELP"
    fi
  done <<EOF
$targets
EOF
}

check_chmod() {
  recursive=0; mode=""; targets=""
  while [ "$#" -gt 0 ]; do
    a="$(unquote "$1")"; shift
    case "$a" in
      --recursive) recursive=1 ;;
      --*) : ;;
      -[Rr]) recursive=1 ;;
      -*) : ;;
      *)
        if [ -z "$mode" ]; then mode="$a"; else targets="${targets}${a}
"; fi
        ;;
    esac
  done

  world_writable=0
  case "$mode" in
    777|0777|a+rwx|a=rwx|ugo+rwx|ugo=rwx) world_writable=1 ;;
  esac
  [ "$world_writable" -eq 1 ] || return 0

  if [ "$recursive" -eq 1 ]; then
    block "chmod -R $mode — recursively world-writable; grant the narrowest mode that works instead"
    return 0
  fi
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    if is_dangerous_target "$t"; then
      block "chmod $mode '$t' — world-writable on a system root"
    fi
  done <<EOF
$targets
EOF
}

check_dd() {
  while [ "$#" -gt 0 ]; do
    a="$(unquote "$1")"; shift
    case "$a" in
      of=/dev/*)
        dev="${a#of=}"
        case "$dev" in
          /dev/null|/dev/zero|/dev/random|/dev/urandom|/dev/stdout|/dev/stderr|/dev/stdin|/dev/tty|/dev/fd/*) ;;
          *) block "dd $a — writing straight to a device node destroys whatever is on it" ;;
        esac
        ;;
    esac
  done
}

analyze_segment() {
  sudo_used=0
  while [ "$#" -gt 0 ]; do
    tok="$(unquote "$1")"
    case "$tok" in
      sudo|doas) sudo_used=1; shift ;;
      -u|--user) shift; [ "$#" -gt 0 ] && shift || true ;;
      env|nohup|nice|ionice|setsid|stdbuf|time|command|builtin|exec) shift ;;
      -*) shift ;;
      *=*) shift ;;
      *) break ;;
    esac
  done
  [ "$#" -gt 0 ] || return 0

  name="$(unquote "$1")"; name="${name##*/}"; shift
  case "$name" in
    rm)                 check_rm "$@" ;;
    chmod)              check_chmod "$@" ;;
    dd)                 check_dd "$@" ;;
    mkfs|mkfs.*|mke2fs) block "$name — creates a filesystem, erasing the target device" ;;
  esac
}

# Split the command into segments on shell separators. Splitting inside quotes
# is possible and harmless: it only produces more segments to inspect, never
# fewer. Segments are word-split by the shell with globbing off (set -f).
segments="$(printf '%s' "$norm" | tr ';|&`(){}' '\n\n\n\n\n\n\n\n')"
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  analyze_segment $seg
done <<EOF
$segments
EOF

# --- whole-command patterns ------------------------------------------------

# Fork bomb: a function whose body pipes into itself and backgrounds. Matching
# on the whitespace-stripped command normalizes `:(){ :|:& };:` and its many
# spaced-out variants; the self-reference test replaces a back-reference,
# which POSIX ERE does not have.
stripped="$(printf '%s' "$cmd" | tr -d ' \t\n')"
defs="$(printf '%s' "$stripped" | grep -Eo '[A-Za-z_.:][A-Za-z0-9_.:]*\(\)\{[^}]*\}' || true)"
while IFS= read -r d; do
  [ -n "$d" ] || continue
  fname="${d%%(*}"
  body="${d#*\{}"; body="${body%\}}"
  case "$body" in
    *"$fname|$fname"*)
      case "$body" in
        *"&"*) block "fork bomb — function '$fname' pipes into itself and backgrounds" ;;
      esac
      ;;
  esac
done <<EOF
$defs
EOF

SHELLS='sh|bash|zsh|ksh|dash|ash|fish|csh|tcsh'
if printf '%s' "$norm" | grep -Eq "(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?([^[:space:]|]+/)?($SHELLS)([[:space:]]|$)"; then
  block "curl/wget piped into a shell — download the script, read it, then run it"
fi
if printf '%s' "$norm" | grep -Eq "($SHELLS)[[:space:]]+([^[:space:]]+[[:space:]]+)*<\((curl|wget)"; then
  block "shell reading a process substitution of curl/wget — same unreviewed remote code, different syntax"
fi
if printf '%s' "$norm" | grep -Eq "(eval|source|\.|($SHELLS)[[:space:]]+-c)[[:space:]]+[^|;]*\\\$\((curl|wget)"; then
  block "remote script evaluated inline (\$(curl …)) — same unreviewed remote code, different syntax"
fi

# Repo-supplied extra patterns, one ERE per line (newline-separated, not
# colon-separated: a colon is load-bearing inside POSIX classes like
# [[:space:]], and splitting there would corrupt every such pattern).
while IFS= read -r pat; do
  [ -n "$pat" ] || continue
  printf '%s' "$norm" | grep -Eq -e "$pat" 2> /dev/null
  rc="$?"
  case "$rc" in
    0) block "matches a \$DCG_EXTRA_PATTERNS rule: '$pat'" ;;
    1) ;;
    *) echo "dangerous-command-guard: CANNOT CHECK — invalid ERE in \$DCG_EXTRA_PATTERNS: '$pat'" >&2
       exit 2 ;;
  esac
done <<EOF
${DCG_EXTRA_PATTERNS:-}
EOF

# --- verdict ---------------------------------------------------------------

if [ -n "$reasons" ]; then
  echo "dangerous-command-guard: blocking this command:" >&2
  printf '%s' "$cmd" | head -c 300 | sed 's/^/    /' >&2
  echo "" >&2
  printf '%s' "$reasons" >&2
  echo "dangerous-command-guard: blocking. Narrow the target, drop the recursive/force flags, or do it by hand outside the agent — do not re-run this with the guard removed." >&2
  exit 2
fi

exit 0

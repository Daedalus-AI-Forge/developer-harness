#!/usr/bin/env bash
# guard-selftest.sh — regression tests for the guard scripts in ../scripts.
#
# What this proves, per guard:
#
#   secret-scan / check-large-files / check-merge-markers / quality-gate:
#     the shared payload narrowing (lib/commit-payload.sh) skips every
#     non-commit shell payload — with offending content STAGED, `git status`
#     and `git restore --staged` still pass (the deadlock the narrowing
#     exists to prevent: the guard's own remediation advice must never be
#     blocked by the guard) — while a `git commit` payload, a bare no-stdin
#     run (git pre-commit mode), and a `git commit -m "prose about commit"`
#     all still scan and block. Quoted prose (`echo "time to commit"`)
#     skips; a commit hiding behind `git status\ngit commit` does not.
#
#   protected-paths-guard:
#     tier-1 zero-access holds for file-tool payloads AND for apply_patch
#     payloads (v4a envelope in tool_input.command, `\n`-escaped); tier-2
#     no-delete catches `*** Delete File:` targets, including a patch fed
#     through the shell as a heredoc; hunk BODY lines never false-block; the
#     documented allow-list (.git, .env.example) still passes.
#
#   dangerous-command-guard: block/pass smoke test.
#
#   tty behavior: guards invoked on a pseudo-terminal with nothing piped
#     return immediately (fail-closed scan for commit guards, fail-open for
#     the path guard) instead of hanging on a stdin read. Exercised via
#     script(1) when available, SKIP otherwise.
#
# All staging happens in a disposable repo under $TMPDIR, created with mktemp
# and removed on exit — never in the repo this script ships in, never in the
# caller's home. Dependency-free: bash + git + the same POSIX tools the
# guards themselves use (no jq). Exit 0 iff every non-skipped case passes.

set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
scripts="$(cd "$here/../scripts" && pwd)" || exit 1

SS="$scripts/secret-scan.sh"
LF="$scripts/check-large-files.sh"
MM="$scripts/check-merge-markers.sh"
QG="$scripts/quality-gate.sh"
PP="$scripts/protected-paths-guard.sh"
DC="$scripts/dangerous-command-guard.sh"

for s in "$SS" "$LF" "$MM" "$QG" "$PP" "$DC"; do
  [ -x "$s" ] || { echo "guard-selftest: missing or non-executable: $s" >&2; exit 1; }
done

# The guards' own knobs must not leak in from the caller's environment, and
# neither may a GIT_DIR pointing at some other repository.
unset PPG_ZERO_ACCESS PPG_NO_DELETE PPG_ALLOW DCG_EXTRA_PATTERNS LARGE_FILE_KB
unset QG_PY_FORMAT QG_PY_LINT QG_PY_TYPECHECK QG_JS_FORMAT QG_JS_LINT \
      QG_JS_TYPECHECK QG_RUST_FORMAT QG_RUST_LINT QG_MAX_ERROR_LINES
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

work="$(mktemp -d "${TMPDIR:-/tmp}/guard-selftest.XXXXXX")" || exit 1
trap 'rm -rf "$work"' EXIT

repo="$work/repo"
git init -q "$repo" || exit 1
cd "$repo" || exit 1
[ -d .git ] || exit 1
git config user.email selftest@example.invalid
git config user.name "guard-selftest"
git config commit.gpgsign false
git commit -q --allow-empty -m "init" || exit 1
mkdir -p sub

pass=0; fail=0; skip=0

record() { # $1 = PASS/FAIL/SKIP, $2 = case name, $3 = detail
  case "$1" in
    PASS) pass=$((pass + 1)) ;;
    FAIL) fail=$((fail + 1)) ;;
    SKIP) skip=$((skip + 1)) ;;
  esac
  printf '%-4s  %-58s  %s\n' "$1" "$2" "$3"
}

check() { # $1 = case name, $2 = expected exit, $3 = stdin payload ("" = </dev/null), rest = argv
  ck_name="$1"; ck_want="$2"; ck_payload="$3"; shift 3
  if [ -n "$ck_payload" ]; then
    printf '%s' "$ck_payload" | "$@" > /dev/null 2> "$work/err"
    ck_got=$?
  else
    "$@" < /dev/null > /dev/null 2> "$work/err"
    ck_got=$?
  fi
  if [ "$ck_got" -eq "$ck_want" ]; then
    record PASS "$ck_name" "exit $ck_got (= want)"
  else
    record FAIL "$ck_name" "want $ck_want, got $ck_got; stderr: $(head -2 "$work/err" | tr '\n' ' ')"
  fi
}

bash_payload() { # $1 = command, with any inner double quotes pre-escaped as \"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"
}

# --- optional pty harness (defect 3: never hang on a terminal) --------------
TTY_STYLE=none
if command -v script > /dev/null 2>&1; then
  if script -q /dev/null true > /dev/null 2>&1 < /dev/null; then
    TTY_STYLE=bsd      # macOS/BSD: script [-q] file command...
  elif script -qec true /dev/null > /dev/null 2>&1 < /dev/null; then
    TTY_STYLE=linux    # util-linux: script -qec 'command' file
  fi
fi

tty_case() { # $1 = case name, $2 = expected exit, rest = argv (run on a pty, nothing piped)
  tc_name="$1"; tc_want="$2"; shift 2
  if [ "$TTY_STYLE" = none ]; then
    record SKIP "$tc_name" "script(1) not usable here; tty path not exercised"
    return
  fi
  tc_rcf="$work/tty-rc"
  rm -f "$tc_rcf"
  tc_inner=""
  for tc_a in "$@"; do tc_inner="$tc_inner $(printf '%q' "$tc_a")"; done
  tc_inner="$tc_inner; echo \$? > $(printf '%q' "$tc_rcf")"
  case "$TTY_STYLE" in
    bsd)   script -q /dev/null bash -c "$tc_inner" ;;
    linux) script -qec "$tc_inner" /dev/null ;;
  esac > /dev/null 2>&1 < /dev/null &
  tc_pid=$!
  tc_i=0
  while kill -0 "$tc_pid" 2> /dev/null; do
    tc_i=$((tc_i + 1))
    if [ "$tc_i" -gt 100 ]; then
      kill -9 "$tc_pid" 2> /dev/null
      wait "$tc_pid" 2> /dev/null
      record FAIL "$tc_name" "HUNG on a tty (killed after ~10s) — the [ -t 0 ] check regressed"
      return
    fi
    sleep 0.1
  done
  wait "$tc_pid" 2> /dev/null
  tc_got="$(tr -d '[:space:]' < "$tc_rcf" 2> /dev/null)"
  if [ "$tc_got" = "$tc_want" ]; then
    record PASS "$tc_name" "exit $tc_got (= want), no hang"
  else
    record FAIL "$tc_name" "want $tc_want, got '${tc_got:-none}'"
  fi
}

echo "== commit guards: secret staged =========================================="
# The fixture line is ASSEMBLED at runtime rather than written literally: this
# file lives in a repo whose own secret-scan hook reads staged additions, and a
# literal credential-shaped line here would make the suite that tests the guard
# the one thing the guard refuses to commit. Split the keyword so the source
# does not match the pattern while the file on disk does.
printf 'pass%s = "hunter2hunter2"\n' 'word' > creds.txt
git add creds.txt

check "secret-scan: git status payload passes"            0 "$(bash_payload 'git status')"                                    "$SS"
check "secret-scan: git restore --staged payload passes"  0 "$(bash_payload 'git restore --staged creds.txt')"                "$SS"
check "secret-scan: git commit payload blocks"            2 "$(bash_payload 'git commit -m \"add config\"')"                  "$SS"
check "secret-scan: bare no-stdin run blocks (pre-commit)" 2 ""                                                               "$SS"
check "secret-scan: commit-in-prose message still blocks" 2 "$(bash_payload 'git commit -m \"mentions commit in prose\"')"    "$SS"
check "secret-scan: quoted prose (echo) skips"            0 "$(bash_payload 'echo \"time to commit\"')"                       "$SS"
check "secret-scan: commit-named file (cat) skips"        0 "$(bash_payload 'cat notes-about-commit.md')"                     "$SS"
check "secret-scan: env prefix + absolute git blocks"     2 "$(bash_payload 'FOO=bar /usr/bin/git commit')"                   "$SS"
check "secret-scan: git -C in && segment blocks"          2 "$(bash_payload 'cd sub && git -C .. commit')"                    "$SS"
check "secret-scan: commit on second payload line blocks" 2 "$(bash_payload 'git status\ngit commit -m wip')"                 "$SS"
check "secret-scan: commit in pipe segment blocks"        2 "$(bash_payload 'echo x | git commit -F -')"                      "$SS"
tty_case "secret-scan: tty, nothing piped — scans, no hang" 2 "$SS"

echo "== commit guards: pre-commit symlink mode ================================"
ln -s "$SS" .git/hooks/pre-commit
check "pre-commit symlink: direct run blocks (lib fallback)" 2 "" .git/hooks/pre-commit
if git -c core.hooksPath=.git/hooks commit -q -m "should be blocked" > /dev/null 2>&1; then
  record FAIL "pre-commit symlink: git commit aborted" "commit succeeded despite staged secret"
  git reset -q HEAD~1 2> /dev/null
else
  record PASS "pre-commit symlink: git commit aborted" "git refused the commit"
fi
rm -f .git/hooks/pre-commit

git reset -q
rm -f creds.txt

echo "== commit guards: large file staged (LARGE_FILE_KB=4) ===================="
: > big.bin
chunk="xxxxxxxxxxxxxxxx"                       # 16 bytes
chunk="$chunk$chunk$chunk$chunk"               # 64
chunk="$chunk$chunk"                           # 128
i=0
while [ "$i" -lt 64 ]; do printf '%s' "$chunk" >> big.bin; i=$((i + 1)); done   # 8 KB
git add big.bin

check "check-large-files: git status payload passes"       0 "$(bash_payload 'git status')"                                 env LARGE_FILE_KB=4 "$LF"
check "check-large-files: git restore --staged passes"     0 "$(bash_payload 'git restore --staged big.bin')"               env LARGE_FILE_KB=4 "$LF"
check "check-large-files: git commit payload blocks"       2 "$(bash_payload 'git commit -m \"add data\"')"                 env LARGE_FILE_KB=4 "$LF"
check "check-large-files: bare no-stdin run blocks"        2 ""                                                             env LARGE_FILE_KB=4 "$LF"
check "check-large-files: commit-in-prose still blocks"    2 "$(bash_payload 'git commit -m \"mentions commit in prose\"')" env LARGE_FILE_KB=4 "$LF"

git reset -q
rm -f big.bin

echo "== commit guards: merge markers staged ==================================="
printf '<<<<<<< HEAD\nours\n=======\ntheirs\n>>>>>>> branch\n' > conflict.txt
git add conflict.txt

check "check-merge-markers: git status payload passes"     0 "$(bash_payload 'git status')"                                 "$MM"
check "check-merge-markers: git restore --staged passes"   0 "$(bash_payload 'git restore --staged conflict.txt')"          "$MM"
check "check-merge-markers: git commit payload blocks"     2 "$(bash_payload 'git commit -m \"merge\"')"                    "$MM"
check "check-merge-markers: bare no-stdin run blocks"      2 ""                                                             "$MM"
check "check-merge-markers: commit-in-prose still blocks"  2 "$(bash_payload 'git commit -m \"mentions commit in prose\"')" "$MM"

git reset -q
rm -f conflict.txt

echo "== commit guards: clean index ============================================"
check "secret-scan: clean index, commit payload passes"    0 "$(bash_payload 'git commit -m \"ok\"')"  "$SS"
check "secret-scan: clean index, bare run passes"          0 ""                                        "$SS"
check "check-large-files: clean index, commit passes"      0 "$(bash_payload 'git commit -m \"ok\"')"  env LARGE_FILE_KB=4 "$LF"
check "check-merge-markers: clean index, commit passes"    0 "$(bash_payload 'git commit -m \"ok\"')"  "$MM"
check "quality-gate: git status payload passes (narrowed)" 0 "$(bash_payload 'git status')"            "$QG"
check "quality-gate: clean index, commit payload passes"   0 "$(bash_payload 'git commit -m \"ok\"')"  "$QG"
check "quality-gate: clean index, bare run passes"         0 ""                                        "$QG"

echo "== protected-paths-guard ================================================="
check "protected-paths: Write payload for .env blocks"     2 '{"tool_name":"Write","tool_input":{"file_path":".env","content":"X"}}' "$PP"
check "protected-paths: apply_patch adding .env blocks"    2 '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Add File: .env\n+SECRET=1\n*** End Patch"}}' "$PP"
check "protected-paths: apply_patch deleting test blocks"  2 '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Delete File: tests/test_x.py\n*** End Patch"}}' "$PP"
check "protected-paths: apply_patch move-to .env blocks"   2 '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: config.txt\n*** Move to: .env\n*** End Patch"}}' "$PP"
check "protected-paths: apply_patch on src/main.py passes" 0 '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: src/main.py\n@@\n+x = 1\n*** End Patch"}}' "$PP"
check "protected-paths: apply_patch .env.example passes (allow)" 0 '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Add File: .env.example\n+SECRET=\n*** End Patch"}}' "$PP"
check "protected-paths: heredoc patch via Bash blocks delete" 2 "$(bash_payload 'apply_patch <<EOF\n*** Begin Patch\n*** Delete File: tests/test_a.py\n*** End Patch\nEOF')" "$PP"
check "protected-paths: hunk body naming .env passes"      0 "$(bash_payload 'apply_patch <<EOF\n*** Begin Patch\n*** Update File: README.md\n@@\n+copy .env.example to .env\n*** End Patch\nEOF')" "$PP"
check "protected-paths: Write payload for .git/config passes" 0 '{"tool_name":"Write","tool_input":{"file_path":".git/config","content":"X"}}' "$PP"
check "protected-paths: rm -rf .git/tests passes (.git allow)" 0 "$(bash_payload 'rm -rf .git/tests')" "$PP"
check "protected-paths: rm -rf tests via shell blocks"     2 "$(bash_payload 'rm -rf tests')" "$PP"
tty_case "protected-paths: tty, nothing piped — fail-open, no hang" 0 "$PP"

echo "== dangerous-command-guard (smoke) ======================================="
check "dangerous-command: rm -rf / blocks"                 2 "$(bash_payload 'rm -rf /')"   "$DC"
check "dangerous-command: ls -la passes"                   0 "$(bash_payload 'ls -la')"     "$DC"

echo "=========================================================================="
printf 'guard-selftest: %d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skip"
[ "$fail" -eq 0 ] || exit 1
exit 0

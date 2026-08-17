# Template: "## Guards" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md`, then replace the
placeholder rows with the guard scripts that repo actually vendors (see
`hooks/` in developer-harness).

---

## Guards

This repo runs guard scripts around risky actions. They exit non-zero with a
reason on stderr when they block; do not bypass or disable them — fix the
underlying issue instead, or ask the user how to proceed.

| Guard script | Runs | Blocks when |
| --- | --- | --- |
| `<relative/path/to/secret-scan.sh>` | Before `git commit` (agent hook and/or git pre-commit) | Staged additions match credential patterns (AWS keys, `sk-` keys, `ghp_` tokens, PEM private keys, hardcoded passwords) |
| `<relative/path/to/check-large-files.sh>` | Before `git commit` | A staged blob exceeds the size limit (default 1 MB; `LARGE_FILE_KB` overrides) — use Git LFS for big assets |
| `<relative/path/to/check-merge-markers.sh>` | Before `git commit` | Staged additions contain `<<<<<<<` / `>>>>>>>` conflict markers |
| `<relative/path/to/quality-gate.sh>` | Before `git commit` | A configured format/lint/type check fails for the staged files' languages (ruff · pyright/mypy · biome/prettier+eslint · tsc · cargo fmt/clippy); missing tools are skipped with a notice, never silently |
| `<relative/path/to/dangerous-command-guard.sh>` | PreToolUse on every shell call | The command matches the destructive set (`rm -r` on `/` `~` `.` `..` or root-depth wildcards, `--no-preserve-root`, `sudo rm`, recursive `chmod 777`, `mkfs`, `dd` onto a device, fork bombs, curl-piped-to-shell); extend via `DCG_EXTRA_PATTERNS` |
| `<relative/path/to/protected-paths-guard.sh>` | PreToolUse on file-touching and shell calls | A zero-access path is touched or a no-delete path is deleted — tier lists are env-bound (`PPG_ZERO_ACCESS` / `PPG_NO_DELETE` / `PPG_ALLOW`), so declare what this repo actually protects |
| `<relative/path/to/guard.sh>` | `<when it runs>` | `<what it blocks>` |

Before committing, assume these guards will run; keep secrets in ignored env
files so they never reach the staged diff, and fix quality-gate failures at
the source — never by disabling the check.

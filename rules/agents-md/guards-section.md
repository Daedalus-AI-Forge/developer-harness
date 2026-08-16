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
| `<relative/path/to/guard.sh>` | `<when it runs>` | `<what it blocks>` |

Before committing, assume these guards will run; keep secrets in ignored env
files so they never reach the staged diff.

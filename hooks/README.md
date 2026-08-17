# hooks/

Tool-neutral guard scripts plus per-tool wiring templates. The scripts in
[`scripts/`](scripts/) read whatever JSON arrives on stdin, inspect the
repository directly (e.g. `git diff --cached`), and signal a block with
**exit code 2 + a reason on stderr** — the convention shared by Claude Code,
Codex, and Cursor hooks, and compatible with plain git hooks (any non-zero
exit aborts a git hook).

Current scripts:

| Script | What it does | Blocks when |
| --- | --- | --- |
| `scripts/secret-scan.sh` | Scans staged additions (`git diff --cached`) for AWS `AKIA...` keys, `sk-...` keys, GitHub `ghp_...` tokens, PEM private-key headers, and hardcoded `password=` assignments | Any pattern matches (exit 2) |
| `scripts/check-large-files.sh` | Measures every staged blob (`git cat-file -s`); LFS-tracked files pass naturally because their staged blob is the pointer | A staged file exceeds 1 MB (override: `LARGE_FILE_KB=<kb>`) |
| `scripts/check-merge-markers.sh` | Scans staged additions for `<<<<<<<` / `>>>>>>>` conflict markers at line start; a bare `=======` is deliberately ignored (setext/rst underlines), which is safe because every real conflict contains the other two markers | A conflict marker is being committed |
| `scripts/quality-gate.sh` | Detects the repo's language lanes (pyproject.toml → Python, package.json → JS/TS, Cargo.toml → Rust) and runs the canonical fast checks over staged files: `ruff format --check` + `ruff check` (via `uv run`/`uvx`), pyright/mypy **if configured**, biome **or** prettier `--check` + eslint **if configured**, `tsc --noEmit` if tsconfig.json, `cargo fmt --check` + `cargo clippy` | A configured check fails; a tool that is missing or unconfigured is skipped **with a notice on stderr**, never silently |

The secret-scan patterns cover exactly the class of leak that work-tracker
access invites (PATs, API keys): tracker credentials belong in env vars or
the OS keychain per the Auth note in the `## Project bindings` template
(`rules/agents-md/project-bindings-section.md`), never in tracked files.
secret-scan is a lightweight pattern gate; when a repo wants entropy-based
scanning with allowlists/baselines, layer
[gitleaks](https://github.com/gitleaks/gitleaks) or
[detect-secrets](https://github.com/Yelp/detect-secrets) on top — the norm
is gitleaks for fast pre-commit blocking, detect-secrets for legacy repos
that need a baseline.

## Which hook when

Pre-commit is for gates that finish in seconds; anything slower trains
people (and agents) to bypass it. The consensus — the
[pre-commit framework](https://pre-commit.com/) itself, and
[Thoughtworks' pre-commit guidance](https://www.thoughtworks.com/en-us/insights/blog/pre-commit-don-t-git-hooked) —
is quick lints at commit time, the full suite later:

| Check | Belongs | Why |
| --- | --- | --- |
| secret-scan, large files, merge markers | pre-commit | milliseconds; every commit |
| format/lint (`ruff`, `biome`/`prettier`+`eslint`, `cargo fmt`) | pre-commit | seconds; auto-fixable |
| type check (`pyright`/`mypy`, `tsc --noEmit`) | pre-commit if fast, else pre-push | project-wide, can grow |
| full `<test-command>` suite | pre-push / CI | too slow for commit cadence; a slow gate is a skipped gate |

## quality-gate.sh knobs

Every default can be re-bound or disabled per repo — align these with the
`<lint-command>`-style bindings in the consuming repo's AGENTS.md:

| Env var | Default | `off` disables |
| --- | --- | --- |
| `QG_PY_FORMAT` | `ruff format --check <staged .py>` via `uv run` (uv.lock) / `uvx` / PATH | yes |
| `QG_PY_LINT` | `ruff check <staged .py>` | yes |
| `QG_PY_TYPECHECK` | `pyright` if pyrightconfig.json/`[tool.pyright]`; `mypy` if `[tool.mypy]`/mypy.ini (never via `uvx` — isolated env lacks project deps) | yes |
| `QG_JS_FORMAT` | `npx prettier --check <staged>` if configured (skipped when biome.json rules) | yes |
| `QG_JS_LINT` | `npx biome check <staged>` if biome.json, else `npx eslint <staged>` if configured | yes |
| `QG_JS_TYPECHECK` | `npx tsc --noEmit` if tsconfig.json + staged TS | yes |
| `QG_RUST_FORMAT` | `cargo fmt --all -- --check` | yes |
| `QG_RUST_LINT` | `cargo clippy --all-targets -- -D warnings` (compiles the crate; turn off if too slow) | yes |
| `QG_MAX_ERROR_LINES` | 15 failure lines shown per check | — |

Set a var to a command string to replace the default entirely (runs via
`sh -c` from the repo root; the staged file list is not appended).

## Wiring files: why two dialects

There is deliberately **no `hooks/hooks.json`** in this repo. Both Claude
Code and Codex auto-discover that exact path inside a plugin and parse it
with their own schema (Claude supports an `if` narrowing field; Codex does
not), so a single shared file at the magnet path would be wrong for one of
them. Instead:

- [`claude.hooks.json`](claude.hooks.json) — Claude dialect
  (`${CLAUDE_PLUGIN_ROOT}`, `if: "Bash(git commit*)"` narrowing), declared
  explicitly via the `"hooks"` field in `.claude-plugin/plugin.json`
  ([plugins reference](https://code.claude.com/docs/en/plugins-reference)).
- [`codex.hooks.json`](codex.hooks.json) — Codex dialect (`${PLUGIN_ROOT}`,
  no `if`; the scripts' own no-op guards and quality-gate's stdin narrowing
  replace it), declared via the `"hooks"` field in
  `.codex-plugin/plugin.json`
  ([Codex plugin docs](https://developers.openai.com/codex/plugins/build)).

All four scripts are wired in both files, in the same order the table above
lists them.

## a) Claude Code

Two options ([hooks docs](https://code.claude.com/docs/en/hooks)):

- **Via the plugin**: install this repo as a plugin;
  `.claude-plugin/plugin.json` declares `hooks/claude.hooks.json`, and
  `${CLAUDE_PLUGIN_ROOT}` resolves to the installed plugin directory
  ([plugins docs](https://code.claude.com/docs/en/plugins)).
- **Standalone**: copy the scripts into your repo and add to
  `.claude/settings.json` (the `if` field narrows matching using permission
  rule syntax; omit it to run on every Bash call). One entry per script,
  same shape:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(git commit*)",
            "command": "${CLAUDE_PROJECT_DIR}/hooks/scripts/secret-scan.sh"
          },
          {
            "type": "command",
            "if": "Bash(git commit*)",
            "command": "${CLAUDE_PROJECT_DIR}/hooks/scripts/check-large-files.sh"
          },
          {
            "type": "command",
            "if": "Bash(git commit*)",
            "command": "${CLAUDE_PROJECT_DIR}/hooks/scripts/check-merge-markers.sh"
          },
          {
            "type": "command",
            "if": "Bash(git commit*)",
            "command": "${CLAUDE_PROJECT_DIR}/hooks/scripts/quality-gate.sh"
          }
        ]
      }
    ]
  }
}
```

Exit 2 blocks the tool call; stderr becomes the blocking reason shown to Claude.
If a Claude Code version ignores the `if` narrowing, the hooks simply run on
every Bash call — harmless, because every script exits 0 whenever nothing is
staged, and quality-gate additionally passes straight through on payloads
that are not a `git commit`.

## b) Codex

Codex CLI uses the same schema family in `<repo>/.codex/hooks.json` or
`~/.codex/hooks.json` ([hooks docs](https://developers.openai.com/codex/hooks),
now hosted at [learn.chatgpt.com/docs/hooks](https://learn.chatgpt.com/docs/hooks)):
same `hooks` → `PreToolUse` → `matcher` → `hooks[]` nesting, same
exit-2-plus-stderr blocking. For standalone (non-plugin) use, copy the shape
of [`codex.hooks.json`](codex.hooks.json) into `.codex/hooks.json`, replacing
`${PLUGIN_ROOT}` with a repo-relative path such as
`hooks/scripts/secret-scan.sh`. Codex has no `if` field — the scripts no-op
when nothing is staged, and quality-gate skips non-commit payloads on its
own. Hooks are feature-gated in `~/.codex/config.toml` (`[features]`
`hooks`), and Codex asks you to review and trust each non-managed hook
(`/hooks` in the TUI) before it runs. When installed as a plugin, Codex
would also auto-discover a `hooks/hooks.json`; this repo intentionally
ships none (see "Wiring files" above) and declares
`hooks/codex.hooks.json` in `.codex-plugin/plugin.json` instead.

## c) Cursor

Cursor uses its own schema in `.cursor/hooks.json`
([hooks docs](https://cursor.com/docs/agent/hooks)): a required `"version": 1`
and camelCase event names. `beforeShellExecution` fires before any shell
command; a hook can block by printing `{"permission": "deny"}` or simply by
exiting 2, which these scripts do:

```json
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      { "command": "hooks/scripts/secret-scan.sh" },
      { "command": "hooks/scripts/check-large-files.sh" },
      { "command": "hooks/scripts/check-merge-markers.sh" },
      { "command": "hooks/scripts/quality-gate.sh" }
    ]
  }
}
```

## d) OpenCode

OpenCode has no hooks.json; it uses JS plugins in `.opencode/plugins/`
([plugins docs](https://opencode.ai/docs/plugins/)). A short shim that runs
the guards before `git commit` bash calls and blocks by throwing:

```js
// .opencode/plugins/guards.js
const GUARDS = [
  "hooks/scripts/secret-scan.sh",
  "hooks/scripts/check-large-files.sh",
  "hooks/scripts/check-merge-markers.sh",
  "hooks/scripts/quality-gate.sh",
]

export const Guards = async ({ $ }) => ({
  "tool.execute.before": async (input, output) => {
    if (input.tool !== "bash") return
    if (!/git\s+commit/.test(output.args?.command ?? "")) return
    for (const guard of GUARDS) {
      const r = await $`bash ${guard} < /dev/null`.nothrow().quiet()
      if (r.exitCode !== 0) throw new Error(r.stderr.toString())
    }
  },
})
```

The `git commit` narrowing must live in the JS here: OpenCode has no
declarative matcher, and the shim feeds each guard `< /dev/null` — empty
stdin is exactly the case where quality-gate fail-closes toward running its
toolchains (its own payload-based narrowing never sees a payload), so
without the regex every bash call would pay for a full lint/type-check
pass. The three cheap guards tolerate broader wiring (they no-op in
milliseconds when nothing is staged), but the example keeps all four behind
the same narrowing — one shape, least surprise.

## e) Plain git (no agent)

A single script can still be symlinked directly, but git supports only one
`pre-commit` file, so with all four guards use a two-line driver:

```bash
cat > .git/hooks/pre-commit <<'SH'
#!/bin/sh
for guard in secret-scan check-large-files check-merge-markers quality-gate; do
  hooks/scripts/$guard.sh < /dev/null || exit $?
done
SH
chmod +x .git/hooks/pre-commit
```

(Git runs hooks from the repo top level, so the relative path holds.) Works
for human commits too — the scripts detect a terminal and skip the stdin
drain.

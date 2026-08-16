# hooks/

Tool-neutral guard scripts plus a wiring template. The scripts in
[`scripts/`](scripts/) read whatever JSON arrives on stdin, inspect the
repository directly (e.g. `git diff --cached`), and signal a block with
**exit code 2 + a reason on stderr** — the convention shared by Claude Code,
Codex, and Cursor hooks, and compatible with plain git hooks (any non-zero
exit aborts a git hook).

Current scripts:

| Script | What it does | Blocks when |
| --- | --- | --- |
| `scripts/secret-scan.sh` | Scans staged additions (`git diff --cached`) for AWS `AKIA...` keys, `sk-...` keys, GitHub `ghp_...` tokens, PEM private-key headers, and hardcoded `password=` assignments | Any pattern matches (exit 2) |

[`hooks.json`](hooks.json) is the wiring template in the Claude Code plugin
hook schema (`hooks` → event → `matcher` → `hooks[]`). JSON has no comments,
so all explanation lives here.

## a) Claude Code

Two options ([hooks docs](https://code.claude.com/docs/en/hooks)):

- **Via the plugin**: install this repo as a plugin and `hooks/hooks.json` is
  picked up automatically; `${CLAUDE_PLUGIN_ROOT}` resolves to the installed
  plugin directory ([plugins docs](https://code.claude.com/docs/en/plugins)).
- **Standalone**: copy the script into your repo and add to
  `.claude/settings.json` (the `if` field narrows matching using permission
  rule syntax; omit it to run on every Bash call):

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
          }
        ]
      }
    ]
  }
}
```

Exit 2 blocks the tool call; stderr becomes the blocking reason shown to Claude.

## b) Codex

Codex CLI uses the same schema family in `<repo>/.codex/hooks.json` or
`~/.codex/hooks.json` ([hooks docs](https://developers.openai.com/codex/hooks),
now hosted at [learn.chatgpt.com/docs/hooks](https://learn.chatgpt.com/docs/hooks)):
same `hooks` → `PreToolUse` → `matcher` → `hooks[]` nesting, same
exit-2-plus-stderr blocking. Copy the JSON above into `.codex/hooks.json`,
replacing `${CLAUDE_PROJECT_DIR}` with a repo-relative path such as
`hooks/scripts/secret-scan.sh` (the Claude-specific `if` field is not in the
Codex docs — drop it and let the script no-op when nothing is staged).
Hooks are feature-gated in `~/.codex/config.toml` (`[features]` `hooks`), and
Codex asks you to review and trust each non-managed hook (`/hooks` in the TUI)
before it runs.

## c) Cursor

Cursor uses its own schema in `.cursor/hooks.json`
([hooks docs](https://cursor.com/docs/agent/hooks)): a required `"version": 1`
and camelCase event names. `beforeShellExecution` fires before any shell
command; a hook can block by printing `{"permission": "deny"}` or simply by
exiting 2, which this script does:

```json
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      { "command": "hooks/scripts/secret-scan.sh" }
    ]
  }
}
```

## d) OpenCode

OpenCode has no hooks.json; it uses JS plugins in `.opencode/plugins/`
([plugins docs](https://opencode.ai/docs/plugins/)). A short shim that runs
the script before bash tool calls and blocks by throwing:

```js
// .opencode/plugins/secret-scan.js
export const SecretScan = async ({ $ }) => ({
  "tool.execute.before": async (input) => {
    if (input.tool !== "bash") return
    const r = await $`bash hooks/scripts/secret-scan.sh < /dev/null`
      .nothrow().quiet()
    if (r.exitCode !== 0) throw new Error(r.stderr.toString())
  },
})
```

## e) Plain git (no agent)

```bash
ln -s ../../hooks/scripts/secret-scan.sh .git/hooks/pre-commit
```

Works for human commits too — the script detects a terminal and skips the
stdin drain.

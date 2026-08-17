# hooks/

Tool-neutral guard scripts plus per-tool wiring templates. The scripts in
[`scripts/`](scripts/) read whatever JSON arrives on stdin, inspect the
repository directly (e.g. `git diff --cached`), and signal a block with
**exit code 2 + a reason on stderr** — the convention shared by Claude Code,
Codex, and Cursor hooks, and compatible with plain git hooks (any non-zero
exit aborts a git hook).

Every script is dependency-free (bash + git + POSIX text tools; no jq, no
`grep -P`), works dropped into any repository, and takes its configuration
from environment variables with generic defaults.

Two failure modes, kept distinct on purpose:

- **cannot check** — the script could not do its job (a missing utility, an
  unreadable file, an invalid setting). It exits **2** and says
  `CANNOT CHECK`. A check that did not run is never reported as a pass.
- **fail open** — there was nothing to judge (empty stdin, a tool payload with
  no command or path in it). It exits **0**. This mirrors what the platforms
  themselves do with unparseable input, and it is why hooks are a policy
  layer rather than a security boundary; see
  [Three things to know before wiring](#three-things-to-know-before-wiring).

## The guard set

| Layer | Script | What it does | Blocks when |
| --- | --- | --- | --- |
| Safety | `scripts/dangerous-command-guard.sh` | Inspects the shell command in a PreToolUse payload for the practitioner-consensus destructive set: `rm -r` against `/`, `~`, `$HOME`, `.`, `..`, a bare `*`, a top-level system directory or a root-depth wildcard; `--no-preserve-root`; any `sudo rm`; recursive `chmod 777`/`a+rwx`; `mkfs`; `dd of=/dev/<device>`; fork bombs; curl/wget piped into a shell | A pattern matches (exit 2) |
| Safety | `scripts/protected-paths-guard.sh` | Two tiers over file-tool paths and shell commands — **zero access** (`.ssh`, `.aws`, `.gnupg`, `.kube`, `.env`, `.env.*`) and **no delete** (`test`, `tests`, `spec`, `specs`, `__tests__`) | A tool touches a zero-access path, or a delete-shaped command targets a no-delete path |
| Commit | `scripts/secret-scan.sh` | Scans staged additions (`git diff --cached`) for AWS `AKIA...` keys, `sk-...` keys, GitHub `ghp_...` tokens, PEM private-key headers, and hardcoded `password=` assignments | Any pattern matches |
| Commit | `scripts/check-large-files.sh` | Measures every staged blob (`git cat-file -s`); LFS-tracked files pass naturally because their staged blob is the pointer | A staged file exceeds 1 MB (override: `LARGE_FILE_KB=<kb>`) |
| Commit | `scripts/check-merge-markers.sh` | Scans staged additions for `<<<<<<<` / `>>>>>>>` conflict markers at line start; a bare `=======` is deliberately ignored (setext/rst underlines), which is safe because every real conflict contains the other two markers | A conflict marker is being committed |
| Commit | `scripts/quality-gate.sh` | Detects the repo's language lanes (pyproject.toml → Python, package.json → JS/TS, Cargo.toml → Rust) and runs the canonical fast checks over staged files: `ruff format --check` + `ruff check` (via `uv run`/`uvx`), pyright/mypy **if configured**, biome **or** prettier `--check` + eslint **if configured**, `tsc --noEmit` if tsconfig.json, `cargo fmt --check` + `cargo clippy` | A configured check fails; a tool that is missing or unconfigured is skipped **with a notice on stderr**, never silently |
| Repo hygiene *(opt-in)* | `scripts/instruction-scan.sh` | Scans instruction-bearing files (`skills/`, `rules/`, `agents/`, `commands/`, root Markdown) for invisible-Unicode injection vectors — Unicode Tag characters, zero-width characters, bidi overrides and isolates — as UTF-8 byte sequences under `LC_ALL=C` | Any invisible character is found in scope |
| Repo hygiene *(opt-in)* | `scripts/agents-md-budget.sh` | Computes the largest AGENTS.md **chain** a working directory would be handed (root file plus every nested one on the path), using staged sizes inside a git repo | The chain exceeds 32768 bytes; warns from 24576 |
| Team *(opt-in)* | `scripts/done-authority-gate.sh` | Stop-event gate: refuses "done" unless the team's declared done-authority has appended `verdict: <role>: accepted - …` to the team status file | No verdict, a stale verdict, or a `rejected`/`blocked` one |

The first six are wired by default in
[`claude.hooks.json`](claude.hooks.json) and
[`codex.hooks.json`](codex.hooks.json). The last three are **not** — they are
opt-ins with their own wiring section below, because a repo-hygiene scan
belongs in CI and a team gate belongs only where a team is declared.

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
| dangerous-command, protected-paths | agent PreToolUse only | they judge a tool call that has not happened yet; there is no commit to attach them to |
| secret-scan, large files, merge markers | pre-commit | milliseconds; every commit |
| instruction-scan (staged mode) | pre-commit | milliseconds on the few instruction files a commit touches |
| format/lint (`ruff`, `biome`/`prettier`+`eslint`, `cargo fmt`) | pre-commit | seconds; auto-fixable |
| type check (`pyright`/`mypy`, `tsc --noEmit`) | pre-commit if fast, else pre-push | project-wide, can grow |
| instruction-scan `--all`, agents-md-budget | CI | whole-tree passes, and the budget is a property of the repo, not of one commit |
| full `<test-command>` suite | pre-push / CI | too slow for commit cadence; a slow gate is a skipped gate |

## Three things to know before wiring

**1. A hook is a policy layer, not an access-control boundary.** Every
command filter here — the platforms' own `if`/matcher narrowing included — is
best-effort string matching over a payload, and every one of these scripts
fails open when it cannot parse what it was handed. Obfuscation, an unusual
quoting style, or a payload shape the extractor does not recognize all end in
"no opinion", which means "allowed". Put hard allow/deny in the runtime's
**permission system** (Claude Code permissions, Codex sandbox and approval
policy, Cursor's command allowlist) and use these hooks as the policy layer
on top: the permission system decides what the agent *may* do, the hooks
decide what it *should* do here and explain why on stderr.

**2. Keep the git-level wiring even when the agent-level wiring is in
place.** Agent-runtime hook enforcement is young code and has had bypass gaps
historically — an event that did not fire, a tool path that skipped the
matcher, a nested invocation that never surfaced as a tool call. `git` runs
its own hooks for every commit regardless of who or what typed the command,
so the commit-layer guards (secret-scan, large files, merge markers, quality
gate, instruction-scan) belong in `.git/hooks/pre-commit` **as well as** the
agent config. Two independent enforcement points, one of which does not
depend on the agent behaving.

**3. Checked-in hook configuration is executable code — review it as
such.** A hook entry is a command line that runs with your privileges, in
your shell, with your credentials in the environment, and repo-controlled
hook settings have been a remote-code-execution vector in agent tooling
before now (settings from a cloned repository executing before the user ever
saw a trust prompt). That cuts both ways: read this repo's
`claude.hooks.json`, `codex.hooks.json`, and every script in `scripts/`
before you install them, exactly as you would read a `postinstall` script —
and treat any hook wiring arriving inside a cloned repository the same way.
Everything here is plain bash for that reason: it is meant to be read.

## Guard knobs

Defaults are generic; every knob below is an environment variable, so it can
be set in the hook wiring, in CI, or per shell. Align the quality-gate ones
with the `<lint-command>`-style bindings in the consuming repo's AGENTS.md.

| Script | Env var | Default / meaning |
| --- | --- | --- |
| dangerous-command-guard | `DCG_EXTRA_PATTERNS` | additional POSIX EREs to block, **one per line** (not colon-separated — a colon is part of `[[:space:]]`). Additive only; there is no off switch. |
| protected-paths-guard | `PPG_ZERO_ACCESS` | `.ssh:.aws:.gnupg:.kube:.env:.env.*` — no tool may touch these at all |
| protected-paths-guard | `PPG_NO_DELETE` | `test:tests:spec:specs:__tests__` — may be written and edited, never deleted |
| protected-paths-guard | `PPG_ALLOW` | exemptions for both tiers: `.env.example:.env.sample:.env.template:.env.dist:node_modules:.venv:venv:__pycache__:dist:build:target:coverage:.git` |
| check-large-files | `LARGE_FILE_KB` | `1024` (1 MB) |
| instruction-scan | `INSTRUCTION_SCAN_MODE` | `staged` (pre-commit) or `tree` (CI); `--all` on the command line means `tree` |
| instruction-scan | `INSTRUCTION_SCAN_PATHS` | `skills:rules:agents:commands` — roots scanned in full; root-level Markdown is always included |
| instruction-scan | `INSTRUCTION_SCAN_EXTS` | `md:markdown:yaml:yml:txt:json` inside those roots |
| instruction-scan | `INSTRUCTION_SCAN_SKIP` | codepoint ids to ignore, e.g. `U+200D:U+200C` for docs that carry emoji ZWJ sequences |
| agents-md-budget | `AGENTS_MD_MAX_BYTES` | `32768` — blocks above it |
| agents-md-budget | `AGENTS_MD_WARN_BYTES` | `24576` — warns, still exits 0 |
| agents-md-budget | `AMB_FILENAME` | `AGENTS.md`; set to `CLAUDE.md` to budget that chain instead |
| agents-md-budget | `AMB_EXCLUDE_DIRS` | `.git:node_modules:.venv:venv:target:dist:build:vendor:.next:__pycache__` |
| done-authority-gate | `DONE_AUTHORITY_FILE` | required — the team status file to read |
| done-authority-gate | `DONE_AUTHORITY_ROLE` | required — the role holding the done-verdict |
| done-authority-gate | `DONE_AUTHORITY_SUBJECT` | optional — a branch/task string the verdict line must also contain, so a stale verdict cannot satisfy the gate |
| done-authority-gate | `DONE_AUTHORITY_GATE` | `off` disables the gate explicitly |

The two path tiers are pattern lists, not paths: a pattern **without** a
slash matches any single path component (`tests` matches `src/tests/x.py`),
a pattern **with** a slash matches the path or any directory prefix of it,
and a leading `~` or `$HOME` is expanded first. Setting a tier to the empty
string disables it — explicit configuration, not a bypass.

### quality-gate.sh knobs

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
  (`${CLAUDE_PLUGIN_ROOT}`, `if: "Bash(git commit*)"` narrowing, a second
  matcher for the file-touching tools), declared explicitly via the `"hooks"`
  field in `.claude-plugin/plugin.json`
  ([plugins reference](https://code.claude.com/docs/en/plugins-reference)).
- [`codex.hooks.json`](codex.hooks.json) — Codex dialect (`${PLUGIN_ROOT}`,
  no `if`; the scripts' own no-op guards and quality-gate's stdin narrowing
  replace it), declared via the `"hooks"` field in
  `.codex-plugin/plugin.json`
  ([Codex plugin docs](https://developers.openai.com/codex/plugins/build)).

Both files wire the same six default guards, safety layer first. The safety
guards are **not** narrowed to `git commit` — they exist to see every call.

## a) Claude Code

Two options ([hooks docs](https://code.claude.com/docs/en/hooks)):

- **Via the plugin**: install this repo as a plugin;
  `.claude-plugin/plugin.json` declares `hooks/claude.hooks.json`, and
  `${CLAUDE_PLUGIN_ROOT}` resolves to the installed plugin directory
  ([plugins docs](https://code.claude.com/docs/en/plugins)).
- **Standalone**: copy the scripts into your repo and add to
  `.claude/settings.json` (the `if` field narrows matching using permission
  rule syntax; omit it to run on every call of that tool):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/hooks/scripts/dangerous-command-guard.sh"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/hooks/scripts/protected-paths-guard.sh"
          },
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
      },
      {
        "matcher": "Write|Edit|MultiEdit|NotebookEdit|Read",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/hooks/scripts/protected-paths-guard.sh"
          }
        ]
      }
    ]
  }
}
```

Exit 2 blocks the tool call; stderr becomes the blocking reason shown to Claude.
If a Claude Code version ignores the `if` narrowing, the commit guards simply
run on every Bash call — harmless, because each exits 0 whenever nothing is
staged, and quality-gate additionally passes straight through on payloads
that are not a `git commit`. Tool names in a `matcher` that this version does
not have never match, which costs nothing.

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

Only the shell-tool matcher is wired for Codex here, because that is the
payload shape this repo has verified. Before relying on the two safety
guards under Codex, run the probe in
[Verify that a wiring actually blocks](#verify-that-a-wiring-actually-blocks)
against a real payload from your version: if the guard cannot find a command
string it fails open, which is silent by design.

## c) Cursor

Cursor uses its own schema in `.cursor/hooks.json`
([hooks docs](https://cursor.com/docs/agent/hooks)): a required `"version": 1`
and camelCase event names. `beforeShellExecution` fires before any shell
command; a hook can block by printing `{"permission": "deny"}` or simply by
exiting 2, which these scripts do. `beforeReadFile` / `beforeSubmitPrompt`
and the file-edit events carry paths rather than a command, which is the
shape protected-paths-guard reads:

```json
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      { "command": "hooks/scripts/dangerous-command-guard.sh" },
      { "command": "hooks/scripts/protected-paths-guard.sh" },
      { "command": "hooks/scripts/secret-scan.sh" },
      { "command": "hooks/scripts/check-large-files.sh" },
      { "command": "hooks/scripts/check-merge-markers.sh" },
      { "command": "hooks/scripts/quality-gate.sh" }
    ],
    "beforeReadFile": [
      { "command": "hooks/scripts/protected-paths-guard.sh" }
    ]
  }
}
```

## d) OpenCode

OpenCode has no hooks.json; it uses JS plugins in `.opencode/plugins/`
([plugins docs](https://opencode.ai/docs/plugins/)). The shim below runs the
safety guards on every bash call, the commit guards only on `git commit`, and
the path guard on file tools — blocking by throwing:

```js
// .opencode/plugins/guards.js
const SAFETY = [
  "hooks/scripts/dangerous-command-guard.sh",
  "hooks/scripts/protected-paths-guard.sh",
]
const COMMIT = [
  "hooks/scripts/secret-scan.sh",
  "hooks/scripts/check-large-files.sh",
  "hooks/scripts/check-merge-markers.sh",
  "hooks/scripts/quality-gate.sh",
]

export const Guards = async ({ $ }) => ({
  "tool.execute.before": async (input, output) => {
    const fail = (r) => { if (r.exitCode !== 0) throw new Error(r.stderr.toString()) }

    if (input.tool === "bash") {
      const cmd = output.args?.command ?? ""
      for (const g of SAFETY) fail(await $`bash ${g} ${cmd}`.nothrow().quiet())
      if (!/git\s+commit/.test(cmd)) return
      for (const g of COMMIT) fail(await $`bash ${g} < /dev/null`.nothrow().quiet())
      return
    }

    // File tools: pass whichever path field this version uses.
    const p = output.args?.filePath ?? output.args?.file_path ?? output.args?.path
    if (!p) return
    fail(await $`bash hooks/scripts/protected-paths-guard.sh ${p}`.nothrow().quiet())
  },
})
```

Two details matter here. The safety guards are given the command **as an
argument** rather than on stdin — they accept either, and OpenCode has no
hook payload to hand them. The `git commit` narrowing must live in the JS
because OpenCode has no declarative matcher, and the commit guards are fed
`< /dev/null`: empty stdin is exactly the case where quality-gate fail-closes
toward running its toolchains, so without the regex every bash call would pay
for a full lint/type-check pass.

## e) Plain git (no agent)

Git supports one `pre-commit` file, so drive the commit-layer guards from a
loop. The two safety guards are not in this list — there is no commit to
attach them to:

```bash
cat > .git/hooks/pre-commit <<'SH'
#!/bin/sh
for guard in secret-scan check-large-files check-merge-markers instruction-scan quality-gate; do
  hooks/scripts/$guard.sh < /dev/null || exit $?
done
SH
chmod +x .git/hooks/pre-commit
```

(Git runs hooks from the repo top level, so the relative path holds.) Works
for human commits too — the scripts detect a terminal and skip the stdin
drain. Drop `instruction-scan` from the loop if the repo ships no
instruction-bearing files; it will otherwise tell you, on stderr, that it
scanned nothing.

## Opt-in guards

### instruction-scan.sh — in CI

The staged mode above covers a repo's own commits. The whole-tree mode is for
pull requests and for anything vendored in from outside, which is where the
risk actually is: audits of skill marketplaces have found a substantial share
of published skills carrying flaws, with prompt injection through the
SKILL.md body the dominant vector — and invisible-Unicode payloads among
them, readable by a model and not by a reviewer. Run it over every skill you
adopt from a third party, before the first load:

```yaml
# any CI runner, any provider
- run: hooks/scripts/instruction-scan.sh --all
```

Point it at the vendored tree with `INSTRUCTION_SCAN_PATHS` when the skills
live somewhere else (`INSTRUCTION_SCAN_PATHS=.agents/skills:.claude/agents`).

### agents-md-budget.sh — in CI, or pre-push

```yaml
- run: hooks/scripts/agents-md-budget.sh
```

It measures the largest chain any working directory would receive — root
AGENTS.md plus every nested one down that path — because that concatenated
chain is what a tool actually delivers. Codex caps that chain at 32 KiB and
truncates silently, so overflow does not fail loudly at load time; it just
quietly stops being instructions. Hence a gate that fails loudly instead.
`@import` references are not expanded: the number is the chain's own bytes.

### done-authority-gate.sh — only where a team is declared

Not wired by default. Agent teams are experimental, and a stop gate in a repo
with no team declared is friction with no payoff. Where a `## Teams` entry
does exist, this gate mechanizes one invariant from it — *exactly one role
declares work done* — by requiring that role's verdict line in the team
status file:

```
verdict: qa-reviewer: accepted - 14 cases executed, evidence in docs/qa/2026-08-16.md
verdict: qa-reviewer: rejected - empty-state case fails; see finding 3
```

The last matching line wins, `accepted` passes, `rejected`/`blocked` fail,
and any other word is reported as a misconfiguration rather than guessed at.
Wire it on the runtime's stop / task-completed event — the event name differs
per tool (Claude Code `Stop` and `SubagentStop`; other runtimes use
task-completed or teammate-idle shapes), and only the event name changes:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "DONE_AUTHORITY_FILE=docs/team-log.md DONE_AUTHORITY_ROLE=qa-reviewer ${CLAUDE_PROJECT_DIR}/hooks/scripts/done-authority-gate.sh"
          }
        ]
      }
    ]
  }
}
```

Set `DONE_AUTHORITY_SUBJECT` to the branch or task id where a team runs more
than one round against the same log — without it, an `accepted` from a
previous round satisfies the gate.

## Verify that a wiring actually blocks

A guard you have not seen block is a guard you are guessing about. Each
script is callable by hand with the payload shape it expects:

```bash
# should print a reason and exit 2
printf '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
  | hooks/scripts/dangerous-command-guard.sh; echo "rc=$?"

# should exit 0 — false positives are what kill a guard
printf '{"tool_name":"Bash","tool_input":{"command":"rm -rf build/"}}' \
  | hooks/scripts/dangerous-command-guard.sh; echo "rc=$?"

# zero-access tier
hooks/scripts/protected-paths-guard.sh --command 'cat .env'; echo "rc=$?"

# no-delete tier
hooks/scripts/protected-paths-guard.sh --command 'rm -rf tests'; echo "rc=$?"

# whole-tree instruction scan
hooks/scripts/instruction-scan.sh --all; echo "rc=$?"
```

Then repeat the first one through the actual runtime — ask the agent to run
a harmless command and confirm the hook fired — because the payload field
names are the part that varies between tools and versions.

## When a guard blocks

Fix the cause. Unstage the secret and move it to an ignored env file; narrow
the `rm` target; read the value from the environment instead of the `.env`
file; fix the failing test instead of deleting it; delete the invisible
characters; trim the AGENTS.md chain. Every block message names the specific
remedy, and every default that is genuinely wrong for a repo is an
environment variable away from being re-bound deliberately, in configuration,
where the next reader can see it. `--no-verify`, a removed hook entry, or a
guard commented out for one commit are all the same move: the check stops
running and nobody finds out.

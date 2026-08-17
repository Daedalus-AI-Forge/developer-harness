# Consuming developer-harness from OpenCode

OpenCode consumes **skills** and **commands** natively; hooks route through a
JS plugin, roles through `AGENTS.md`. Docs verified 2026-08:
[skills](https://opencode.ai/docs/skills/),
[commands](https://opencode.ai/docs/commands/),
[plugins](https://opencode.ai/docs/plugins/),
[agents](https://opencode.ai/docs/agents/),
[rules](https://opencode.ai/docs/rules/).

## Skills (native — two options)

**Option A — point OpenCode at a clone (recommended).** OpenCode scans
configured skill paths recursively for `**/SKILL.md`, so a clone needs no
vendoring at all:

```jsonc
// opencode.json
{ "skills": { "paths": ["<path-to-clone>/developer-harness/skills"] } }
```

This also keeps the architect skills' sibling resource dirs
(`skills/architect-shared/`, `skills/contracts/`) in place — the selective-
vendoring caveat below never applies. Update with `git pull`.

**Option B — vendor via the skills CLI:**

```
npx skills add daedalus-ai-forge/developer-harness --all
```

OpenCode discovers skills in `.opencode/skills/`, `.claude/skills/`, and
`.agents/skills/` (project) plus the `~/.config/opencode/`, `~/.claude/`, and
`~/.agents/` equivalents — the CLI's default vendoring works as-is. The agent
loads them on demand through its native `skill` tool when a task matches a
skill's `description`.

Option-B caveat: the two architect skills depend on the sibling dirs
`skills/architect-shared/` and `skills/contracts/` (no SKILL.md, so per-skill
installers may skip them) — when vendoring selectively, copy those two dirs
alongside.

Vendored skills include `systematic-debugging` (from obra/superpowers),
`deep-research` (authored in-house, MIT) for multi-source verified evidence,
`grill-me` (from mattpocock/skills, MIT) to stress-test a plan, and
`skill-creator` (from anthropics/skills, Apache-2.0) when creating or
updating a skill, and `karpathy-guidelines` (from
multica-ai/andrej-karpathy-skills, MIT), loaded on demand while writing or
reviewing code — OpenCode cannot read Claude Code plugins, so these
vendored copies are the OpenCode path to those skills.

## Commands (copy)

For explicit invocation, copy the wrappers into `.opencode/commands/`
(project) or `~/.config/opencode/commands/` (global):

```bash
mkdir -p .opencode/commands
cp path/to/developer-harness/commands/*.md .opencode/commands/
```

Then run e.g. `/tighten-types src/models.py`. Dialect notes: OpenCode
documents `description`, `agent`, `model`, and `subtask` frontmatter and
supports `$ARGUMENTS` (plus positional `$1`, `$2`, ...) — all compatible with
these wrappers. The `argument-hint` field is a Claude Code extension; OpenCode
doesn't document it, so drop it if your version complains.

## Agents (routing via AGENTS.md)

OpenCode's native agents use a different frontmatter dialect
(`description`, `mode: subagent`) in `.opencode/agents/`. Either:

- adapt a role file: keep the body, replace the frontmatter with
  `description:` + `mode: subagent` (and drop `model: inherit` — it is not a
  valid OpenCode provider/model id), save to `.opencode/agents/<role>.md`; or
- route via `AGENTS.md`: copy role files into your repo and paste
  [`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md)
  into `AGENTS.md`.

## Hooks (JS plugin shim)

OpenCode has no hooks.json; use the plugin shim in
[`../hooks/README.md`](../hooks/README.md) — a `.opencode/plugins/*.js` file
that runs the guard scripts in `tool.execute.before` and blocks by throwing.
The shim narrows to `git commit` bash calls in JS before invoking the guards,
so the expensive quality gates never fire on ordinary commands.

## Rules

OpenCode reads `AGENTS.md` at the project root (and
`~/.config/opencode/AGENTS.md` globally). Paste the guards/roles templates
from [`../rules/agents-md/`](../rules/agents-md/) there.

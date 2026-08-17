# Consuming developer-harness from Cursor

Cursor consumes **skills**, **agents**, and **hooks** natively. Docs verified
2026-08: [skills](https://cursor.com/docs/skills),
[subagents](https://cursor.com/docs/agent/subagents),
[hooks](https://cursor.com/docs/agent/hooks),
[rules / AGENTS.md](https://cursor.com/docs/context/rules).

## Plugins (docs-sourced — verify on install)

Cursor's docs state that it loads plugins written to the Agent Plugins spec
unchanged, and that it reads subagent definitions from `.claude/agents/` as
native Cursor subagents. If that holds for your version, this repo needs no
Cursor-specific packaging at all: the same plugin root that serves Claude
Code serves Cursor, and the role contracts vendored for Claude Code double as
Cursor agents — one copy, two tools.

Both claims are taken from documentation and have **not** been executed
against a live Cursor install here. Treat them as the first thing you verify
("Verify the load", at the end of this guide), not as the plan you commit to.
The per-class instructions below are the path that does not depend on either
claim.

## Skills (native)

```
npx skills add daedalus-ai-forge/developer-harness --all
```

Cursor loads skills from `.agents/skills/` and `.cursor/skills/` (project) and
`~/.agents/skills/`, `~/.cursor/skills/` (user), plus `.claude/skills/` and
`.codex/skills/` for compatibility — so the CLI's default vendoring works
as-is. Invoke a skill by typing `/` in Agent chat and picking its name
(e.g. `/tighten-types`), or let Cursor auto-select by description.

Caveat: the two architect skills depend on the sibling dirs
`skills/architect-shared/` and `skills/contracts/` (no SKILL.md, so per-skill
installers may skip them) — when vendoring selectively, copy those two dirs
alongside.

## Commands

Current Cursor docs have folded slash commands into skills (a built-in
`/migrate-to-skills` converts old commands), so the docs no longer describe a
`.cursor/commands/` install path. Preferred: rely on the installed skills and
invoke them with `/name`. If your Cursor version still loads legacy command
files, `commands/*.md` can be copied into `.cursor/commands/` unchanged — the
`description` + `$ARGUMENTS` dialect matches — but treat that path as
deprecated (not verified in current docs).

## Agents (native)

Cursor reads subagent definitions from `.cursor/agents/` **and**
`.claude/agents/` (also `.codex/agents/`; project beats user level). So one
copy serves Claude Code and Cursor:

```bash
mkdir -p .claude/agents
cp path/to/developer-harness/agents/<group>/<role>.md .claude/agents/
```

Format matches `agents/_template.md`: markdown with `name`, `description`,
optional `model: inherit` frontmatter. The harness groups roles in team
subfolders (`project-control/`, `develop-team/`, `design-team/`); Cursor's
support for nested agent folders is unverified — if grouped copies don't
appear in the subagent list, flatten on copy (drop the role files directly
into `.claude/agents/`).

The judging roles additionally carry a `disallowedTools` denylist, which
Claude Code enforces. Cursor's own subagent controls are coarser — a
read-only mode rather than a per-tool list — and whether it honors this
field is **not verified** here. So on Cursor, treat a "reviews, never
implements" boundary as contract prose the agent is asked to keep until you
have watched it refuse: set the subagent read-only where the mode exists,
and where the boundary must hold regardless, back it with a
`beforeShellExecution` hook (next section), which Cursor does enforce.

## Hooks (native)

Copy the guard scripts under `hooks/scripts/` into your repo and wire them in
`.cursor/hooks.json` (`"version": 1`, `beforeShellExecution` event; exit 2
blocks). Exact JSON, the current script list, and which guards are default-on
versus opt-in: [`../hooks/README.md`](../hooks/README.md).

## Rules

Cursor reads `AGENTS.md` in the project root (and subdirectories) as a plain
markdown rules file. Paste the templates from
[`../rules/agents-md/`](../rules/agents-md/) there, or convert them into
`.cursor/rules` `.mdc` files if you use structured rules.

## Verify the load — do not skip this

Cursor has documented cases of **silently failing to load `AGENTS.md`**: no
error, no warning, just an agent operating without the rules you wrote. Every
other step in this guide is invisible if that one fails, so finish the setup
by asking for evidence rather than assuming it:

1. Open a fresh Agent chat and ask it to **list the rules currently applied
   to this session, and where each came from**. You are checking that
   `AGENTS.md` (and any `.cursor/rules` files) appear by name.
2. Ask it to quote one line that exists only in your `AGENTS.md` — a
   binding value, a guard name. A model that can list the file but not quote
   it has the name from the directory listing, not the content.
3. Spawn one subagent by name and confirm it answers in role.

If the rules are absent, the usual causes are file location (project root,
not a subdirectory you happened to open), a workspace opened above the repo
root, or an editor setting disabling `AGENTS.md`. Fix the load before
trusting anything downstream of it — a harness whose rules never loaded looks
exactly like a harness that loaded and was ignored, and only one of those is
worth debugging.

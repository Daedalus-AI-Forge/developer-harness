# Consuming developer-harness from Cursor

Cursor consumes **skills**, **agents**, and **hooks** natively. Docs verified
2026-08: [skills](https://cursor.com/docs/skills),
[subagents](https://cursor.com/docs/agent/subagents),
[hooks](https://cursor.com/docs/agent/hooks),
[rules / AGENTS.md](https://cursor.com/docs/context/rules).

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
cp path/to/developer-harness/agents/<role>.md .claude/agents/
```

Format matches `agents/_template.md`: markdown with `name`, `description`,
optional `model: inherit` frontmatter.

## Hooks (native)

Copy `hooks/scripts/secret-scan.sh` into your repo and wire it in
`.cursor/hooks.json` (`"version": 1`, `beforeShellExecution` event; exit 2
blocks). Exact JSON: [`../hooks/README.md`](../hooks/README.md).

## Rules

Cursor reads `AGENTS.md` in the project root (and subdirectories) as a plain
markdown rules file. Paste the templates from
[`../rules/agents-md/`](../rules/agents-md/) there, or convert them into
`.cursor/rules` `.mdc` files if you use structured rules.

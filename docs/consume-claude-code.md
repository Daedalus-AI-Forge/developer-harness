# Consuming developer-harness from Claude Code

Claude Code consumes every harness class natively. Docs verified 2026-08:
[plugins](https://code.claude.com/docs/en/plugins),
[marketplaces](https://code.claude.com/docs/en/plugin-marketplaces),
[skills](https://code.claude.com/docs/en/slash-commands),
[subagents](https://code.claude.com/docs/en/sub-agents),
[hooks](https://code.claude.com/docs/en/hooks).

## Channel 1: plugin (everything at once)

The repo root is a plugin (`.claude-plugin/plugin.json`), and
`.claude-plugin/marketplace.json` makes the repo its own marketplace:

```
/plugin marketplace add daedalus-ai-forge/developer-harness
/plugin install developer-harness@developer-harness
```

This picks up by convention, from the plugin root:

- `skills/` — all skills, namespaced: `/developer-harness:tighten-types`,
  `/developer-harness:architect-design-review`, etc.
- `commands/` — flat-file wrappers (Claude Code treats these as skills too;
  they duplicate the `skills/` entries by name, so in Claude Code invoke the
  skills directly — the wrappers exist for tools that consume command files)
- `agents/` — role templates appear as subagents; the directory is read
  recursively, so the team subfolders (`project-control/`, `develop-team/`,
  `design-team/`) load as-is (`_template.md` is a scaffold, not a usable
  role; delete or replace it in real use)
- hooks — declared via `plugin.json` → `hooks/claude.hooks.json` (no
  auto-discovered `hooks/hooks.json` exists): all four guard scripts
  (secret-scan, quality-gate, check-large-files, check-merge-markers) as
  `PreToolUse` guards on `Bash(git commit*)`; `${CLAUDE_PLUGIN_ROOT}`
  resolves the paths

## Channel 2: skills only, vendored

```
npx skills add daedalus-ai-forge/developer-harness --all
```

Vendors the skills into your repo (canonically `.agents/skills/`, linked into
`.claude/skills/`) so contributors get them with a plain `git clone`. See the
[skills CLI](https://github.com/vercel-labs/skills).

Caveat: the two architect skills depend on the sibling dirs
`skills/architect-shared/` and `skills/contracts/` (no SKILL.md, so per-skill
installers may skip them) — when vendoring selectively, copy those two dirs
alongside.

## Piecemeal

- **Agents**: copy a role file into `.claude/agents/` — format is markdown
  with `name` + `description` frontmatter, optional `model: inherit`. Claude
  Code reads `.claude/agents/` recursively, so the grouped structure
  (`agents/develop-team/`, `agents/design-team/`, …) can be copied as-is.
- **Hooks**: copy the four scripts under `hooks/scripts/` and wire them in
  `.claude/settings.json` — exact JSON in [`../hooks/README.md`](../hooks/README.md).
- **Rules**: paste [`../rules/agents-md/guards-section.md`](../rules/agents-md/guards-section.md)
  into your `CLAUDE.md`.

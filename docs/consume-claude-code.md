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
- `agents/` — role templates appear as subagents (`_template.md` is a
  scaffold, not a usable role; delete or replace it in real use)
- `hooks/hooks.json` — wires `hooks/scripts/secret-scan.sh` as a `PreToolUse`
  guard on `Bash(git commit*)`; `${CLAUDE_PLUGIN_ROOT}` resolves the path

## Channel 2: skills only, vendored

```
npx skills add daedalus-ai-forge/developer-harness --all
```

Vendors the skills into your repo (canonically `.agents/skills/`, linked into
`.claude/skills/`) so contributors get them with a plain `git clone`. See the
[skills CLI](https://github.com/vercel-labs/skills).

## Piecemeal

- **Agents**: copy a role file into `.claude/agents/` — format is markdown
  with `name` + `description` frontmatter, optional `model: inherit`.
- **Hooks**: copy `hooks/scripts/secret-scan.sh` and wire it in
  `.claude/settings.json` — exact JSON in [`../hooks/README.md`](../hooks/README.md).
- **Rules**: paste [`../rules/agents-md/guards-section.md`](../rules/agents-md/guards-section.md)
  into your `CLAUDE.md`.

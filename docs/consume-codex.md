# Consuming developer-harness from Codex

Codex consumes **skills** and **hooks** natively; roles route through
`AGENTS.md`. Docs verified 2026-08 (developers.openai.com/codex/* now
redirects to learn.chatgpt.com):
[skills](https://learn.chatgpt.com/docs/build-skills),
[AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
[hooks](https://learn.chatgpt.com/docs/hooks),
[subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents).

## Skills (native)

```
npx skills add daedalus-ai-forge/developer-harness --all
```

The CLI vendors skills into `.agents/skills/`, which Codex reads natively
(it searches `.agents/skills` in the cwd, parent directories, and repo root,
plus `~/.agents/skills`). Invoke explicitly by typing `$` + the skill name:

```
$tighten-types src/models.py
$architect-design-review docs/design/spec.md
```

or pick from the `/skills` selector. Codex also auto-selects skills whose
`description` matches the task.

## Commands

Codex has no repo-level custom slash commands — skip `commands/` and invoke
skills with `$name` as above.

## Agents (routing via AGENTS.md)

Codex custom agents are TOML files in `.codex/agents/`, not markdown, so the
markdown role contracts in `agents/` are not installed directly. Instead:

1. Copy the role files somewhere in your repo (e.g. `docs/roles/`).
2. Paste [`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md)
   into your `AGENTS.md` and point each row at a role file.

Codex concatenates `AGENTS.md` files from the repo root down (32 KiB default
budget), so keep the routing table short and let the contract files carry the
detail.

## Hooks (native)

Copy `hooks/scripts/secret-scan.sh` into your repo and wire it in
`.codex/hooks.json` — same `PreToolUse` schema family as Claude Code, same
exit-2-blocks convention. Exact JSON, the `[features] hooks` toggle, and the
`/hooks` trust flow: [`../hooks/README.md`](../hooks/README.md).

## Rules

Paste [`../rules/agents-md/guards-section.md`](../rules/agents-md/guards-section.md)
into `AGENTS.md` so the agent knows the guards exist and doesn't fight them.

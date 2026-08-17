# Consuming developer-harness from Codex

Three tiers, by preference. Docs verified 2026-08 (developers.openai.com/codex/*
redirects to learn.chatgpt.com):
[plugins](https://developers.openai.com/codex/plugins),
[plugin build](https://developers.openai.com/codex/plugins/build),
[skills](https://developers.openai.com/codex/skills).

## 1. Plugin install (preferred)

The repo root is a Codex plugin (`.codex-plugin/plugin.json`) and its own
one-entry marketplace (`.agents/plugins/marketplace.json`):

```
codex plugin marketplace add daedalus-ai-forge/developer-harness
```

Then open `/plugins` in the TUI and install `developer-harness` from the
marketplace entry. Once installed:

- `/plugins` — browse, install, and inspect plugins
- `$<skill-name>` — invoke a bundled skill explicitly, e.g.
  `$tighten-types src/models.py`

Every skill ships an OpenAI sidecar (`skills/<name>/agents/openai.yaml`) with
`display_name` and `short_description` — that is what Codex shows in its skill
picker — plus a `default_prompt` on the explicitly-invocable skills
(tighten-types, contract-docstrings, architect-design-review,
architect-codebase-review, mermaid-skill, gantt-roadmap, feature-build,
define-team, systematic-debugging, deep-research, grill-me, skill-creator).
Vendored skills include `systematic-debugging` (from obra/superpowers) —
invoke `$systematic-debugging` when debugging starts; `deep-research`
(authored in-house, MIT) — `$deep-research` for multi-source verified
evidence; `grill-me` (from mattpocock/skills, MIT) — `$grill-me` to
stress-test a plan; `skill-creator` (from anthropics/skills, Apache-2.0) —
`$skill-creator` when creating or updating a skill; and `karpathy-guidelines`
(from multica-ai/andrej-karpathy-skills, MIT) — auto-selected while coding, no
`$` invocation. Codex cannot read Claude Code plugins, so these vendored
copies are the Codex path to those skills.

Note on `skill-creator` in Codex: its authoring guidance and schemas work
as-is, but its bundled eval/benchmark and description-tuning scripts invoke
the `claude` CLI (`claude -p`) and write `.claude/commands/`, so that
workflow needs Claude Code alongside (details in
[`../VENDOR-ATTRIBUTION.md`](../VENDOR-ATTRIBUTION.md)).

Guard hooks are bundled and declared per tool — there is deliberately no
auto-discovered `hooks/hooks.json`. `.codex-plugin/plugin.json` declares
`"hooks": "./hooks/codex.hooks.json"` (Codex dialect: `${PLUGIN_ROOT}`, no
`if`, statusMessages), wiring all four guard scripts (secret-scan,
quality-gate, check-large-files, check-merge-markers); the Claude dialect
lives separately in `hooks/claude.hooks.json`. Authoritative wiring
reference: [`../hooks/README.md`](../hooks/README.md).

## 2. skills CLI

```
npx skills add daedalus-ai-forge/developer-harness --all
```

The CLI vendors skills into `.agents/skills/`, which Codex reads natively
(cwd, parent directories, repo root, plus `~/.agents/skills`). Invoke with
`$` + skill name or the `/skills` selector; Codex also auto-selects skills
whose `description` matches the task. No plugin machinery involved — use this
when you want the skills pinned in-repo by content hash (`skills-lock.json`).

Caveat: the two architect skills depend on the sibling dirs
`skills/architect-shared/` and `skills/contracts/` (no SKILL.md, so per-skill
installers may skip them) — when vendoring selectively, copy those two dirs
alongside.

## 3. Agents (routing via AGENTS.md)

Plugins carry no role contracts, and Codex custom agents are TOML files in
`.codex/agents/`, not markdown — so the role contracts in `agents/` route
through `AGENTS.md` instead:

1. Copy the role files somewhere in your repo (e.g. `docs/roles/`).
2. Paste [`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md)
   into your `AGENTS.md` and point each row at a role file.

Codex concatenates `AGENTS.md` files from the repo root down (32 KiB default
budget), so keep the routing table short and let the contract files carry the
detail.

## Hooks and rules

Hooks: plugin installs get all four guards automatically via
`hooks/codex.hooks.json`; standalone (non-plugin) repos copy that file's
shape into `.codex/hooks.json` — feature toggle and trust flow in
[`../hooks/README.md`](../hooks/README.md). Rules: paste
[`../rules/agents-md/guards-section.md`](../rules/agents-md/guards-section.md)
into `AGENTS.md` so the agent knows the guards exist and doesn't fight them.

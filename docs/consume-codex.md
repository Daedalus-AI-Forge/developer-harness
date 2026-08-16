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
- `@developer-harness` — invoke the plugin (or one of its skills) explicitly
- `$<skill-name>` — invoke a bundled skill, e.g. `$tighten-types src/models.py`

Every skill ships an OpenAI sidecar (`skills/<name>/agents/openai.yaml`) with
`display_name` and `short_description` — that is what Codex shows in its skill
picker — plus a `default_prompt` on the explicitly-invocable skills
(tighten-types, contract-docstrings, architect-design-review,
architect-codebase-review, mermaid-skill, gantt-roadmap).

Caveat: our marketplace entry points at the repo root (`"path": "."`); the
official examples only show `./plugins/<name>` subdirectory paths, so the
root-path layout is pending a live install test.

The plugin bundles no hooks — the plugin-bundled hook definition format is
pending verification. Wire `secret-scan.sh` manually per
[`../hooks/README.md`](../hooks/README.md).

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

Hooks: copy `hooks/scripts/secret-scan.sh` and wire it in `.codex/hooks.json` —
exact JSON, feature toggle, and trust flow in
[`../hooks/README.md`](../hooks/README.md). Rules: paste
[`../rules/agents-md/guards-section.md`](../rules/agents-md/guards-section.md)
into `AGENTS.md` so the agent knows the guards exist and doesn't fight them.

# Companion skills (external, not vendored)

Four external plugins are wired into this harness's roles by name but
deliberately not copied into `skills/` — install them from their own sources
where you want them. All four are load-before-writing references, not method
gates; every role that names them degrades gracefully where they are absent.

| Skill | Used by | Install | Why not vendored |
| --- | --- | --- | --- |
| `frontend-design` | `ux-designer` | Claude Code: `/plugin install frontend-design@claude-plugins-official` (Anthropic's official marketplace, [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)) | Proprietary licence — the source repo's LICENSE.md is "© Anthropic PBC. All rights reserved", Commercial Terms of Service — so it is not redistributable here. |
| `claude-security` | `security-engineer` (advisory — its `/claude-security` command runs a multi-agent scan-codebase / scan-changes / suggest-patches menu) | Claude Code: `/plugin install claude-security@claude-plugins-official` ([docs](https://code.claude.com/docs/en/claude-security); needs Claude Code ≥ 2.1.154, a paid plan, and `python3` ≥ 3.9.6) | Proprietary licence — the plugin's LICENSE grants a limited internal-use licence "solely with Claude Code" (© Anthropic PBC), so it is not redistributable here. |
| `ui-ux-pro-max` | `ux-designer`, `frontend-developer`, `design-reviewer` (advisory only) | `/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill` then `/plugin install ui-ux-pro-max@ui-ux-pro-max-skill` ([repo](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill), MIT) | ~12 MB across ~337 files of searchable design databases — far past this repo's library size budget. |
| `system-design-skills` | `tech-lead` (gate/conformance vocabulary), `backend-developer`, `data-engineer`, `devops-engineer` (building blocks per concern), `analyst` (`back-of-the-envelope` as estimation input — all advisory) | Claude Code: `/plugin marketplace add proyecto26/system-design-skills` then `/plugin install system-design-skills` ([repo](https://github.com/proyecto26/system-design-skills), MIT); other tools: `npx skills add proyecto26/system-design-skills` (vendors the 22 skills only — the `/design` command and orchestrator agent ship via the plugin channel) | MIT, but 22 interlinked skills — ~824 KB across 127 files — past the library size budget, and the orchestrator routes among them by name, so the collection only makes sense whole. |

In Claude Code, `frontend-design` and `claude-security` are also declared as
cross-marketplace dependencies in `.claude-plugin/plugin.json`, so installing
this plugin auto-installs both from Anthropic's own marketplace — a pointer,
not redistribution, which is what their proprietary licences require.
`ui-ux-pro-max` and `system-design-skills` live in third-party marketplaces
and stay manual installs.

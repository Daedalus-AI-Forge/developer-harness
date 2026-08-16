# developer-harness

A reusable agent harness shared across Daedalus AI Forge projects: [Agent
Skills](https://agentskills.io) plus command wrappers, agent role templates,
guard hooks, and instruction-file fragments — all project-agnostic, packaged
so Claude Code, Codex, Cursor, and OpenCode can each consume what they
understand.

## Taxonomy

```
developer-harness/
├── skills/            # 19 Agent Skills (SKILL.md format) + 2 shared-resource dirs
│   │                  #   language: csharp-developer, java-architect, python-pro,
│   │                  #     rust-engineer, typescript-pro
│   │                  #   conventions: python-conventions, python-api-design,
│   │                  #     rustdoc-conventions, rust-pragmatic, rust-api-checklist
│   │                  #   docs: contract-docstrings, python-documentation, typescript-docs
│   │                  #   method/review: tighten-types, architect-design-review,
│   │                  #     architect-codebase-review
│   │                  #   diagrams/planning: mermaid-skill, gantt-roadmap
│   │                  #   team orchestration: feature-build
│   │                  #   shared resources (not skills): architect-shared/, contracts/
├── commands/          # thin /command wrappers around explicitly-invocable skills
├── agents/            # generic subagent role contracts, grouped by team:
│                      #   root — coordination: product-owner (value execution),
│                      #     person-of-contact (communication/RACI routing)  (+ _template.md)
│                      #   project-control/: product-manager, project-manager,
│                      #     legal-reviewer, researcher
│                      #   develop-team/: tech-lead, developer (base), frontend-developer,
│                      #     backend-developer, devops-engineer, mobile-developer,
│                      #     data-engineer, security-engineer, qa-reviewer, debugger
│                      #   design-team/: ux-designer, design-reviewer, content-designer,
│                      #     design-system-steward, technical-artist
├── hooks/             # tool-neutral guard scripts + wiring template (hooks.json)
├── rules/             # AGENTS.md / CLAUDE.md section templates (roles, teams, guards, engineering discipline, project bindings, raci)
├── docs/              # per-tool consumption guides (consume-<tool>.md)
└── .claude-plugin/    # plugin.json + marketplace.json (repo root = plugin root)
```

## What each tool can consume

| Harness class | Claude Code | Codex | Cursor | OpenCode |
| --- | --- | --- | --- | --- |
| **skills/** | native (plugin or `.agents/skills/`) | native (plugin or `.agents/skills/`) | native (`.agents/skills/` et al., invoke `/name`) | native (`.agents/skills/` et al., `skill` tool) |
| **commands/** | native (plugin; skills already cover it) | routing — no command files, use `$name` | routing — use `/name` skills (legacy copy) | copy → `.opencode/commands/` |
| **agents/** | native (plugin or `.claude/agents/`) | routing — `## Roles` in AGENTS.md | copy → `.claude/agents/` (read natively) | routing — AGENTS.md (or copy + adapt frontmatter) |
| **hooks/** | native (plugin `hooks/hooks.json`) | copy → `.codex/hooks.json` | copy → `.cursor/hooks.json` | copy — JS plugin shim |
| **rules/** | copy — paste into CLAUDE.md | copy — paste into AGENTS.md | copy — paste into AGENTS.md | copy — paste into AGENTS.md |

Per-tool step-by-step guides with doc citations: [docs/consume-claude-code.md](docs/consume-claude-code.md)
· [docs/consume-codex.md](docs/consume-codex.md)
· [docs/consume-cursor.md](docs/consume-cursor.md)
· [docs/consume-opencode.md](docs/consume-opencode.md)

## Install

### Channel 1 — skills CLI (all four tools)

```bash
# See what's available without installing
npx skills add daedalus-ai-forge/developer-harness -l

# Install everything, for every detected agent tool
npx skills add daedalus-ai-forge/developer-harness --all

# Or pick specific skills
npx skills add daedalus-ai-forge/developer-harness -s python-conventions -a '*' -y
```

The [`skills` CLI](https://github.com/vercel-labs/skills) vendors the content
into your repo (canonically under `.agents/skills/`) and pins it by content
hash in `skills-lock.json`. Commit both — contributors then get the skills
with a plain `git clone`, no CLI required. Update later with
`npx skills update -p`.

### Channel 2 — Claude Code plugin (skills + commands + agents + hooks)

The repo root is a plugin and its own marketplace:

```
/plugin marketplace add daedalus-ai-forge/developer-harness
/plugin install developer-harness@developer-harness
```

Skills then invoke as `/developer-harness:<skill-name>`, and the
`secret-scan` guard hook wires up automatically.

### Channel 3 — Codex plugin (skills)

The repo root is also a Codex plugin (`.codex-plugin/plugin.json`) with its
own marketplace (`.agents/plugins/marketplace.json`):

```
codex plugin marketplace add daedalus-ai-forge/developer-harness
/plugins   # in the Codex TUI: install developer-harness, then invoke $<skill-name>
```

Details, invocation syntax, and caveats: [docs/consume-codex.md](docs/consume-codex.md).

## Skill format

```
skills/<name>/SKILL.md    # one directory per skill (Agent Skills spec)
```

Skill frontmatter sticks to the portable spec fields (`name`, `description`,
`license`, `compatibility`, `metadata`) so every client can read them.

## License

MIT for skills authored here. Vendored third-party skills keep their original
licenses and attribution — see per-skill LICENSE files and
`VENDOR-ATTRIBUTION.md`.

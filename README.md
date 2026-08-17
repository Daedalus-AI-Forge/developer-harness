# developer-harness

A reusable agent harness shared across Daedalus AI Forge projects: [Agent
Skills](https://agentskills.io) plus command wrappers, agent role templates,
guard hooks, and instruction-file fragments — all project-agnostic, packaged
so Claude Code, Codex, Cursor, and OpenCode can each consume what they
understand.

## Taxonomy

```
developer-harness/
├── skills/            # 26 Agent Skills (SKILL.md format) + 2 shared-resource dirs
│   │                  #   language: csharp-developer, java-architect, python-pro,
│   │                  #     rust-engineer, typescript-pro
│   │                  #   conventions: python-conventions, python-api-design,
│   │                  #     rustdoc-conventions, rust-pragmatic, rust-api-checklist
│   │                  #   docs: contract-docstrings, python-documentation, typescript-docs
│   │                  #   method/review: tighten-types, architect-design-review,
│   │                  #     architect-codebase-review, systematic-debugging,
│   │                  #     deep-research, grill-me, karpathy-guidelines
│   │                  #   diagrams/planning: mermaid-skill, gantt-roadmap
│   │                  #   team orchestration: feature-build, define-team, role
│   │                  #   meta: skill-creator
│   │                  #   shared resources (not skills): architect-shared/, contracts/
├── commands/          # thin /command wrappers around explicitly-invocable skills
├── agents/            # generic subagent role contracts, grouped by team:
│                      #   root — coordination: product-owner (value execution),
│                      #     person-of-contact (communication/RACI routing)  (+ _template.md)
│                      #   project-control/: product-manager, project-manager,
│                      #     legal-reviewer
│                      #   develop-team/: tech-lead, developer (base), frontend-developer,
│                      #     backend-developer, devops-engineer, mobile-developer,
│                      #     data-engineer, security-engineer, debugger
│                      #   design-team/: ux-designer, content-designer,
│                      #     design-system-steward, technical-artist
│                      #   research-team/: researcher, analyst (shared specialists)
│                      #   validation-team/: qa-reviewer, design-reviewer,
│                      #     integration-validator, performance-validator,
│                      #     release-validator, evidence-validator
├── hooks/             # 9 tool-neutral guard scripts (6 wired by default, 3 opt-in)
│                      #   + per-tool wiring dialects (claude.hooks.json /
│                      #   codex.hooks.json — deliberately no hooks.json)
├── rules/             # AGENTS.md / CLAUDE.md section templates (roles, teams incl. five predefined teams, guards, engineering discipline, coding rules, design docs, project bindings, raci)
├── docs/              # per-tool consumption guides (consume-<tool>.md)
└── .claude-plugin/    # plugin.json + marketplace.json (repo root = plugin root)
```

## What each tool can consume

| Harness class | Claude Code | Codex | Cursor | OpenCode |
| --- | --- | --- | --- | --- |
| **skills/** | native (plugin or `.agents/skills/`) | native (plugin or `.agents/skills/`) | native (`.agents/skills/` et al., invoke `/name`) | native (`.agents/skills/` et al., `skill` tool) |
| **commands/** | native (plugin; skills already cover it) | routing — no command files, use `$name` | routing — use `/name` skills (legacy copy) | copy → `.opencode/commands/` |
| **agents/** | native (plugin or `.claude/agents/`; `disallowedTools` enforced) | routing — `## Roles` in AGENTS.md, or convert → `.codex/agents/*.toml` (`sandbox_mode` per role) | copy → `.claude/agents/` (read natively; `disallowedTools` honoring unverified) | convert → `.opencode/agents/` (`permission: edit: deny`), or routing — AGENTS.md |
| **hooks/** | native (plugin → `hooks/claude.hooks.json`) | native (plugin → `hooks/codex.hooks.json`) or copy → `.codex/hooks.json` | copy → `.cursor/hooks.json` | copy — JS plugin shim |
| **rules/** | copy — paste into CLAUDE.md | copy — paste into AGENTS.md (32 KiB budget, truncated silently) | copy — paste into AGENTS.md (verify it loaded) | copy — paste into AGENTS.md, or `instructions` globs in `opencode.json` (file references are not followed) |

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

Skills then invoke as `/developer-harness:<skill-name>`, the role contracts
load as subagents with their `disallowedTools` boundaries enforced, and the
default-wired guard hooks (`hooks/claude.hooks.json`) come with them.

Installing the plugin also resolves two recommended companions, declared as
dependencies on Anthropic's official `claude-plugins-official` marketplace
(registered by Claude Code by default): `frontend-design` (aesthetic
direction for the `ux-designer` role) and `claude-security` (deep
vulnerability scans for the `security-engineer` role). If your Claude Code
predates plugin dependencies, install them manually:

```
/plugin install frontend-design@claude-plugins-official
/plugin install claude-security@claude-plugins-official
```

Both are Anthropic-proprietary, so they install from Anthropic's own
marketplace and are referenced here by name only — never redistributed
(see the companion-skills note in [AGENTS.md](AGENTS.md)).

### Channel 3 — Codex plugin (skills)

The repo root is also a Codex plugin (`.codex-plugin/plugin.json`) with its
own marketplace (`.agents/plugins/marketplace.json`):

```
codex plugin marketplace add daedalus-ai-forge/developer-harness --ref v0.1.0
/plugins   # in the Codex TUI: install developer-harness, then invoke $<skill-name>
```

`--ref` pins the marketplace to a tag, branch, or commit SHA; omit it and you
track the default branch — fine while evaluating, not fine once a guard hook
or a review gate is load-bearing.

Details, invocation syntax, and caveats: [docs/consume-codex.md](docs/consume-codex.md).

## Supply chain and trust

Installing a marketplace plugin hands an agent instructions it will follow and
scripts it will execute, in your repo, with your credentials on the machine.
That is a dependency decision, not a convenience — and it applies to this
harness exactly as much as to anything else you install. Review it the way
you would review a package you are about to `npm install`.

**What installing the Claude Code plugin also installs.** Two cross-marketplace
dependencies resolve from Anthropic's official `claude-plugins-official`
marketplace:

| Dependency | What it adds | Why it is a dependency, not a copy |
| --- | --- | --- |
| `frontend-design` | Aesthetic direction for the `ux-designer` role — typography, visual intent, choices that don't read as templated defaults. Advisory reference; `ux-designer` works without it. | Anthropic-proprietary licence; referenced by name, never redistributed. |
| `claude-security` | A `/claude-security` command running multi-agent scan-codebase / scan-changes / suggest-patches passes, available to the `security-engineer` role. Advisory. | Anthropic-proprietary licence, limited internal-use grant. |

Claude Code shows the will-install set before it resolves dependencies — read
that list rather than confirming through it. Two things are worth knowing
before you do: neither dependency is required for any harness role to
function (both degrade to prose guidance when absent), and both come from
Anthropic's own marketplace rather than a third party. If you would rather
not take them, install the companions manually and skip the plugin channel
in favor of the skills CLI, which pulls no dependencies at all.

**Review hook wiring like executable code, because it is.** Every guard in
`hooks/` is a shell script that runs on your machine before a tool call —
six of the nine wired by default when you install the plugin, three shipped
unwired. Read the scripts and the dialect file (`hooks/claude.hooks.json`,
`hooks/codex.hooks.json`) before trusting them; they are short, dependency-free
bash by design, precisely so that reading them is realistic. Each tool has a
trust gate for exactly this: Codex feature-gates hooks and asks you to review
each non-managed one under `/hooks`; Cursor and Claude Code surface hook
configuration on install. Treat a hook you have not read the way you would
treat a `postinstall` script you have not read — and note that this cuts both
ways: a guard you disable because it was inconvenient is a guard that will
not be there on the commit that needed it.

**Scan instruction content before it reaches an agent.** Skills, role
contracts, and rules fragments are prompts an agent will follow, which makes
them an injection surface — a marketplace skill can carry instructions its
description never mentions, and can carry them in characters your reviewer
cannot see. The harness ships
[`hooks/scripts/instruction-scan.sh`](hooks/scripts/instruction-scan.sh) for
that specific class: it scans instruction-bearing files for invisible-Unicode
injection vectors — Unicode Tag characters, zero-width characters, bidi
overrides — and it is worth pointing at vendored content as much as at your
own. It is an opt-in guard, not default-wired, because the natural home for a
whole-tree scan is CI.

`instruction-scan.sh` covers what is invisible, not what is merely
misleading; a skill whose plain-text instructions are hostile passes it. For
a second opinion from outside this repo, Invariant Labs'
[`mcp-scan`](https://github.com/invariantlabs-ai/mcp-scan)
scans agent tool and skill content for prompt-injection and tool-poisoning
patterns across all four of the tools this harness targets. Run a scan over
any marketplace content you are about to install — including this one.
A harness that tells you to review its supply chain and exempts itself is
not making an argument, it is making an advertisement.

**Pinning, and where it is still open.** The Codex channel pins with
`--ref` (above), and the skills CLI pins by content hash in
`skills-lock.json` — both give you a reproducible install and a diff to read
before you move. The Claude Code channel is the gap: this repo does not
declare a ref or version pin on its two cross-marketplace dependencies,
because no such field is confirmed for dependency entries in the versions
targeted here, and shipping configuration that may be silently ignored is
worse than shipping none. Until that is confirmed, pin the Claude Code side
by pinning what you can see — install from a tagged clone, and re-read the
diff when you update. Adding a declared pin is tracked as a follow-up.

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

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
  `design-team/`, `research-team/`, `validation-team/`) load as-is
  (`_template.md` is a scaffold, not a usable role; delete or replace it in
  real use)
- hooks — declared via `plugin.json` → `hooks/claude.hooks.json` (no
  auto-discovered `hooks/hooks.json` exists): six guard scripts as
  `PreToolUse` hooks — the two safety guards unnarrowed (and
  `protected-paths-guard` additionally on the file tools), the four commit
  guards narrowed with `if: "Bash(git commit*)"`; `${CLAUDE_PLUGIN_ROOT}`
  resolves the paths. Three more ship unwired — see below

## Role frontmatter: enforced boundaries

Every harness role says what it will not do — "gates and reviews, never
implements", "reports drift, never patches product code". In Claude Code that
sentence is backed by frontmatter rather than left to good intentions: the
roles whose contracts forbid editing carry a `disallowedTools` line naming the
edit tools, and Claude Code refuses those tools to the subagent:

```yaml
---
name: tech-lead
description: The design gate and the conformance verdict. …
model: inherit
disallowedTools: Edit, NotebookEdit
---
```

Prose boundaries are a request; `disallowedTools` is a wall. The distinction
matters most exactly where the pressure is highest — a reviewer that has just
found the bug and could "just fix it" is the failure mode this closes. Two
tiers, derived from each contract's own Boundaries: the six validation-team
roles deny `Write, Edit, NotebookEdit` (their deliverable is a verdict
returned to the caller), while `tech-lead` and the authoring roles deny
`Edit, NotebookEdit` and keep `Write`, because each files its own document.
The seven implementation roles carry no line at all: writing code is the job.
`debugger` also ships without a denylist — deliberately: its contract permits
an explicitly-authorized fix once the root cause is proven, so the prose
governs and a repo wanting hard read-only adds the line locally.

Bash is never denied anywhere — a verdict without executed evidence is
worthless — and no contract ships a `tools:` allowlist, which would have to
enumerate every tool a role might ever need, including the ones a
multi-agent harness injects at runtime. The deny lists are defaults, not
verdicts on your workflow: copy a contract into your own `.claude/agents/`
and adjust the line, and the repo-local file wins over the plugin's. Full
table and the per-role override notes:
[`../agents/README.md`](../agents/README.md).

Three notes on what the frontmatter does *not* buy you:

- **The plugin channel ignores `permissionMode`, `hooks`, and `mcpServers` on
  agent frontmatter.** Agents loaded from a plugin get `disallowedTools`
  enforcement and nothing else from that family, so never encode a boundary
  in a field the channel drops — if it must hold, it belongs in
  `disallowedTools`, in a hook, or (for humans) in the contract body.
- **The `skills:` preload field is a candidate, not something shipped here.**
  It would let a role declare the skills it always loads — `debugger` pulling
  `systematic-debugging`, `researcher` pulling `deep-research`. No shipped
  contract sets it, and none should until one thing is verified: how a skill
  name resolves when the skill arrives through a *plugin namespace*
  (`/developer-harness:systematic-debugging`) rather than sitting in the
  project's own skills directory. That is exactly the install shape this
  channel produces, and a name that fails to resolve fails silently. Until a
  consumer confirms it in their own install, the roles that want a companion
  skill say so in prose, which degrades correctly everywhere. If you verify
  it, say so — the field is worth having.
- **Copies drift.** `disallowedTools` protects the copy Claude Code loaded,
  not the role file you pasted into a wiki.

## Teams: sequential subagents by default

The harness declares multi-role chains as teams
([`../rules/agents-md/teams-section.md`](../rules/agents-md/teams-section.md)),
and every declared team carries an `execution-mode` of `agent-team`,
`subagents`, or `single-session`. Claude Code's agent-teams feature is
**experimental**, so the harness defaults to the other two: each stage runs
as its own subagent with the role contract loaded, or one session adopts the
roles in sequence. Both are first-class — `single-session` is not a degraded
fallback, and the `feature-build` skill runs correctly either way.

That default is not just conservatism about an experimental flag. The
official guidance points the same direction: work that is sequential, touches
the same files, or is dependency-heavy — one stage's output being the next
stage's input, which is exactly what a gated chain is — runs better in a
single session than split across a team of agents, where parallel workers
contend over the same files and lose the shared context the chain depends on.
Agent teams pay off when the work genuinely forks; a plan gate → implement →
conformance review → verdict chain never does.

If you turn agent teams on anyway, set `execution-mode: agent-team`
explicitly in the team entry, keep `fix-rounds` and the human checkpoints as
declared, and treat the handoff record as mandatory rather than implied — the
six required elements exist precisely because instruction-file inheritance
across delegation is unreliable.

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

## Guards: six wired by default, three opt-in

Nine guard scripts ship under `hooks/scripts/`, and the wiring splits them by
whether the policy they encode is universal. Six are wired in
`hooks/claude.hooks.json` and arrive with the plugin:

| Layer | Script | Narrowing |
| --- | --- | --- |
| Safety | `dangerous-command-guard.sh` | every Bash call — a destructive command is not a commit-time concern |
| Safety | `protected-paths-guard.sh` | every Bash call **and** every file tool (`Write`/`Edit`/`MultiEdit`/`NotebookEdit`/`Read`) — credential dirs (`.ssh`, `.aws`, `.env*`) are zero-access, test directories are no-delete |
| Commit | `secret-scan.sh` | `Bash(git commit*)` |
| Commit | `check-large-files.sh` | `Bash(git commit*)` |
| Commit | `check-merge-markers.sh` | `Bash(git commit*)` |
| Commit | `quality-gate.sh` | `Bash(git commit*)` |

The other three ship **unwired**, on purpose — each encodes a policy a given
repo may not hold, and a guard that blocks work for a reason the team never
agreed to is a guard the team learns to bypass:

- [`instruction-scan.sh`](../hooks/scripts/instruction-scan.sh) — scans
  instruction-bearing files (`skills/`, `rules/`, `agents/`, `commands/`,
  root Markdown) for invisible-Unicode injection vectors: Tag characters,
  zero-width characters, bidi overrides. That is the surface you inherit
  whenever you vendor a skill from anywhere, this repo included — but it
  belongs in CI over the whole tree rather than on every commit.
- [`agents-md-budget.sh`](../hooks/scripts/agents-md-budget.sh) — computes
  the largest AGENTS.md chain a working directory would be handed and blocks
  past 32 KiB (warning from 24 KiB). That is Codex's silent-truncation
  budget, and it matters in Claude Code repos too, because the same AGENTS.md
  usually serves both tools and the tail simply stops existing in either.
- [`done-authority-gate.sh`](../hooks/scripts/done-authority-gate.sh) — a
  Stop-event gate refusing "done" until the team's declared done-authority
  has recorded an accepted verdict in the team status file. Only meaningful
  where a `## Teams` entry actually declares one.

[`../hooks/README.md`](../hooks/README.md) is authoritative: every script,
what it blocks on, its env overrides, and the wiring for the three opt-ins.
Read it before wiring, not after a guard surprises you — and when one blocks,
fix the underlying issue rather than the guard.

## Piecemeal

- **Agents**: copy a role file into `.claude/agents/` — format is markdown
  with `name` + `description` frontmatter, optional `model: inherit`, plus
  `disallowedTools` on the roles that must not edit. Claude Code reads
  `.claude/agents/` recursively, so the grouped structure
  (`agents/develop-team/`, `agents/design-team/`, …) can be copied as-is.
- **Hooks**: copy the scripts under `hooks/scripts/` and wire them in
  `.claude/settings.json` — exact JSON in [`../hooks/README.md`](../hooks/README.md).
- **Rules**: paste [`../rules/agents-md/guards-section.md`](../rules/agents-md/guards-section.md)
  into your `CLAUDE.md`.

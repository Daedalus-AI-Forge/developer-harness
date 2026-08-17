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

**Pin the ref for reproducible installs.** `marketplace add` takes an
official `--ref` flag naming a git tag, branch, or commit SHA; without it the
marketplace tracks the default branch, so what you install today and what a
teammate installs next month are different content:

```
codex plugin marketplace add daedalus-ai-forge/developer-harness --ref v0.1.0
```

Pin to a tag (or a full SHA) in any repo where a guard hook or a review gate
is load-bearing, and move the pin deliberately — re-run `marketplace add`
with the new ref, read the diff, then reinstall. Treat an unpinned
marketplace the way you would treat an unpinned dependency.

Then open `/plugins` in the TUI and install `developer-harness` from the
marketplace entry. Once installed:

- `/plugins` — browse, install, and inspect plugins
- `$<skill-name>` — invoke a bundled skill explicitly, e.g.
  `$tighten-types src/models.py`

Two surface caveats, both from the official
[plugins](https://developers.openai.com/codex/plugins) doc. First, where
plugins run: Codex CLI and Codex in the ChatGPT desktop app (plus ChatGPT
Chat and Work on web, desktop, and mobile) — **the Codex IDE extension does
not support plugins**, so nothing above applies there. Second, installation
is not live in the installing session: bundled skills become available when
you start a new chat or CLI session after installing, so restart before
concluding a skill or hook failed to arrive.

Every skill ships an OpenAI sidecar (`skills/<name>/agents/openai.yaml`) with
`display_name` and `short_description` — that is what Codex shows in its skill
picker — plus a `default_prompt` on the explicitly-invocable skills
(tighten-types, contract-docstrings, architect-design-review,
architect-codebase-review, mermaid-skill, gantt-roadmap, feature-build,
define-team, role, systematic-debugging, deep-research, grill-me,
skill-creator).
Vendored skills include `systematic-debugging` (from obra/superpowers) —
invoke `$systematic-debugging` when debugging starts; `deep-research`
(authored in-house, MIT) — `$deep-research` for multi-source verified
evidence; `grill-me` (from mattpocock/skills, MIT) — `$grill-me` to
stress-test a plan; `skill-creator` (from anthropics/skills, Apache-2.0) —
`$skill-creator` when creating or updating a skill; and `karpathy-guidelines`
(from multica-ai/andrej-karpathy-skills, MIT) — auto-selected while coding, no
`$` invocation. Codex cannot read Claude Code plugins, so these vendored
copies are the Codex path to those skills.

The split is also declared, not just documented — but note that
"explicitly invocable" and "explicit-only" are different sets. The nine
explicit-ONLY sidecars (tighten-types, contract-docstrings,
architect-design-review, architect-codebase-review, feature-build,
define-team, role, grill-me, skill-creator) carry
`policy.allow_implicit_invocation: false` alongside their `default_prompt`,
so Codex offers them in the picker and on `$name` but does not pull a whole
review or team-orchestration pipeline into a session on description match
alone. The remaining four invocable skills — mermaid-skill, gantt-roadmap,
systematic-debugging, deep-research — keep a `default_prompt` but carry no
such policy, because they are also auto-selected companions to a role.
Load-before-writing references carry neither and stay auto-selectable —
that is the point of them.

Note on `skill-creator` in Codex: its authoring guidance and schemas work
as-is, but its bundled eval/benchmark and description-tuning scripts invoke
the `claude` CLI (`claude -p`) and write `.claude/commands/`, so that
workflow needs Claude Code alongside (details in
[`../VENDOR-ATTRIBUTION.md`](../VENDOR-ATTRIBUTION.md)).

Guard hooks are bundled and declared per tool — there is deliberately no
auto-discovered `hooks/hooks.json`. `.codex-plugin/plugin.json` declares
`"hooks": "./hooks/codex.hooks.json"` (Codex dialect: `${PLUGIN_ROOT}`, no
`if`, statusMessages); the Claude dialect lives separately in
`hooks/claude.hooks.json`. Authoritative wiring reference and the current
script list: [`../hooks/README.md`](../hooks/README.md).

**Verification status of the Codex hook wiring.** The `hooks` key on
`plugin.json` is official, and the dialect file is written to the published
schema — but that schema is asserted from documentation here, not smoke-tested
against a live Codex install in this repo, and the event names and payload
shape are the part most likely to drift. Treat `hooks/codex.hooks.json` as
*candidate* configuration until you have watched it fire: install the plugin,
open `/hooks` in the TUI to review and trust the hooks (hooks are enabled by
default and never run untrusted — trust is recorded against each hook's hash,
so any change forces re-review; `[features] hooks = false` in
`~/.codex/config.toml` is the off switch, per the
[hooks](https://developers.openai.com/codex/hooks) doc), then stage a file
with an obvious fake credential and attempt a commit. If the
guards do not fire, nothing silently degrades — the scripts are dual-use, so
fall back to the plain-git driver in
[`../hooks/README.md`](../hooks/README.md), which needs no agent at all. Report
a schema mismatch rather than working around it in the dialect file.

## 2. skills CLI

```
npx skills add daedalus-ai-forge/developer-harness --all
```

The CLI vendors skills into `.agents/skills/`, which Codex reads natively
(cwd, parent directories, repo root, plus `~/.agents/skills`). Invoke with
`$` + skill name or the `/skills` selector; Codex also auto-selects skills
whose `description` matches the task. No plugin machinery involved — use this
when you want the skills pinned in-repo by content hash (`skills-lock.json`).

**Mind the skill-catalog context budget before installing all 26.** Codex's
initial skills list uses at most 2% of the model's context window, or 8,000
characters when the window is unknown; past that, Codex shortens skill
descriptions first and, for large sets, may omit skills from the list with a
warning ([skills](https://developers.openai.com/codex/skills)). This repo's
26 skill descriptions total roughly 7.8K characters before names and paths
are counted, so a full install sits at that fallback budget — expect
shortened entries, and possibly omitted ones, in sessions where the window
is unknown or small. The budget governs only that initial list — Codex still
reads the full `SKILL.md` of any skill it selects — but a skill omitted from
the list is invisible to auto-selection, and whether `$name` still reaches it
is not stated in the doc (verify against a live install before relying on
it). If that bites, install the subset you use instead of `--all`: drop the
flag for an interactive picker, or name skills directly —

```
npx skills add daedalus-ai-forge/developer-harness \
  --skill tighten-types --skill systematic-debugging
```

Caveat: the two architect skills depend on the sibling dirs
`skills/architect-shared/` and `skills/contracts/` (no SKILL.md, so per-skill
installers may skip them) — when vendoring selectively, copy those two dirs
alongside. A second consequence of the missing `SKILL.md`, for anyone
repackaging this repo for the **public plugin directory**: submission
validation requires every immediate child of `skills/` to contain one
(`skill_manifest_missing`,
[submission-errors](https://developers.openai.com/plugins/deploy/submission-errors)),
and no manifest-level exclude exists, so those two shared dirs would have to
move out of `skills/` first. Marketplace and skills-CLI installs document no
such check; treat local tolerance as documentation-sourced — verify against
a live install.

## 3. Agents — two paths

Plugins carry no role contracts, and Codex custom agents are TOML, not
markdown, so the role contracts in `agents/` reach Codex either by routing
(cheap, works everywhere) or by materialization (native subagents, more setup).

### 3a. Routing via AGENTS.md

1. Copy the role files somewhere in your repo (e.g. `docs/roles/`).
2. Paste [`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md)
   into your `AGENTS.md` and point each row at a role file.

Codex concatenates `AGENTS.md` files from the repo root down, so keep the
routing table short and let the contract files carry the detail — see the
budget note below, which is the failure mode this path actually hits.

The `role` skill rides this path: `$role <role-name>` adopts one of the
copied contracts for the session — resolved from the repo's role files or
the `## Roles` table, never approximated from memory — and holds the
delegation-first stance: boundaries absolute, out-of-lane work handed to
the owning role or team rather than absorbed.

### 3b. Materializing roles as `.codex/agents/*.toml`

Codex reads project-scoped subagents from `.codex/agents/<name>.toml` (user
scope: `~/.codex/agents/`). One file per role, three required keys:

```toml
# .codex/agents/qa-reviewer.toml
name = "qa-reviewer"
description = "Delegate adversarial review of a diff, PR, or \"done\" claim. Verifies with executed evidence, never a summary."
developer_instructions = """
<paste the body of agents/validation-team/qa-reviewer.md here>
"""

# model = "<model-id>"           # optional — omit to inherit the session model
sandbox_mode = "read-only"       # optional — see below
```

`name` and `description` carry over from the harness role's frontmatter
verbatim; `developer_instructions` takes the contract body (Bindings /
Mission / Method / Deliverable / Boundaries) — a TOML multi-line string, so
mind literal `"""` in the body. Optional keys documented alongside those
three: `model`, `sandbox_mode`, `mcp_servers` (which MCP servers this agent
may reach), and a skills configuration table for narrowing which skills the
agent loads. Only add the latter two once you have read the schema for your
Codex version — an unknown key is worth less than a paragraph in the role
body telling the agent what it may touch.

**`sandbox_mode` is the Codex analogue of tool restriction.** Codex has no
per-agent tool denylist, but it has a session-level sandbox, and that is
where a harness boundary becomes enforceable: "reviews, never implements"
stops being prose the model may rationalize past and becomes something the
runtime refuses.

The mapping is not one-to-one, because the sandbox is coarser than a tool
list. Give `sandbox_mode = "read-only"` to the roles that file nothing at
all — the six `validation-team/` roles and `debugger`, the ones denying
`Write, Edit, NotebookEdit` in the Claude Code dialect. Everyone else needs
to write *something*: `tech-lead` files buy-vs-build calls and the
decomposition into `<design-docs>`, and the authoring roles each file their
own spec, ledger, plan, or research note, so a read-only sandbox would
disable them outright. Those roles run at the workspace-write level your repo
normally uses, and their "never patches product code" boundary stays prose
plus review — state it in `developer_instructions` rather than pretending the
sandbox is carrying it. Implementation roles get workspace-write for the
obvious reason.

**Smoke-test spawning before you rely on it.** Subagent name resolution in
Codex carried defects that were only fixed mid-2026 — agents that existed on
disk but would not spawn by name. After writing the files, spawn each role
once by name in a throwaway session and confirm it answers as that role
before wiring a chain that assumes it. If yours does not resolve, upgrade
Codex or fall back to routing (3a) — do not build a team on a subagent you
have not seen start.

### AGENTS.md budget: 32 KiB, truncated silently

Codex's concatenated instruction context has a default 32 KiB budget, and
overflow is dropped **without a warning** — the tail of your AGENTS.md simply
stops existing, and nothing in the session says so. Roles pasted inline,
long `## Teams` chains, and a `## Project bindings` table are exactly the
content that pushes a repo over. Two consequences: keep AGENTS.md a routing
table pointing at files, and check the size mechanically rather than by eye.

The harness ships that check as
[`../hooks/scripts/agents-md-budget.sh`](../hooks/scripts/agents-md-budget.sh):
it computes the largest AGENTS.md **chain** a working directory would be
handed — the root file plus every nested one on the path, which is what Codex
actually concatenates — and blocks past 32768 bytes, warning from 24576. It
ships **opt-in**, not default-wired, so wire it yourself where it matters:
in CI, or as a commit guard so an overflowing AGENTS.md is refused instead of
silently truncating an agent's instructions. Wiring, thresholds, and env
overrides: [`../hooks/README.md`](../hooks/README.md).

## Hooks and rules

Hooks: plugin installs get the default-wired guards via
`hooks/codex.hooks.json`; standalone (non-plugin) repos copy that file's
shape into `.codex/hooks.json` — feature toggle, trust flow, and which
guards are default-on versus opt-in are all in
[`../hooks/README.md`](../hooks/README.md), which is the single source of
truth for the script list. Rules: paste
[`../rules/agents-md/guards-section.md`](../rules/agents-md/guards-section.md)
into `AGENTS.md` so the agent knows the guards exist and doesn't fight them.

One more line worth pasting for Codex specifically: whichever roles you
materialize under `.codex/agents/`, name them in the `## Roles` table too.
The TOML files are what Codex spawns; the table is what a session reading
AGENTS.md knows exists.

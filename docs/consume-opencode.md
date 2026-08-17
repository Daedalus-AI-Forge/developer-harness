# Consuming developer-harness from OpenCode

OpenCode consumes **skills** and **commands** natively; hooks route through a
JS plugin, roles through `AGENTS.md`. Docs verified 2026-08:
[skills](https://opencode.ai/docs/skills/),
[commands](https://opencode.ai/docs/commands/),
[plugins](https://opencode.ai/docs/plugins/),
[agents](https://opencode.ai/docs/agents/),
[rules](https://opencode.ai/docs/rules/),
[config](https://opencode.ai/docs/config/) and the published
[config schema](https://opencode.ai/config.json). Where a shape below says
"verified live", it was exercised against opencode 1.18.15.

## Skills (native — two options)

**Option A — point OpenCode at a clone (recommended).** OpenCode scans
configured skill paths recursively for `**/SKILL.md`. This repo ships that
config at its root — [`opencode.json`](../opencode.json) — so working inside
a clone needs no setup at all:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": {
    "paths": ["skills"]
  }
}
```

From any other project, use the same shape with the path to the clone
(`"paths": ["<path-to-clone>/developer-harness/skills"]`). The `skills.paths`
key comes from the published [config schema](https://opencode.ai/config.json)
("Additional paths to skill folders" — the
[config docs page](https://opencode.ai/docs/config/) does not list it), and
it is verified live: with this file at the repo root, `opencode debug skill`
finds the whole `skills/` tree; without it, none of it. Two notes from that
run: config is read at startup, so restart OpenCode after adding the file;
and skills deduplicate by name, so a same-named skill in a global directory
(`~/.claude/skills/`, `~/.config/opencode/skills/`) shadows the repo copy —
`skill-creator` is the likely collision.

This also keeps the architect skills' sibling resource dirs
(`skills/architect-shared/`, `skills/contracts/`) in place — the selective-
vendoring caveat below never applies. Update with `git pull`.

**Option B — vendor via the skills CLI:**

```
npx skills add daedalus-ai-forge/developer-harness --all
```

OpenCode discovers skills in `.opencode/skills/`, `.claude/skills/`, and
`.agents/skills/` (project) plus the `~/.config/opencode/`, `~/.claude/`, and
`~/.agents/` equivalents — the CLI's default vendoring works as-is. The agent
loads them on demand through its native `skill` tool when a task matches a
skill's `description`.

Option-B caveat: the two architect skills depend on the sibling dirs
`skills/architect-shared/` and `skills/contracts/` (no SKILL.md, so per-skill
installers may skip them) — when vendoring selectively, copy those two dirs
alongside.

Vendored skills include `systematic-debugging` (from obra/superpowers),
`deep-research` (authored in-house, MIT) for multi-source verified evidence,
`grill-me` (from mattpocock/skills, MIT) to stress-test a plan, and
`skill-creator` (from anthropics/skills, Apache-2.0) when creating or
updating a skill, and `karpathy-guidelines` (from
multica-ai/andrej-karpathy-skills, MIT), loaded on demand while writing or
reviewing code — OpenCode cannot read Claude Code plugins, so these
vendored copies are the OpenCode path to those skills.

## Commands (copy)

For explicit invocation, copy the wrappers into `.opencode/commands/`
(project) or `~/.config/opencode/commands/` (global):

```bash
mkdir -p .opencode/commands
cp path/to/developer-harness/commands/*.md .opencode/commands/
```

Then run e.g. `/tighten-types src/models.py` — or `/role tech-lead` to adopt
a shipped role contract for the session: the `role` skill resolves the
contract from the role files copied into the repo (or the `## Roles` table —
see Agents below) and delegates out-of-lane work rather than absorbing it.
Dialect notes: OpenCode
documents `description`, `agent`, `model`, and `subtask` frontmatter and
supports `$ARGUMENTS` (plus positional `$1`, `$2`, ...) — all compatible with
these wrappers. The `argument-hint` field is a Claude Code extension; OpenCode
doesn't document it, so drop it if your version complains.

## Agents — convert, don't just route

OpenCode's native agents live in `.opencode/agents/<role>.md` (project) or
`~/.config/opencode/agents/` (global) and the frontmatter maps nearly 1:1
onto a harness role contract — `description` carries over verbatim, `model:
inherit` is dropped (not a valid OpenCode provider/model id), `mode:
subagent` is added, and the whole body (Bindings / Mission / Method /
Deliverable / Boundaries) stays untouched:

```markdown
---
description: Delegate adversarial review of a diff, PR, or "done" claim. Verifies with executed evidence, never a summary.
mode: subagent
permission:
  edit: deny
---

<body of agents/validation-team/qa-reviewer.md, unchanged>
```

That mapping ships as a script —
[`../scripts/agents-to-opencode.sh`](../scripts/agents-to-opencode.sh)
(bash, dependency-free, like every other executable in this repo):

```bash
path/to/developer-harness/scripts/agents-to-opencode.sh .opencode/agents
```

It converts every role contract in `agents/` (skipping READMEs and any
scaffolding file starting with `_`): `description` verbatim, `mode: subagent`
added, `model: inherit` dropped, any `disallowedTools` denylist containing
`Edit` mapped to `permission: edit: deny`, body untouched. It prints every
file it writes, refuses to overwrite without `--force`, never writes outside
the target directory, and is idempotent — re-run it after a `git pull`.
Verified live: all converted roles register as subagents in
`opencode agent list`.

**`permission: edit: deny` is why conversion beats routing.** Every judging
role in the harness says "reviews, never implements" — as prose, that is a
request the model can rationalize past under pressure. Under OpenCode it can
be enforced — verified live at the config layer: `opencode debug agent
qa-reviewer` on a converted contract resolves `edit → deny` (the tool-call
refusal itself is OpenCode's own permission system, not re-tested here).
The mapping is mechanical:
every role that carries a `disallowedTools` line in the harness gets
`edit: deny` here — the whole `validation-team/` group, plus `tech-lead` and
the authoring roles (`product-owner`, `person-of-contact`, `product-manager`,
`project-manager`, `legal-reviewer`, `ux-designer`, `content-designer`,
`design-system-steward`, `technical-artist`, `researcher`, `analyst`).
`debugger` ships no denylist — its contract's explicitly-authorized-fix path
governs; add `edit: deny` locally for hard read-only. The
harness's two tiers collapse into one here, since OpenCode's `permission`
block has no separate write/edit split; the roles that file their own
documents lose a little reach in exchange for a boundary the runtime holds.
The seven implementation roles keep edit rights, obviously — restrict by
boundary, never by default. Leave `bash` permitted throughout: a verdict
without executed evidence is worthless.

The full denylist table, with each role's own override note, is in
[`../agents/README.md`](../agents/README.md).

Routing via `AGENTS.md` — copy role files into the repo and paste
[`../rules/agents-md/roles-section.md`](../rules/agents-md/roles-section.md)
— still works and costs nothing, but it buys description-level awareness
only: no spawnable subagent, no enforced boundary. Use it for roles you
consult and conversion for roles you delegate to.

## Hooks (JS plugin shim)

OpenCode has no hooks.json; its hook surface is a JS plugin
([plugins docs](https://opencode.ai/docs/plugins/)). The shim ships as a
reviewable file — [`../hooks/opencode.guards.js`](../hooks/opencode.guards.js)
— that runs the guard scripts in `tool.execute.before` and blocks by
throwing, with the blocking guard's stderr as the error message, so the
refusal arrives with its reason. Install by copying:

```bash
mkdir -p .opencode/plugins
cp path/to/developer-harness/hooks/opencode.guards.js .opencode/plugins/guards.js
```

The shim narrows to `git commit` bash calls in JS before invoking the commit
guards, so the expensive quality gates never fire on ordinary commands; the
full wiring notes are in [`../hooks/README.md`](../hooks/README.md). The
install is a deliberate copy step, not part of the shipped `opencode.json`:
a plugin is executable code, and hook wiring arriving inside a cloned
repository is exactly the thing to read before it runs (hooks/README.md,
"Three things to know"). The shim expects the guard scripts in
`hooks/scripts/` under the project root — set `GUARD_SCRIPTS_DIR` when they
are vendored elsewhere. Verified live: the plugin loads cleanly from
`.opencode/plugins/` (and a plugin whose initializer throws is reported as
`failed to load plugin`, so a broken install fails loudly, not silently).

## Rules — and the file-reference trap

OpenCode reads `AGENTS.md` at the project root (and
`~/.config/opencode/AGENTS.md` globally), and prefers it: where both exist,
`AGENTS.md` takes priority over `CLAUDE.md`, so a repo carrying both should
treat `AGENTS.md` as the real file and `CLAUDE.md` as the `@AGENTS.md`
pointer.

The trap: **OpenCode does not follow file references inside AGENTS.md.** A
`## Roles` table whose rows link to `docs/roles/qa-reviewer.md` puts the
names in context and nothing else — the linked contracts are not pulled in,
and nothing announces the difference. The agent may still open the file with
its read tool, but "may" is not what a gate is built on, and a role whose
Boundaries section never loaded is a role in name only. Two fixes, and the
first is the one to use:

**Load the contracts as instruction files.** OpenCode's config takes an
`instructions` array of paths and globs, each loaded into context alongside
`AGENTS.md`:

```jsonc
// opencode.json — at the project root
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "docs/roles/*.md",
    "docs/rules/*.md"
  ]
}
```

Point the globs at wherever you copied the role contracts and the pasted
`rules/agents-md/` fragments. Everything matched is loaded, so glob narrowly
— a directory of twenty-six role contracts in every session is a context
budget spent on roles the task will never use. The usual shape is a small
`docs/roles/` holding only the roles that repo actually delegates to, with
the rest reachable by conversion into `.opencode/agents/` (loaded on demand
when spawned, not up front).

**Or inline the content.** Paste the guards/roles templates from
[`../rules/agents-md/`](../rules/agents-md/) into `AGENTS.md` bodily rather
than linking to them. Cheap and reliable; it just grows the always-loaded
file, so reserve it for the short fragments — the guards section, the
bindings table — and let the instruction globs carry the long ones.

---
name: role-name
description: The role's lane in a few words. Use when <the concrete situations that should route here>. <The one boundary a caller most often gets wrong.>
model: inherit
disallowedTools: Edit, NotebookEdit
---

# Role Name

<!-- ROLE CONTRACT TEMPLATE. This scaffold lives in rules/ rather than
     agents/ because every markdown file in a plugin's agents/ directory
     installs as a live subagent (read recursively, no exemption for
     underscore-prefixed files) — a template kept there would ship a bogus
     `role-name` role to every consumer. Copy this file into the target
     agents directory (this repo's agents/<team>/, or a consuming repo's
     .claude/agents/), rename it to the role's name, and fill it in. -->

<!-- FRONTMATTER POLICY — read before filling the block above.

     `name` — lowercase, hyphens, EQUAL to the filename stem. It is the
     address the orchestrator delegates to.

     `description` — a ROUTER RULE, not marketing. It is the only text a
     dispatching agent reads when choosing between twenty-six roles, so it
     must name the *situations* that belong here, not the qualities the role
     has. Shape: lane, then a trigger clause — `Use when …`, or
     `Use PROACTIVELY when …` for the roles that must be engaged BEFORE a
     decision or a build rather than after (legal-reviewer, tech-lead's gate,
     debugger's pre-fix diagnosis are the shipped examples). Keep it under
     500 characters, and close with the boundary callers most often get
     wrong, so a near-miss routes onward instead of being absorbed. Never put
     a numeric target or a capability claim in it that nothing computes.

     `model: inherit` — the default, and the shipped setting for every role
     here. Do NOT pin a tier: a pinned model outlives the tier names it was
     written against, silently overrides the caller's own choice, and is a
     known failure mode in published role libraries. Inheritance keeps the
     decision with the consumer.

     `disallowedTools` — OPTIONAL, and a DENYLIST only. Add it when the
     Boundaries section forbids a class of action, so the prohibition holds
     even when the prose is skimmed. Derive the list from this contract's own
     Boundaries and Deliverable — nothing broader:
       · judges, gates, and diagnosers → `Write, Edit, NotebookEdit`
       · the same, but the Deliverable is a document filed to a bound path →
         `Edit, NotebookEdit` (Write stays for that document)
       · implementation roles → no line at all
     Bash normally stays: a verdict without executed evidence is worthless,
     and it is the Boundaries prose, not the tool list, that governs what
     Bash is for.

     NEVER write a `tools:` ALLOWLIST. An allowlist has to enumerate every
     tool the role will ever need — including the team-communication tools a
     multi-agent harness injects — and omitting one silently breaks the role
     inside a team. Both major published role libraries shipped that bug.

     Pair any `disallowedTools` line with one bullet in Boundaries saying it
     is the mechanical form of the boundary above and that a consuming repo
     may override it by copying this contract into its own agents directory.

     IGNORED FIELDS: when these contracts are distributed through a plugin,
     the consuming tool honors `tools`, `disallowedTools`, and `model`, but
     IGNORES `permissionMode`, `hooks`, and `mcpServers` in agent
     frontmatter. Do not encode a guarantee in a field that will not be read
     — wire hooks at the harness level (`hooks/`) instead.

     UNVERIFIED, THEREFORE UNUSED: a `skills:` field can preload named skills
     into a subagent, but how a name resolves when the skill arrives through a
     plugin namespace is unconfirmed. No contract here sets it — a role that
     wants a companion skill says so in its Method ("load X where installed …
     where absent, this Method stands alone"), which degrades everywhere
     instead of failing silently in one place. See agents/README.md.

     Delete the `disallowedTools` line entirely if this role implements. -->

## Bindings

<!-- Choosing Requires vs Optional: a binding is REQUIRED only when the role
     cannot produce an honest deliverable without it (a missing required
     binding triggers step 4 of the Resolution protocol — the role declares
     itself unavailable and stops). It is OPTIONAL when the role can still
     deliver without it, at reduced depth — the role names the gap and
     continues. Ask: "could this role still return something truthful and
     useful without this binding?" Yes → Optional. Delete whichever line the
     role does not use. -->

- Requires: `<a>`, `<b>` — cannot operate without these (protocol step 4
  applies).
- Optional: `<c>` — enriches the role; degrade gracefully if absent.
- Resolution: per the "Resolution protocol" in the repo's
  `## Project bindings` section (AGENTS.md/CLAUDE.md).

## Mission

What this role exists to produce, in one or two sentences. State the outcome,
not the activity.

## Method

How the role works, as a short ordered list:

1. Gather the inputs it needs (files, diffs, specs).
2. Apply its discipline (the checklist, convention, or review lens it owns).
3. Draft, self-check, and tighten the result.

## Deliverable

The exact artifact returned to the caller — e.g. "a markdown report with one
finding per line: `severity | file:line | issue | suggested fix`". Be concrete
enough that the caller can validate the output mechanically.

## Boundaries

- What the role must NOT do (e.g. never edits files, never runs the test
  suite, never expands scope beyond the given target).
- What it should hand back to the caller instead of deciding itself.
- **Mechanically enforced where supported:** the frontmatter
  `disallowedTools: <list>` is the tool-level form of "<the boundary it
  enforces, quoted from above>" — <what stays, and why>. A consuming repo
  that needs a different balance copies this contract into its own agents
  directory and adjusts the list; the prose above still governs where the
  field is ignored. <!-- Delete this bullet if the role has no
  disallowedTools line. -->

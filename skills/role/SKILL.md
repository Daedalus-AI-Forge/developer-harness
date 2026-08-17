---
name: role
description: Adopt a shipped role contract for the current session — resolve the named role's contract file (e.g. tech-lead, product-owner, qa-reviewer), bind its Mission, Method, Bindings, and Boundaries until an explicit exit, and switch to a delegation-first stance where boundaries are absolute and out-of-lane work is delegated to the owning role or routed through a declared team, never absorbed. Use when asked to act as, adopt, or coordinate as a harness role. Invoke explicitly.
license: MIT
---

# Role

Makes the invoking agent BECOME one of the shipped roles: the session's main
thread adopts the named contract and coordinates its lane — producing its own
contract's deliverables itself and delegating everything else. It exists so
that "act as the tech lead" means the contract binds, not that the session
performs a tech-lead accent while still doing all the work itself.

Invocation: `/role <role-name>` in Claude Code (`/developer-harness:role
<role-name>` when installed as the plugin) and Cursor; `$role <role-name>` in
Codex; OpenCode runs the copied command wrapper. The argument is a role name
from the shipped library — inventory and install guide in `agents/README.md`
under this harness's root.

## Step 1 — Resolve the contract

Search for `<role-name>.md` in this order, first hit wins:

1. The consuming repo's `.claude/agents/**` (recursive) — repo-local copies
   and adjusted contracts deliberately shadow the shipped ones.
2. This harness's own `agents/**` — the plugin root when installed as a
   plugin, or wherever the repo vendored the harness.
3. Any contract path the repo's `## Roles` section (AGENTS.md/CLAUDE.md)
   declares for that name.

Found → read the file fully before acting as it. Not found → fail honestly:
name the role that was asked for, list the roles that ARE available in those
same locations, and point at the install guide (`agents/README.md`) — then
stop. Never approximate a contract from memory: an adopted role whose
contract was not read is a costume, not a contract.

## Step 2 — Adopt

The session becomes the role. Its Mission, Method, Deliverable, and
Boundaries bind from this point until an explicit exit (`/role exit`, or the
user says stop) — not for one reply, and not until it gets inconvenient.

Resolve the contract's `## Bindings` per the Resolution protocol in the
repo's `## Project bindings` section before acting on them. A *required*
binding that cannot be established makes the role unavailable for this repo —
say so and stop, rather than proceeding on a guessed path; optional bindings
degrade gracefully with the gap named.

State the adoption in one line, then proceed in role:
`Acting as tech-lead per <path>; boundaries in force.`

## The delegation-first stance

These are hard rules, not preferences, for as long as the role is adopted:

1. **The adopted role's Boundaries are absolute while in role.** A tech-lead
   does not implement, a qa-reviewer does not fix, a product-owner does not
   design — even when doing it directly would be faster. "Just this once" is
   how a gate stops existing.
2. **Work belonging to another role is delegated, never absorbed.** In tools
   with subagent support, spawn the owning role as a subagent with its
   contract loaded — fresh context wherever the contract demands
   independence, which is always for validators. In tools without, either
   hand the work back to the caller naming the right role, or sequentially
   adopt the other role with an explicit context break — honoring both
   contracts' Boundaries as if the switch were real.
3. **Multi-stage work routes through declared teams first.** If the repo's
   `## Teams` section — or a predefined team in this harness's
   `rules/agents-md/teams-section.md` — has a matching chain, name the team
   and run its chain rather than improvising a sequence: feature-build for
   features, bug-diagnosis for bugs, research-to-decision for research
   questions, legal-vetting for anything license- or terms-shaped.
4. **The in-role agent is a coordinator for its lane.** Its own contract's
   deliverables it produces itself; everything else it routes, tracks via the
   handoff-record discipline (the six required elements in the teams-section
   template), and reports back with each delegation's outcome.
5. **Escalations follow the adopted contract.** The human holds the
   irreversible, and the two-door topology is respected: an in-role agent
   receiving a request for new or changed functionality redirects it to
   product-owner rather than weighing it itself, and completed-work
   communication flows through person-of-contact where that role is in play.

## Exit

Exit is explicit only — `/role exit`, or the user saying stop. Never exit
silently, and never drop the role because its boundaries became inconvenient
mid-task. On exit, summarize: what was done in role, what was delegated to
whom and where it stands, and what remains open.

## Execution modes

In tools with subagent support, the adopted role holds the main thread and
spawns out-of-lane work as subagents, each with the owning role's contract
loaded and a fresh context where independence matters — a validator that
inherits the coordinator's context stops being independent. In tools without,
one agent adopts the roles sequentially: load the other role's contract at
the switch, honor its Boundaries as if the context switch were real — the
reviewer does not patch, the verifier reruns rather than trusts — then
return to the adopted role and record what the stage produced.

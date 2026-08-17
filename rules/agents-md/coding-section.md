# Template: "## Coding rules" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`),
then replace the placeholder rows in the routing table with the repo's actual
languages and convention skills. The seeded rows are this harness's own
examples — keep them where the repo uses those skills, drop them where it
does not.

---

## Coding rules

Repo conventions win over instinct: code is written the way this repo
writes it, not the way any model would write it by default. This section
routes to the conventions; method — TDD, debugging before fixes,
verification before completion — is governed by the `## Engineering
discipline` section (template beside this one).

### Convention routing

Load the matching convention skills BEFORE writing code — the skills are
the rules; this table is only the router:

| Language / domain | Load BEFORE writing |
| --- | --- |
| Python | `python-conventions`; plus `contract-docstrings` on boundary/IO code |
| Rust | `rustdoc-conventions`; plus `rust-api-checklist` when a `pub` item is added or changed |
| Any language | the matching capability skill per the harness AGENTS.md skill-selection guide |
| `<language or domain>` | `<the repo's own convention skill(s)>` |

Quality gates run via the `<lint-command>` and `<test-command>` bindings
(resolved in `## Project bindings`) — never bypassed.

### What belongs here vs in a skill

Coding rules that are one-line-per-rule and always-on belong in this
section, stated directly. Anything reference-sized — a style corpus, an
API checklist, a capability guide — belongs in a skill this table routes
to, loaded when the matching work starts.

# AGENTS.md — developer-harness

## What this repo is

A reusable agent harness: Agent Skills, command wrappers, subagent role templates, guard
hooks, and instruction-file fragments that any repository can adopt. Everything here is
project-agnostic and packaged so Claude Code, Codex, Cursor, and OpenCode can each consume
the classes they understand. This file is the map — read it whether you are working *on*
this repo or selecting a skill *from* it.

## Repo map

```
developer-harness/
├── skills/                  # 20 skills (SKILL.md format), one directory per skill
│   ├── architect-shared/    #   shared resources for the two architect skills (NOT a skill)
│   └── contracts/           #   review contracts for the architect skills (NOT a skill)
├── commands/                # 8 thin /command wrappers around explicitly-invocable skills
├── agents/                  # generic role contracts in five groups (+ _template.md + install guide)
│   │                        #   root — coordination: product-owner, person-of-contact;
│   │                        #     shared specialist: researcher
│   ├── project-control/     #   product-manager, project-manager, legal-reviewer
│   ├── develop-team/        #   tech-lead, developer, frontend-developer, backend-developer,
│   │                        #     devops-engineer, mobile-developer, data-engineer,
│   │                        #     security-engineer, debugger
│   ├── design-team/         #   ux-designer, content-designer, design-system-steward,
│   │                        #     technical-artist
│   └── validation-team/     #   qa-reviewer, design-reviewer, integration-validator,
│                            #     performance-validator, release-validator
├── hooks/                   # guard scripts (scripts/secret-scan.sh) + wiring template (hooks.json)
├── rules/                   # AGENTS.md/CLAUDE.md section templates (## Roles, ## Teams, ## Guards, ## Engineering discipline, ## Project bindings, ## RACI)
├── docs/                    # consume-claude-code.md, consume-codex.md, consume-cursor.md, consume-opencode.md
├── .claude-plugin/          # plugin.json + marketplace.json — repo root is a Claude Code plugin
├── .codex-plugin/           # plugin.json — repo root is also a Codex plugin
├── .agents/plugins/         # marketplace.json for the Codex plugin channel
└── VENDOR-ATTRIBUTION.md    # provenance ledger for vendored skills (+ VENDOR-LICENSE-*.txt)
```

## Skill selection guide

Invocation by tool: `/name` in Claude Code (`/developer-harness:name` when installed as the
plugin) and Cursor; `$name` in Codex; OpenCode loads skills on demand through its native
`skill` tool when the task matches a skill description. Eight skills are explicitly
invocable and ship both a `commands/` wrapper and a Codex `default_prompt`:
**tighten-types, contract-docstrings, architect-design-review, architect-codebase-review,
mermaid-skill, gantt-roadmap, feature-build, define-team**. The rest are
load-before-writing references that tools auto-select by description.

### Python (6 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Implementing any Python code | `python-pro` | Vendored capability reference (async patterns, typing depth, performance, packaging, testing breadth). Read before implementing; it is a reference, not a contract. |
| Writing Python that must follow house style | `python-conventions` | One-line-per-rule conventions: Google docstrings + ruff D config, naming, 3.12+ idioms, typing policy. Load BEFORE writing any Python code. |
| Designing or reviewing a library's public API | `python-api-design` | API shape: progressive disclosure, naming, error design, fail-loud rules, evolution/deprecation/breaking changes. |
| Building library documentation as a deliverable | `python-documentation` | Sphinx setup (autodoc/napoleon/furo), API references, tutorials, ReadTheDocs config. |
| Hardening type annotations on existing code | `tighten-types` | Explicit pass over a given scope: missing attribute types, Pydantic models over loose dicts, overloads, redundant in-body annotations. |
| Documenting failure modes on boundary/IO code | `contract-docstrings` | Docstrings as contracts: input invariants, errors raised on violation, errors from external state, silenced errors. Invoke explicitly on a chosen scope. |

Disambiguation:

- `python-pro` says what Python *can* do; `python-conventions` says how code *is* written
  here. When writing new code load both — conventions win on conflict (the precedence
  block in `python-pro` says so itself).
- `python-conventions` and `python-documentation` both cover Google-style docstrings:
  conventions is the enforcement rule-index while coding; documentation is for producing a
  docs site (Sphinx/ReadTheDocs/tutorials) as an artifact.
- `tighten-types` and `contract-docstrings` are batch passes you point at a file or
  directory, not always-on style rules. Types → tighten-types; failure-mode prose →
  contract-docstrings.
- Library surface questions ("should this be a function or a class?", "how do I deprecate
  this?") → `python-api-design`, not python-pro.

### Rust (4 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Implementing any Rust code | `rust-engineer` | Vendored capability reference (ownership, zero-cost abstractions, async, unsafe discipline, performance). Read after design/planning, before the first failing test. |
| Writing doc-comments or setting lint policy | `rustdoc-conventions` | Project-pinned rules: doc-comment section order, first-sentence ≤15 words, mandatory `# Errors`/`# Safety`, Cargo.toml `[lints]` table. Load BEFORE writing Rust code. Wins all conflicts. |
| Authoring/reviewing public API prose | `rust-pragmatic` | Microsoft Pragmatic Rust Guidelines (M-* rules). Do not read the whole ~33k-token corpus — grep `references/guidelines.txt` for the relevant M-* sections only. |
| Adding/changing a `pub` item, or pre-publication review | `rust-api-checklist` | Official rust-lang C-* API Guidelines checklist (naming, documentation, predictability, dependability). Full checklist before anything goes public; naming + docs sections for internal crates. |

`rustdoc-conventions` is the router: it tells you when to escalate to `rust-api-checklist`
(public API surface changed) or `rust-pragmatic` (doc prose quality), and its rules take
precedence over both.

### TypeScript, C#, Java (4 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Implementing TypeScript | `typescript-pro` | Vendored capability reference: advanced types, generics, type-level programming, end-to-end type safety. |
| Writing TS documentation or ADRs | `typescript-docs` | JSDoc patterns, TypeDoc configuration, ADRs, framework-specific patterns (NestJS, Express, React, Angular, Vue), docs CI. |
| Implementing C# / Unity code | `csharp-developer` | Vendored capability reference: async/await, DI, LINQ, records, analyzers, memory. Fit note inside: for non-web projects (Unity, desktop) take the language craft, discard the ASP.NET/EF architecture opinions. |
| Implementing Java | `java-architect` | Vendored capability reference: modern Java, concurrency, module/service structure, JVM performance. Fit note inside: upstream assumes Maven/Spring; your build tool and framework choices win. |

### Method / review (2 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Gating a design spec BEFORE building | `architect-design-review` | Reads a spec, generates Mermaid architecture diagrams, evaluates against architecture principles, writes an HTML report to `docs/architecture/review/`. Never reviews existing code. |
| Auditing an EXISTING codebase | `architect-codebase-review` | Explores the code, produces current-state diagrams, evaluates, proposes improvements with revised diagrams, writes an HTML report. Never evaluates design specs. |

The two are mutually exclusive by construction — each names the other in its Non-Goals.
Both are read-only apart from the report, and both depend on the sibling directories
`skills/architect-shared/` and `skills/contracts/` (no SKILL.md, so per-skill installers
may skip them — vendor those two directories alongside).

### Diagrams / planning (2 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Any diagram: flowchart, sequence, class, ER, state, architecture… | `mermaid-skill` | Generates `.mmd` sources and exports PNG/SVG/PDF via `mmdc` or the Kroki API; 12+ diagram types, automatic layout, validation before export. |
| Turning a plan/milestones into a schedule | `gantt-roadmap` | Produces a dated Mermaid Gantt chart (phases, dependencies, milestones) plus critical-path, risk, and assumption notes; real ISO dates enable `.ics` calendar export. |

Mermaid can draw Gantt charts too — prefer `gantt-roadmap` when the point is the
*schedule* (dates, dependencies, critical path); prefer `mermaid-skill` when the point is
the *diagram and its export*.

### Team orchestration (2 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Building one scoped feature end-to-end with gates | `feature-build` | Runs the team chain: tech-lead plan gate → TDD implementation → tech-lead design-conformance review → qa-reviewer verdict. One fix round per gate; only the verifier declares done. In tools with subagent support each stage runs as its own subagent with the role contract loaded; elsewhere one agent adopts the roles in sequence. |
| Declaring a custom multi-role team in a repo | `define-team` | Interviews you (name → members from the harness role library → chain with return paths → handoff record → authority rules → optional team memory), validates the entry (every member resolves, exactly one done-authority, every stage has a return path), then appends it to the repo's `## Teams` section and shows the diff. Invoke explicitly. |

`feature-build` composes the roles in `agents/`; the same chain is declarable per repo as
a team (template: `rules/agents-md/teams-section.md`). The template ships five predefined
teams — feature-build, design-review, bug-diagnosis, research-to-decision, legal-vetting —
and `define-team` scaffolds custom ones.

## Guards

`hooks/scripts/secret-scan.sh` scans staged additions (`git diff --cached`) for credential
patterns — AWS `AKIA...` keys, `sk-...` keys, GitHub `ghp_...` tokens, PEM private-key
headers, hardcoded `password=` assignments — and blocks with exit code 2 plus a reason on
stderr. It is dependency-free (bash + git + grep) and exits 0 when nothing is staged.

Wire it per [hooks/README.md](hooks/README.md): as a git pre-commit hook and/or an agent
PreToolUse-style hook (Claude Code wires it automatically via the plugin's
`hooks/hooks.json`; Codex uses `.codex/hooks.json`; Cursor `.cursor/hooks.json`; OpenCode
a JS plugin shim). When a guard blocks, fix the underlying issue — unstage the secret or
move it to an ignored env file — never bypass the guard.

## Roles

`agents/` ships twenty-four concrete generic roles in five groups: the coordination pair
and the shared researcher specialist at the directory root, plus `project-control/`,
`develop-team/`, `design-team/`, and `validation-team/`.

**Coordination root + shared specialist.** **product-owner** (owns the Product Goal and
the single ordered backlog, authors acceptance criteria before work starts, accepts or
returns delivered increments — judges value, never dispatches work or designs solutions)
and **person-of-contact** (resolves completed work against the repo's `## RACI` table,
hands outcomes to the Responsible/Accountable parties, brokers cross-component
collaborations — routes and brokers, never decides value or assigns work). Dispatch
itself lives in the consuming tool's orchestration, not in any role. In team operation
the human has two doors into the team: requests to add or change functionality enter
through product-owner, and handoff communication flows through person-of-contact —
standalone use of a single role is unaffected. **researcher** also sits at the root as a
shared specialist serving develop-team and design-team (cited primary sources, inference
labeled as inference — grounds their decisions, never makes them).

**Project control (`project-control/`).** **product-manager** (problem framing,
personas, prioritization rationale, success metrics — direction not delivery; legal
exposure routes to legal-reviewer), **project-manager** (goals into sequenced, owned
tasks with schedule and risk — consumes product direction, never sets it),
**legal-reviewer** (red-flag ledgers, clause summaries, attorney question lists —
analysis for human review, never final legal advice; any role may engage it before
public-facing or license-touching decisions). The boundary in the management trio:
product-manager answers "are we building the right thing?", product-owner "what is most
valuable next — and did it deliver?", project-manager "will it ship predictably?".

**Develop team (`develop-team/`).** **tech-lead** gates (design gate before build,
buy-vs-build, seam pinning, design-conformance review — never implements);
**developer** is the generic implementation base (TDD from a failing test, repo
conventions, small reviewable changes — implements, never approves its own work); the
layer roles cover one layer's concerns each: **frontend-developer** (UI state,
accessibility, responsive/asset budgets, design fidelity, rendering evidence),
**backend-developer** (API contract discipline, data integrity and migrations, failure
modes and idempotency, observability hooks), **mobile-developer** (platform lifecycle
and background-execution constraints, offline-first data, permissions/privacy UX,
app-store review discipline, device evidence, bundle/battery budgets),
**data-engineer** (schema/migration custody, idempotent replayable pipelines,
data-quality checks as code, PII discipline with lineage, cost awareness),
**devops-engineer** (pipeline custody, reproducible builds, secrets hygiene,
release/rollback — never bypasses gates), and **security-engineer** (defensive only:
threat modeling, secrets hygiene, supply-chain vetting, least-privilege and
trust-boundary review — reviews and hardens, never builds offensive tooling); and
**debugger** closes the loop on failures (root cause with evidence, proposes rather
than fixes). The done-verdict on develop-team's work comes from validation-team's
qa-reviewer, not from anyone inside the team.

**Design team (`design-team/`).** **ux-designer** (buildable design specs: flows,
per-screen states including empty/loading/error/first-run, verifiable visual intent —
consumes product direction, never edits production code), **content-designer**
(interface language: one name per concept in a terminology glossary, errors and empty
states as first-class content, audits of the strings the code actually ships;
legal-sounding copy routes to legal-reviewer), **design-system-steward** (tokens,
components, and conventions in one source of truth; drift audits with canonical
replacements; gated additions — reports drift, never patches product code), and
**technical-artist** (opt-in, for real-time/3D/character products: asset budgets as
gates, mechanical asset validation, the source-to-runtime pipeline documented —
validates and specifies, never authors art). The experience verdict on the built UI
comes from validation-team's design-reviewer. The group adds two bindings to the
vocabulary: `<design-system>` (the design system's source of truth — tokens, component
conventions, theme) and `<design-assets>` (source art/asset files, distinct from code
and docs).

**Validation team (`validation-team/`).** The five independent verdicts on finished
work: **qa-reviewer** (functional — adversarial review with executed evidence, never
implements), **design-reviewer** (experience — fidelity state-by-state, accessibility
with executed checks plus labeled judgment, design-system conformance),
**integration-validator** (integration — the contract under test identified, the real
seam exercised end-to-end and never mocked, contract drift and seam failure modes
probed), **performance-validator** (performance — reproducible measurements against
explicit budgets; no budget or no measurement means no verdict), and
**release-validator** (readiness — the actual artifact built and smoke-tested, claims
traced to merged changes and passing tests, rollback path known). Validators live
outside the teams they judge and none of the five verdicts substitutes for another.
release-validator judges readiness only — whether the release is safely shippable —
while release timing and value stay product-owner's call: readiness and value are
different verdicts.

**Language lives in skills; layer lives in roles; compose per repo.** A
language-specific developer is a dev role plus the matching language skills — e.g.
`dev-csharp` = `developer` + the `csharp-developer` skill — declared in the consuming
repo's `## Roles` section, not shipped here.

The role-contract **template** (`_template.md`: frontmatter + `## Bindings` +
Mission / Method / Deliverable / Boundaries) is for authoring more. The shipped roles
reference project layout only through `<placeholder>` bindings (`<source-root>`,
`<test-command>`, …) that a consuming repo resolves in a `## Project bindings` section
of its AGENTS.md or CLAUDE.md — template in
[rules/agents-md/project-bindings-section.md](rules/agents-md/project-bindings-section.md).
Each contract declares which bindings it **requires** and which are **optional**; a
missing binding is handled by that section's Resolution protocol (infer candidates from
the repo → confirm with the user → persist the row), and a *required* binding that
cannot be established disables the role for the repo — it never proceeds on a guessed
path, while optional bindings degrade gracefully. Multi-role chains — members,
stage order, handoff record, authority rules, optional team memory — are declared per
repo in a `## Teams` section (template in
[rules/agents-md/teams-section.md](rules/agents-md/teams-section.md)); the template
ships five predefined teams (feature-build, design-review, bug-diagnosis,
research-to-decision, legal-vetting), the `feature-build` skill ships that chain as an
executable process, and the `define-team` skill scaffolds custom entries. The
`person-of-contact` role consumes a per-repo `## RACI` section — component ownership
rows it routes communication by — template in
[rules/agents-md/raci-section.md](rules/agents-md/raci-section.md). Project-specific
roles still belong in consuming repos (e.g. their `.claude/agents/`), and both kinds
route through an AGENTS.md `## Roles` section for tools that cannot read markdown agents
(Codex, OpenCode). See [agents/README.md](agents/README.md) and
[rules/agents-md/roles-section.md](rules/agents-md/roles-section.md).

## Contributing to this harness

Hard rules when editing anything in this repo:

1. **Generality.** Nothing project-specific: no product names, no hard-coded repo layouts,
   no absolute paths, no personal data. Every skill, hook, rule, and role template must
   work dropped into ANY repository.
2. **Portable frontmatter only.** SKILL.md frontmatter sticks to the Agent Skills spec
   fields: `name`, `description`, `license`, `compatibility`, `metadata`. `name` must
   equal the directory name.
3. **Vendored skills stay close to upstream.** Bodies are verbatim (or converted per the
   documented shapes) — do not "improve" them. Any local modification must be recorded in
   [VENDOR-ATTRIBUTION.md](VENDOR-ATTRIBUTION.md) with source repo, licence, and revision;
   the `VENDOR-LICENSE-*.txt` files must be preserved.
4. **OpenAI sidecar per skill.** Every skill directory carries
   `agents/openai.yaml` with `interface.display_name` and `interface.short_description`;
   add `default_prompt` only for explicitly-invocable skills (the eight listed above),
   never for load-before-writing references.
5. **English only.** All content in this repo is written in English.
6. **Keep the consumption docs true.** Adding or changing a harness class means updating
   the README consumption matrix and the relevant `docs/consume-<tool>.md`; a new
   explicitly-invocable skill also needs a `commands/` wrapper and a `default_prompt`.

## Consuming this harness

Three channels, detailed per tool in `docs/consume-<tool>.md`
([Claude Code](docs/consume-claude-code.md) · [Codex](docs/consume-codex.md) ·
[Cursor](docs/consume-cursor.md) · [OpenCode](docs/consume-opencode.md)):
skills CLI (`npx skills add daedalus-ai-forge/developer-harness --all` — vendors into
`.agents/skills/`, all four tools), Claude Code plugin (`/plugin marketplace add
daedalus-ai-forge/developer-harness` — skills + commands + agents + hooks), and Codex
plugin (`codex plugin marketplace add daedalus-ai-forge/developer-harness` — skills).

# AGENTS.md — developer-harness

## What this repo is

A reusable agent harness: Agent Skills, command wrappers, subagent role templates, guard
hooks, and instruction-file fragments that any repository can adopt. Everything is
project-agnostic, packaged so Claude Code, Codex, Cursor, and OpenCode each consume the
classes they understand. This file is the map — read it whether you are working *on*
this repo or selecting a skill *from* it.

## Repo map

```
developer-harness/
├── skills/                  # 26 skills (SKILL.md format), one directory per skill
│   └── architect-shared/, contracts/  # shared resources for the architect skills (NOT skills)
├── commands/                # 13 /command wrappers for the explicitly-invocable skills
├── agents/                  # generic role contracts in six groups (+ install guide)
│   │                        #   root — coordination: product-owner, person-of-contact
│   ├── project-control/     #   direction, delivery, legal
│   ├── develop-team/        #   tech-lead, developer + layer roles, debugger
│   ├── design-team/         #   spec, content, design-system, technical-art roles
│   ├── research-team/       #   researcher, analyst
│   └── validation-team/     #   the six verdict roles (full roster in ## Roles below)
├── hooks/                   # 9 guard scripts — 6 wired by default, 3 opt-in (see ## Guards)
│                            #   + scripts/lib/, tests/, per-tool declared wiring files
├── rules/                   # AGENTS.md/CLAUDE.md section templates (Roles, Teams, Guards,
│                            #   discipline, coding, design docs, bindings, RACI)
│                            #   + role-contract-template.md (scaffold for new roles)
├── scripts/, opencode.json  # tool-native converters; repo-local OpenCode skill discovery
├── docs/                    # per-tool consumption guides (consume-<tool>.md) + companion-skills.md
├── .claude-plugin/          # repo root is a Claude Code plugin (plugin.json + marketplace.json)
├── .codex-plugin/, .agents/plugins/  # repo root is also a Codex plugin + its marketplace
└── VENDOR-ATTRIBUTION.md    # provenance ledger for vendored skills (+ VENDOR-LICENSE-*.txt)
```

## Skill selection guide

Invocation by tool: `/name` in Claude Code (`/developer-harness:name` when installed as the
plugin) and Cursor; `$name` in Codex; OpenCode auto-loads skills through its native
`skill` tool on description match. Thirteen skills are explicitly
invocable, each with a `commands/` wrapper and a Codex `default_prompt`:
**tighten-types, contract-docstrings, architect-design-review, architect-codebase-review,
mermaid-skill, gantt-roadmap, feature-build, define-team, role, systematic-debugging,
deep-research, grill-me, skill-creator**. The rest are load-before-writing references
that tools auto-select by description.

### Python (6 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Implementing any Python code | `python-pro` | Vendored capability reference (async, typing depth, performance, packaging, testing). A reference, not a contract. |
| Writing Python that must follow house style | `python-conventions` | One-line-per-rule conventions: Google docstrings + ruff D config, naming, 3.12+ idioms, typing policy. Load BEFORE writing any Python code. |
| Designing or reviewing a library's public API | `python-api-design` | API shape: progressive disclosure, naming, error design, fail-loud rules, evolution/deprecation/breaking changes. |
| Building library documentation as a deliverable | `python-documentation` | Sphinx setup (autodoc/napoleon/furo), API references, tutorials, ReadTheDocs config. |
| Hardening type annotations on existing code | `tighten-types` | Explicit pass over a given scope: missing attribute types, Pydantic models over loose dicts, overloads, redundant in-body annotations. |
| Documenting failure modes on boundary/IO code | `contract-docstrings` | Docstrings as contracts: input invariants, errors raised on violation, external-state errors, silenced errors. Invoke explicitly on a chosen scope. |

Disambiguation:

- `python-pro` says what Python *can* do; `python-conventions` says how code *is* written
  here. When writing new code load both — conventions win on conflict.
- Both `python-conventions` and `python-documentation` cover Google-style docstrings:
  conventions is the enforcement rule-index while coding; documentation is for producing
  a docs site (Sphinx/ReadTheDocs) as an artifact.
- `tighten-types` and `contract-docstrings` are batch passes you point at a file or
  directory, not always-on style rules. Types → tighten-types; failure-mode prose →
  contract-docstrings.
- Library surface questions (function vs class, how to deprecate) →
  `python-api-design`, not python-pro.

### Rust (4 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Implementing any Rust code | `rust-engineer` | Vendored capability reference (ownership, async, unsafe discipline, performance). Read after design/planning, before the first failing test. |
| Writing doc-comments or setting lint policy | `rustdoc-conventions` | Project-pinned rules: doc-comment section order, first-sentence ≤15 words, mandatory `# Errors`/`# Safety`, Cargo.toml `[lints]` table. Load BEFORE writing Rust code. Wins all conflicts. |
| Authoring/reviewing public API prose | `rust-pragmatic` | Microsoft Pragmatic Rust Guidelines (M-* rules). Do not read the whole ~33k-token corpus — grep `references/guidelines.txt` for the relevant M-* sections only. |
| Adding/changing a `pub` item, or pre-publication review | `rust-api-checklist` | Official rust-lang C-* API Guidelines checklist. Full checklist before anything goes public; naming + docs sections for internal crates. |

`rustdoc-conventions` is the router: it escalates to `rust-api-checklist` (public API
surface changed) or `rust-pragmatic` (doc prose quality); its rules take precedence
over both.

### TypeScript, C#, Java (4 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Implementing TypeScript | `typescript-pro` | Vendored capability reference: advanced types, generics, type-level programming, end-to-end type safety. |
| Writing TS documentation or ADRs | `typescript-docs` | JSDoc patterns, TypeDoc configuration, ADRs, framework-specific patterns, docs CI. |
| Implementing C# / Unity code | `csharp-developer` | Vendored capability reference: async/await, DI, LINQ, records, memory. Fit note inside: for non-web projects (Unity, desktop) take the language craft, discard the ASP.NET/EF opinions. |
| Implementing Java | `java-architect` | Vendored capability reference: modern Java, concurrency, module/service structure, JVM performance. Fit note inside: upstream assumes Maven/Spring; your build/framework choices win. |

### Method / review (7 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Diagnosing any bug, test failure, or unexpected behavior | `systematic-debugging` | Companion to the `debugger` role — load before proposing any fix. Four-phase gate (root cause → pattern → hypothesis → implementation); no fixes without root-cause investigation. Vendored. |
| Writing, reviewing, or refactoring any code (behavioral discipline) | `karpathy-guidelines` | Always-on behavioral reference against LLM coding pitfalls: surface assumptions before implementing, simplicity over speculative abstraction, surgical changes (every changed line traces to the request), imperative tasks recast as verifiable goals. Companion to the `developer` role; auto-selected, never `$`-invoked; the moment a bug appears, `systematic-debugging` takes over. Vendored. |
| Answering a research question too big for one search pass | `deep-research` | Companion to the `researcher` role — invoke when claims are contested, the landscape is unknown, more than ~three independent sources are needed, or a decision hangs on it. Staged pipeline (decompose → parallel sweeps → adversarial verification → critic loop → cited synthesis), scaled to the question class. Serves as the research-to-decision team's researcher stage where declared. |
| Stress-testing a plan, decision, or idea before acting | `grill-me` | Relentless round-based interview: frontier questions with recommended answers, agent fetches facts, user makes decisions; done when nothing is silently assumed. Vendored. |
| Creating or updating a skill in this repo | `skill-creator` | Meta-gate and Contributing rule: interviews intent, drafts the SKILL.md, runs evals/benchmarks, tunes description triggering. Vendored. Invoke explicitly before writing any SKILL.md by hand. |
| Gating a design spec BEFORE building | `architect-design-review` | Reads a spec, generates Mermaid architecture diagrams, evaluates against architecture principles, writes an HTML report to `docs/architecture/review/`. Never reviews existing code. |
| Auditing an EXISTING codebase | `architect-codebase-review` | Explores the code, produces current-state diagrams, evaluates, proposes improvements with revised diagrams, writes an HTML report. Never evaluates design specs. |

Mutually exclusive by construction — each names the other in its Non-Goals; both are
read-only apart from the report and depend on the sibling dirs
`skills/architect-shared/` and `skills/contracts/` (no SKILL.md — per-skill installers
may skip them; vendor both alongside).

### Diagrams / planning (2 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Any diagram: flowchart, sequence, class, ER, state, architecture… | `mermaid-skill` | Generates `.mmd` sources and exports PNG/SVG/PDF via `mmdc` or the Kroki API; validation before export. |
| Turning a plan/milestones into a schedule | `gantt-roadmap` | Produces a dated Mermaid Gantt chart plus critical-path, risk, and assumption notes; real ISO dates enable `.ics` calendar export. |

Mermaid can draw Gantt charts too — prefer `gantt-roadmap` when the point is the
*schedule*; `mermaid-skill` when the point is the *diagram and its export*.

### Team orchestration (3 skills)

| You are doing | Skill | Why / when |
| --- | --- | --- |
| Building one scoped feature end-to-end with gates | `feature-build` | Runs the team chain: tech-lead plan gate → TDD implementation → tech-lead design-conformance review → qa-reviewer verdict; fix-rounds 1 per gate (raisable per repo); only the verifier declares done. |
| Declaring a custom multi-role team in a repo | `define-team` | Interviews you through the full team schema (template: `rules/agents-md/teams-section.md`), validates the entry (member resolution, one done-authority, return paths, name collisions, size budget), then appends it to the repo's `## Teams` section and shows the diff. Invoke explicitly. |
| Adopting a role for the session (delegation-first coordination) | `role` | Loads a shipped role contract and binds it to the session: boundaries absolute, out-of-lane work delegated to the right role or team, never absorbed. `/role tech-lead` (Claude) · `$role tech-lead` (Codex). |

`feature-build` composes the roles in `agents/`; the same chain is declarable per repo
as a team. The teams template ships five predefined teams — feature-build,
design-review, bug-diagnosis, research-to-decision, legal-vetting.

### Companion skills (external, not vendored)

Four external plugins are wired into roles by name but deliberately not vendored:
`frontend-design` and `claude-security` are Anthropic-proprietary — not
redistributable, so the Claude Code plugin auto-installs both as cross-marketplace
dependencies from Anthropic's own marketplace — while `ui-ux-pro-max` and
`system-design-skills` are MIT but far past the library size budget and stay manual
installs. All four are advisory; every role that names them degrades gracefully
where absent. Read [docs/companion-skills.md](docs/companion-skills.md) for which
roles use each, install commands, and licence details before installing any of them.

## Guards

Nine guard scripts under `hooks/scripts/`, dependency-free, exit 2 + a stderr
reason to block, in two wiring classes plus an opt-in set:

**Safety (PreToolUse on every call, wired by default in every dialect):**
`dangerous-command-guard.sh` — the destructive-command set in shell tool calls
(dangerous `rm -r` targets, `sudo rm`, recursive `chmod 777`, `mkfs`, `dd`
onto a device, fork bombs, curl-piped-to-shell; extend via
`DCG_EXTRA_PATTERNS`); and `protected-paths-guard.sh` — zero-access tier
(`.ssh` `.aws` `.gnupg` `.kube` `.env*`) plus no-delete tier (test/spec
dirs), `PPG_*` overrides.

**Commit (git pre-commit + PreToolUse; each guard re-reads the payload via
`scripts/lib/commit-payload.sh` and passes untouched on non-commit calls, so a
guard cannot wedge the session it protects):** `secret-scan.sh`
(credential patterns in staged additions), `quality-gate.sh` (auto-detected
format/lint/typecheck lanes; configured-but-failing blocks, unconfigured
skips with a notice; `QG_*` aligns with `<lint-command>` bindings),
`check-large-files.sh` (staged blobs over 1 MB), and
`check-merge-markers.sh` (conflict markers in added lines).

**Opt-in (shipped, not wired):** `instruction-scan.sh` — invisible-Unicode
injection vectors (Tag, zero-width, bidi characters) in instruction files,
staged or `--all` for CI; `agents-md-budget.sh` — the AGENTS.md chain
against the 32 KiB Codex silent-truncation cap (warn at 24 KiB); and
`done-authority-gate.sh` — blocks task completion until the team's declared
done-authority has recorded its `verdict:` line in the team status file.

Wire them per [hooks/README.md](hooks/README.md), then prove the wiring blocks
by running `hooks/tests/guard-selftest.sh`. The plugin ships **no
auto-discovered `hooks/hooks.json`**: each tool's manifest declares its own
wiring file (`hooks/claude.hooks.json`, `hooks/codex.hooks.json`,
`hooks/opencode.guards.js`; Cursor in that README).
Two facts govern the directory: hooks are a POLICY layer, not an access
boundary — filters are best-effort and fail open on unparseable input, so hard
allow/deny belongs in each tool's permission system; and checked-in hook config
executes with user privileges, so review hook wiring like any executable code.
When a guard blocks, fix the underlying issue — never bypass the guard, and fix
quality-gate failures at the source, never by disabling the check.

## Roles

`agents/` ships twenty-six generic roles in six groups — the coordination pair at the
directory root plus the five team directories:

**Coordination root.** **product-owner** (Product Goal, the single ordered backlog,
acceptance criteria before work starts, accept/return on increments — judges value,
never dispatches work or designs solutions) and **person-of-contact** (routes
completed work via the repo's `## RACI` table, brokers cross-component
collaborations — never decides value or assigns work).
Dispatch lives in the consuming tool's orchestration, not in any role. The human has
two doors into a team: change requests → product-owner; handoff communication →
person-of-contact.

**Project control (`project-control/`).** **product-manager** (problem framing,
personas, prioritization, success metrics — direction not delivery),
**project-manager** (goals into sequenced, owned tasks with schedule and risk —
consumes direction, never sets it), **legal-reviewer** (red-flag ledgers, clause
summaries, attorney question lists — analysis for human review, never final legal
advice; any role may engage it before public-facing or license-touching decisions).
The trio's boundary: product-manager "are we building the right thing?",
product-owner "what is most valuable next — and did it deliver?", project-manager
"will it ship predictably?".

**Develop team (`develop-team/`).** **tech-lead** gates (design gate before build,
buy-vs-build, seam pinning, design-conformance review — never implements);
**developer** is the generic implementation base (TDD from a failing test, small
reviewable changes — never approves its own work); the layer roles cover one layer's
concerns each: **frontend-developer** (UI state, accessibility, design fidelity),
**backend-developer** (API contracts, data integrity, failure modes),
**mobile-developer** (platform lifecycle, offline-first data, store review),
**data-engineer** (schema/migration custody, idempotent pipelines, PII discipline),
**devops-engineer** (pipeline custody, secrets hygiene, release/rollback — never
bypasses gates), and **security-engineer** (defensive only — reviews and hardens,
never builds offensive tooling); and **debugger** closes the loop on failures (root
cause with evidence, proposes rather than fixes). The done-verdict comes from
validation-team's qa-reviewer, never from anyone inside the team.

**Design team (`design-team/`).** **ux-designer** (buildable design specs: flows,
per-screen states including empty/loading/error/first-run — never edits production
code), **content-designer** (interface language: terminology glossary, errors and
empty states as first-class content; legal-sounding copy routes to legal-reviewer),
**design-system-steward** (tokens/components/conventions in one source of truth;
drift audits — reports drift, never patches product code), and **technical-artist**
(opt-in for real-time/3D products: asset budgets as gates — validates and specifies,
never authors art). The experience verdict on the built UI comes from
validation-team's design-reviewer. The group adds two bindings: `<design-system>`
and `<design-assets>` (source art, distinct from code and docs).

**Research team (`research-team/`).** The shared specialists serving develop-team and
design-team — they ground those teams' decisions, never make them. **researcher**
(cited primary sources with access dates, adversarial verification, inference labeled
as inference) and **analyst** (decision-grade numbers: stated assumptions, shown
arithmetic, sensitivity notes). Boundary lines: analyst interprets data,
data-engineer builds the pipelines that collect it; analyst PREDICTS,
performance-validator MEASURES; the soundness verdict on research is
evidence-validator's lane.

**Validation team (`validation-team/`).** The six independent verdicts on finished
work: **qa-reviewer** (functional — adversarial review with executed evidence, never
implements), **design-reviewer** (experience — fidelity state-by-state, accessibility
with executed checks, design-system conformance), **integration-validator**
(integration — the real seam exercised end-to-end, never mocked),
**performance-validator** (performance — reproducible measurements against explicit
budgets; no budget or no measurement means no verdict), **release-validator**
(readiness — the actual artifact built and smoke-tested, rollback path known;
release timing and value stay product-owner's call), and **evidence-validator**
(evidence — claims independently re-derived; judges evidence quality, never the
decision). Validators live outside the teams they judge and none of the six
verdicts substitutes for another.

**Language lives in skills; layer lives in roles; compose per repo** — e.g.
`dev-csharp` = `developer` + the `csharp-developer` skill, declared in the consuming
repo's `## Roles` section, not shipped here.

The role-contract **template** (`rules/role-contract-template.md`: frontmatter + `## Bindings` +
Mission / Method / Deliverable / Boundaries) is for authoring more. Non-implementing
contracts carry two-tier `disallowedTools` denylists (validation-team:
`Write, Edit, NotebookEdit`; tech-lead and the authoring roles:
`Edit, NotebookEdit`) — never a `tools:` allowlist, Bash never denied, repo-local
copies override; enforcement details and cross-tool equivalents in
[agents/README.md](agents/README.md). The shipped roles
reference project layout only through `<placeholder>` bindings (`<source-root>`,
`<test-command>`, …) that a consuming repo resolves in a `## Project bindings` section
of its AGENTS.md or CLAUDE.md — template in
[rules/agents-md/project-bindings-section.md](rules/agents-md/project-bindings-section.md).
Each contract declares which bindings it **requires** and which are **optional**;
a missing binding triggers that section's Resolution protocol (infer → confirm with
the user → persist), a *required* binding that cannot be established disables the
role for the repo — never a guessed path — and optional ones degrade gracefully.
Multi-role chains are declared per repo in a `## Teams` section — read the template
in [rules/agents-md/teams-section.md](rules/agents-md/teams-section.md) for the full
schema before declaring one. Entries carry members, chain with return paths,
execution-mode (fallback agent-team → subagents → single-session), fix-rounds per
gate (default 1), the six-element handoff record (resolved binding VALUES — never
placeholder names), and authority rules with exactly one done-authority. Validator
stages receive only the handoff record plus the artifact under review — never the
producing session. The `person-of-contact` role consumes a per-repo `## RACI`
section — component ownership rows it routes communication by — template in
[rules/agents-md/raci-section.md](rules/agents-md/raci-section.md). Project-specific
roles still belong in consuming repos (e.g. their `.claude/agents/`), and both kinds
route through an AGENTS.md `## Roles` section for tools that cannot read markdown agents
(Codex, OpenCode) — template in
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
   add `default_prompt` only for explicitly-invocable skills (the thirteen listed above),
   never for load-before-writing references. Explicit-ONLY skills additionally set
   top-level `policy.allow_implicit_invocation: false`; the four invocables that also
   auto-trigger by description (mermaid-skill, gantt-roadmap, systematic-debugging,
   deep-research) must not — read [docs/consume-codex.md](docs/consume-codex.md)
   before changing any sidecar.
5. **English only.** All content in this repo is written in English.
6. **Keep the consumption docs true.** Adding or changing a harness class means updating
   the README consumption matrix and the relevant `docs/consume-<tool>.md`; a new
   explicitly-invocable skill also needs a `commands/` wrapper and a `default_prompt`.
7. **Skills are authored with skill-creator.** New or updated skills in this repo are
   authored with the `skill-creator` skill (vendored here) — invoke it before writing a
   SKILL.md by hand.

## Consuming this harness

Three channels — skills CLI (`npx skills add daedalus-ai-forge/developer-harness
--all`, vendors into `.agents/skills/`, all four tools), Claude Code plugin
(skills + commands + agents + hooks), and Codex plugin (skills; pin with `--ref`) —
install commands in the README; read the guide for your tool before installing:
[Claude Code](docs/consume-claude-code.md) · [Codex](docs/consume-codex.md) ·
[Cursor](docs/consume-cursor.md) · [OpenCode](docs/consume-opencode.md).
Supply-chain review guidance — dependency auto-installs, hook wiring as executable
code, instruction scanning — lives in the README's Supply chain and trust section.

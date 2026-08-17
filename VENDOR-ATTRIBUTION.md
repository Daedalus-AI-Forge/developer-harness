# Vendored skill provenance

Third-party skills copied into `skills/`. Recorded so source, licence and exact
revision are auditable. All free/open-source.

Two vendoring shapes are in use, and the difference matters when auditing:
- **Verbatim** — the file is theirs including its frontmatter; nothing was re-wrapped.
- **Converted** — the upstream file was an AGENT definition, not a skill. Its `tools:` and
  `model:` frontmatter fields were dropped and a house `name` + `description` written, because
  skills have no such fields. **The body is still verbatim** — that is what is being vendored —
  with a provenance + precedence block prepended above it.

| Skill dir | Source repo | Path in repo | Licence | Revision | Shape | Installed |
|---|---|---|---|---|---|---|
| `gantt-roadmap` | [mohitagw15856/pm-claude-skills](https://github.com/mohitagw15856/pm-claude-skills) (1,218★) | `skills/gantt-roadmap` | MIT | `34d8a3705615ddc7e597c0ca889624732a69f1a6` | verbatim | 2026-07-25 |
| `mermaid-skill` | [Agents365-ai/mermaid-skill](https://github.com/Agents365-ai/mermaid-skill) (147★) | `skills/mermaid-skill` | MIT | `150d8d00e7b0b5457a26277d146d5ab5f6fa2e1f` | verbatim | 2026-07-25 |
| `python-pro` | [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) (23,756★) | `categories/02-language-specialists/python-pro.md` | MIT | `947b44ca0c58d606b084e9cb1a2389335b49278b` | converted | 2026-07-27 |
| `rust-engineer` | VoltAgent/awesome-claude-code-subagents | `categories/02-language-specialists/rust-engineer.md` | MIT | `947b44ca0c58d606b084e9cb1a2389335b49278b` | converted | 2026-07-27 |
| `java-architect` | VoltAgent/awesome-claude-code-subagents | `categories/02-language-specialists/java-architect.md` | MIT | `947b44ca0c58d606b084e9cb1a2389335b49278b` | converted | 2026-07-27 |
| `csharp-developer` | VoltAgent/awesome-claude-code-subagents | `categories/02-language-specialists/csharp-developer.md` | MIT | `947b44ca0c58d606b084e9cb1a2389335b49278b` | converted | 2026-07-27 |
| `typescript-pro` | VoltAgent/awesome-claude-code-subagents | `categories/02-language-specialists/typescript-pro.md` | MIT | `947b44ca0c58d606b084e9cb1a2389335b49278b` | converted | 2026-07-27 |
| `architect-design-review` + `architect-codebase-review` + `architect-shared/` + `contracts/` | [sirius-zuo/architect-skills](https://github.com/sirius-zuo/architect-skills) | whole repo minus `tests/`, `RUNS.md`, assets (its own `install.sh`) | MIT | `2513f0f92297e8813f03d1e31c5a075372152133` | verbatim (4 sibling dirs — skills reference `../architect-shared/`) | 2026-08-02 |
| `systematic-debugging` | [obra/superpowers](https://github.com/obra/superpowers) | `skills/systematic-debugging` | MIT | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` | verbatim | 2026-08-16 |
| `grill-me` | [mattpocock/skills](https://github.com/mattpocock/skills) | `skills/productivity/grilling` (method) + `skills/productivity/grill-me` (dispatcher) | MIT | `86cba45f4244b2545112d13e77ba82eb2bfad325` | converted (collapsed) | 2026-08-16 |
| `skill-creator` | [anthropics/skills](https://github.com/anthropics/skills) | `skills/skill-creator` | Apache-2.0 | `f6656c1256d5a8adfa37db9110046ef20bac644c` | verbatim | 2026-08-16 |
| `karpathy-guidelines` | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | `skills/karpathy-guidelines` | MIT (declared; no LICENSE file — see note) | `2c606141936f1eeef17fa3043a72095b4765b9c2` | verbatim | 2026-08-16 |

Licence texts retained as required: `VENDOR-LICENSE-pm-claude-skills-MIT.txt`,
`VENDOR-LICENSE-agents365-mermaid-MIT.txt`,
`VENDOR-LICENSE-voltagent-awesome-claude-code-subagents-MIT.txt`,
`VENDOR-LICENSE-architect-skills-MIT.txt`,
`VENDOR-LICENSE-obra-superpowers-MIT.txt`,
`VENDOR-LICENSE-mattpocock-skills-MIT.txt`,
`VENDOR-LICENSE-andrej-karpathy-skills-MIT.txt` (skill-creator's Apache-2.0 licence
is retained in-directory as `skills/skill-creator/LICENSE.txt` — see its note below).

`architect-skills` pre-install content review (2026-08-02): no egress or exec in any
installed file (`install.sh` is plain `cp -r` and is not itself installed); both SKILL.md files
carry their own content-isolation + non-goals + path-sanitization clauses; generated HTML reports
load Mermaid.js from the jsdelivr CDN, so VIEWING a report needs internet — the review itself
runs offline.
Local modification: `architect-design-review`'s spec-path default was generalized from upstream (ask the user; no fixed location); body otherwise unmodified.

`mermaid-skill` local modification (2026-08-16): the top-level `homepage:` frontmatter
field was relocated under `metadata:` for Agent Skills spec portability; body unmodified.

The five VoltAgent skills are **capability references, not contracts**: each carries a
precedence block stating that project-local conventions (a project's CLAUDE.md and its own
convention skills) override the upstream text wherever they conflict. Only the languages in
our stack were taken — the other 26 templates in that category were deliberately skipped (a
skill that is never invoked is context debt).

Why vendored rather than installed as plugins: `pm-claude-skills` exposes 96 plugins over 771
skills (too coarse — we want one skill), and `Agents365-ai/mermaid-skill` ships no
`.claude-plugin/marketplace.json` at all. Prefer the plugin route when a well-scoped plugin
exists.

`systematic-debugging` (2026-08-16): the six runtime files were taken (`SKILL.md`,
`root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`,
`condition-based-waiting-example.ts`, `find-polluter.sh`); upstream's authoring artifacts
(`CREATION-LOG.md`, `test-*.md` pressure-test scenarios) were deliberately skipped. All
copied files verified byte-identical to upstream revision `b36e082` by git blob hash.
Local modifications: none to any body; `license` + `metadata.source` fields added to the
SKILL.md frontmatter (house convention). The body references two sibling skills by their
plugin-namespaced names (`superpowers:test-driven-development`,
`superpowers:verification-before-completion`) which are not vendored here — treat those
lines as pointers to the upstream plugin, not resolvable skill names. It is wired as the
companion to the `agents/develop-team/debugger.md` role contract.

`grill-me` (2026-08-16): upstream splits a dispatcher skill (`grill-me`, a 157-byte
pointer) from the method skill (`grilling`); the pair was collapsed into one skill here —
the `grilling` body vendored byte-identical (blob `1c2bb7bf` verified against revision
`86cba45`) under house frontmatter, with the dispatcher's role played by
`commands/grill-me.md`. Upstream's two `openai.yaml` sidecars were replaced by one house
sidecar carrying a `default_prompt`. `VENDOR-LICENSE-mattpocock-skills-MIT.txt` added to
the retained-licence list above.

`skill-creator` (2026-08-16): all 18 upstream files were taken — `agents/` (the
grader/comparator/analyzer subagent instructions), `eval-viewer/` + `assets/` (the eval
review UI), `references/schemas.md`, and `scripts/` (the eval/benchmark/packaging tooling,
exec bits preserved) — every file is a runtime resource, nothing was skipped. All copied
files verified byte-identical to upstream revision `f6656c1` by git blob hash; the sole
modification is the house `license` + `metadata.source` frontmatter fields. The upstream
repo has NO root LICENSE and its document skills are source-available only — this skill
ships its own Apache-2.0 LICENSE.txt (© 2026 Anthropic PBC), retained in-directory, which
satisfies attribution. The scripts need Python 3, plus optionally a local `claude` CLI for
running evals. Codex-native limits, precisely: the eval and description-tuning scripts
(`run_eval.py`, `improve_description.py`, and their `run_loop.py` driver) invoke the
`claude` CLI as a subprocess (`claude -p`), `run_eval.py` writes command files into
`.claude/commands/` (and `aggregate_benchmark.py` summarizes those eval runs' output), and
`quick_validate.py` imports PyYAML, which is not vendored — so in Codex the authoring
guidance and `references/schemas.md` work as-is, while the advertised eval/benchmark
workflow is Claude-CLI-dependent; the scripts are unmodified per the verbatim policy. It is wired as the harness's meta-rule via the Contributing rule in
AGENTS.md: new or updated skills in this repo are authored with `skill-creator`.

Evaluated, not vendored (2026-08-16): `frontend-design`
([anthropics/claude-code](https://github.com/anthropics/claude-code), plugin
`plugins/frontend-design` v1.1.0, plugin last touched `b407389`) — size is fine (a single
~8 KB SKILL.md) but the repo's LICENSE.md is proprietary ("© Anthropic PBC. All rights
reserved", Commercial Terms of Service; verified upstream 2026-08-16), so it cannot be
redistributed here. `ui-ux-pro-max`
([nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
v2.5.0) — MIT (verified upstream 2026-08-16), but ~11.7 MB across 337 files of searchable
design databases (plus an Apache-2.0 `ui-styling` sub-skill), far past library size.
`claude-security`
([anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official),
plugin `plugins/claude-security` v0.10.0) — same verdict as `frontend-design`: the
plugin's own LICENSE is proprietary (a limited internal-use licence "solely with Claude
Code", © Anthropic PBC; verified upstream 2026-08-16), so it cannot be redistributed
here. All three are wired reference-only: the `ux-designer`, `frontend-developer`,
`design-reviewer`, and `security-engineer` role contracts name them "where installed",
and install pointers live in AGENTS.md's companion-skills note. `frontend-design` and
`claude-security` are additionally declared as cross-marketplace dependencies in
`.claude-plugin/plugin.json` (allowlisted in `.claude-plugin/marketplace.json`), so
Claude Code auto-installs them from Anthropic's own marketplace — an install pointer,
not redistribution, which is what their proprietary licences require.

`system-design-skills`
([proyecto26/system-design-skills](https://github.com/proyecto26/system-design-skills)
v0.1.0) — MIT (standard text, © 2026 Proyecto 26; verified upstream 2026-08-16), but 22
interlinked skills totalling ~824 KB across 127 files in `skills/` alone (plus an
orchestrator agent, a `/design` command, and a shared GUIDE), past library size on both
prongs. The skills cross-reference each other by bare skill name and the `system-design`
orchestrator routes among all 22, so vendoring any single block would ship dangling
references; it is also a well-scoped plugin with its own marketplace manifest, so per the
note above the plugin route is preferred. Wired reference-only: the `tech-lead`,
`backend-developer`, `data-engineer`, and `devops-engineer` role contracts name its
building blocks "where installed" (advisory — the approved design in `<design-docs>`
always wins), and install pointers live in AGENTS.md's companion-skills note.

`karpathy-guidelines` (2026-08-16): the single skill in an eponymous 9-file repo — the
other files re-package the same four principles as CLAUDE.md/Cursor-rule distributions
and were deliberately skipped, as was the root `EXAMPLES.md` (before/after pedagogy the
skill never references). Body verified byte-identical to upstream blob `6a62d044` at the
revision above; sole modification is the house `metadata.source` frontmatter field
(`license: MIT` is upstream's own). Licence: the upstream repo ships NO LICENSE file
(GitHub detection: none), but the author declares MIT in three places at that revision —
README "## License", the SKILL.md `license:` frontmatter field, and
`.claude-plugin/plugin.json` — recorded with the reproduced MIT template in
`VENDOR-LICENSE-andrej-karpathy-skills-MIT.txt`. Rights note: the skill body quotes no
prose by Andrej Karpathy — it is the upstream author's own operational text derived from
ideas in Karpathy's public X post, which the vendored file itself links as its source;
Karpathy is not affiliated with and has not endorsed the upstream project, and the skill
claims neither. It is a load-before-writing reference (display-only sidecar, no command
wrapper) wired into the `agents/develop-team/developer.md` role contract; it composes
with `systematic-debugging` rather than competing — it governs behavior while writing
code, and on any bug or test failure systematic-debugging is the governing method.

To update: re-copy from the source repo and bump the revision above.

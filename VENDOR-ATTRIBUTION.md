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

Licence texts retained as required: `VENDOR-LICENSE-pm-claude-skills-MIT.txt`,
`VENDOR-LICENSE-agents365-mermaid-MIT.txt`,
`VENDOR-LICENSE-voltagent-awesome-claude-code-subagents-MIT.txt`,
`VENDOR-LICENSE-architect-skills-MIT.txt`,
`VENDOR-LICENSE-obra-superpowers-MIT.txt`.

`architect-skills` pre-install content review (2026-08-02): no egress or exec in any
installed file (`install.sh` is plain `cp -r` and is not itself installed); both SKILL.md files
carry their own content-isolation + non-goals + path-sanitization clauses; generated HTML reports
load Mermaid.js from the jsdelivr CDN, so VIEWING a report needs internet — the review itself
runs offline.
Local modification: `architect-design-review`'s spec-path default was generalized from upstream (ask the user; no fixed location); body otherwise unmodified.

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

To update: re-copy from the source repo and bump the revision above.

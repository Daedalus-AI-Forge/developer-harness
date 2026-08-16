# Template: "## Project bindings" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`),
then replace the example values with that repo's real paths and commands.
Generic role contracts (see `agents/` in developer-harness) refer to these
`<placeholder>` names instead of hard-coding any project layout; this section
is the one place they resolve.

Keep the vocabulary small: keep only the rows the roles you adopt actually
use, and add a new placeholder only when a role contract needs it. Paths are
relative to the repo root; commands run from the repo root.

---

## Project bindings

Role contracts use `<placeholder>` names for project-specific locations and
commands. They resolve here and only here: a contract never guesses a value.
Each contract's `## Bindings` block declares which placeholders it
**requires** (it cannot operate without them) and which are **optional**
(they enrich the role; it degrades gracefully without them).

| Placeholder | Meaning | Example value |
| --- | --- | --- |
| `<design-docs>` | Where specs and design docs live | `docs/design/` |
| `<design-system>` | Where the design system's source of truth lives — tokens, component conventions, theme (a tokens directory or theme doc, not the feature specs in `<design-docs>`) | `src/theme/tokens/` |
| `<design-assets>` | Where source art/asset files live (models, rigs, textures, audio) — distinct from code and docs | `assets/source/` |
| `<source-root>` | Production source code | `src/` |
| `<test-command>` | How to run the test suite | `pytest -q` |
| `<lint-command>` | How to run lint / static checks | `ruff check .` |
| `<build-command>` | How to produce the build/release artifact | `npm run build` |
| `<ci-config>` | Where CI/CD pipeline definitions live | `.github/workflows/` |
| `<docs-root>` | Human-facing documentation | `docs/` |
| `<research-notes>` | Where research write-ups are filed | `docs/research/` |
| `<product-docs>` | Where product direction docs live (briefs, personas, metric definitions) | `docs/product/` |
| `<roadmap-docs>` | Where delivery plans, ordered backlogs, schedules, and risk registers live | `docs/roadmap/` |
| `<team-log>` | Append-only team log: product-owner's decision/acceptance records, project-manager's delivery status records, person-of-contact's routing records (see the `## Teams` template) | `docs/team-log.md` |
| `<work-tracker>` | The one authoritative place tasks live — person-of-contact handoffs and task pickups resolve against it. A type plus location; three supported forms, documented below | `github` |

`<work-tracker>` takes one of three forms — each readable by both humans
and agents:

- `github` — GitHub Issues/Projects. Agents access via the `gh` CLI
  (`gh issue view <n>`, `gh project item-list`); humans via the web board.
- `azure-devops` — Azure DevOps Boards. Agents access via the `az boards`
  CLI or Microsoft's official Azure DevOps MCP server; humans via the web.
- `local:<path>` — a task-file directory in the repo (e.g.
  `local:docs/tasks/`), one markdown file per task; the file convention is
  in the `## RACI` template (`raci-section.md`).

**Auth** (by reference, per tracker type):

- `github` — authenticate once via `gh auth login` (CLI, keychain-backed);
  CI uses the `GH_TOKEN` env var. Agents inherit ambient auth — no token
  configuration in the repo.
- `azure-devops` — `az devops login` (the az CLI stores the PAT) or the
  `AZURE_DEVOPS_EXT_PAT` env var; with the Azure DevOps MCP server, pass
  the PAT via environment-variable expansion in the MCP config (e.g.
  `${AZURE_DEVOPS_PAT}`) — the committed config carries the variable NAME
  only. Tool-local secret homes: shell profile, OS keychain, or Claude
  Code's `.claude/settings.local.json` (auto-gitignored).
- `local:<path>` — no auth.

**Token values never enter tracked files — configs reference environment
variables by name; the harness's secret-scan hook blocks common token
patterns at commit time, by design.**

### Resolution protocol

When a role needs a binding that has no row in the table above:

1. **Search.** Infer candidates from the repo itself before asking: CI
   configs and package manifests (`pyproject.toml`, `package.json`,
   `Cargo.toml`, `Makefile`, workflow files) reveal build, test, and lint
   commands; conventional directories (`docs/`, `design/`, `specs/`) reveal
   doc bindings.
2. **Ask.** Present the best candidate(s) to the user for confirmation —
   "is `npm run build` the `<build-command>`?" — never a bare "what is the
   path?".
3. **Set.** On confirmation, persist the binding: add the row to this
   `## Project bindings` table so it is never asked again.
4. **Disable.** If a REQUIRED binding cannot be established — the user
   declines, or nothing suitable exists — the role declares itself
   unavailable for this repo: it states exactly which binding is missing and
   what it is for, and stops. It never proceeds degraded on a guessed path.
   Optional bindings degrade gracefully: the role notes the gap and
   continues.

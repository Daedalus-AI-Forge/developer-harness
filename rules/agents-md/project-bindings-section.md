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
commands. They resolve here and only here: a contract never guesses a value,
and if a placeholder it needs has no row below, the agent must ask before
proceeding.

| Placeholder | Meaning | Example value |
| --- | --- | --- |
| `<design-docs>` | Where specs and design docs live | `docs/design/` |
| `<source-root>` | Production source code | `src/` |
| `<test-command>` | How to run the test suite | `pytest -q` |
| `<lint-command>` | How to run lint / static checks | `ruff check .` |
| `<docs-root>` | Human-facing documentation | `docs/` |
| `<research-notes>` | Where research write-ups are filed | `docs/research/` |

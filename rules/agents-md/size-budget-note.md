# Note: instruction-file size budget

Shared by every `agents-md/` template. Read it before pasting a section into
a consuming repo's `AGENTS.md` / `CLAUDE.md`, and apply it when the file
grows.

---

- Keep the combined declared sections well inside **32 KiB**. Codex
  concatenates instruction files against that budget and truncates
  **silently** — the END of the file is what disappears, so an over-budget
  file loses its last sections with no error and no diff.
- Keep each instruction file under **~200 lines**. Adherence to a rule falls
  as the file it sits in grows; a long file is a file whose middle is
  skimmed.
- Place `## Roles` and `## Teams` **early** in the file, above reference
  material. What the model must route on goes first; what it may consult
  goes last.
- Copy only the rows, bindings, and teams this repo actually runs. The
  templates are menus, not bundles — an unused team entry costs budget and
  buys nothing.
- Move anything reference-sized (long convention lists, method write-ups)
  into a skill or a linked doc and leave a one-line pointer. The instruction
  file is a router, not a manual.
- Run the harness's `hooks/scripts/agents-md-budget.sh` before committing an
  instruction-file change; fix what it reports rather than shipping over
  budget.

# Template: "## RACI" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`),
then replace the example rows with the repo's real components and
contributors. The `person-of-contact` role (see `agents/` in
developer-harness) consumes this section: it is the table that tells the
role who to hand outcomes to, who to consult before a decision closes, and
who to inform after it lands.

When a repo adopts `person-of-contact` and has no `## RACI` section, the
Resolution protocol applies (see
[`project-bindings-section.md`](project-bindings-section.md)): the role
drafts a candidate table from `.github/CODEOWNERS` and `git shortlog -sn`
per component, confirms it with the user, and writes this section. It never
invents ownership silently, and it disables itself if no table can be
established.

---

## RACI

Component ownership and communication routing. **R**esponsible does the
work; **A**ccountable owns the outcome — exactly ONE per row, a row with
two As is invalid; **C**onsulted is heard before a decision closes;
**I**nformed is notified after it lands. Values are contributor names or
handles.

| Component | Responsible | Accountable | Consulted | Informed |
| --- | --- | --- | --- | --- |
| rendering | `@alice` | `@alice` | `@bob` | `@carol`, `@dave` |
| inference | `@bob` | `@bob` | `@alice` | `@carol` |
| docs site | `@carol` | `@alice` | — | everyone |

Cross-component work touches every affected component's row: the
person-of-contact role names each Responsible party involved and brokers
the integration conversation (e.g. rendering × inference: `@alice` and
`@bob` are both named, with the integration question stated).

Keep the table current: ownership changes are proposed by
person-of-contact and confirmed by a human before the table is edited.

### Context handoff

When person-of-contact routes a task, the handoff MUST carry:

- the task reference in `<work-tracker>` — issue number, work-item id, or
  task-file path;
- the component(s) touched;
- the R/A/C/I names for those components, from the table above;
- links to the relevant spec in `<design-docs>`;
- where to report completion.

One handoff format serves both kinds of assignee — a RACI entry may be a
human or an AI agent. The assignee pulls full context per tracker type:
`github` → `gh issue view` / `gh project item-list`; `azure-devops` →
`az boards` CLI or the Azure DevOps MCP server; `local:<path>` → read the
task file. Assignees authenticate to `<work-tracker>` per the Auth note in
`## Project bindings`; a handoff never includes credentials.

For the `local:<path>` tracker type, one markdown file per task —
parseable by an agent, readable by a human:

```markdown
---
id: TASK-042
component: rendering
status: in-progress        # todo | in-progress | blocked | done
acceptance_criteria:
  - Frame time stays under 16 ms on the reference scene
  - No regression in the golden-image test suite
links:
  - docs/design/render-pipeline.md
---

Short task description in plain prose.
```

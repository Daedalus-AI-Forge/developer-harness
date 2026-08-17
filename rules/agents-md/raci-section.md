# Template: "## RACI" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`),
then replace the example rows with the repo's real components and
contributors. The `person-of-contact` role (see `agents/` in
developer-harness) routes against this table — who to hand outcomes to, who
to consult before a decision closes, who to inform after it lands.

When a repo adopts `person-of-contact` and has no `## RACI` section, run the
Resolution protocol (see
[`project-bindings-section.md`](project-bindings-section.md)): draft a
candidate table from `.github/CODEOWNERS` and `git shortlog -sn` per
component, confirm it with the user, then write this section. Never invent
ownership silently; disable the role when no table can be established.

Apply the shared [`size-budget-note.md`](size-budget-note.md) before pasting.

---

## RACI

Route component ownership and communication through the table below.
**R**esponsible does the work; **A**ccountable owns the outcome — exactly ONE
per row, and a row with two As is invalid, so fix it before routing anything
through it; **C**onsulted is heard before a decision closes; **I**nformed is
notified after it lands. Use contributor names or handles as values.

| Component | Responsible | Accountable | Consulted | Informed |
| --- | --- | --- | --- | --- |
| rendering | `@alice` | `@alice` | `@bob` | `@carol`, `@dave` |
| inference | `@bob` | `@bob` | `@alice` | `@carol` |
| docs site | `@carol` | `@alice` | — | everyone |

Read every affected component's row on cross-component work: name each
Responsible party involved and broker the integration conversation with the
question stated (e.g. rendering × inference: name `@alice` and `@bob`, and
state the integration question).

Keep the table current. Propose ownership changes through person-of-contact
and get a human's confirmation before editing a row.

### Context handoff

When person-of-contact routes a task, carry ALL of the following in the
handoff — a handoff missing any item is incomplete, so do not route it:

- the task reference in `<work-tracker>` — issue number, work-item id, or
  task-file path;
- the component(s) touched;
- the R/A/C/I names for those components, from the table above;
- links to the relevant spec in `<design-docs>`;
- the resolved binding VALUES the assignee needs (`pytest -q`, not
  `<test-command>`) — never assume the instruction file reaches them;
- where to report completion.

Route a task that enters a declared chain through that team's handoff record
instead (six required elements — see the `## Teams` section); this list is
the routing handoff, not a substitute for it.

Use one handoff format for both kinds of assignee — a RACI entry may be a
human or an AI agent. The assignee pulls full context per tracker type:
`github` → `gh issue view` / `gh project item-list`; `azure-devops` →
`az boards` CLI or the Azure DevOps MCP server; `local:<path>` → read the
task file. Authenticate to `<work-tracker>` per the Auth note in
`## Project bindings`, and never put a credential in a handoff.

For the `local:<path>` tracker type, write one markdown file per task —
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

Write `status` only from the stage that owns the task, and never overwrite a
status a later stage already set. Write the acceptance criteria BEFORE the
work starts — criteria authored afterwards describe what happened rather
than what was required.

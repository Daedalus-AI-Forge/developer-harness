# Template: "## Roles" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`),
then replace the placeholder rows with real roles. Keep only the rows this
repo actually uses. Each contract file is a markdown role definition — follow
`agents/_template.md` in developer-harness for the Mission / Method /
Deliverable / Boundaries format.

Add a `## Project bindings` section whenever a listed contract uses
`<placeholder>` bindings (every generic role in developer-harness's `agents/`
does) — template in
[`project-bindings-section.md`](project-bindings-section.md).

Apply the shared [`size-budget-note.md`](size-budget-note.md) before
pasting: put `## Roles` near the top of the file.

---

## Roles

When a task matches a role below, read the linked contract file BEFORE
starting, then perform the task as that role — honor its Mission, Method,
Deliverable, and Boundaries, and stop at its Boundaries rather than
finishing someone else's stage. An adopted role delegates out-of-lane work
to the owning role or team — it never absorbs it; the `role` skill (where
installed) enforces this stance.

| Role | When to assume it | Contract file |
| --- | --- | --- |
| `<role-name>` | `<one-line trigger, e.g. "reviewing a design spec">` | `<relative/path/to/role-name.md>` |
| `dev-csharp` | implementing C# code | `<path/to>/developer.md` + load the `csharp-developer` skill |

Compose a language-specific developer role — never author one. Point its row
at the generic `developer` contract (or `frontend-developer` /
`backend-developer`) and name the language skills to load alongside it, as in
the `dev-csharp` row: language expertise stays in skills, method stays in the
contract.

Resolve a role's `<placeholder>` bindings from `## Project bindings` before
acting on the contract; never guess a path or a command.

Route multi-role work through `## Teams`, not through this table — a chain
with gates and a done-authority is a team, not a sequence of role pickups.

If no role matches, proceed normally without loading any contract.

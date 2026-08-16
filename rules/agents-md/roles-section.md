# Template: "## Roles" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md`, then replace the
placeholder rows with real roles. Each contract file is a markdown role
definition (see `agents/_template.md` in developer-harness for the
Mission / Method / Deliverable / Boundaries format).

If any listed contract uses `<placeholder>` bindings (the generic roles in
developer-harness's `agents/` do), also add a `## Project bindings` section —
template in [`project-bindings-section.md`](project-bindings-section.md).

---

## Roles

When a task matches a role below, read the linked contract file first and
perform the task as that role, honoring its Mission, Method, Deliverable,
and Boundaries.

| Role | When to assume it | Contract file |
| --- | --- | --- |
| `<role-name>` | `<one-line trigger, e.g. "reviewing a design spec">` | `<relative/path/to/role-name.md>` |
| `<role-name>` | `<trigger>` | `<relative/path/to/role-name.md>` |

If no role matches, proceed normally without loading any contract.

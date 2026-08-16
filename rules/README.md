# rules/

Instruction fragments meant to be pasted into a consuming repo's agent
instruction file — `AGENTS.md` (Codex, OpenCode, and the cross-tool
[AGENTS.md convention](https://agents.md)) or `CLAUDE.md` (Claude Code).

These exist for harness classes some tools cannot consume natively:

- **Roles**: Codex defines custom agents in TOML and OpenCode uses its own
  frontmatter dialect, so markdown role contracts from [`../agents/`](../agents/)
  are routed through an instruction-file section instead of installed as files.
- **Guards**: every tool wires hooks differently, so the instruction file
  documents which guard scripts exist and when they run.

## Templates

| Template | Produces | Use when |
| --- | --- | --- |
| [`agents-md/roles-section.md`](agents-md/roles-section.md) | A `## Roles` routing table: role name → contract file | The consuming tool can't read `.claude/agents/` (Codex, OpenCode) |
| [`agents-md/guards-section.md`](agents-md/guards-section.md) | A `## Guards` list of hook scripts and when they run | Any repo that vendors scripts from [`../hooks/`](../hooks/) |

## How to use

1. Copy the template body into the consuming repo's `AGENTS.md` (or
   `CLAUDE.md`).
2. Replace the placeholder rows with the actual roles/guards that repo uses.
3. Keep paths relative to the consuming repo's root.

Keep fragments generic: no project names, no machine-specific paths.

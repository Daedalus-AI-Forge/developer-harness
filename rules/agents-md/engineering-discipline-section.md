# Template: "## Engineering discipline" section for AGENTS.md

Copy the block below into the consuming repo's `AGENTS.md` (or `CLAUDE.md`).
Unlike the roles/guards templates it is ready to paste as-is — the only
placeholders are the quality-gate commands, which should name the repo's
actual formatter / linter / type checker.

---

## Engineering discipline

### Before writing code

- No implementation without a design or spec that says what is being built and
  why. Throwaway spikes are exempt — but spike code is never imported by real code.
- Load the repo's written conventions (style, naming, docstrings) before
  writing. Conventions live in files and tooling, not in anyone's memory.
- TDD is mandatory: write the failing test first, watch it fail, then write
  the code that makes it pass.

### Bugs

- Systematic debugging BEFORE any fix: reproduce, read the actual error,
  confirm the cause. Never fix what you cannot explain.
- Debug rather than guess when the cause is not already known, when it worked
  before and does not now, or when success is reported with nothing verifiable
  behind it — silent success is a symptom, not a result.

### Claiming completion

- Evidence before any "done", "fixed", or "passing" claim: run the
  verification command and read its output first. No command, no claim.

### Quality gates

- Conventions are enforced by tooling wired into hooks/CI — e.g.
  `<format --check>` · `<lint>` · `<type-check>`, which today canonically
  means `uv run ruff format --check` · `uv run ruff check` · `uvx pyright`
  in Python, or `npx prettier --check .` · `npx eslint .` ·
  `npx tsc --noEmit` in JS/TS — never by memory.
- NEVER bypass a gate (`--no-verify` or equivalent). Fix the underlying issue.

### One source of truth

- Canonical facts live in ONE place; everywhere else links to it, never
  restates it. Decisions get stable IDs owned by one document; other
  documents reference the ID and never re-decide.

### Scope and ownership

- One task, one owner. Never two writers in the same file concurrently —
  parallelize only independent work; isolate risky edits in their own
  worktree or branch.

### Version control

- `git checkout -- <path>` is FORBIDDEN as an undo: it discards EVERY
  uncommitted change in that file, including work that is not yours. Reverse
  your own edit with the editor — you made it, you know what it was. If git
  must restore something, name the source explicitly
  (`git restore --source=<sha> --worktree <path>`) and record the file's
  checksum before and after.
- Treat uncommitted work as the only copy of itself, because it is.
- Small commits; messages describe intent and never reference ignored or
  local-only paths.

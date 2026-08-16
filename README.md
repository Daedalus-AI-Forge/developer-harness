# developer-harness

Reusable [Agent Skills](https://agentskills.io) shared across Daedalus AI Forge
projects — language conventions, engineering method, and review checklists that
apply to any codebase, packaged in the open SKILL.md format.

Skills here work with any client that speaks the Agent Skills standard
(Claude Code, Codex, Cursor, OpenCode, Amp, and others).

## Install

```bash
# See what's available without installing
npx skills add daedalus-ai-forge/developer-harness -l

# Install everything, for every detected agent tool
npx skills add daedalus-ai-forge/developer-harness --all

# Or pick specific skills
npx skills add daedalus-ai-forge/developer-harness -s python-conventions -a '*' -y
```

The `skills` CLI vendors the content into your repo (canonically under
`.agents/skills/`) and pins it by content hash in `skills-lock.json`. Commit
both — contributors then get the skills with a plain `git clone`, no CLI
required. Update later with `npx skills update -p`.

## Layout

```
skills/<name>/SKILL.md    # one directory per skill (Agent Skills spec)
```

Skill frontmatter sticks to the portable spec fields (`name`, `description`,
`license`, `compatibility`, `metadata`) so every client can read them.

## License

MIT for skills authored here. Vendored third-party skills keep their original
licenses and attribution — see per-skill LICENSE files and
`VENDOR-ATTRIBUTION.md`.

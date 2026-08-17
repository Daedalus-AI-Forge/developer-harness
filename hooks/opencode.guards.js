// opencode.guards.js — OpenCode plugin shim for the guard scripts in
// hooks/scripts/. OpenCode has no hooks.json dialect; its extension point is
// a JS plugin (https://opencode.ai/docs/plugins/), so this file is the
// OpenCode counterpart of claude.hooks.json / codex.hooks.json: the same six
// default guards, the same safety-first layering, the same block semantics.
//
// Install:  cp hooks/opencode.guards.js .opencode/plugins/guards.js
//   (global: ~/.config/opencode/plugins/guards.js — then set
//   GUARD_SCRIPTS_DIR, because hooks/scripts will not be under every project)
//
// What it does, in `tool.execute.before` (fires before every tool call):
//   - bash tool  -> dangerous-command-guard + protected-paths-guard on the
//     command string, in ARGUMENT mode (`guard.sh 'cmd'` / `guard.sh
//     --command 'cmd'`): OpenCode hands a plugin tool arguments, not a hook
//     payload, and the guards accept either. Then, only when the command
//     looks like a `git commit`, the four commit guards (secret-scan,
//     check-large-files, check-merge-markers, quality-gate) run with a
//     PreToolUse-shaped JSON payload synthesized onto stdin, so each guard's
//     own payload narrowing still sees the real command.
//   - path-carrying tools (read/write/edit/...) -> protected-paths-guard on
//     the path argument, whatever the tool is called.
//
// Block semantics: the guards signal a block with exit 2 + the reason on
// stderr; an OpenCode plugin blocks a tool call by throwing. This shim
// converts one into the other and puts the guard's stderr into the Error
// message, so the refusal arrives with its WHY attached.
//
// The `git commit` narrowing lives here in JS because OpenCode has no
// declarative matcher. It is deliberately loose (`git ... commit` anywhere
// in the command): an over-match costs one cheap pass — the commit guards
// re-narrow on the payload they are handed — while an exact matcher that
// missed a commit spelling would silently skip the gates. quality-gate may
// invoke real toolchains, which is why it must not run on every bash call.
//
// What this shim deliberately does NOT do:
//   - It is not an access-control boundary. Everything here is best-effort
//     matching over tool arguments (hooks/README.md, "Three things to know");
//     hard allow/deny belongs in OpenCode's `permission` config.
//   - It does not replace the git-level pre-commit wiring. `git` enforces
//     its own hooks no matter who typed the command — keep both layers.
//
// FAIL-OPEN, mirroring the guards themselves: a bash call with no command
// string, a tool payload with no recognizable path field, or a tool this
// shim does not know about are all "nothing to judge", and the call passes
// untouched. FAIL-LOUD on malfunction: a guard that cannot run (missing
// script, missing utility) exits non-zero with a CANNOT CHECK reason, which
// this shim surfaces as a block — a check that did not run is never a pass.
//
// Runtime: OpenCode runs plugins under Bun and passes Bun's `$` shell API in
// the plugin context (https://opencode.ai/docs/plugins/) — no import, no
// dependency, and no Node fallback needed because the host, not the file,
// chooses the runtime.

export const Guards = async ({ $, directory, worktree }) => {
  // Where the guard scripts live. `worktree` is the project root OpenCode
  // reports (fall back to the working directory). A repo that vendors the
  // scripts somewhere else sets GUARD_SCRIPTS_DIR to that directory.
  const root = worktree || directory || "."
  const scriptsDir = process.env.GUARD_SCRIPTS_DIR || `${root}/hooks/scripts`

  const COMMIT_GUARDS = [
    "secret-scan.sh",
    "check-large-files.sh",
    "check-merge-markers.sh",
    "quality-gate.sh",
  ]

  // Exit 0 passes; anything else blocks, with the guard's stderr as the
  // reason (exit 2 is the guards' block signal; 126/127 etc. are the shim's
  // own "could not run the guard", reported, never swallowed).
  const gate = (guard, r) => {
    if (r.exitCode === 0) return
    const reason = r.stderr.toString().trim()
    throw new Error(reason || `${guard}: blocked (exit ${r.exitCode}, no reason on stderr)`)
  }

  return {
    "tool.execute.before": async (input, output) => {
      const args = output.args ?? {}

      if ((input.tool || "").toLowerCase() === "bash") {
        const cmd = args.command ?? ""
        if (!cmd) return // nothing to judge — fail open

        // Safety guards: every bash call, command handed as an argument.
        const dcg = `${scriptsDir}/dangerous-command-guard.sh`
        gate("dangerous-command-guard.sh", await $`bash ${dcg} ${cmd}`.cwd(root).nothrow().quiet())
        const ppg = `${scriptsDir}/protected-paths-guard.sh`
        gate("protected-paths-guard.sh", await $`bash ${ppg} --command ${cmd}`.cwd(root).nothrow().quiet())

        // Commit guards: only when the command is commit-shaped.
        if (!/\bgit\b[\s\S]*\bcommit\b/.test(cmd)) return
        const payload = JSON.stringify({ tool_name: "bash", tool_input: { command: cmd } })
        for (const guard of COMMIT_GUARDS) {
          const g = `${scriptsDir}/${guard}`
          gate(guard, await $`echo ${payload} | bash ${g}`.cwd(root).nothrow().quiet())
        }
        return
      }

      // Every other tool: guard the path if the arguments carry one.
      // Field name varies by tool/version; unknown shapes fail open.
      const p = args.filePath ?? args.file_path ?? args.path
      if (!p) return
      const ppg = `${scriptsDir}/protected-paths-guard.sh`
      gate("protected-paths-guard.sh", await $`bash ${ppg} ${p}`.cwd(root).nothrow().quiet())
    },
  }
}

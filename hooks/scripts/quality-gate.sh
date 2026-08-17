#!/usr/bin/env bash
# quality-gate.sh — run the repo's canonical fast quality checks (format,
# lint, type check) over the languages present in the STAGED diff.
#
# Project-type detection (files at the repo root):
#   pyproject.toml / setup.cfg / setup.py -> Python lane (staged *.py *.pyi)
#   package.json                          -> JS/TS lane  (staged *.js *.jsx
#                                            *.mjs *.cjs *.ts *.tsx *.mts *.cts)
#   Cargo.toml                            -> Rust lane   (staged *.rs)
#
# Default checks per lane (2026 canon):
#   Python: `ruff format --check` + `ruff check` on the staged files — via
#           `uv run ruff` when the repo is a uv project (uv.lock) and ruff
#           resolves there, else `uvx ruff`, else `ruff` on PATH.
#           Type check ONLY if configured: pyrightconfig.json or
#           [tool.pyright] -> pyright (uv run / PATH / uvx); mypy.ini,
#           .mypy.ini, [tool.mypy], or setup.cfg [mypy] -> mypy (uv run /
#           PATH only — never uvx: an isolated env cannot see the project's
#           dependencies, so uvx mypy reports false import errors).
#   JS/TS:  if biome.json[c] exists -> `npx biome check` (replaces both
#           prettier and eslint); otherwise `npx prettier --check` and
#           `npx eslint`, each ONLY if configured (config file, or a
#           "prettier"/"eslint"/"eslintConfig" key in package.json).
#           `npx tsc --noEmit` if tsconfig.json exists and TS files are
#           staged (always project-wide: per-file tsc ignores tsconfig).
#           npx runs with --no-install: a configured-but-uninstalled tool is
#           a skip-notice, never a surprise network install.
#   Rust:   `cargo fmt --all -- --check` +
#           `cargo clippy --all-targets -- -D warnings` (workspace-wide;
#           cargo has no per-file mode). Clippy compiles the crate — set
#           QG_RUST_LINT=off if that is too slow for your commit cadence.
#
# Outcome rules:
#   - a configured check that FAILS          -> BLOCK (exit 2, errors on stderr)
#   - a tool not configured / not installed  -> SKIP with a notice on stderr
#     (never silent, never blocking)
#   - full test suites do NOT belong here: pre-commit is for fast gates;
#     run the repo's `<test-command>` pre-push or in CI.
#
# Env overrides — align these with the consuming repo's `<lint-command>` /
# `<format-command>` / `<type-check-command>` bindings in AGENTS.md:
#   QG_PY_FORMAT   QG_PY_LINT   QG_PY_TYPECHECK
#   QG_JS_FORMAT   QG_JS_LINT   QG_JS_TYPECHECK
#   QG_RUST_FORMAT QG_RUST_LINT
#     ="off"        -> disable that one check (skips with a notice)
#     ="<command>"  -> replace the default: the command runs as-is via
#                      `sh -c` from the repo root (the staged file list is
#                      NOT appended — bind the full command, e.g.
#                      QG_PY_LINT="uv run ruff check src tests")
#   QG_MAX_ERROR_LINES -> failure lines shown per check (default 15)
#
# Two ways to run it (same dual-use wiring as secret-scan.sh):
#
#   1. Git pre-commit hook: call it from .git/hooks/pre-commit.
#      Any non-zero exit aborts the commit.
#
#   2. PreToolUse-style agent hook (Claude Code / Codex / Cursor): the agent
#      pipes the hook event JSON to stdin. This gate may invoke real
#      toolchains, so it narrows first — via the shared quote-aware helper in
#      lib/commit-payload.sh, the same one the cheap commit guards use: a
#      payload whose command is not an actual `git commit` invocation passes
#      immediately (a bare `commit` in quoted prose no longer runs the
#      toolchains, and a `git commit` never slips past as prose). Empty
#      stdin or an unrecognized payload always runs the gate (fail-closed
#      toward checking). Exit 2 + stderr = block.
#
# Exit codes: 0 = all checks passed or were skipped-with-notice,
#             2 = at least one configured check failed (blocking).

set -u

# Narrow to `git commit` payloads via the shared helper (it reads stdin and
# never hangs on a terminal); see lib/commit-payload.sh for the decision
# table. If the helper is missing — e.g. this file was symlinked into
# .git/hooks/ or copied out alone — fall back to drain-and-run: wrong only
# in the slow direction, never the unsafe one.
if . "${BASH_SOURCE[0]%/*}/lib/commit-payload.sh" 2>/dev/null; then
  commit_payload_wants_scan || exit 0
elif [ ! -t 0 ]; then
  cat > /dev/null || true
fi

# Outside a git repo, or nothing staged: nothing to gate.
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$repo_root" || exit 0

staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)"
[ -n "$staged" ] || exit 0

max_lines="${QG_MAX_ERROR_LINES:-15}"
gate_failed=0

note() {
  echo "quality-gate: skip: $*" >&2
}

report_fail() { # $1 = label, $2 = command shown, $3 = captured output
  echo "quality-gate: BLOCKED: $1 failed" >&2
  echo "  command: $2" >&2
  printf '%s\n' "$3" | head -n "$max_lines" | sed 's/^/    /' >&2
  gate_failed=1
}

# gate VAR LABEL [default command...]
#   $VAR="off"      -> skip with notice
#   $VAR="<cmd>"    -> run the override via `sh -c`
#   no default given -> skip with notice unless overridden
gate() {
  local var="$1" label="$2" ov="" out=""
  shift 2
  eval "ov=\${${var}:-}"
  if [ "$ov" = "off" ]; then
    note "$label disabled (\$$var=off)"
    return 0
  fi
  if [ -n "$ov" ]; then
    if ! out="$(sh -c "$ov" 2>&1)"; then
      report_fail "$label" "$ov  (from \$$var)" "$out"
    fi
    return 0
  fi
  if [ "$#" -eq 0 ]; then
    note "$label [override: set \$$var]"
    return 0
  fi
  if ! out="$("$@" 2>&1)"; then
    report_fail "$label" "$*" "$out"
  fi
  return 0
}

# --- Bucket staged files by language ---------------------------------------
py_files=()
js_files=()
ts_files=()
rs_files=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    *.py|*.pyi)             py_files+=("$f") ;;
    *.ts|*.tsx|*.mts|*.cts) ts_files+=("$f"); js_files+=("$f") ;;
    *.js|*.jsx|*.mjs|*.cjs) js_files+=("$f") ;;
    *.rs)                   rs_files+=("$f") ;;
  esac
done <<EOF
$staged
EOF

# --- Python lane ------------------------------------------------------------
if [ "${#py_files[@]}" -gt 0 ]; then
  if [ -f pyproject.toml ] || [ -f setup.cfg ] || [ -f setup.py ]; then
    # Resolve how to invoke ruff: project-pinned first, then ephemeral, then PATH.
    ruff_run=()
    if [ -f uv.lock ] && command -v uv > /dev/null 2>&1 \
      && uv run ruff --version > /dev/null 2>&1; then
      ruff_run=(uv run ruff)
    elif command -v uvx > /dev/null 2>&1 && uvx ruff --version > /dev/null 2>&1; then
      ruff_run=(uvx ruff)
    elif command -v ruff > /dev/null 2>&1; then
      ruff_run=(ruff)
    fi

    if [ "${#ruff_run[@]}" -gt 0 ]; then
      gate QG_PY_FORMAT "Python format (${ruff_run[*]} format --check)" \
        "${ruff_run[@]}" format --check "${py_files[@]}"
      gate QG_PY_LINT "Python lint (${ruff_run[*]} check)" \
        "${ruff_run[@]}" check "${py_files[@]}"
    else
      gate QG_PY_FORMAT "Python format — ruff not runnable (install uv or ruff)"
      gate QG_PY_LINT "Python lint — ruff not runnable (install uv or ruff)"
    fi

    # Type check only when the repo says it type-checks.
    has_pyright_cfg=0
    has_mypy_cfg=0
    if [ -f pyrightconfig.json ] \
      || grep -q '^\[tool\.pyright' pyproject.toml 2>/dev/null; then
      has_pyright_cfg=1
    fi
    if [ -f mypy.ini ] || [ -f .mypy.ini ] \
      || grep -q '^\[tool\.mypy' pyproject.toml 2>/dev/null \
      || grep -q '^\[mypy' setup.cfg 2>/dev/null; then
      has_mypy_cfg=1
    fi

    if [ "$has_pyright_cfg" -eq 1 ]; then
      pyright_run=()
      if [ -f uv.lock ] && command -v uv > /dev/null 2>&1 \
        && uv run pyright --version > /dev/null 2>&1; then
        pyright_run=(uv run pyright)
      elif command -v pyright > /dev/null 2>&1; then
        pyright_run=(pyright)
      elif command -v uvx > /dev/null 2>&1 && uvx pyright --version > /dev/null 2>&1; then
        pyright_run=(uvx pyright)
      fi
      if [ "${#pyright_run[@]}" -gt 0 ]; then
        gate QG_PY_TYPECHECK "Python type check (${pyright_run[*]})" \
          "${pyright_run[@]}" "${py_files[@]}"
      else
        gate QG_PY_TYPECHECK "Python type check — pyright configured but not runnable"
      fi
    elif [ "$has_mypy_cfg" -eq 1 ]; then
      mypy_run=()
      if [ -f uv.lock ] && command -v uv > /dev/null 2>&1 \
        && uv run mypy --version > /dev/null 2>&1; then
        mypy_run=(uv run mypy)
      elif command -v mypy > /dev/null 2>&1; then
        mypy_run=(mypy)
      fi
      if [ "${#mypy_run[@]}" -gt 0 ]; then
        gate QG_PY_TYPECHECK "Python type check (${mypy_run[*]})" \
          "${mypy_run[@]}" "${py_files[@]}"
      else
        gate QG_PY_TYPECHECK "Python type check — mypy configured but not runnable (uvx unsuitable: isolated env lacks project deps)"
      fi
    elif [ -n "${QG_PY_TYPECHECK:-}" ]; then
      gate QG_PY_TYPECHECK "Python type check"
    else
      note "Python type check — no pyright/mypy configuration detected"
    fi
  else
    note "staged Python files but no pyproject.toml/setup.cfg/setup.py at repo root — Python lane skipped"
  fi
fi

# --- JS/TS lane -------------------------------------------------------------
if [ "${#js_files[@]}" -gt 0 ]; then
  if [ ! -f package.json ]; then
    note "staged JS/TS files but no package.json at repo root — JS/TS lane skipped"
  elif ! command -v npx > /dev/null 2>&1; then
    note "JS/TS lane — npx not found (install Node.js); biome/prettier/eslint/tsc skipped"
  else
    has_biome_cfg=0
    if [ -f biome.json ] || [ -f biome.jsonc ]; then has_biome_cfg=1; fi

    has_prettier_cfg=0
    for c in .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.yaml \
      .prettierrc.json5 .prettierrc.js .prettierrc.cjs .prettierrc.mjs \
      .prettierrc.toml prettier.config.js prettier.config.cjs prettier.config.mjs; do
      if [ -f "$c" ]; then has_prettier_cfg=1; break; fi
    done
    if [ "$has_prettier_cfg" -eq 0 ] \
      && grep -q '"prettier"[[:space:]]*:' package.json 2>/dev/null; then
      has_prettier_cfg=1
    fi

    has_eslint_cfg=0
    for c in eslint.config.js eslint.config.mjs eslint.config.cjs \
      eslint.config.ts eslint.config.mts eslint.config.cts \
      .eslintrc.js .eslintrc.cjs .eslintrc.yaml .eslintrc.yml .eslintrc.json .eslintrc; do
      if [ -f "$c" ]; then has_eslint_cfg=1; break; fi
    done
    if [ "$has_eslint_cfg" -eq 0 ] \
      && grep -Eq '"(eslint|eslintConfig)"[[:space:]]*:' package.json 2>/dev/null; then
      has_eslint_cfg=1
    fi

    if [ "$has_biome_cfg" -eq 1 ]; then
      # Biome is the ruff-analog: one tool for format + lint.
      if npx --no-install biome --version > /dev/null 2>&1; then
        gate QG_JS_LINT "JS/TS format+lint (npx biome check)" \
          npx --no-install biome check "${js_files[@]}"
      else
        gate QG_JS_LINT "JS/TS format+lint — biome configured but not installed (npm install?)"
      fi
      if [ "$has_prettier_cfg" -eq 1 ] || [ "$has_eslint_cfg" -eq 1 ]; then
        note "prettier/eslint configs also present, but biome.json wins here (force them back via \$QG_JS_FORMAT/\$QG_JS_LINT)"
      fi
      if [ -n "${QG_JS_FORMAT:-}" ] && [ "$QG_JS_FORMAT" != "off" ]; then
        gate QG_JS_FORMAT "JS/TS format"
      fi
    else
      if [ "$has_prettier_cfg" -eq 1 ]; then
        if npx --no-install prettier --version > /dev/null 2>&1; then
          gate QG_JS_FORMAT "JS/TS format (npx prettier --check)" \
            npx --no-install prettier --check "${js_files[@]}"
        else
          gate QG_JS_FORMAT "JS/TS format — prettier configured but not installed (npm install?)"
        fi
      elif [ -n "${QG_JS_FORMAT:-}" ]; then
        gate QG_JS_FORMAT "JS/TS format"
      else
        note "JS/TS format — no prettier (or biome) configuration detected"
      fi

      if [ "$has_eslint_cfg" -eq 1 ]; then
        if npx --no-install eslint --version > /dev/null 2>&1; then
          gate QG_JS_LINT "JS/TS lint (npx eslint)" \
            npx --no-install eslint --no-error-on-unmatched-pattern "${js_files[@]}"
        else
          gate QG_JS_LINT "JS/TS lint — eslint configured but not installed (npm install?)"
        fi
      elif [ -n "${QG_JS_LINT:-}" ]; then
        gate QG_JS_LINT "JS/TS lint"
      else
        note "JS/TS lint — no eslint (or biome) configuration detected"
      fi
    fi

    if [ "${#ts_files[@]}" -gt 0 ] && [ -f tsconfig.json ]; then
      if npx --no-install tsc --version > /dev/null 2>&1; then
        gate QG_JS_TYPECHECK "TypeScript type check (npx tsc --noEmit)" \
          npx --no-install tsc --noEmit
      else
        gate QG_JS_TYPECHECK "TypeScript type check — tsconfig.json present but typescript not installed (npm install?)"
      fi
    elif [ -n "${QG_JS_TYPECHECK:-}" ]; then
      gate QG_JS_TYPECHECK "JS/TS type check"
    elif [ "${#ts_files[@]}" -gt 0 ]; then
      note "TypeScript type check — no tsconfig.json at repo root"
    fi
  fi
fi

# --- Rust lane --------------------------------------------------------------
if [ "${#rs_files[@]}" -gt 0 ]; then
  if [ ! -f Cargo.toml ]; then
    note "staged Rust files but no Cargo.toml at repo root — Rust lane skipped"
  elif ! command -v cargo > /dev/null 2>&1; then
    note "Rust lane — cargo not found on PATH; fmt/clippy skipped"
  else
    if cargo fmt --version > /dev/null 2>&1; then
      gate QG_RUST_FORMAT "Rust format (cargo fmt --check)" \
        cargo fmt --all -- --check
    else
      gate QG_RUST_FORMAT "Rust format — rustfmt not installed (rustup component add rustfmt)"
    fi
    if cargo clippy --version > /dev/null 2>&1; then
      gate QG_RUST_LINT "Rust lint (cargo clippy -D warnings)" \
        cargo clippy --all-targets --quiet -- -D warnings
    else
      gate QG_RUST_LINT "Rust lint — clippy not installed (rustup component add clippy)"
    fi
  fi
fi

if [ "$gate_failed" -ne 0 ]; then
  echo "quality-gate: blocking commit — fix the failures above, re-stage, retry." >&2
  echo "quality-gate: never bypass with --no-verify; to drop a single check, set its QG_* var (see script header)." >&2
  exit 2
fi

exit 0

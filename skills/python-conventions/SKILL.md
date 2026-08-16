---
name: python-conventions
description: Python writing conventions — docstring rules (Google style + ruff D config), naming, modern 3.12+ idioms, typing policy. Load BEFORE writing any Python code. Rule-index style; each rule one line.
---

# Python conventions

Assumed toolchain: uv, pytest, ruff, mypy --strict. This skill covers HOW code is
written. Companion skills, where installed: `contract-docstrings`
(failure-mode docs on boundary code), `tighten-types` (hardening pass),
`python-api-design`, `python-documentation`.

## Docstrings — Google style, ruff-enforced

- pyproject config (every Python component):
  ```toml
  [tool.ruff.lint]
  extend-select = ["D"]
  [tool.ruff.lint.pydocstyle]
  convention = "google"
  [tool.ruff.lint.per-file-ignores]
  "tests/**" = ["D"]
  ```
  plus global `ignore = ["D105", "D107"]` (magic methods, `__init__`).
  Research/spike directories: docstrings exempt entirely.
- Mandatory on every public module, class, and function; optional on `_private` helpers
  (explain WHY in a comment instead).
- First line: one-sentence summary, descriptive mood ("Returns the…" — Google convention;
  D401 imperative is auto-disabled under `convention = "google"`), ends with a period;
  blank line before detail.
- NO types in docstrings — mypy --strict annotations are the single source of truth.
- Args: only params whose constraints/units aren't obvious from name+type; never restate
  the signature.
- Raises: document the actual contract — preconditions, every exception a caller may
  catch, and silenced failures (use `contract-docstrings` on boundary/IO functions).
- Examples: only on top-level public API entry points.

## Naming + API surface

- `get_*` returns, `is_/has_` bools, `to_*` converts (new object), `from_*` constructs.
- Keyword-only args (`*,`) for any boolean or >2-arg public function — no boolean traps.
- Fail loud: never return success-shaped values on error paths (no empty-list-as-failure,
  no fabricated fallbacks, no partial mutation before validation). Raise.

## Modern idioms (3.12+)

- `X | None` never `Optional[X]`; builtin generics (`list[str]`); `type` statement for
  aliases; `Self` for fluent returns.
- `match` only where it beats if-chains (structural dispatch); dataclasses for internal
  value types; Pydantic ONLY at system boundaries needing runtime validation (external
  input surfaces, config parsing); TypedDict for internal dict-shape compat.
- No mutable default args; pathlib over os.path; f-strings only.

---
name: rustdoc-conventions
description: Rustdoc + Rust writing conventions — doc-comment sections, first-sentence rule, Cargo.toml lint table. Load BEFORE writing any Rust code. Companions are rust-pragmatic (prose discipline) and rust-api-checklist (public API review).
---

# Rustdoc conventions

Toolchain baseline: cargo test, clippy-clean, rustfmt. This skill pins doc-comments and
lint policy.

## Doc-comments

- Every `pub` item gets `///`; every public module gets `//!` module docs; `lib.rs` crate
  docs carry the README-level overview.
- First sentence: one line, ≤15 words, third person ("Returns…", "Creates…"). No parameter
  tables — name params inline in prose.
- Sections, in this order, when applicable:
  - `# Examples` — compiling doctests; use `?`, never `unwrap()`.
  - `# Errors` — MANDATORY on any fn returning `Result`.
  - `# Panics` — any reachable panic.
  - `# Safety` — MANDATORY on every `unsafe fn`: list caller invariants. Omission is a
    soundness bug, not a style nit.
- Cross-reference with intra-doc links `` [`Type`] ``.

## Lint policy — Cargo.toml `[lints]` per crate

```toml
[lints.rust]
missing_docs = "warn"          # flip to "deny" when a crate goes public

[lints.clippy]
missing_safety_doc = "deny"
missing_errors_doc = "warn"
missing_panics_doc = "warn"
```

## Writing routing

- Public API surface added/changed → run the `rust-api-checklist` skill (C-* checklist).
- Doc prose quality on public items → `rust-pragmatic` (M-FIRST-DOC-SENTENCE,
  M-MODULE-DOCS, M-CANONICAL-DOCS).
- Errors: `thiserror` for library crates; `anyhow` only in binaries/top-level glue.

---
name: rust-api-checklist
description: The official rust-lang API Guidelines C-* checklist (naming, documentation, predictability, dependability). Use during API design review or adversarial code review whenever a `pub` item in a Rust crate is added or changed, and before any crate/repo goes public.
license: MIT OR Apache-2.0
metadata:
  source: "rust-lang/api-guidelines"
---

# Rust API Guidelines checklist — loader

References (verbatim from rust-lang/api-guidelines, fetched 2026-07-25):
- `references/checklist.md` — the full C-* checklist; walk it for the touched API surface.
- `references/naming.md` — C-CASE, C-CONV (as_/to_/into_), C-GETTER, C-ITER, C-WORD-ORDER.
- `references/documentation.md` — C-CRATE-DOC, C-EXAMPLE, C-QUESTION-MARK, C-FAILURE,
  C-LINK, C-METADATA.

Apply proportionally: internal crates get naming + documentation sections; anything
public-facing gets the full checklist. Project-pinned doc rules in `rustdoc-conventions`
take precedence on conflicts.

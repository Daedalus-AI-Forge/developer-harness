---
name: rust-pragmatic
description: Microsoft Pragmatic Rust Guidelines (agents edition) — prose-level discipline for Rust docs and APIs (M-* rules such as first-doc-sentence ≤15 words, module docs, canonical doc structure). Use when authoring/reviewing public Rust API items or doc-comments; load only the sections relevant to the task (the corpus is ~33k tokens).
license: MIT
metadata:
  source: "microsoft/rust-guidelines"
---

# Microsoft Pragmatic Rust Guidelines — loader

Full corpus: `references/guidelines.txt` (verbatim from
https://microsoft.github.io/rust-guidelines/agents/all.txt, fetched 2026-07-25).

Do NOT read the whole file. Grep for the relevant M-* rule sections:
- Doc work → `M-FIRST-DOC-SENTENCE`, `M-MODULE-DOCS`, `M-CANONICAL-DOCS`
- API shape → search "Universal" section + the specific concern (naming, errors, builders)

Project-pinned doc rules live in `rustdoc-conventions` — where the two disagree, the
project skill wins.

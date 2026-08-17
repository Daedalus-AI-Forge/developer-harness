#!/usr/bin/env bash
# instruction-scan.sh — scan instruction-bearing files for invisible-Unicode
# injection vectors.
#
# Why this class of file: published audits of skill marketplaces found a large
# share of listed skills carrying flaws, with prompt injection through the
# SKILL.md body the dominant vector — and invisible payloads among them, since
# a Unicode Tag or zero-width run is invisible to a human reviewer while a
# model reads it as text. This repo ships exactly that artifact class: skills,
# role contracts, rules fragments, command wrappers. So it scans its own.
#
# What it looks for, matched as UTF-8 BYTE sequences under LC_ALL=C so no
# Unicode-aware tooling is needed anywhere:
#   - Unicode Tag characters, U+E0000-U+E007F (bytes F3 A0 80/81 xx) — the
#     ASCII-mirroring block used to smuggle whole instructions invisibly
#   - zero-width characters: U+200B ZWSP, U+200C ZWNJ, U+200D ZWJ,
#     U+2060 word joiner, U+FEFF zero-width no-break space, U+00AD soft hyphen
#   - bidirectional overrides and isolates: U+202A-U+202E, U+2066-U+2069 —
#     the Trojan Source class, where rendered order differs from byte order
#
# A leading U+FEFF byte-order mark on a file is legitimate and is ignored; the
# same bytes anywhere else are reported.
#
# Dependency-free: bash + grep + sed + tr (+ git in staged mode).
#
# Two shapes, same script:
#   1. Pre-commit (default): scans the STAGED content (`git show :<path>`) of
#      staged instruction files. Nothing staged, nothing to do.
#   2. CI / audit: `instruction-scan.sh --all` (or INSTRUCTION_SCAN_MODE=tree)
#      walks the working tree — run it on pull requests and on any vendored
#      skill you pull in from outside.
#
# Env overrides:
#   INSTRUCTION_SCAN_MODE   staged (default) | tree
#   INSTRUCTION_SCAN_PATHS  colon-separated roots scanned in full
#                           (default: skills:rules:agents:commands)
#                           Markdown at the repo root is always included.
#   INSTRUCTION_SCAN_EXTS   colon-separated extensions inside those roots
#                           (default: md:markdown:yaml:yml:txt:json)
#   INSTRUCTION_SCAN_SKIP   colon-separated codepoint ids to ignore, e.g.
#                           "U+200D:U+200C" for a repo whose docs carry emoji
#                           ZWJ sequences, or "U+00AD" for imported prose
#
# Reports cannot-check separately from checked-clean: if no configured root
# exists and no root Markdown is present, it says so on stderr rather than
# passing silently.
#
# Exit codes: 0 = clean (or nothing in scope), 2 = invisible characters found,
#             or the scan could not run.

set -u

for tool in grep sed; do
  command -v "$tool" > /dev/null 2>&1 || {
    echo "instruction-scan: CANNOT CHECK — '$tool' not found on PATH; the scan did not run." >&2
    exit 2
  }
done

# Drain stdin when piped (agent hooks send JSON); never hang on a terminal.
if [ ! -t 0 ]; then
  cat > /dev/null || true
fi

mode="${INSTRUCTION_SCAN_MODE:-staged}"
case "${1:-}" in
  --all|--tree) mode="tree" ;;
  --staged)     mode="staged" ;;
  "")           ;;
  *) echo "instruction-scan: unknown argument '$1' (expected --all or --staged)" >&2; exit 2 ;;
esac

roots="${INSTRUCTION_SCAN_PATHS:-skills:rules:agents:commands}"
exts="${INSTRUCTION_SCAN_EXTS:-md:markdown:yaml:yml:txt:json}"
skip="${INSTRUCTION_SCAN_SKIP:-}"

# --- the invisible set ------------------------------------------------------
# Parallel arrays: codepoint id, human label, raw UTF-8 bytes.
ids=(
  "U+E0000-E007F" "U+E0000-E007F"
  "U+200B" "U+200C" "U+200D" "U+2060" "U+FEFF" "U+00AD"
  "U+202A" "U+202B" "U+202C" "U+202D" "U+202E"
  "U+2066" "U+2067" "U+2068" "U+2069"
)
labels=(
  "Unicode Tag character (invisible instruction smuggling)"
  "Unicode Tag character (invisible instruction smuggling)"
  "zero-width space" "zero-width non-joiner" "zero-width joiner"
  "word joiner" "zero-width no-break space (mid-file)" "soft hyphen"
  "bidi LEFT-TO-RIGHT EMBEDDING" "bidi RIGHT-TO-LEFT EMBEDDING"
  "bidi POP DIRECTIONAL FORMATTING" "bidi LEFT-TO-RIGHT OVERRIDE"
  "bidi RIGHT-TO-LEFT OVERRIDE" "bidi LEFT-TO-RIGHT ISOLATE"
  "bidi RIGHT-TO-LEFT ISOLATE" "bidi FIRST STRONG ISOLATE"
  "bidi POP DIRECTIONAL ISOLATE"
)
bytes=(
  $'\xf3\xa0\x80' $'\xf3\xa0\x81'
  $'\xe2\x80\x8b' $'\xe2\x80\x8c' $'\xe2\x80\x8d' $'\xe2\x81\xa0' $'\xef\xbb\xbf' $'\xc2\xad'
  $'\xe2\x80\xaa' $'\xe2\x80\xab' $'\xe2\x80\xac' $'\xe2\x80\xad' $'\xe2\x80\xae'
  $'\xe2\x81\xa6' $'\xe2\x81\xa7' $'\xe2\x81\xa8' $'\xe2\x81\xa9'
)

# Honour INSTRUCTION_SCAN_SKIP by building the active index list.
active=()
for i in "${!ids[@]}"; do
  drop=0
  old_ifs="$IFS"; IFS=:
  for s in $skip; do
    [ -n "$s" ] || continue
    [ "$s" = "${ids[$i]}" ] && drop=1
  done
  IFS="$old_ifs"
  [ "$drop" -eq 0 ] && active+=("$i")
done
if [ "${#active[@]}" -eq 0 ]; then
  echo "instruction-scan: CANNOT CHECK — \$INSTRUCTION_SCAN_SKIP disabled every pattern." >&2
  exit 2
fi

grep_args=()
for i in "${active[@]}"; do
  grep_args+=(-e "${bytes[$i]}")
done

# --- candidate files --------------------------------------------------------

has_ext() { # $1 = path, $2 = colon-separated extension list
  he_base="${1##*/}"
  case "$he_base" in *.*) he_ext="${he_base##*.}" ;; *) return 1 ;; esac
  he_old_ifs="$IFS"; IFS=:
  for he_e in $2; do
    if [ -n "$he_e" ] && [ "$he_e" = "$he_ext" ]; then IFS="$he_old_ifs"; return 0; fi
  done
  IFS="$he_old_ifs"
  return 1
}

in_roots() { # $1 = path
  ir_old_ifs="$IFS"; IFS=:
  for ir_r in $roots; do
    [ -n "$ir_r" ] || continue
    ir_r="${ir_r%/}"
    case "$1" in "$ir_r"/*) IFS="$ir_old_ifs"; return 0 ;; esac
  done
  IFS="$ir_old_ifs"
  return 1
}

is_candidate() { # $1 = repo-relative path
  case "$1" in
    */*) in_roots "$1" && has_ext "$1" "$exts" ;;
    *)   has_ext "$1" "md:markdown" ;;   # root level: Markdown only
  esac
}

roots_present=0
old_ifs="$IFS"; IFS=:
for r in $roots; do
  [ -n "$r" ] || continue
  [ -d "${r%/}" ] && roots_present=1
done
IFS="$old_ifs"

files=""
if [ "$mode" = "tree" ]; then
  command -v find > /dev/null 2>&1 || {
    echo "instruction-scan: CANNOT CHECK — 'find' not found on PATH; the tree scan did not run." >&2
    exit 2
  }
  files="$(
    {
      find . -maxdepth 1 -type f -name '*.md' 2> /dev/null
      find . -maxdepth 1 -type f -name '*.markdown' 2> /dev/null
      old_ifs="$IFS"; IFS=:
      for r in $roots; do
        [ -n "$r" ] || continue
        [ -d "${r%/}" ] && find "${r%/}" -type f 2> /dev/null
      done
      IFS="$old_ifs"
    } | sed 's|^\./||' | sort -u
  )"
else
  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0
  files="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)"
fi

# --- scan -------------------------------------------------------------------

BOM=$'\xef\xbb\xbf'
found=0
scanned=0

report_file() { # $1 = path, $2 = buffered content
  rf_path="$1"; rf_buf="$2"
  echo "  ${rf_path}:" >&2
  for i in "${active[@]}"; do
    # The tag patterns match a 3-byte prefix; the rendering swallows the
    # fourth byte too (`.` is one byte under LC_ALL=C), so no orphaned byte
    # is left behind to make the excerpt invalid UTF-8.
    rf_render="${bytes[$i]}"
    case "${ids[$i]}" in "U+E0000-E007F") rf_render="${bytes[$i]}." ;; esac
    rf_hits="$(
      printf '%s\n' "$rf_buf" \
        | LC_ALL=C grep -n -F -e "${bytes[$i]}" 2> /dev/null \
        | head -3 \
        | LC_ALL=C sed "s/${rf_render}/<${ids[$i]}>/g" \
        | LC_ALL=C cut -c1-140
    )"
    [ -n "$rf_hits" ] || continue
    echo "    [${ids[$i]} ${labels[$i]}]" >&2
    printf '%s\n' "$rf_hits" | sed 's/^/      /' >&2
  done
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  is_candidate "$f" || continue

  if [ "$mode" = "tree" ]; then
    [ -f "$f" ] || continue
    scanned=$((scanned + 1))
    # Cheap first pass straight off disk: only a file that hits is read into
    # memory for BOM handling and per-codepoint reporting.
    LC_ALL=C grep -q -F "${grep_args[@]}" -- "$f" 2> /dev/null
    case "$?" in
      1) continue ;;
      0) ;;
      *) echo "instruction-scan: CANNOT CHECK — grep failed on '$f'." >&2; exit 2 ;;
    esac
    buf="$(cat -- "$f" 2>/dev/null)" || {
      echo "instruction-scan: CANNOT CHECK — unreadable file '$f'." >&2
      exit 2
    }
  else
    buf="$(git show ":$f" 2>/dev/null)" || {
      echo "instruction-scan: CANNOT CHECK — staged content of '$f' could not be read." >&2
      exit 2
    }
    scanned=$((scanned + 1))
  fi

  # A byte-order mark at offset 0 is legitimate; the same bytes later are not.
  buf="${buf#"$BOM"}"

  if printf '%s\n' "$buf" | LC_ALL=C grep -q -F "${grep_args[@]}" 2> /dev/null; then
    if [ "$found" -eq 0 ]; then
      echo "instruction-scan: invisible Unicode found in instruction-bearing files:" >&2
      found=1
    fi
    report_file "$f" "$buf"
  fi
done <<EOF
$files
EOF

if [ "$found" -ne 0 ]; then
  echo "instruction-scan: blocking. Delete the invisible characters (they carry no meaning a reader can see); if a file genuinely needs one, exempt that codepoint through \$INSTRUCTION_SCAN_SKIP and say why in the commit." >&2
  exit 2
fi

if [ "$scanned" -eq 0 ]; then
  if [ "$roots_present" -eq 0 ]; then
    echo "instruction-scan: scanned 0 files — none of the configured roots ($roots) exist here. Set \$INSTRUCTION_SCAN_PATHS to this repo's instruction directories, or the scan is checking nothing." >&2
  fi
fi

exit 0

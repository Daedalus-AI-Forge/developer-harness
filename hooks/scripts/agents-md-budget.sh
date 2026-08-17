#!/usr/bin/env bash
# agents-md-budget.sh — keep the AGENTS.md chain inside the size the consuming
# tools will actually deliver to a model.
#
# The chain, not the file: an agent working in <repo>/skills/foo is handed the
# root AGENTS.md concatenated with every nested AGENTS.md on the path down to
# that directory. What matters is therefore the largest chain any working
# directory produces, which is what this script computes — root first, then
# each nested file in path order, exactly as the concatenation is assembled.
#
# Why a hard limit at all: Codex caps the concatenated AGENTS.md chain at
# 32 KiB (32768 bytes) and TRUNCATES silently — everything past the cap is
# dropped with no warning, so the instructions you think are in force simply
# are not. A limit you cannot see enforced is worse than one you can, hence
# this gate. Other tools have their own budgets; the default here is the
# tightest documented one.
#
# Bytes are what the limit counts, so bytes are what this reports — a
# multi-byte character costs more than one character of budget.
#
# Not expanded: @import / @path references (Claude Code's CLAUDE.md style) and
# any file the chain links to. Those pull in more context at load time; this
# gate measures the concatenated chain itself. Point it at CLAUDE.md with
# AMB_FILENAME if that is the chain your consuming tool assembles.
#
# Dependency-free: bash + find + wc (+ git, only to read staged sizes).
#
# In a git repo the size measured is the STAGED one (`git cat-file -s :path`),
# so a pre-commit run judges what the commit will contain; untracked files and
# non-git checkouts fall back to the on-disk size.
#
# Env overrides:
#   AGENTS_MD_MAX_BYTES    hard limit, blocks above it (default 32768)
#   AGENTS_MD_WARN_BYTES   warn threshold, still exit 0 (default 24576)
#   AMB_FILENAME           instruction filename to chain (default AGENTS.md)
#   AMB_EXCLUDE_DIRS       colon-separated directory names never descended
#                          (default .git:node_modules:.venv:venv:target:dist:
#                          build:vendor:.next:__pycache__)
#
# Exit codes: 0 = within budget (a warning still exits 0),
#             2 = over the hard limit, or the measurement could not be made.

set -u

for tool in find wc; do
  command -v "$tool" > /dev/null 2>&1 || {
    echo "agents-md-budget: CANNOT CHECK — '$tool' not found on PATH; the budget was not measured." >&2
    exit 2
  }
done

# Drain stdin when piped (agent hooks send JSON); never hang on a terminal.
if [ ! -t 0 ]; then
  cat > /dev/null || true
fi

max_bytes="${AGENTS_MD_MAX_BYTES:-32768}"
warn_bytes="${AGENTS_MD_WARN_BYTES:-24576}"
filename="${AMB_FILENAME:-AGENTS.md}"
exclude_dirs="${AMB_EXCLUDE_DIRS:-.git:node_modules:.venv:venv:target:dist:build:vendor:.next:__pycache__}"

for v in AGENTS_MD_MAX_BYTES:"$max_bytes" AGENTS_MD_WARN_BYTES:"$warn_bytes"; do
  case "${v#*:}" in
    ''|*[!0-9]*)
      echo "agents-md-budget: CANNOT CHECK — \$${v%%:*} must be a positive integer (got '${v#*:}')." >&2
      exit 2
      ;;
  esac
done
if [ "$warn_bytes" -gt "$max_bytes" ]; then
  echo "agents-md-budget: CANNOT CHECK — \$AGENTS_MD_WARN_BYTES ($warn_bytes) is above \$AGENTS_MD_MAX_BYTES ($max_bytes); the warning could never fire." >&2
  exit 2
fi

in_git=0
if command -v git > /dev/null 2>&1 && git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  in_git=1
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "agents-md-budget: CANNOT CHECK — inside a git work tree but its root could not be resolved." >&2
    exit 2
  }
  cd "$root" || {
    echo "agents-md-budget: CANNOT CHECK — cannot enter repo root '$root'." >&2
    exit 2
  }
fi

# --- collect the instruction files ------------------------------------------

prune_expr=""
old_ifs="$IFS"; IFS=:
for d in $exclude_dirs; do
  [ -n "$d" ] || continue
  prune_expr="$prune_expr -name $d -o"
done
IFS="$old_ifs"
prune_expr="${prune_expr% -o}"

if [ -n "$prune_expr" ]; then
  # shellcheck disable=SC2086
  files="$(find . \( $prune_expr \) -prune -o -type f -name "$filename" -print 2>/dev/null | sed 's|^\./||' | sort)"
else
  files="$(find . -type f -name "$filename" -print 2>/dev/null | sed 's|^\./||' | sort)"
fi

if [ -z "$files" ]; then
  echo "agents-md-budget: no $filename found here — nothing to measure (set \$AMB_FILENAME if this repo's instruction file has another name)." >&2
  exit 0
fi

# Size every file once, up front and in THIS shell, so a measurement failure
# is a loud exit rather than an empty string inside an arithmetic expansion.
# Map lines are "<bytes> <path>" — path last, so paths with spaces survive.
sizes=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  s=""
  if [ "$in_git" -eq 1 ]; then
    s="$(git cat-file -s ":$f" 2>/dev/null)" || s=""
  fi
  if [ -z "$s" ]; then
    s="$(wc -c < "$f" 2>/dev/null)" || {
      echo "agents-md-budget: CANNOT CHECK — could not size '$f'." >&2
      exit 2
    }
  fi
  s="$((s + 0))"
  sizes="${sizes}${s} ${f}
"
done <<EOF
$files
EOF

SIZE=0
size_of() { # $1 = repo-relative path -> sets SIZE
  SIZE=0
  while IFS=' ' read -r so_s so_p; do
    if [ "$so_p" = "$1" ]; then SIZE="$so_s"; return 0; fi
  done <<SIZES
$sizes
SIZES
  echo "agents-md-budget: CANNOT CHECK — no measured size for '$1'." >&2
  exit 2
}

dir_of() { # repo-relative dir of a repo-relative file ("." at the root)
  case "$1" in
    */*) printf '%s' "${1%/*}" ;;
    *)   printf '%s' "." ;;
  esac
}

is_ancestor() { # $1 = ancestor dir, $2 = dir
  [ "$1" = "." ] && return 0
  [ "$1" = "$2" ] && return 0
  case "$2" in "$1"/*) return 0 ;; esac
  return 1
}

# --- worst chain -------------------------------------------------------------

worst_total=0
worst_dir=""
chains=0

while IFS= read -r leaf; do
  [ -n "$leaf" ] || continue
  leaf_dir="$(dir_of "$leaf")"
  chains=$((chains + 1))
  total=0
  while IFS= read -r member; do
    [ -n "$member" ] || continue
    m_dir="$(dir_of "$member")"
    if is_ancestor "$m_dir" "$leaf_dir"; then
      size_of "$member"
      total=$((total + SIZE))
    fi
  done <<INNER
$files
INNER
  if [ "$total" -gt "$worst_total" ]; then
    worst_total="$total"
    worst_dir="$leaf_dir"
  fi
done <<OUTER
$files
OUTER

print_chain() { # prints the worst chain, root first, with running totals
  running=0
  while IFS= read -r member; do
    [ -n "$member" ] || continue
    m_dir="$(dir_of "$member")"
    if is_ancestor "$m_dir" "$worst_dir"; then
      size_of "$member"
      sz="$SIZE"
      running=$((running + sz))
      marker=""
      [ "$running" -gt "$max_bytes" ] && marker="   <- past the ${max_bytes}-byte cap: truncated here"
      echo "    ${member}  ${sz} bytes  (running ${running})${marker}" >&2
    fi
  done <<CHAIN
$files
CHAIN
}

if [ "$worst_total" -gt "$max_bytes" ]; then
  echo "agents-md-budget: the ${filename} chain delivered in '${worst_dir}' is ${worst_total} bytes, over the ${max_bytes}-byte cap by $((worst_total - max_bytes)):" >&2
  print_chain
  echo "agents-md-budget: blocking. Everything past the cap is dropped silently at load time, so move detail into files the chain POINTS AT (skills, rules fragments, docs) and keep the chain itself a map. Raise \$AGENTS_MD_MAX_BYTES only if every consuming tool in this repo documents a larger budget." >&2
  exit 2
fi

if [ "$worst_total" -gt "$warn_bytes" ]; then
  echo "agents-md-budget: WARNING — the ${filename} chain delivered in '${worst_dir}' is ${worst_total} bytes, past the ${warn_bytes}-byte warn line (hard cap ${max_bytes}):" >&2
  print_chain
  echo "agents-md-budget: not blocking. Trim before it reaches the cap — after the cap the overflow disappears without a message." >&2
fi

exit 0

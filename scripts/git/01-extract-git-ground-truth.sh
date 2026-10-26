#!/usr/bin/env bash
#
# 01-extract-git-ground-truth.sh
#
# Extracts the documented options for every git subcommand as the UNION of
# three documentation surfaces git itself ships:
#   1. `git <cmd> -h`                       short structured help
#   2. the man page's option definition lines (and explicit synonym notes,
#      which is the only place e.g. `git diff --staged` is documented)
#   3. `git <cmd> --git-completion-helper-all`  the machine-readable option
#      list git exposes for shell completion
# No single surface is complete: since git 2.46 the -h output of several
# commands (config, diff, log) is a bare usage stub, man definition lines
# omit prose-only synonyms, and the completion helper omits synonyms too.
#
# Produces one file per subcommand in the groundtruth/git/ directory,
# each containing one option per line (e.g. -v, --verbose, --no-edit).
# Toggle options written as --[no-]xxx are expanded into --xxx and --no-xxx.
#
# Requirements: git (any recent version; tested with 2.54)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GT_DIR="$BASE_DIR/data/groundtruth/git"
RAW_DIR="$BASE_DIR/data/groundtruth/raw_help/git"
mkdir -p "$RAW_DIR"

mkdir -p "$GT_DIR"

# Record git version
git --version > "$GT_DIR/_version.txt"

# Get git's own subcommands (builtins + main porcelain, excludes
# third-party git-* commands found on PATH which are machine-dependent)
subcommands=$(git --list-cmds=builtins,main 2>/dev/null | sort -u)

total=$(echo "$subcommands" | wc -l)
echo "Found $total git subcommands. Extracting options..."

count=0
extracted=0

# extract_git_tokens <text>: option tokens incl. --[no-] expansion
extract_git_tokens() {
    local text="$1"
    {
        echo "$text" | grep -oP '(?<![a-zA-Z0-9])-[a-zA-Z0-9](?![a-zA-Z0-9])' || true
        echo "$text" | grep -oP -- '--\[no-\][a-z][a-z0-9-]+' | sed 's/--\[no-\]/--/' || true
        echo "$text" | grep -oP -- '--\[no-\][a-z][a-z0-9-]+' | sed 's/--\[no-\]/--no-/' || true
        echo "$text" | grep -oP -- '--[a-z][a-z0-9-]+' || true
    }
}

for cmd in $subcommands; do
    count=$((count + 1))

    # Surface 1: short structured help (timeout avoids interactive hangs)
    help_text=$(timeout 3 git "$cmd" -h 2>&1 || true)

    # Surface 2: man page option definition lines + synonym notes.
    # Rendered definition lines are indented exactly 7 spaces and start
    # with a dash; deeper-indented lines are prose.
    man_text=$(MANWIDTH=100 timeout 5 git help -m "$cmd" 2>/dev/null | col -b || true)
    man_defs=$(echo "$man_text" | grep -E '^ {7}-' || true)
    man_syns=$(echo "$man_text" | grep -iE 'synonym' || true)

    # Surface 3: completion helper (space-separated, may carry trailing =)
    comp=$(timeout 3 git "$cmd" --git-completion-helper-all 2>/dev/null \
        | tr ' ' '\n' | sed 's/[^a-zA-Z0-9-]*$//' | grep -E '^--?[a-zA-Z0-9-]+$' || true)

    if [ -z "$help_text" ] && [ -z "$man_defs" ] && [ -z "$comp" ]; then
        continue
    fi

    options=$({
        extract_git_tokens "$help_text"
        extract_git_tokens "$man_defs"
        extract_git_tokens "$man_syns"
        echo "$comp"
    } | grep -E '^-' | sort -u || true)

    if [ -n "$options" ]; then
        {
            echo "===== git $cmd -h ====="
            echo "$help_text"
            echo "===== man option definition lines ====="
            echo "$man_defs"
            echo "===== completion helper ====="
            echo "$comp"
        } > "$RAW_DIR/${cmd}.txt"
        echo "$options" > "$GT_DIR/${cmd}.txt"
        extracted=$((extracted + 1))
    fi
done

echo ""
echo "Extracted ground truth for $extracted / $total subcommands."

# Compute summary
total_options=0
for f in "$GT_DIR"/*.txt; do
    [ -f "$f" ] || continue
    [[ "$(basename "$f")" == _* ]] && continue
    n=$(wc -l < "$f")
    total_options=$((total_options + n))
done

echo "$extracted subcommands, $total_options total options" > "$GT_DIR/_summary.txt"
echo "Total documented options: $total_options"
echo "Output: $GT_DIR"

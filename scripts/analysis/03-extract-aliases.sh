#!/usr/bin/env bash
# Build the short<->long alias map for every unit by re-reading each tool's
# --help. This lets step 04 collapse -n and --number into one logical option so
# a human using -n and an LLM using --number count as the same feature. Only
# pairs where both forms exist in the unit's ground truth are kept. Raw help is
# saved under data/groundtruth/raw_help/ for reproducibility; tool versions are
# pinned in data/groundtruth/versions.txt.
# Out: results/analysis/aliases_long.csv  ->  dataset,unit,short,long
set -uo pipefail            # no -e; some --help calls exit non-zero by design
export TERM=dumb            # suppress ANSI/hyperlinks that corrupt parsing

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd "$HERE/../.." && pwd)"
AN="$BASE/results/analysis"
GTDIR="$BASE/data/groundtruth"
RAW="$GTDIR/raw_help"
OUT="$AN/aliases_long.csv"

mkdir -p "$RAW"/{gnu,git,ci}
echo "dataset,unit,short,long" > "$OUT"

# --- resolve the help command for a given dataset+unit, print help to stdout ---
get_help() {
    local ds="$1" unit="$2"
    case "$ds" in
        gnu)
            "$unit" --help 2>/dev/null
            ;;
        git)
            # man-page format; col -b flattens backspace bolding
            git "$unit" --help 2>/dev/null | col -b 2>/dev/null
            ;;
        ci)
            local prog="${unit%%_*}" sub="${unit#*_}"
            case "$prog" in
                docker)         docker "$sub" --help 2>/dev/null ;;
                docker-compose) docker compose $sub --help 2>/dev/null ;;
                npm)            npm "$sub" -h 2>/dev/null ;;
                pip)            pip "$sub" --help 2>/dev/null ;;
            esac
            ;;
    esac
}

# --- pull "short, long" (and npm "short|long") pairs out of help text ----------
extract_pairs() {
    # comma form: -x, --long      (gnu, git, docker, pip)
    grep -oP '(?<!\S)-[a-zA-Z0-9], --[a-z][a-z0-9-]+' || true
    # pipe form:  -x|--long  or  -ws|--workspaces   (npm)
    grep -oP '(?<!\S)-[a-zA-Z0-9]+\|--[a-z][a-z0-9-]+' || true
}

for ds in gnu git ci; do
    for f in "$GTDIR/$ds"/*.txt; do
        unit="$(basename "$f" .txt)"
        case "$unit" in help|npm_help) continue ;; esac

        help_text="$(get_help "$ds" "$unit")"
        [ -z "$help_text" ] && continue
        printf '%s\n' "$help_text" > "$RAW/$ds/$unit.txt"

        # collect this unit's legal options for the consistency filter
        legal="$(grep -E '^-' "$f" | sort -u)"

        printf '%s\n' "$help_text" | extract_pairs | sort -u | while read -r pair; do
            # normalise separator: ", " or "|"  ->  space
            short="${pair%%[,|]*}"
            long="${pair##*[ |]}"
            # keep only if BOTH forms are in the ground-truth list for this unit
            if grep -qxF -- "$short" <<<"$legal" && grep -qxF -- "$long" <<<"$legal"; then
                echo "$ds,$unit,$short,$long"
            fi
        done >> "$OUT"
    done
done

echo "Wrote $OUT"
echo "Alias pairs found per dataset:"
tail -n +2 "$OUT" | cut -d, -f1 | sort | uniq -c
echo "Sample (gnu cat / ls):"
grep -E '^gnu,(cat|ls),' "$OUT" | head -12

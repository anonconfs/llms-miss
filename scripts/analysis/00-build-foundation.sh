#!/usr/bin/env bash
# Build the canonical long table every downstream step reads: one row per option
# used in one invocation -> dataset,population,file,unit,option.
#   dataset     gnu | git | ci
#   population  human | llm  (gnu also has kernel = Linux-kernel experts)
#   unit        the analysed program (gnu tool, git subcommand, ci program_sub)
# An option-less invocation still yields one row with option="", so we can count
# both invocations and options from the same table. Also emits the ground-truth
# long table (dataset,unit,option) from data/groundtruth/.
# Out: results/analysis/{invocations_long,groundtruth_long}.csv
#
# The options field is the only multi-token field and never contains a comma
# (tokens are space-joined), so a plain comma split is exact.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd "$HERE/../.." && pwd)"

OUT_DIR="$BASE/results/analysis"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/invocations_long.csv"

echo "dataset,population,file,unit,option" > "$OUT"

# --- helper: split a space-separated option string into one row per option ----
# Reads CSV lines "dataset,population,file,unit,<options>" on stdin where the
# options field is already unquoted. Emits one output row per option token,
# or a single empty-option row when there were no options.
# Each token is sanitized first: shell punctuation that the miners carried
# over from embedded scripts (trailing quotes, backticks, brackets, commas)
# and any =value suffix are stripped, and tokens that are not dash-led after
# cleaning are dropped. This removes mining artifacts like --continue' or
# --porcelain` without touching genuine option spellings.
emit_rows() {
    awk -F'\t' '{
        n = split($5, opts, " ")
        kept = 0
        for (i = 1; i <= n; i++) {
            o = opts[i]
            gsub(/^["'"'"'`]+/, "", o)            # leading quote noise
            sub(/=.*$/, "", o)                    # =value suffix
            gsub(/["'"'"'`\\);:,.\]}]+$/, "", o)  # trailing shell punctuation
            if (o ~ /^-/) {
                print $1","$2","$3","$4","o
                kept++
            }
        }
        if (kept == 0) print $1","$2","$3","$4","
    }'
}

# --- GNU -----------------------------------------------------------------------
# Source: results/gnu/{human,llm}_invocations.csv  (general OSS humans + LLMs)
#         results/gnu/coreutils_invocations.csv     (Linux-kernel = EXPERT humans)
#   columns: file, tool, "options", option_count
# We carry three GNU populations so the study can contrast an expert human
# population (kernel) against a general human population (oss) and the model
# population (llm). git/ci have only human and llm.
gnu_emit() { # $1=source csv  $2=population label
    tail -n +2 "$1" | awk -F',' -v pop="$2" '{
        file=$1; tool=$2
        opt=$3; gsub(/^"|"$/, "", opt)   # strip surrounding quotes
        printf "gnu\t%s\t%s\t%s\t%s\n", pop, file, tool, opt
    }' | emit_rows >> "$OUT"
}
gnu_emit "$BASE/results/gnu/human_invocations.csv"     human
gnu_emit "$BASE/results/gnu/llm_invocations.csv"       llm
gnu_emit "$BASE/results/gnu/coreutils_invocations.csv" kernel

# --- GIT -----------------------------------------------------------------------
# Source: results/git/git_invocations_raw.csv
#   columns: group, source_file, line_number, subcommand, "options_all", ...
# unit = subcommand; we use options_all (every option seen, valid or not).
tail -n +2 "$BASE/results/git/git_invocations_raw.csv" | awk -F',' '{
    pop=$1; file=$2; scmd=$4
    opt=$5; gsub(/^"|"$/, "", opt)
    printf "git\t%s\t%s\t%s\t%s\n", pop, file, scmd, opt
}' | emit_rows >> "$OUT"

# --- CI ------------------------------------------------------------------------
# Source: results/ci/{human,llm}_ci_invocations.csv
#   columns: file, program, subcommand, options, option_count   (options unquoted)
# unit = program_subcommand to match ground-truth file names.
for pop in human llm; do
    src="$BASE/results/ci/${pop}_ci_invocations.csv"
    tail -n +2 "$src" | awk -F',' -v pop="$pop" '{
        file=$1; prog=$2; scmd=$3
        opt=$4; gsub(/^"|"$/, "", opt)
        unit = (scmd == "" ? prog : prog "_" scmd)
        printf "ci\t%s\t%s\t%s\t%s\n", pop, file, unit, opt
    }' | emit_rows >> "$OUT"
done

# =============================================================================
# Ground-truth long table: every option that each analysed unit *can* take.
#   dataset, unit, option
# Source: data/groundtruth/{gnu,git,ci}/<unit>.txt  (one option per line)
# We skip a couple of non-unit helper files (help.txt dumps) that are not tools.
# =============================================================================
GT_OUT="$OUT_DIR/groundtruth_long.csv"
echo "dataset,unit,option" > "$GT_OUT"

for ds in gnu git ci; do
    for f in "$BASE/data/groundtruth/$ds"/*.txt; do
        unit="$(basename "$f" .txt)"
        # Skip raw help dumps that are not per-unit option lists.
        case "$unit" in
            help|npm_help) continue ;;
        esac
        # Keep only real option lines (start with a dash); ignore blanks/noise.
        grep -E '^-' "$f" | sort -u | while IFS= read -r opt; do
            echo "$ds,$unit,$opt"
        done || true
    done
done >> "$GT_OUT"

# --- report --------------------------------------------------------------------
echo "Wrote $OUT"
echo "Rows per dataset/population (option-level, incl. empty-option rows):"
tail -n +2 "$OUT" | awk -F',' '{print $1, $2}' | sort | uniq -c
echo "Wrote $GT_OUT"
echo "Ground-truth units / options per dataset:"
tail -n +2 "$GT_OUT" | awk -F',' '{u[$1"|"$2]=1; o[$1]++} END{for(k in u){split(k,a,"|"); units[a[1]]++} for(d in units) printf "  %s: %d units, %d options\n", d, units[d], o[d]}'

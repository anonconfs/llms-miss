#!/usr/bin/env bash
# Extract CI-tool invocations (docker, docker-compose, npm, pip) from human- vs
# LLM-written workflow YAML, matched against the CI option ground truth.
# In:  corpus/ci/{human,llm}/, data/groundtruth/ci/
# Out: results/ci/{human,llm}_ci_invocations.csv  (+ usage, comparison & summary byproducts)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUMAN_DIR="$SCRIPT_DIR/../corpus/ci/human"
LLM_DIR="$SCRIPT_DIR/../corpus/ci/llm"
GT_DIR="$SCRIPT_DIR/../data/groundtruth/ci"
RESULTS_DIR="$SCRIPT_DIR/../results/ci"

mkdir -p "$RESULTS_DIR"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# 1. Build tool→subcommand list from ground truth

log "Building tool list from groundtruth..."

# Ground truth files are named like: docker_run.txt, npm_install.txt, pip_install.txt
# We extract the program family + subcommand
declare -A GT_OPTIONS   # gt_options[docker_run] = count of options

while IFS= read -r gtfile; do
    tool_subcmd=$(basename "$gtfile" .txt)
    opt_count=$(wc -l < "$GT_DIR/$gtfile")
    GT_OPTIONS["$tool_subcmd"]=$opt_count
done < <(ls "$GT_DIR" | grep '\.txt$')

log "Ground truth entries: ${#GT_OPTIONS[@]}"

# 2. Extract CI command invocations from workflow files

extract_ci_commands() {
    local data_dir="$1" out_invocations="$2" out_usage="$3"

    echo "file,program,subcommand,options,option_count" > "$out_invocations"

    # Temp files for aggregation
    local tmp_agg
    tmp_agg=$(mktemp)

    find "$data_dir" -type f \( -name "*.yml" -o -name "*.yaml" \) | while IFS= read -r wf_file; do
        local fname
        fname=$(basename "$wf_file")

        # Extract all lines that invoke docker, docker-compose, npm, pip
        # In YAML workflows, commands appear in `run:` blocks
        grep -hE '^\s*(- )?(docker|docker-compose|docker compose|npm|pip3?|pip)\s' "$wf_file" 2>/dev/null | while IFS= read -r line; do
            # Clean the line
            line=$(echo "$line" | sed 's/^[[:space:]]*- //; s/^[[:space:]]*//')

            local program subcommand options

            if [[ "$line" =~ ^(docker[[:space:]]compose|docker-compose)[[:space:]]+([a-z-]+) ]]; then
                program="docker-compose"
                subcommand="${BASH_REMATCH[2]}"
                # Extract options (words starting with -)
                options=$(echo "$line" | grep -oP '(?<!\w)-{1,2}[a-z][a-z0-9-]*' | sort -u | tr '\n' ' ' | sed 's/ $//' || true)
            elif [[ "$line" =~ ^docker[[:space:]]+([a-z]+) ]]; then
                program="docker"
                subcommand="${BASH_REMATCH[1]}"
                options=$(echo "$line" | grep -oP '(?<!\w)-{1,2}[a-z][a-z0-9-]*' | sort -u | tr '\n' ' ' | sed 's/ $//' || true)
            elif [[ "$line" =~ ^npm[[:space:]]+([a-z-]+) ]]; then
                program="npm"
                subcommand="${BASH_REMATCH[1]}"
                options=$(echo "$line" | grep -oP '(?<!\w)-{1,2}[a-z][a-z0-9-]*' | sort -u | tr '\n' ' ' | sed 's/ $//' || true)
            elif [[ "$line" =~ ^pip3?[[:space:]]+([a-z]+) ]]; then
                program="pip"
                subcommand="${BASH_REMATCH[1]}"
                options=$(echo "$line" | grep -oP '(?<!\w)-{1,2}[a-z][a-z0-9-]*' | sort -u | tr '\n' ' ' | sed 's/ $//' || true)
            else
                continue
            fi

            local opt_count
            if [[ -z "$options" ]]; then
                opt_count=0
            else
                opt_count=$(echo "$options" | wc -w)
            fi

            echo "$fname,$program,$subcommand,$options,$opt_count" >> "$out_invocations"
        done || true
    done

# Aggregate into usage summary
    echo "program,subcommand,gt_key,total_options_available,distinct_options_used,coverage_pct,invocations,top_options" > "$out_usage"

    # Process invocations into per-tool-subcommand stats
    tail -n +2 "$out_invocations" | awk -F, '{
        key = $2 "_" $3
        invocations[key]++
        n = split($4, opts, " ")
        for (i = 1; i <= n; i++) {
            if (opts[i] != "") {
                used[key, opts[i]] = 1
                all_opts[key] = all_opts[key] " " opts[i]
            }
        }
    }
    END {
        for (key in invocations) {
            # Count distinct options
            distinct = 0
            opt_list = ""
            for (combo in used) {
                split(combo, parts, SUBSEP)
                if (parts[1] == key) {
                    distinct++
                    opt_list = opt_list " " parts[2]
                }
            }
            printf "%s,%d,%d,%s\n", key, invocations[key], distinct, opt_list
        }
    }' | sort -t, -k2 -nr | while IFS=, read -r gt_key invoc distinct opt_list; do
        local program subcommand
        program="${gt_key%%_*}"
        subcommand="${gt_key#*_}"

        # Look up ground truth
        local gt_total=0
        if [[ -f "$GT_DIR/${gt_key}.txt" ]]; then
            gt_total=$(wc -l < "$GT_DIR/${gt_key}.txt")
        fi

        local coverage=0
        if [[ $gt_total -gt 0 && $distinct -gt 0 ]]; then
            coverage=$(( distinct * 100 / gt_total ))
        fi

        # Top options (first 5)
        local top5
        top5=$(echo "$opt_list" | tr ' ' '\n' | sort | uniq -c | sort -rn | head -5 | awk '{printf "%s(%d) ", $2, $1}' | sed 's/ $//')

        echo "$program,$subcommand,$gt_key,$gt_total,$distinct,$coverage,$invoc,\"$top5\"" >> "$out_usage"
    done

    rm -f "$tmp_agg"
}

# 3. Run extraction on both datasets

log "Analysing HUMAN CI workflows..."
if [[ -d "$HUMAN_DIR" ]] && [[ $(find "$HUMAN_DIR" -type f \( -name "*.yml" -o -name "*.yaml" \) | wc -l) -gt 0 ]]; then
    extract_ci_commands "$HUMAN_DIR" \
        "$RESULTS_DIR/human_ci_invocations.csv" \
        "$RESULTS_DIR/human_ci_usage.csv"
    human_invoc=$(tail -n +2 "$RESULTS_DIR/human_ci_invocations.csv" | wc -l)
    log "  Human invocations: $human_invoc"
else
    log "  No human CI workflow data found in $HUMAN_DIR"
    human_invoc=0
fi

log "Analysing LLM CI workflows..."
if [[ -d "$LLM_DIR" ]] && [[ $(find "$LLM_DIR" -type f \( -name "*.yml" -o -name "*.yaml" \) | wc -l) -gt 0 ]]; then
    extract_ci_commands "$LLM_DIR" \
        "$RESULTS_DIR/llm_ci_invocations.csv" \
        "$RESULTS_DIR/llm_ci_usage.csv"
    llm_invoc=$(tail -n +2 "$RESULTS_DIR/llm_ci_invocations.csv" | wc -l)
    log "  LLM invocations: $llm_invoc"
else
    log "  No LLM CI workflow data found in $LLM_DIR"
    llm_invoc=0
fi

# 4. Produce comparison and coverage summary

log "Producing coverage summary..."

# Build the master coverage CSV
echo "program,subcommand,gt_key,total_options,human_distinct,human_coverage_pct,llm_distinct,llm_coverage_pct" \
    > "$RESULTS_DIR/ci_coverage_summary.csv"

for gtfile in "$GT_DIR"/*.txt; do
    gt_key=$(basename "$gtfile" .txt)
    total=$(wc -l < "$gtfile")
    [[ $total -eq 0 ]] && continue

    program="${gt_key%%_*}"
    # Handle docker-compose specially
    if [[ "$gt_key" == docker-compose_* ]]; then
        program="docker-compose"
        subcommand="${gt_key#docker-compose_}"
    else
        subcommand="${gt_key#*_}"
    fi

    # Count distinct options used by human
    human_distinct=0
    if [[ -f "$RESULTS_DIR/human_ci_invocations.csv" ]]; then
        human_distinct=$(tail -n +2 "$RESULTS_DIR/human_ci_invocations.csv" | \
            awk -F, -v prog="$program" -v subc="$subcommand" \
            '$2 == prog && $3 == subc { n=split($4,a," "); for(i=1;i<=n;i++) if(a[i]!="") o[a[i]]=1 }
             END { print length(o) }')
    fi

    # Count distinct options used by LLM
    llm_distinct=0
    if [[ -f "$RESULTS_DIR/llm_ci_invocations.csv" ]]; then
        llm_distinct=$(tail -n +2 "$RESULTS_DIR/llm_ci_invocations.csv" | \
            awk -F, -v prog="$program" -v subc="$subcommand" \
            '$2 == prog && $3 == subc { n=split($4,a," "); for(i=1;i<=n;i++) if(a[i]!="") o[a[i]]=1 }
             END { print length(o) }')
    fi

    human_cov=$(( human_distinct * 100 / total ))
    llm_cov=$(( llm_distinct * 100 / total ))

    echo "$program,$subcommand,$gt_key,$total,$human_distinct,$human_cov,$llm_distinct,$llm_cov" \
        >> "$RESULTS_DIR/ci_coverage_summary.csv"
done

log ""
log "----------------------------------------"
log " CI WORKFLOW ANALYSIS COMPLETE"
log "----------------------------------------"
log " Results: $RESULTS_DIR/"
log "   human_ci_invocations.csv"
log "   human_ci_usage.csv"
log "   llm_ci_invocations.csv"
log "   llm_ci_usage.csv"
log "   ci_coverage_summary.csv"
log ""
log " Next step: open notebooks/ci_configuration_space.ipynb"

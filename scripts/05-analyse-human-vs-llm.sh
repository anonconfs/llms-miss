#!/usr/bin/env bash
# Extract coreutils invocations from human- vs LLM-written scripts (same logic
# as step 03), matched against the GNU option ground truth.
# In:  corpus/gnu/{human,llm}/, data/groundtruth/gnu/
# Out: results/{human,llm}_invocations.csv  (+ usage, comparison & co-occurrence byproducts)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUMAN_DIR="$SCRIPT_DIR/../corpus/gnu/human"
LLM_DIR="$SCRIPT_DIR/../corpus/gnu/llm"
GT_DIR="$SCRIPT_DIR/../data/groundtruth/gnu"
RESULTS_DIR="$SCRIPT_DIR/../results"

mkdir -p "$RESULTS_DIR"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# 1. Build tool list from ground truth

TOOL_LIST=$(mktemp)
ls "$GT_DIR" | sed 's/\.txt$//' | sort > "$TOOL_LIST"
tool_count=$(wc -l < "$TOOL_LIST")
log "Ground truth tools: $tool_count"

# 2. Shared awk extraction function

extract_invocations() {
    local data_dir="$1" out_csv="$2"
    echo "file,tool,options,option_count" > "$out_csv"

    gawk -v toolfile="$TOOL_LIST" -v gt_dir="$GT_DIR" -v SQ="'" '
    BEGIN {
        while ((getline t < toolfile) > 0) { tools[t] = 1; tool_arr[++nt] = t }
        close(toolfile)
        for (ti = 1; ti <= nt; ti++) {
            t = tool_arr[ti]
            gtf = gt_dir "/" t ".txt"
            while ((getline opt < gtf) > 0) {
                gt_all[t, opt] = 1
                if (match(opt, /^-[A-Za-z0-9]$/) > 0)
                    gt_short[t, substr(opt, 2, 1)] = 1
            }
            close(gtf)
        }
    }

    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }

    {
        _fname = FILENAME
        sub(/.*\//, "", _fname)
        process_line($0, _fname)
    }

    function extract_subshells(line, fname,    i, c, c2, depth, start, content, sq2) {
        sq2 = 0
        for (i = 1; i <= length(line); i++) {
            c = substr(line, i, 1)
            if (c == SQ) { sq2 = !sq2; continue }
            if (sq2) continue
            c2 = substr(line, i, 2)
            if (c2 == "$(") {
                depth = 1; start = i + 2; i += 2
                while (i <= length(line) && depth > 0) {
                    c = substr(line, i, 1)
                    if (c == "(") depth++
                    else if (c == ")") depth--
                    if (depth > 0) i++
                }
                if (depth == 0) {
                    content = substr(line, start, i - start)
                    process_line(content, fname)
                }
            } else if (c == "`") {
                start = i + 1; i++
                while (i <= length(line) && substr(line, i, 1) != "`") i++
                if (i <= length(line)) {
                    content = substr(line, start, i - start)
                    process_line(content, fname)
                }
            }
        }
    }

    function neutralize_quotes(line,    result, i, c, state, len) {
        result = ""; state = 0; len = length(line)
        for (i = 1; i <= len; i++) {
            c = substr(line, i, 1)
            if (state == 0) {
                if (c == SQ) { state = 1; result = result " " }
                else if (c == "\"") { state = 2; result = result " " }
                else if (c == "\\") { result = result " "; i++ }
                else result = result c
            } else if (state == 1) {
                if (c == SQ) { state = 0; result = result " " }
                else result = result " "
            } else if (state == 2) {
                if (c == "\"") { state = 0; result = result " " }
                else if (c == "\\") { result = result " "; i++ }
                else result = result " "
            }
        }
        return result
    }

    function process_line(line, fname,    clean, n, i, cmds) {
        extract_subshells(line, fname)
        clean = neutralize_quotes(line)
        gsub(/\$\([^)]*\)/, " ", clean)
        gsub(/`[^`]*`/, " ", clean)
        gsub(/\|\|/, "\x01", clean)
        gsub(/&&/, "\x01", clean)
        gsub(/\|/, "\x01", clean)
        gsub(/;/, "\x01", clean)
        n = split(clean, cmds, "\x01")
        for (i = 1; i <= n; i++)
            process_command(cmds[i], fname)
    }

    function process_command(cmd, fname,    nw, words, cmdword, w, word, body,
                             opts, optcount, ci, ch, all_gt, first_ch) {
        sub(/^[[:space:]]+/, "", cmd)
        while (cmd ~ /^(sudo|env|nice|nohup|command|exec|builtin|xargs)[[:space:]]/)
            sub(/^(sudo|env|nice|nohup|command|exec|builtin|xargs)[[:space:]]+/, "", cmd)
        sub(/^\$\(/, "", cmd)
        sub(/^`/, "", cmd)

        nw = split(cmd, words, /[[:space:]]+/)
        if (nw == 0) return
        cmdword = words[1]
        sub(/.*\//, "", cmdword)

        if (!(cmdword in tools)) return

        opts = ""
        optcount = 0
        for (w = 2; w <= nw; w++) {
            word = words[w]
            if (word == "--") break
            if (word !~ /^-/) continue
            if (word ~ /^-[0-9]+$/) continue
            if (word == "-") continue

            # Artifact detection: reject tokens with shell metacharacters
            if (word ~ /[\$\(\)\{\}\[\]\\`]/) continue
            if (index(word, SQ) > 0) continue

            # Strip trailing garbage chars
            sub(/[)";,]+$/, "", word)
            if (word == "" || word == "-" || word ~ /^---/) continue

            # Skip shell test operators
            if (word ~ /^-(eq|ne|gt|lt|ge|le)$/) break

            # Must look like an option
            if (word !~ /^-[a-zA-Z]/ && word !~ /^--[a-z]/) continue

            # Long option: strip =value, count 1
            if (word ~ /^--/) {
                sub(/=.*$/, "", word)
                if (opts != "") opts = opts " "
                opts = opts word
                optcount++
                continue
            }

            # Short option: classify and possibly expand
            body = substr(word, 2)

            # Case A: all-alpha body, length > 1
            if (length(body) > 1 && body ~ /^[A-Za-z]+$/) {
                all_gt = 1
                for (ci = 1; ci <= length(body); ci++) {
                    ch = substr(body, ci, 1)
                    if (!((cmdword SUBSEP ch) in gt_short)) { all_gt = 0; break }
                }
                if (all_gt) {
                    for (ci = 1; ci <= length(body); ci++) {
                        if (opts != "") opts = opts " "
                        opts = opts "-" substr(body, ci, 1)
                        optcount++
                    }
                    continue
                }
                first_ch = substr(body, 1, 1)
                if ((cmdword SUBSEP first_ch) in gt_short) {
                    if (opts != "") opts = opts " "
                    opts = opts "-" first_ch
                    optcount++
                    continue
                }
                if (opts != "") opts = opts " "
                opts = opts word
                optcount++
                continue
            }

            # Case B: body has non-alpha chars (e.g., -n1, -d:, -f2-)
            if (length(body) > 1) {
                first_ch = substr(body, 1, 1)
                if (first_ch ~ /[A-Za-z]/ && (cmdword SUBSEP first_ch) in gt_short) {
                    if (opts != "") opts = opts " "
                    opts = opts "-" first_ch
                    optcount++
                    continue
                }
                if (opts != "") opts = opts " "
                opts = opts word
                optcount++
                continue
            }

            # Case C: single-char short option
            if (opts != "") opts = opts " "
            opts = opts word
            optcount++
        }

        gsub(/"/, "\"\"", opts)
        printf "%s,%s,\"%s\",%d\n", fname, cmdword, opts, optcount
    }
    ' "$data_dir"/* >> "$out_csv"

    echo $(($(wc -l < "$out_csv") - 1))
}

# 3. Compute per-tool summary from invocations CSV

compute_usage() {
    local inv_csv="$1" usage_csv="$2"
    echo "tool,total_invocations,files_using,distinct_options,min_opts_per_call,max_opts_per_call,avg_opts_per_call,top_options" > "$usage_csv"

    awk -F',' 'NR == 1 { next }
    {
        tool = $2
        file = $1
        optcount = $NF + 0

        count[tool]++
        if (!seen[tool, file]++) file_count[tool]++
        opts_sum[tool] += optcount
        if (!(tool in min_opts) || optcount < min_opts[tool]) min_opts[tool] = optcount
        if (optcount > max_opts[tool]) max_opts[tool] = optcount

        # Parse options from field 3
        line = $0
        idx1 = index(line, ","); rest = substr(line, idx1+1)
        idx2 = index(rest, ","); rest2 = substr(rest, idx2+1)
        last_comma = 0
        for (p = length(rest2); p >= 1; p--)
            if (substr(rest2, p, 1) == ",") { last_comma = p; break }
        if (last_comma > 0) opt_field = substr(rest2, 1, last_comma - 1)
        else opt_field = rest2
        gsub(/^"|"$/, "", opt_field)
        nn = split(opt_field, olist, " ")
        for (j = 1; j <= nn; j++)
            if (olist[j] != "") { opt_freq[tool, olist[j]]++; distinct[tool, olist[j]] = 1 }
    }
    END {
        for (tool in count) {
            nopts = 0
            for (key in distinct) { split(key, kp, SUBSEP); if (kp[1] == tool) nopts++ }
            avg = (count[tool] > 0) ? opts_sum[tool] / count[tool] : 0

            delete top_o; delete top_c
            for (key in opt_freq) {
                split(key, kp, SUBSEP)
                if (kp[1] != tool) continue
                c = opt_freq[key]
                for (k = 1; k <= 5; k++) {
                    if (c > (top_c[k]+0)) {
                        for (m = 5; m > k; m--) { top_o[m] = top_o[m-1]; top_c[m] = top_c[m-1] }
                        top_o[k] = kp[2]; top_c[k] = c
                        break
                    }
                }
            }
            top_str = ""
            for (k = 1; k <= 5; k++) {
                if (top_o[k] != "") {
                    if (top_str != "") top_str = top_str " "
                    top_str = top_str top_o[k] "(" top_c[k] ")"
                }
            }
            printf "%s,%d,%d,%d,%d,%d,%.1f,\"%s\"\n",
                tool, count[tool], file_count[tool], nopts,
                min_opts[tool], max_opts[tool], avg, top_str
        }
    }' "$inv_csv" | sort -t',' -k2 -rn >> "$usage_csv"
}

# 4. Compute co-occurrence

compute_cooccurrence() {
    local inv_csv="$1" cooc_csv="$2"
    awk -F',' 'NR > 1 { files[$1][$2] = 1 }
    END {
        print "tool_a,tool_b,shared_files"
        for (f in files) {
            n = 0
            for (t in files[f]) tarr[++n] = t
            for (i = 1; i <= n; i++)
                for (j = i+1; j <= n; j++)
                    if (tarr[i] > tarr[j]) { tmp = tarr[i]; tarr[i] = tarr[j]; tarr[j] = tmp }
            for (i = 1; i <= n; i++)
                for (j = i+1; j <= n; j++)
                    pairs[tarr[i], tarr[j]]++
            delete tarr
        }
        for (p in pairs) {
            split(p, ab, SUBSEP)
            printf "%s,%s,%d\n", ab[1], ab[2], pairs[p]
        }
    }' "$inv_csv" | (head -1; tail -n +2 | sort -t',' -k3 -rn) > "$cooc_csv"
}

# ANALYSE HUMAN SCRIPTS

log "=== Analysing HUMAN scripts ==="
human_scripts=$(find "$HUMAN_DIR" -type f | wc -l)
log "  Files: $human_scripts"

human_inv="$RESULTS_DIR/human_invocations.csv"
human_total=$(extract_invocations "$HUMAN_DIR" "$human_inv")
log "  Invocations: $human_total"

human_usage="$RESULTS_DIR/human_usage.csv"
compute_usage "$human_inv" "$human_usage"
human_tools=$(($(wc -l < "$human_usage") - 1))
log "  Distinct tools used: $human_tools"

human_cooc="$RESULTS_DIR/human_cooccurrence.csv"
compute_cooccurrence "$human_inv" "$human_cooc"
log "  Co-occurrence pairs: $(($(wc -l < "$human_cooc") - 1))"

# ANALYSE LLM SCRIPTS

log ""
log "=== Analysing LLM scripts ==="
llm_scripts=$(find "$LLM_DIR" -type f | wc -l)
log "  Files: $llm_scripts"

llm_inv="$RESULTS_DIR/llm_invocations.csv"
llm_total=$(extract_invocations "$LLM_DIR" "$llm_inv")
log "  Invocations: $llm_total"

llm_usage="$RESULTS_DIR/llm_usage.csv"
compute_usage "$llm_inv" "$llm_usage"
llm_tools=$(($(wc -l < "$llm_usage") - 1))
log "  Distinct tools used: $llm_tools"

llm_cooc="$RESULTS_DIR/llm_cooccurrence.csv"
compute_cooccurrence "$llm_inv" "$llm_cooc"
log "  Co-occurrence pairs: $(($(wc -l < "$llm_cooc") - 1))"

# COMPARISON TABLE

log ""
log "=== Building comparison table ==="

COMP_CSV="$RESULTS_DIR/human_vs_llm_comparison.csv"
echo "tool,human_invocations,human_files,human_distinct_opts,human_avg_opts,llm_invocations,llm_files,llm_distinct_opts,llm_avg_opts,ratio_invocations" > "$COMP_CSV"

# Join human and LLM usage by tool name
awk -F',' '
    FILENAME ~ /human_usage/ && NR > 1 {
        h_inv[$1] = $2; h_files[$1] = $3; h_opts[$1] = $4; h_avg[$1] = $7
    }
    FILENAME ~ /llm_usage/ && FNR > 1 {
        l_inv[$1] = $2; l_files[$1] = $3; l_opts[$1] = $4; l_avg[$1] = $7
    }
    END {
        for (t in h_inv) all[t] = 1
        for (t in l_inv) all[t] = 1
        for (t in all) {
            hi = (t in h_inv) ? h_inv[t] : 0
            hf = (t in h_files) ? h_files[t] : 0
            ho = (t in h_opts) ? h_opts[t] : 0
            ha = (t in h_avg) ? h_avg[t] : 0
            li = (t in l_inv) ? l_inv[t] : 0
            lf = (t in l_files) ? l_files[t] : 0
            lo = (t in l_opts) ? l_opts[t] : 0
            la = (t in l_avg) ? l_avg[t] : 0
            ratio = (hi > 0) ? li / hi : (li > 0 ? 999 : 0)
            printf "%s,%d,%d,%d,%.1f,%d,%d,%d,%.1f,%.2f\n",
                t, hi, hf, ho, ha, li, lf, lo, la, ratio
        }
    }
' "$human_usage" "$llm_usage" | sort -t',' -k2 -rn >> "$COMP_CSV"

comp_tools=$(($(wc -l < "$COMP_CSV") - 1))
log "  Tools in comparison: $comp_tools"

# Cleanup

rm -f "$TOOL_LIST"

# Summary report

log ""
log "----------------------------------------"
log "ANALYSIS COMPLETE"
log "----------------------------------------"
log ""
log "                     HUMAN        LLM"
log "  Scripts:           $human_scripts          $llm_scripts"
log "  Total invocations: $human_total       $llm_total"
log "  Tools used:        $human_tools           $llm_tools"
log ""
log "Output files:"
log "  $human_inv"
log "  $human_usage"
log "  $human_cooc"
log "  $llm_inv"
log "  $llm_usage"
log "  $llm_cooc"
log "  $COMP_CSV"
log ""
log "Top 10 tools — HUMAN:"
tail -n +2 "$human_usage" | head -10 | \
    awk -F',' '{printf "  %-12s %5d calls in %3d files  (avg %.1f opts)\n", $1, $2, $3, $7}'
log ""
log "Top 10 tools — LLM:"
tail -n +2 "$llm_usage" | head -10 | \
    awk -F',' '{printf "  %-12s %5d calls in %3d files  (avg %.1f opts)\n", $1, $2, $3, $7}'
log ""
log "Biggest human vs LLM differences (by ratio):"
tail -n +2 "$COMP_CSV" | awk -F',' '$2 > 5 || $6 > 5' | sort -t',' -k10 -rn | head -5 | \
    awk -F',' '{printf "  %-12s human=%4d  llm=%4d  ratio=%.1f×\n", $1, $2, $6, $10}'
log ""
tail -n +2 "$COMP_CSV" | awk -F',' '$2 > 5 || $6 > 5' | sort -t',' -k10 -n | head -5 | \
    awk -F',' '{printf "  %-12s human=%4d  llm=%4d  ratio=%.2f×\n", $1, $2, $6, $10}'

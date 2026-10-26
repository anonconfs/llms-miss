#!/usr/bin/env bash
# Extract coreutils invocations from the Linux-kernel shell scripts (the expert
# human population), matched against the GNU option ground truth.
# In:  corpus/gnu/linux/, data/groundtruth/gnu/
# Out: results/coreutils_invocations.csv  (+ per-tool usage & co-occurrence byproducts)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../corpus/gnu/linux"
GT_DIR="$SCRIPT_DIR/../data/groundtruth/gnu"
RESULTS_DIR="$SCRIPT_DIR/../results"

mkdir -p "$RESULTS_DIR"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# 1. Build tool list

TOOL_LIST=$(mktemp)
ls "$GT_DIR" | sed 's/\.txt$//' | sort > "$TOOL_LIST"
tool_count=$(wc -l < "$TOOL_LIST")
script_count=$(find "$DATA_DIR" -name "*.sh" | wc -l)
log "Ground truth tools: $tool_count"
log "Scripts to analyse: $script_count"

# 2. Extract all invocations (improved awk with quote-awareness)

INVOCATIONS_CSV="$RESULTS_DIR/coreutils_invocations.csv"
log "Extracting invocations (improved awk)..."

echo "file,tool,options,option_count" > "$INVOCATIONS_CSV"

gawk -v toolfile="$TOOL_LIST" -v gt_dir="$GT_DIR" -v SQ="'" '
BEGIN {
    # Load tool names
    while ((getline t < toolfile) > 0) { tools[t] = 1; tool_arr[++nt] = t }
    close(toolfile)

    # Load GT: short options and all options per tool
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

# Skip comments and blank lines
/^[[:space:]]*#/ { next }
/^[[:space:]]*$/ { next }

{
    _fname = FILENAME
    sub(/.*\//, "", _fname)
    process_line($0, _fname)
}

# Extract $(...) and `...` subshells, respecting single quotes
function extract_subshells(line, fname,    i, c, c2, depth, start, content, sq) {
    sq = 0
    for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (c == SQ) { sq = !sq; continue }
        if (sq) continue

        c2 = substr(line, i, 2)
        if (c2 == "$(") {
            depth = 1
            start = i + 2
            i += 2
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
            if (sq) continue
            start = i + 1
            i++
            while (i <= length(line) && substr(line, i, 1) != "`") i++
            if (i <= length(line)) {
                content = substr(line, start, i - start)
                process_line(content, fname)
            }
        }
    }
}

# Neutralize all quoted content (replace with spaces)
function neutralize_quotes(line,    result, i, c, state, len) {
    result = ""
    state = 0  # 0=normal, 1=single-quote, 2=double-quote
    len = length(line)
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

# Main line processing
function process_line(line, fname,    clean, n, i, cmds) {
    # Phase 1: Extract subshell invocations (recursive)
    extract_subshells(line, fname)

    # Phase 2: Neutralize quoted content for main command processing
    clean = neutralize_quotes(line)

    # Also neutralize any remaining $(...) / backtick content
    gsub(/\$\([^)]*\)/, " ", clean)
    gsub(/`[^`]*`/, " ", clean)

    # Phase 3: Split on command separators
    gsub(/\|\|/, "\x01", clean)
    gsub(/&&/, "\x01", clean)
    gsub(/\|/, "\x01", clean)
    gsub(/;/, "\x01", clean)
    n = split(clean, cmds, "\x01")

    for (i = 1; i <= n; i++)
        process_command(cmds[i], fname)
}

# Process a single command segment
function process_command(cmd, fname,    nw, words, cmdword, w, word, body,
                         opts, optcount, ci, ch, all_gt, first_ch) {
    sub(/^[[:space:]]+/, "", cmd)

    # Strip common wrappers/prefixes
    while (cmd ~ /^(sudo|env|nice|nohup|command|exec|builtin|xargs)[[:space:]]/)
        sub(/^(sudo|env|nice|nohup|command|exec|builtin|xargs)[[:space:]]+/, "", cmd)
    sub(/^\$\(/, "", cmd)
    sub(/^`/, "", cmd)

    nw = split(cmd, words, /[[:space:]]+/)
    if (nw == 0) return
    cmdword = words[1]
    sub(/.*\//, "", cmdword)  # strip path (/usr/bin/sort → sort)

    if (!(cmdword in tools)) return

    opts = ""
    optcount = 0
    for (w = 2; w <= nw; w++) {
        word = words[w]
        if (word == "--") break
        if (word !~ /^-/) continue
        if (word ~ /^-[0-9]+$/) continue
        if (word == "-") continue

        # ── Artifact detection: reject tokens with shell metacharacters ──
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

        # Case A: all-alpha body, length > 1 → possible combined options
        if (length(body) > 1 && body ~ /^[A-Za-z]+$/) {
            # Check if ALL chars are GT short options for this tool
            all_gt = 1
            for (ci = 1; ci <= length(body); ci++) {
                ch = substr(body, ci, 1)
                if (!((cmdword SUBSEP ch) in gt_short)) { all_gt = 0; break }
            }
            if (all_gt) {
                # Expand combined options: -rf → -r -f
                for (ci = 1; ci <= length(body); ci++) {
                    if (opts != "") opts = opts " "
                    opts = opts "-" substr(body, ci, 1)
                    optcount++
                }
                continue
            }
            # First char is a known GT short → option with value (e.g., -ibackup)
            first_ch = substr(body, 1, 1)
            if ((cmdword SUBSEP first_ch) in gt_short) {
                if (opts != "") opts = opts " "
                opts = opts "-" first_ch
                optcount++
                continue
            }
            # Unknown multi-char option (e.g., find -name) → store as-is
            if (opts != "") opts = opts " "
            opts = opts word
            optcount++
            continue
        }

        # Case B: body has non-alpha chars (e.g., -n1, -d:, -f2-)
        if (length(body) > 1) {
            first_ch = substr(body, 1, 1)
            if (first_ch ~ /[A-Za-z]/ && (cmdword SUBSEP first_ch) in gt_short) {
                # Known short option with attached value
                if (opts != "") opts = opts " "
                opts = opts "-" first_ch
                optcount++
                continue
            }
            # Unknown option with value → store as-is
            if (opts != "") opts = opts " "
            opts = opts word
            optcount++
            continue
        }

        # Case C: single-char short option (-v, -r, etc.)
        if (opts != "") opts = opts " "
        opts = opts word
        optcount++
    }

    gsub(/"/, "\"\"", opts)
    printf "%s,%s,\"%s\",%d\n", fname, cmdword, opts, optcount
}
' "$DATA_DIR"/*.sh >> "$INVOCATIONS_CSV"

total_invocations=$(($(wc -l < "$INVOCATIONS_CSV") - 1))
log "Total invocations: $total_invocations"

# 3. Per-tool summary

USAGE_CSV="$RESULTS_DIR/coreutils_usage.csv"
log "Computing per-tool statistics..."

echo "tool,total_invocations,files_using,distinct_options,min_opts_per_call,max_opts_per_call,avg_opts_per_call,top_options" > "$USAGE_CSV"

awk -F',' 'NR == 1 { next }
{
    tool = $2
    file = $1
    optcount = $NF + 0

    count[tool]++
    files[tool, file] = 1
    if (!(file in file_seen[tool])) { file_count[tool]++; file_seen[tool][file] = 1 }
    opts_sum[tool] += optcount
    if (!(tool in min_opts) || optcount < min_opts[tool]) min_opts[tool] = optcount
    if (optcount > max_opts[tool]) max_opts[tool] = optcount

    # Parse options from column 3 (may contain commas inside quotes)
    # Rebuild options field: everything between first and last quote in field 3
    line = $0
    # Find options: between 2nd comma and last comma
    idx1 = index(line, ",")
    rest = substr(line, idx1+1)
    idx2 = index(rest, ",")
    rest2 = substr(rest, idx2+1)
    # rest2 = "\"opt1 opt2\"",N  — strip the trailing ,N
    last_comma = 0
    for (p = length(rest2); p >= 1; p--) {
        if (substr(rest2, p, 1) == ",") { last_comma = p; break }
    }
    if (last_comma > 0) opt_field = substr(rest2, 1, last_comma - 1)
    else opt_field = rest2
    gsub(/^"|"$/, "", opt_field)

    nn = split(opt_field, olist, " ")
    for (j = 1; j <= nn; j++) {
        if (olist[j] != "") opt_freq[tool, olist[j]]++
    }
    # Track distinct options
    for (j = 1; j <= nn; j++) {
        if (olist[j] != "") distinct[tool, olist[j]] = 1
    }
}
END {
    for (tool in count) {
        # Count distinct options
        nopts = 0
        for (key in distinct) {
            split(key, kp, SUBSEP)
            if (kp[1] == tool) nopts++
        }
        avg = (count[tool] > 0) ? opts_sum[tool] / count[tool] : 0

        # Top 5 options by frequency
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
}' "$INVOCATIONS_CSV" | sort -t',' -k2 -rn >> "$USAGE_CSV"

used_tools=$(($(wc -l < "$USAGE_CSV") - 1))
log "Tools actually used: $used_tools / $tool_count"

# 4. Co-occurrence (edge list, sorted by strength)

COOC_CSV="$RESULTS_DIR/coreutils_cooccurrence.csv"
log "Computing co-occurrence..."

# Build per-file tool sets, then count pairs
awk -F',' 'NR > 1 { files[$1][$2] = 1 }
END {
    print "tool_a,tool_b,shared_files"
    for (f in files) {
        # Get tools in this file
        n = 0
        for (t in files[f]) tarr[++n] = t
        # Sort for consistent pairs
        for (i = 1; i <= n; i++)
            for (j = i+1; j <= n; j++)
                if (tarr[i] > tarr[j]) { tmp = tarr[i]; tarr[i] = tarr[j]; tarr[j] = tmp }
        # Count all pairs
        for (i = 1; i <= n; i++)
            for (j = i+1; j <= n; j++)
                pairs[tarr[i], tarr[j]]++
        delete tarr
    }
    for (p in pairs) {
        split(p, ab, SUBSEP)
        printf "%s,%s,%d\n", ab[1], ab[2], pairs[p]
    }
}' "$INVOCATIONS_CSV" | (head -1; tail -n +2 | sort -t',' -k3 -rn) > "$COOC_CSV"

cooc_pairs=$(($(wc -l < "$COOC_CSV") - 1))
log "Co-occurrence pairs: $cooc_pairs"

# 5. Summary

rm -f "$TOOL_LIST"

log ""
log "------------------------------------"
log "ANALYSIS COMPLETE"
log "------------------------------------"
log ""
log "Output:"
log "  $INVOCATIONS_CSV  ($total_invocations rows)"
log "  $USAGE_CSV  ($used_tools tools)"
log "  $COOC_CSV  ($cooc_pairs pairs)"
log ""
log "Top 15 most-used coreutils in Linux kernel scripts:"
tail -n +2 "$USAGE_CSV" | head -15 | \
    awk -F',' '{printf "  %-12s %5d calls in %4d files  (opts: %d–%d, avg %.1f)\n", $1, $2, $3, $5, $6, $7}'
log ""
log "Top 10 co-occurring pairs:"
tail -n +2 "$COOC_CSV" | head -10 | \
    awk -F',' '{printf "  %-10s + %-10s  in %4d files\n", $1, $2, $3}'

#!/usr/bin/env bash
# 08-pilot-agent-trajectories.sh
#
# Pilot for "Dataset D": commands that LLM AGENTS actually EXECUTE, as
# opposed to commands that models write into static artifacts.
#
# Source: nebius/SWE-agent-trajectories (public, Hugging Face). Each row is
# a full SWE-agent run; assistant ("ai") turns carry exactly one fenced
# command block that the agent executed in its sandbox.
#
# We mine the executed commands, keep invocations of units we already have
# ground truth for (the GNU programs of Dataset A and the Git subcommands
# of Dataset C), and compute the same headline metrics as the main study:
# reach, options per call, zero-option share, and validity.
#
# This is a PILOT: a sample of trajectories, one agent family. It is meant
# to test whether the static-corpus findings transfer to the agentic
# setting, not to replace a full Dataset D.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
RAW_DIR="$BASE_DIR/corpus/agents/raw"
OUT_DIR="$BASE_DIR/results/agents"
GT_GNU="$BASE_DIR/data/groundtruth/gnu"
GT_GIT="$BASE_DIR/data/groundtruth/git"

PAGES=6          # pages of 100 trajectories each
PAGE_LEN=100
# Set DATASET to any HF dataset slug, e.g.:
#   nebius/SWE-agent-trajectories          (public, Llama models)
#   all-hands-ai/swe-bench-lite-trajectories (gated: Claude, GPT-4o, etc.)
#   cognitivecomputations/SWEbench_Verified_Trajectories (gated)
DATASET="${DATASET:-nebius/SWE-agent-trajectories}"

# Optional: set HF_TOKEN env var to access gated datasets.
#   export HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx
#   DATASET=all-hands-ai/swe-bench-lite-trajectories ./08-pilot-agent-trajectories.sh
HF_TOKEN="${HF_TOKEN:-}"

mkdir -p "$RAW_DIR" "$OUT_DIR"

# download
_auth_header() {
  if [[ -n "$HF_TOKEN" ]]; then
    echo "-H" "Authorization: Bearer ${HF_TOKEN}"
  fi
}

for ((p = 0; p < PAGES; p++)); do
  off=$((p * PAGE_LEN))
  f="$RAW_DIR/rows_${off}.json"
  if [[ ! -s "$f" ]]; then
    echo "[download] rows offset=$off"
    curl -s --max-time 300 \
      $(_auth_header) \
      "https://datasets-server.huggingface.co/rows?dataset=${DATASET}&config=default&split=train&offset=${off}&length=${PAGE_LEN}" \
      -o "$f"
  fi
done

# extract executed command lines
# One line per executed command block line: traj_id<TAB>model<TAB>command
CMDS="$OUT_DIR/agent_commands.tsv"
: > "$CMDS"
for f in "$RAW_DIR"/rows_*.json; do
  jq -r '
    .rows[] | .row as $r |
    ($r.trajectory // [])[] |
    select(.role == "ai") |
    (.text // "") |
    [ $r.instance_id, $r.model_name, . ] | @tsv
  ' "$f"
done | awk -F'\t' '
  {
    # The command is inside the (last) ``` fenced block of the ai turn.
    n = split($3, parts, /```/)
    if (n >= 3) {
      block = parts[n - 1]
      sub(/^[a-z]*\\n/, "", block)        # drop language tag if present
      gsub(/\\n/, "\n", block)
      gsub(/\\t/, " ", block)
      m = split(block, lines, "\n")
      for (i = 1; i <= m; i++) {
        line = lines[i]
        gsub(/^[ \t]+|[ \t\r]+$/, "", line)
        if (line != "") printf "%s\t%s\t%s\n", $1, $2, line
      }
    }
  }
' >> "$CMDS"
echo "[extract] $(wc -l < "$CMDS") executed command lines"

# build unit set from GT
UNITS="$OUT_DIR/.units"
for f in "$GT_GNU"/*.txt; do basename "$f" .txt; done > "$UNITS"

# parse invocations
# Output: unit<TAB>options(space separated, may be empty)
INV="$OUT_DIR/agent_invocations.tsv"
awk -F'\t' -v unitsfile="$UNITS" '
  BEGIN {
    while ((getline u < unitsfile) > 0) gnu[u] = 1
    close(unitsfile)
  }
  {
    # split a shell line on separators into simple commands
    line = $3
    # ignore agent built-ins and editor pseudo commands
    gsub(/2>[^ ]*/, "", line)
    n = split(line, segs, /(\|\||&&|\||;)/)
    for (s = 1; s <= n; s++) {
      seg = segs[s]
      gsub(/^[ \t]+|[ \t]+$/, "", seg)
      if (seg == "") continue
      k = split(seg, tok, /[ \t]+/)
      if (k == 0) continue
      c = 1
      if (tok[c] == "sudo" || tok[c] == "env" || tok[c] == "command") c++
      cmd = tok[c]
      sub(/^.*\//, "", cmd)              # strip path prefix
      unit = ""
      start = 0
      if (cmd == "git" && c + 1 <= k && tok[c+1] ~ /^[a-z-]+$/) {
        unit = "git_" tok[c+1]; start = c + 2
      } else if (cmd in gnu && cmd != "git") {
        unit = cmd; start = c + 1
      } else next
      opts = ""
      for (i = start; i <= k; i++) {
        t = tok[i]
        if (t == "--") break
        if (t !~ /^-/) continue
        sub(/=.*$/, "", t)
        gsub(/["'\''`\\);:,.\]}]+$/, "", t)
        if (t !~ /^--?[a-zA-Z]/) continue
        # split short-option clusters (-rf -> -r -f), but not for the
        # X-style units whose single-dash words are real options
        if (t ~ /^-[a-zA-Z]{2,}$/ && unit != "find" && unit != "stty") {
          for (j = 2; j <= length(t); j++) {
            st = "-" substr(t, j, 1)
            opts = (opts == "" ? st : opts " " st)
          }
        } else {
          opts = (opts == "" ? t : opts " " t)
        }
      }
      printf "%s\t%s\n", unit, opts
    }
  }
' "$CMDS" > "$INV"
echo "[parse] $(wc -l < "$INV") invocations of GT units"

# metrics
SUMMARY="$OUT_DIR/agent_pilot_summary.csv"
awk -F'\t' -v gtgnu="$GT_GNU" -v gtgit="$GT_GIT" '
  function gtfile(u) {
    if (u ~ /^git_/) { g = u; sub(/^git_/, "", g); return gtgit "/" g ".txt" }
    return gtgnu "/" u ".txt"
  }
  {
    ds = ($1 ~ /^git_/) ? "git" : "gnu"
    inv[ds]++
    if ($2 == "") { zero[ds]++; next }
    n = split($2, o, " ")
    nopts[ds] += n
    for (i = 1; i <= n; i++) {
      key = ds SUBSEP $1 SUBSEP o[i]
      if (!(key in seen)) {
        seen[key] = 1
        f = gtfile($1)
        valid = 0
        while ((getline line < f) > 0) if (line == o[i]) { valid = 1; break }
        close(f)
        isvalid[key] = valid
        distinct[ds]++
        if (!valid) invalid_distinct[ds]++
      }
      occ[ds]++
      if (!isvalid[key]) invalid_occ[ds]++
    }
  }
  END {
    print "dataset,invocations,pct_zero_option,mean_opts_per_call,distinct_options,invalid_distinct,invalid_occurrence_pct"
    for (ds in inv)
      printf "%s,%d,%.2f,%.3f,%d,%d,%.2f\n", ds, inv[ds],
        100 * zero[ds] / inv[ds], nopts[ds] / inv[ds],
        distinct[ds], invalid_distinct[ds],
        (occ[ds] ? 100 * invalid_occ[ds] / occ[ds] : 0)
  }
' "$INV" | sort > "$SUMMARY"
echo "[done] $SUMMARY"
cat "$SUMMARY"

# top options per dataset for inspection
awk -F'\t' '{ ds = ($1 ~ /^git_/) ? "git" : "gnu"
  if ($2 != "") { n = split($2, o, " "); for (i=1;i<=n;i++) print ds "," $1 "," o[i] } }' \
  "$INV" | sort | uniq -c | sort -rn > "$OUT_DIR/agent_option_counts.txt"
echo "[done] $OUT_DIR/agent_option_counts.txt (top 15):"
head -15 "$OUT_DIR/agent_option_counts.txt"

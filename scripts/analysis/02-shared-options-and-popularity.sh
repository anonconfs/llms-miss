#!/usr/bin/env bash
# For every used ground-truth option, count how OFTEN each population used it
# (invocation-weighted, not just present/absent), so shared options can be
# compared by popularity. An "option use" = one option token in one invocation
# (`grep -i -E` counts once for -i and once for -E).
# In:  results/analysis/{invocations_long,groundtruth_long}.csv
# Out: results/analysis/a2_option_popularity.csv
#      dataset,unit,option,human_uses,llm_uses,human_pct,llm_pct,status
#      (*_pct = share of that population's option-uses in the dataset;
#       status = shared | human_only | llm_only)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd "$HERE/../.." && pwd)"
AN="$BASE/results/analysis"

INV="$AN/invocations_long.csv"
GT="$AN/groundtruth_long.csv"
POP_OUT="$AN/a2_option_popularity.csv"
SH_OUT="$AN/a2_shared_options.csv"

awk -F',' '
    # ground-truth membership
    FNR==NR { if (FNR==1) next; gt[$1,$2,$3]=1; next }

    # invocation rows: tally per (dataset,unit,option,population)
    FNR==1 { next }
    {
        ds=$1; pop=$2; unit=$4; opt=$5
        if (opt=="") next
        if (!((ds,unit,opt) in gt)) next         # ground-truth options only
        # a2 is the human-vs-model comparison: count ONLY those two cohorts.
        # The kernel reference cohort must not leak into either column.
        if (pop=="human")    { h[ds,unit,opt]++; htot[ds]++; seen[ds,unit,opt]=1 }
        else if (pop=="llm") { l[ds,unit,opt]++; ltot[ds]++; seen[ds,unit,opt]=1 }
    }
    END {
        OFS=","
        print "dataset,unit,option,human_uses,llm_uses,human_pct,llm_pct,status" > "/dev/stdout"
        for (k in seen) {
            split(k, a, SUBSEP); ds=a[1]; unit=a[2]; opt=a[3]
            hu = (k in h) ? h[k] : 0
            lu = (k in l) ? l[k] : 0
            hp = (htot[ds]>0) ? 100*hu/htot[ds] : 0
            lp = (ltot[ds]>0) ? 100*lu/ltot[ds] : 0
            status = (hu>0 && lu>0) ? "shared" : (hu>0 ? "human_only" : "llm_only")
            printf "%s,%s,%s,%d,%d,%.3f,%.3f,%s\n", ds, unit, opt, hu, lu, hp, lp, status
        }
    }
' "$GT" "$INV" > "$POP_OUT.tmp"

{ head -1 "$POP_OUT.tmp"; tail -n +2 "$POP_OUT.tmp" \
    | sort -t, -k1,1 -k2,2 -k4,4nr; } > "$POP_OUT"
rm -f "$POP_OUT.tmp"

# shared options only, ranked by combined use, with a popularity gap
{
    echo "dataset,unit,option,human_uses,llm_uses,human_pct,llm_pct,combined_uses,abs_pct_gap"
    tail -n +2 "$POP_OUT" | awk -F',' '$8=="shared"{
        comb=$4+$5; gap=$6-$7; if(gap<0)gap=-gap
        printf "%s,%s,%s,%s,%s,%s,%s,%d,%.3f\n",$1,$2,$3,$4,$5,$6,$7,comb,gap
    }' | sort -t, -k1,1 -k8,8nr
} > "$SH_OUT"

echo "Wrote $POP_OUT"
echo "Wrote $SH_OUT"
echo
echo "Shared / human_only / llm_only option counts per dataset:"
tail -n +2 "$POP_OUT" | awk -F',' '{c[$1","$8]++} END{for(k in c) print "  "k": "c[k]}' | sort
echo
echo "Top 10 shared options by combined use:"
tail -n +2 "$SH_OUT" | head -10 | column -t -s','

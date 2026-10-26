#!/usr/bin/env bash
# Short-vs-long form preference, using the alias map from step 03. When an
# option offers both a short (-x) and a long (--word) spelling, how often did
# each population pick each form? Counting is invocation-weighted and scoped per
# program, so `ls -l` and `wc -l` never mix.
# In:  results/analysis/{aliases_long,groundtruth_long,invocations_long}.csv
# Out: results/analysis/a4_form_preference.csv  (alias-resolved view)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd "$HERE/../.." && pwd)"
AN="$BASE/results/analysis"

ALI="$AN/aliases_long.csv"
GT="$AN/groundtruth_long.csv"
INV="$AN/invocations_long.csv"

COV_OUT="$AN/a4_logical_coverage.csv"
FORM_OUT="$AN/a4_form_preference.csv"
RAW_OUT="$AN/a4_form_preference_raw.csv"
DETAIL_OUT="$AN/a4_alias_usage_detail.csv"

awk -F',' -v DETAIL="$DETAIL_OUT" -v COV="$COV_OUT" -v FORM="$FORM_OUT" -v RAW="$RAW_OUT" '
    # file 1: alias map
    ARGIND==1 {
        if (FNR==1) next
        ds=$1; unit=$2; short=$3; long=$4
        canon[ds,unit,short]=long      # short collapses to its long form
        canon[ds,unit,long]=long       # long maps to itself
        paired[ds,unit,long]=1         # this logical option has two spellings
        next
    }
    # file 2: ground truth
    ARGIND==2 {
        if (FNR==1) next
        ds=$1; unit=$2; opt=$3
        lg = ((ds,unit,opt) in canon) ? canon[ds,unit,opt] : opt
        gtlog[ds,unit,lg]=1
        next
    }
    # file 3: invocations
    ARGIND==3 {
        if (FNR==1) next
        ds=$1; pop=$2; unit=$4; opt=$5
        if (opt=="") next
        lg = ((ds,unit,opt) in canon) ? canon[ds,unit,opt] : opt
        if (!((ds,unit,lg) in gtlog)) next        # ground-truth logical options only
        usedlog[ds,unit,pop,lg]=1
        # record spelling actually used, for cross-spelling + form preference
        form = (opt ~ /^--/) ? "long" : "short"
        spell[ds,unit,pop,lg,form]=1
        rawcount[ds,pop,form]++                   # syntactic: every legal option token, as written
        if ((ds,unit,lg) in paired) {
            fcount[ds,pop,form]++                 # alias-resolved: only when both forms exist (a real choice)
        }
    }
    END {
        OFS=","

        # alias usage detail + cross-spelling tallies
        print "dataset,unit,logical_option,paired,human_short,human_long,llm_short,llm_long" > DETAIL
        for (k in usedlog) {
            split(k, a, SUBSEP); ds=a[1]; unit=a[2]; pop=a[3]; lg=a[4]
            seenlog[ds,unit,lg]=1
        }
        for (k in seenlog) {
            split(k, a, SUBSEP); ds=a[1]; unit=a[2]; lg=a[3]
            hs=((ds,unit,"human",lg,"short") in spell)?1:0
            hl=((ds,unit,"human",lg,"long")  in spell)?1:0
            ls=((ds,unit,"llm",lg,"short")   in spell)?1:0
            ll=((ds,unit,"llm",lg,"long")    in spell)?1:0
            pr=((ds,unit,lg) in paired)?1:0
            print ds,unit,lg,pr,hs,hl,ls,ll >> DETAIL

            humanuses = (hs||hl)
            llmuses   = (ls||ll)
            if (humanuses) hum_logical[ds]++
            if (llmuses)   llm_logical[ds]++
            if (humanuses && llmuses) {
                shared_logical[ds]++
                # same spelling if their spelling sets intersect
                same = ((hs&&ls) || (hl&&ll))
                if (same) shared_same[ds]++
                else      shared_diff[ds]++
            }
        }

        # gt logical total = distinct logical options in ground truth
        for (k in gtlog) { split(k,a,SUBSEP); gtl[a[1]]++ }

        # logical coverage rollup
        print "dataset,gt_logical_options,human_logical,llm_logical,shared_logical,shared_same_spelling,shared_diff_spelling" > COV
        for (ds in gtl) {
            printf "%s,%d,%d,%d,%d,%d,%d\n", ds, gtl[ds],
                (ds in hum_logical?hum_logical[ds]:0),
                (ds in llm_logical?llm_logical[ds]:0),
                (ds in shared_logical?shared_logical[ds]:0),
                (ds in shared_same?shared_same[ds]:0),
                (ds in shared_diff?shared_diff[ds]:0) >> COV
        }

        # form preference (two views)
        # RAW counts every legal option token as written; FORM keeps only the
        # options that offer both a short and a long spelling (a real choice).
        print "dataset,population,short_uses,long_uses,short_pct,long_pct" > FORM
        print "dataset,population,short_uses,long_uses,short_pct,long_pct" > RAW
        split("gnu git ci", dsl, " ")
        split("human llm kernel", pl, " ")
        for (i in dsl) for (j in pl) {
            ds=dsl[i]; pop=pl[j]
            rs=(ds,pop,"short") in rawcount ? rawcount[ds,pop,"short"] : 0
            rl=(ds,pop,"long")  in rawcount ? rawcount[ds,pop,"long"]  : 0
            rtot=rs+rl
            if (rtot>0)
                printf "%s,%s,%d,%d,%.1f,%.1f\n", ds,pop,rs,rl,100*rs/rtot,100*rl/rtot >> RAW
            s=(ds,pop,"short") in fcount ? fcount[ds,pop,"short"] : 0
            l=(ds,pop,"long")  in fcount ? fcount[ds,pop,"long"]  : 0
            tot=s+l
            if (tot>0)
                printf "%s,%s,%d,%d,%.1f,%.1f\n", ds,pop,s,l,100*s/tot,100*l/tot >> FORM
        }
    }
' "$ALI" "$GT" "$INV"
# sort detail for readability
{ head -1 "$DETAIL_OUT"; tail -n +2 "$DETAIL_OUT" | sort -t, -k1,1 -k2,2 -k3,3; } > "$DETAIL_OUT.s"
mv "$DETAIL_OUT.s" "$DETAIL_OUT"

echo "Wrote $COV_OUT"; echo "Wrote $FORM_OUT"; echo "Wrote $RAW_OUT"; echo "Wrote $DETAIL_OUT"
echo; echo "LOGICAL COVERAGE"
column -t -s',' "$COV_OUT"
echo; echo "FORM PREFERENCE (syntactic, all tokens)"
column -t -s',' "$RAW_OUT"
echo; echo "FORM PREFERENCE (alias-resolved)"
column -t -s',' "$FORM_OUT"

#!/usr/bin/env bash
# Count programs and options per dataset, and how far each population reaches
# into the documented option space. Works for any population set (gnu has
# kernel/human/llm; git and ci have human/llm). Reports per-population reach,
# the never-used region, and the human-vs-llm shared / human-only / llm-only
# split (kernel excluded from that pair).
# In:  results/analysis/{invocations_long,groundtruth_long}.csv
# Out: results/analysis/a1_{population_coverage,dataset_summary,human_llm_split}.csv
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd "$HERE/../.." && pwd)"
AN="$BASE/results/analysis"

INV="$AN/invocations_long.csv"
GT="$AN/groundtruth_long.csv"

COV_OUT="$AN/a1_population_coverage.csv"
SUM_OUT="$AN/a1_dataset_summary.csv"
SPLIT_OUT="$AN/a1_human_llm_split.csv"
UNIT_OUT="$AN/a1_unit_coverage.csv"

# -----------------------------------------------------------------------------
# Single pass over ground truth + invocations.
#   used[ds, pop, unit, opt] = 1  for every LEGAL option a population used
#   seenunit[ds, pop, unit]  = 1  for every unit a population invoked at all
# From these we derive per-population reach, the union/never region, and the
# human-vs-llm split, without hard-coding the population set.
# -----------------------------------------------------------------------------
awk -F',' '
    # ---- ground truth: legal (dataset,unit,option) ----
    FNR==NR {
        if (FNR==1) next
        gt[$1, $2, $3]=1            # dataset, unit, option
        gtn[$1, $2]++              # options per (dataset,unit)
        if (!(($1,$2) in unitseen)) { unitseen[$1,$2]=1; gtunits[$1]++ }
        gtopts[$1]++
        next
    }
    # ---- invocations ----
    FNR==1 { next }
    {
        ds=$1; pop=$2; unit=$4; opt=$5
        pops[ds, pop]=1
        seenunit[ds, pop, unit]=1
        if (opt=="") next
        if ((ds, unit, opt) in gt) used[ds, pop, unit, opt]=1
    }
    END {
        OFS=","
        # ---- per (dataset,unit) tallies; also per-population reach ----
        for (k in gtn) {
            split(k, a, SUBSEP); ds=a[1]; unit=a[2]
            for (g in gt) {
                split(g, b, SUBSEP)
                if (b[1]!=ds || b[2]!=unit) continue
                opt=b[3]
                anyuse=0
                for (pk in pops) {
                    split(pk, p, SUBSEP)
                    if (p[1]!=ds) continue
                    pop=p[2]
                    if ((ds,pop,unit,opt) in used) {
                        reach[ds,pop]++          # distinct legal options used
                        anyuse=1
                    }
                }
                if (anyuse) union[ds]++           # used by at least one pop
            }
        }
        # units invoked per population
        for (s in seenunit) {
            split(s, c, SUBSEP); ds=c[1]; pop=c[2]
            unitsused[ds,pop]++
        }

        # ---- a1_population_coverage.csv ----
        print "dataset,population,units_used,opts_used,gt_options,reach_pct" > COV
        for (pk in pops) {
            split(pk, p, SUBSEP); ds=p[1]; pop=p[2]
            ou = (reach[ds,pop]+0); uu = (unitsused[ds,pop]+0)
            pct = (gtopts[ds]>0) ? 100.0*ou/gtopts[ds] : 0
            printf "%s,%s,%d,%d,%d,%.2f\n", ds, pop, uu, ou, gtopts[ds], pct > COV
        }

        # ---- a1_dataset_summary.csv ----
        print "dataset,gt_units,gt_options,opts_union,opts_never,never_pct" > SUM
        for (ds in gtopts) {
            uni=(union[ds]+0); never=gtopts[ds]-uni
            npct=(gtopts[ds]>0)?100.0*never/gtopts[ds]:0
            printf "%s,%d,%d,%d,%d,%.2f\n", ds, gtunits[ds], gtopts[ds], uni, never, npct > SUM
        }

        # ---- a1_human_llm_split.csv (the RQ3 contrast; kernel excluded) ----
        print "dataset,shared,human_only,llm_only,human_total,llm_total" > SPL
        for (ds in gtopts) {
            sh=0; ho=0; lo=0; ht=0; lt=0
            for (g in gt) {
                split(g, b, SUBSEP)
                if (b[1]!=ds) continue
                unit=b[2]; opt=b[3]
                inh=((ds,"human",unit,opt) in used)
                inl=((ds,"llm",  unit,opt) in used)
                if (inh) ht++
                if (inl) lt++
                if (inh && inl) sh++
                else if (inh) ho++
                else if (inl) lo++
            }
            printf "%s,%d,%d,%d,%d,%d\n", ds, sh, ho, lo, ht, lt > SPL
        }

        # ---- a1_unit_coverage.csv (long: dataset,unit,population,opts_used,gt_options) ----
        print "dataset,unit,population,opts_used,gt_options" > UNIT
        for (pk in pops) {
            split(pk, p, SUBSEP); ds=p[1]; pop=p[2]
            for (k in gtn) {
                split(k, a, SUBSEP)
                if (a[1]!=ds) continue
                unit=a[2]; cnt=0
                for (g in gt) {
                    split(g, b, SUBSEP)
                    if (b[1]!=ds || b[2]!=unit) continue
                    if ((ds,pop,unit,b[3]) in used) cnt++
                }
                if (cnt>0 || ((ds,pop,unit) in seenunit))
                    printf "%s,%s,%s,%d,%d\n", ds, unit, pop, cnt, gtn[k] > UNIT
            }
        }
    }
' OFS=',' \
  COV="$COV_OUT" SUM="$SUM_OUT" SPL="$SPLIT_OUT" UNIT="$UNIT_OUT" \
  "$GT" "$INV"

# Sort bodies for stable, readable output (header kept first; read from file so
# head/tail over a stream cannot drop buffered lines).
for f in "$COV_OUT" "$SUM_OUT" "$SPLIT_OUT" "$UNIT_OUT"; do
    { head -1 "$f"; tail -n +2 "$f" | sort -t, -k1,1 -k2,2 -k3,3; } > "$f.tmp"
    mv "$f.tmp" "$f"
done

echo "Wrote $COV_OUT"
echo "Wrote $SUM_OUT"
echo "Wrote $SPLIT_OUT"
echo "Wrote $UNIT_OUT"
echo
echo "================= DATASET SUMMARY ================="
column -t -s',' "$SUM_OUT"
echo
echo "================= POPULATION REACH ================="
column -t -s',' "$COV_OUT"
echo
echo "================= HUMAN vs LLM SPLIT ================="
column -t -s',' "$SPLIT_OUT"

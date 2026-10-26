#!/usr/bin/env bash
# Option co-occurrence edges: which options appear together in the same
# invocation, built separately for humans and LLMs so the two styles compare as
# graphs. Computed per unit (the -l in `ls` differs from the -l in `wc`); for an
# invocation using {a,b,c} we emit every unordered pair. Reads the source
# invocation files (not the exploded table) to keep each invocation's option set.
# Out: results/analysis/a6_cooccurrence.csv
#      dataset,population,unit,option_a,option_b,cooccur_count
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd "$HERE/../.." && pwd)"
AN="$BASE/results/analysis"
EDGES="$AN/a6_cooccurrence.csv"

# Stream of "dataset<TAB>population<TAB>unit<TAB>opt1 opt2 ..." for every
# invocation that used at least two options.
emit_invocations() {
    # GNU
    for pop in human llm; do
        tail -n +2 "$BASE/results/gnu/${pop}_invocations.csv" | awk -F',' -v p="$pop" '{
            opt=$3; gsub(/^"|"$/,"",opt)
            if (split(opt,a," ") >= 2) printf "gnu\t%s\t%s\t%s\n", p, $2, opt
        }'
    done
    # GIT (options_all = every option seen in the invocation)
    tail -n +2 "$BASE/results/git/git_invocations_raw.csv" | awk -F',' '{
        opt=$5; gsub(/^"|"$/,"",opt)
        if (split(opt,a," ") >= 2) printf "git\t%s\t%s\t%s\n", $1, $4, opt
    }'
    # CI
    for pop in human llm; do
        tail -n +2 "$BASE/results/ci/${pop}_ci_invocations.csv" | awk -F',' -v p="$pop" '{
            opt=$4; gsub(/^"|"$/,"",opt)
            unit = ($3=="" ? $2 : $2"_"$3)
            if (split(opt,a," ") >= 2) printf "ci\t%s\t%s\t%s\n", p, unit, opt
        }'
    done
}

# Turn each invocation's option set into sorted unordered pairs and count them.
emit_invocations | awk -F'\t' '
    {
        ds=$1; pop=$2; unit=$3
        nraw=split($4, raw, " ")
        # sanitize tokens the same way the foundation does (strip shell
        # punctuation and =value suffixes, keep only dash-led tokens)
        n=0
        for (i=1;i<=nraw;i++) {
            t=raw[i]
            gsub(/^["'"'"'`]+/, "", t); sub(/=.*$/, "", t)
            gsub(/["'"'"'`\\);:,.\]}]+$/, "", t)
            if (t ~ /^-/) o[++n]=t
        }
        # de-duplicate options within the invocation, then sort for a stable pair key
        delete seen; m=0
        for (i=1;i<=n;i++) if (!(o[i] in seen)) { seen[o[i]]=1; u[++m]=o[i] }
        # simple insertion sort (small m)
        for (i=2;i<=m;i++){ key=u[i]; j=i-1; while(j>=1 && u[j]>key){u[j+1]=u[j];j--} u[j+1]=key }
        for (i=1;i<=m;i++) for (k=i+1;k<=m;k++) {
            cnt[ds,pop,unit,u[i],u[k]]++
        }
    }
    END {
        print "dataset,population,unit,option_a,option_b,cooccur_count"
        for (e in cnt) { split(e,a,SUBSEP); print a[1]","a[2]","a[3]","a[4]","a[5]","cnt[e] }
    }
' > "$EDGES.tmp"

{ head -1 "$EDGES.tmp"; tail -n +2 "$EDGES.tmp" | sort -t, -k1,1 -k2,2 -k3,3 -k6,6nr; } > "$EDGES"
rm -f "$EDGES.tmp"

# Node degree per option (how many distinct partners, and total co-occurrences).
{
    echo "dataset,population,unit,option,distinct_partners,total_cooccur"
    tail -n +2 "$EDGES" | awk -F',' '
    {
        # each edge contributes to both endpoints
        deg[$1,$2,$3,$4]++; tot[$1,$2,$3,$4]+=$6
        deg[$1,$2,$3,$5]++; tot[$1,$2,$3,$5]+=$6
    }
    END { for (k in deg){ split(k,a,SUBSEP);
        print a[1]","a[2]","a[3]","a[4]","deg[k]","tot[k] } }
    ' | sort -t, -k1,1 -k2,2 -k3,3 -k6,6nr
} > "$AN/a6_node_degree.csv"

echo "Wrote $EDGES"
echo "Wrote $AN/a6_node_degree.csv"
echo
echo "Co-occurrence edges per dataset/population:"
tail -n +2 "$EDGES" | awk -F',' '{c[$1" "$2]++} END{for(k in c) print "  "k": "c[k]}' | sort
echo
echo "Top co-occurring option pairs (any dataset):"
tail -n +2 "$EDGES" | sort -t, -k6,6nr | head -10 | column -t -s',' || true

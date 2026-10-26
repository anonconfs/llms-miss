#!/usr/bin/env bash
# Three metrics backing prose claims in the paper:
#   validity      fraction of emitted options that are real ground-truth options
#                 ("models rarely emit options that do not exist")
#   distribution  options per invocation: mean, median, %zero, p90, max
#                 ("the median invocation supplies zero options")
#   concentration how top-heavy usage is: normalised Shannon entropy and Gini
#                 ("a small, stable subset is used intensively")
# In:  results/analysis/{invocations_long,groundtruth_long,a2_option_popularity}.csv,
#      results/gnu/*_invocations.csv, results/ci/*_ci_invocations.csv,
#      results/git/git_invocations_raw.csv
# Out: results/analysis/a7_{validity,distribution,concentration}.csv
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd "$HERE/../.." && pwd)"
AN="$BASE/results/analysis"

INV="$AN/invocations_long.csv"
GT="$AN/groundtruth_long.csv"
POP="$AN/a2_option_popularity.csv"

VAL_OUT="$AN/a7_validity.csv"
DIST_OUT="$AN/a7_distribution.csv"
CONC_OUT="$AN/a7_concentration.csv"

# M7  Validity -- legal vs illegal option occurrences per dataset/population.

awk -F',' '
    FNR==NR { if (FNR>1) gt[$1,$2,$3]=1; next }      # ground truth
    FNR==1 { next }
    {
        ds=$1; pop=$2; unit=$4; opt=$5
        if (opt=="") next
        tot[ds,pop]++
        if ((ds,unit,opt) in gt) ok[ds,pop]++
        else { bad[ds,pop]++; if (!((ds,pop,unit,opt) in seenbad)){seenbad[ds,pop,unit,opt]=1; distinctbad[ds,pop]++} }
    }
    END {
        print "dataset,population,opt_occurrences,valid_occurrences,invalid_occurrences,invalid_pct,distinct_invalid_options"
        for (k in tot) {
            split(k,a,SUBSEP); ds=a[1]; pop=a[2]
            t=tot[k]+0; o=ok[k]+0; b=bad[k]+0
            pct=(t>0)?100.0*b/t:0
            printf "%s,%s,%d,%d,%d,%.2f,%d\n", ds, pop, t, o, b, pct, distinctbad[k]+0
        }
    }
' "$GT" "$INV" > "$VAL_OUT.tmp"
{ head -1 "$VAL_OUT.tmp"; tail -n +2 "$VAL_OUT.tmp" | sort -t, -k1,1 -k2,2; } > "$VAL_OUT"; rm -f "$VAL_OUT.tmp"

# M8  Distribution -- options per invocation, straight from the source result
# files (each row there is exactly one invocation with an option_count column).
#   gnu : results/gnu/{human,llm,coreutils}_invocations.csv  col 4 = option_count
#   ci  : results/ci/{human,llm}_ci_invocations.csv          col 5 = option_count
#   git : results/git/git_invocations_raw.csv                 col 6 = num_options
# We emit "dataset population count" rows then summarise with one awk.
{
    tail -n +2 "$BASE/results/gnu/human_invocations.csv"     | awk -F',' '{print "gnu human "$4}'
    tail -n +2 "$BASE/results/gnu/llm_invocations.csv"       | awk -F',' '{print "gnu llm "$4}'
    tail -n +2 "$BASE/results/gnu/coreutils_invocations.csv" | awk -F',' '{print "gnu kernel "$4}'
    tail -n +2 "$BASE/results/ci/human_ci_invocations.csv"   | awk -F',' '{print "ci human "$5}'
    tail -n +2 "$BASE/results/ci/llm_ci_invocations.csv"     | awk -F',' '{print "ci llm "$5}'
    # git: count options from the options_all field itself with the same
    # sanitization the foundation applies (the stored num_options column is
    # unreliable for one malformed row that embeds a comma in the field).
    tail -n +2 "$BASE/results/git/git_invocations_raw.csv"    | awk -F',' '{
        opt=$5; gsub(/^"|"$/, "", opt)
        n = split(opt, t, " "); c = 0
        for (i = 1; i <= n; i++) {
            o = t[i]
            gsub(/^["'"'"'`]+/, "", o); sub(/=.*$/, "", o)
            gsub(/["'"'"'`\\);:,.\]}]+$/, "", o)
            if (o ~ /^-/) c++
        }
        print "git "$1" "c
    }'
} | awk '
    { ds=$1; pop=$2; c=$3+0; key=ds" "pop
      n[key]++; sum[key]+=c; if(c==0) zero[key]++
      vals[key]=vals[key]" "c
      if(c>max[key]) max[key]=c
    }
    END {
        print "dataset,population,n_invocations,mean_options,median_options,pct_zero_option,p90_options,max_options"
        for (key in n) {
            # median & p90 via sort of the collected values
            m=split(vals[key], arr, " ")
            # arr[1] is empty (leading space); compact into v[]
            cnt=0; for(i=1;i<=m;i++) if(arr[i]!="") v[++cnt]=arr[i]+0
            # insertion sort (small-ish; fine for our sizes)
            for(i=2;i<=cnt;i++){x=v[i];j=i-1;while(j>=1&&v[j]>x){v[j+1]=v[j];j--}v[j+1]=x}
            med=(cnt%2)?v[(cnt+1)/2]:(v[cnt/2]+v[cnt/2+1])/2.0
            p90i=int(0.9*cnt); if(p90i<1)p90i=1
            split(key,a," "); ds=a[1]; pp=a[2]
            printf "%s,%s,%d,%.3f,%g,%.2f,%g,%d\n", ds, pp, n[key], sum[key]/n[key], med, 100.0*zero[key]/n[key], v[p90i], max[key]
            delete v
        }
    }
' > "$DIST_OUT.tmp"
{ head -1 "$DIST_OUT.tmp"; tail -n +2 "$DIST_OUT.tmp" | sort -t, -k1,1 -k2,2; } > "$DIST_OUT"; rm -f "$DIST_OUT.tmp"

# M2  Concentration -- normalised Shannon entropy and Gini of the per-option
# usage counts, per dataset/population, from the invocation-weighted popularity
# table (human_uses, llm_uses).  High entropy / low Gini = even usage; low
# entropy / high Gini = a few options dominate.
#   a2_option_popularity.csv: dataset,unit,option,human_uses,llm_uses,...

awk -F',' '
    NR==1 { next }
    { ds=$1; h=$4+0; l=$5+0
      if (h>0){ hc[ds]++; hv[ds]=hv[ds]" "h; hsum[ds]+=h }
      if (l>0){ lc[ds]++; lv[ds]=lv[ds]" "l; lsum[ds]+=l }
    }
    function entropy(vals, total,   m,arr,i,p,H,n){
        n=split(vals,arr," "); H=0
        for(i=1;i<=n;i++){ if(arr[i]=="")continue; p=arr[i]/total; if(p>0) H-=p*log(p) }
        return H
    }
    function gini(vals,   m,arr,i,j,cnt,v,sumabs,sumv){
        m=split(vals,arr," "); cnt=0
        for(i=1;i<=m;i++) if(arr[i]!="") v[++cnt]=arr[i]+0
        if(cnt<=1) return 0
        sumabs=0; sumv=0
        for(i=1;i<=cnt;i++){ sumv+=v[i]; for(j=1;j<=cnt;j++) sumabs+=(v[i]>v[j]?v[i]-v[j]:v[j]-v[i]) }
        delete v
        return sumabs/(2.0*cnt*sumv)
    }
    END {
        print "dataset,population,n_options_used,norm_entropy,gini"
        for (ds in hsum) {
            He=entropy(hv[ds],hsum[ds]); ne=(hc[ds]>1)?He/log(hc[ds]):0
            printf "%s,human,%d,%.3f,%.3f\n", ds, hc[ds], ne, gini(hv[ds])
        }
        for (ds in lsum) {
            Le=entropy(lv[ds],lsum[ds]); ne=(lc[ds]>1)?Le/log(lc[ds]):0
            printf "%s,llm,%d,%.3f,%.3f\n", ds, lc[ds], ne, gini(lv[ds])
        }
    }
' "$POP" > "$CONC_OUT.tmp"
{ head -1 "$CONC_OUT.tmp"; tail -n +2 "$CONC_OUT.tmp" | sort -t, -k1,1 -k2,2; } > "$CONC_OUT"; rm -f "$CONC_OUT.tmp"

echo "Wrote $VAL_OUT"; column -t -s',' "$VAL_OUT"; echo
echo "Wrote $DIST_OUT"; column -t -s',' "$DIST_OUT"; echo
echo "Wrote $CONC_OUT"; column -t -s',' "$CONC_OUT"

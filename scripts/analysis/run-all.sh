#!/usr/bin/env bash
# Run the analysis pipeline end to end. Each step writes CSVs to
# results/analysis/; the notebooks in scripts/notebooks/ read those CSVs.
#   00 foundation tables (invocations + ground truth)
#   01 program/option counts and coverage
#   02 shared options and invocation-weighted popularity
#   03 short<->long alias map from each tool's --help
#   04 short-vs-long form preference
#   06 option co-occurrence edges
#   07 options-per-invocation distribution, concentration, validity
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for step in \
    00-build-foundation.sh \
    01-program-and-option-counts.sh \
    02-shared-options-and-popularity.sh \
    03-extract-aliases.sh \
    04-short-long-preference.sh \
    06-option-cooccurrence.sh \
    07-distribution-and-validity.sh
do
    echo "============================================================"
    echo ">>> $step"
    echo "============================================================"
    bash "$HERE/$step"
    echo
done

echo "All analysis steps complete. Outputs in results/analysis/."

#!/bin/bash
# Matching (sub)strings of words between German varieties (Alemannic, Bavarian, Standard German)

source /media/AllBlue/LanguageData/TOOLS/vTextCleaning/bin/activate

SOURCE="bar"
TARGET="deu"
SRCLANG="Bavarian"
TRGLANG="German"

CLEANDIR="/media/AllBlue/LanguageData/CLEAN"
#PREPDIR="/media/AllBlue/LanguageData/PREP/2024SchuMATh-${SOURCE}L-Sock-${TARGET}L-DBLI-0001"
EXPDIR="/media/AllBlue/LanguageData/EXPERIMENT/2024SchuMATh-${SOURCE}L-SYNT-${TARGET}L-DBLI-0001"
mkdir "${EXPDIR}" -p

# python3 /media/CrazyProjects/LowResDialectology/DialectTools/launch/StringMatching-German.py \
#     --source "${SOURCE}" \
#     --target "${TARGET}" \
#     --src-lang "${SRCLANG}" \
#     --trg-lang "${TRGLANG}" \
#     --clean-dir "${CLEANDIR}" \
#     --exp-dir "${EXPDIR}" 

# echo "No Alemannic file created by ChatGPT → FileNotFoundError"



for MATCH in no_prefixes no_suffixes prefixes suffixes; do
    # Temporary quick fix to merge all frequency dictionaries for better overview:
    python3 /media/CrazyProjects/LowResDialectology/DialectTools/launch/StringMatching-German-MergeFreqDicts.py \
        --match "${MATCH}" \
        --source "${SOURCE}" \
        --target "${TARGET}" \
        --exp-dir "${EXPDIR}" 
done



# SOURCE="als"
# TARGET="deu"
# SRCLANG="Alemannic"
# TRGLANG="German"

# CLEANDIR="/media/AllBlue/LanguageData/CLEAN"
# #PREPDIR="/media/AllBlue/LanguageData/PREP/2024SchuMATh-${SOURCE}L-Sock-${TARGET}L-DBLI-0001"
# EXPDIR="/media/AllBlue/LanguageData/EXPERIMENT/2024SchuMATh-${SOURCE}L-SYNT-${TARGET}L-DBLI-0001"
# mkdir "${EXPDIR}" -p

# python3 /media/CrazyProjects/LowResDialectology/DialectTools/launch/StringMatching-German.py \
#     --source "${SOURCE}" \
#     --target "${TARGET}" \
#     --src-lang "${SRCLANG}" \
#     --trg-lang "${TRGLANG}" \
#     --clean-dir "${CLEANDIR}" \
#     --exp-dir "${EXPDIR}" 




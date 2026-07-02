#!/usr/bin/env bash
#Code written by ChatGPT, edited by Mark Schroeder 11 JAN 2026	
set -euo pipefail

HTML_FILE="blog/portfolio/portfolio.html"

if [[ ! -f "$HTML_FILE" ]]; then
  echo "Error: file not found: $HTML_FILE" >&2
  exit 1
fi

echo "Paste 5 prices (TSLA, MSTR, CRSP, ARKG, VAS), one per line."
echo "When done, press Ctrl-D."
echo

prices=()
while IFS= read -r line; do
  # strip CRLF, spaces, leading $
  cleaned="$(printf '%s' "$line" | tr -d '\r' | sed -E 's/[[:space:]]+//g; s/^\$//')"
  [[ -z "$cleaned" ]] && continue

  if [[ ! "$cleaned" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: invalid price line: '$line'" >&2
    exit 1
  fi

  prices+=("$cleaned")
done

if [[ "${#prices[@]}" -ne 5 ]]; then
  echo "Error: expected 5 prices, got ${#prices[@]}." >&2
  exit 1
fi

TSLA="${prices[0]}"
MSTR="${prices[1]}"
ARKG="${prices[2]}"
CRSP="${prices[3]}"
VAS="${prices[4]}"

TODAY="$(date '+%d %B %Y')"

# Backup
cp -a "$HTML_FILE" "$HTML_FILE.bak"

# IMPORTANT: the trailing 'e' on each substitute prevents "pattern not found" from failing vim.
if ! vim -Es "$HTML_FILE" \
  -c "%s/^\(\\s*TSLA:.*Average price (USD): \\$\\)\\zs[0-9.][0-9.]*/$TSLA/e" \
  -c "%s/^\(\\s*MSTR:.*Average price (USD): \\$\\)\\zs[0-9.][0-9.]*/$MSTR/e" \
  -c "%s/^\(\\s*ARKG:.*Average price (USD): \\$\\)\\zs[0-9.][0-9.]*/$ARKG/e" \
  -c "%s/^\(\\s*CRSP:.*Average price (USD): \\$\\)\\zs[0-9.][0-9.]*/$CRSP/e" \
  -c "%s/^\(\\s*VAS:.*Average price (AUD): \\$\\)\\zs[0-9.][0-9.]*/$VAS/e" \
  -c "%s/^\(.*Holdings as of \).*/\1$TODAY/e" \
  -c "wq"
then
  echo "Error: vim failed to update the file. Backup kept at: $HTML_FILE.bak" >&2
  exit 1
fi

echo "Prices updated."
echo "Date set to $TODAY"
echo "Backup saved as $HTML_FILE.bak"

printf "\nWould you like to push the changes to github and have them pulled down by the vps? (y/n)"

read push
if [ "$push" = "y" ];then
	bash /home/mark/Documents/code/bashScripts/updateMarksch.sh
else
	echo "Okay, we won't push it for you."
fi

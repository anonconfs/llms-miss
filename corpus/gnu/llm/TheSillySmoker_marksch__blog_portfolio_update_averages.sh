#!/usr/bin/env bash
# Code written by ChatGPT, edited by Mark Schroeder 11 JAN 2026
# Modified: read prices from Calc (.ods) by converting to .xlsx once, then update HTML
set -euo pipefail

# ------------------ EDIT THESE ------------------
HTML_FILE="blog/portfolio/portfolio.html"

ODS_FILE="/run/user/1000/gvfs/smb-share:server=marks-macbook-air.local,share=sambashare/open_mark/open_marks_portfolio_mac.ods"   # <-- set this
SHEET_NAME="Insights"                  # <-- set this exactly (case-sensitive)

# Cells in the sheet (set these)
CELL_TSLA="E13"
CELL_MSTR="E14"
CELL_ARKG="E15"
CELL_CRSP="E16"
CELL_VAS="E17"
# ------------------------------------------------

die() { echo "Error: $*" >&2; exit 1; }

[[ -f "$HTML_FILE" ]] || die "HTML file not found: $HTML_FILE"
[[ -f "$ODS_FILE"   ]] || die "Spreadsheet not found: $ODS_FILE"

# LibreOffice binary (Debian may provide 'libreoffice' and/or 'soffice')
LO_BIN=""
if command -v libreoffice >/dev/null 2>&1; then
  LO_BIN="libreoffice"
elif command -v soffice >/dev/null 2>&1; then
  LO_BIN="soffice"
else
  die "LibreOffice not found. Install with: sudo apt install libreoffice"
fi

python3 -c "import openpyxl" >/dev/null 2>&1 \
  || die "python3-openpyxl not found. Install with: sudo apt install python3-openpyxl"

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

# Convert ODS -> XLSX (one-time snapshot per run)
"$LO_BIN" --headless --nologo --nolockcheck --nodefault --norestore \
  --convert-to xlsx --outdir "$tmpdir" "$ODS_FILE" >/dev/null 2>&1 \
  || die "LibreOffice failed converting ODS to XLSX."

# Find the converted xlsx
xlsx="$(ls -1 "$tmpdir"/*.xlsx 2>/dev/null | head -n 1 || true)"
[[ -n "$xlsx" && -f "$xlsx" ]] || die "Could not locate converted XLSX in $tmpdir"

# Read the 5 cells from the converted XLSX
mapfile -t prices < <(
python3 - "$xlsx" "$SHEET_NAME" \
  "$CELL_TSLA" "$CELL_MSTR" "$CELL_ARKG" "$CELL_CRSP" "$CELL_VAS" <<'PY'
import sys
from openpyxl import load_workbook

xlsx_path = sys.argv[1]
sheet_name = sys.argv[2]
cells = sys.argv[3:]

wb = load_workbook(xlsx_path, data_only=True, read_only=True)
if sheet_name not in wb.sheetnames:
    raise SystemExit(f"Error: sheet not found: {sheet_name}. Available: {', '.join(wb.sheetnames)}")

ws = wb[sheet_name]

def clean(v):
    if v is None:
        return ""
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v).strip().replace(" ", "")
    if s.startswith("$"):
        s = s[1:]
    return s

for c in cells:
    print(clean(ws[c].value))
PY
)

[[ "${#prices[@]}" -eq 5 ]] || die "Expected 5 values, got ${#prices[@]}."

# Validate numeric
for i in "${!prices[@]}"; do
  v="${prices[$i]}"
  [[ -n "$v" ]] || die "Empty cell value at index $i (check sheet/cell refs)."
  [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "Non-numeric cell value '$v' at index $i."
done

TSLA="$(printf "%.2f" "${prices[0]}")"
MSTR="$(printf "%.2f" "${prices[1]}")"
ARKG="$(printf "%.2f" "${prices[2]}")"
CRSP="$(printf "%.2f" "${prices[3]}")"
VAS="$(printf "%.2f" "${prices[4]}")"

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

echo "Prices updated from ODS snapshot ($ODS_FILE) sheet '$SHEET_NAME'."
echo "TSLA=$TSLA  MSTR=$MSTR  ARKG=$ARKG  CRSP=$CRSP  VAS=$VAS"
echo "Date set to $TODAY"
echo "Backup saved as $HTML_FILE.bak"

printf "\nWould you like to push the changes to github and have them pulled down by the vps? (y/n)"

read push
if [ "$push" = "y" ];then
	bash /home/mark/Documents/code/bashScripts/updateMarksch.sh
else
	echo "Okay, we won't push it for you."
fi


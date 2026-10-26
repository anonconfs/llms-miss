#!/usr/bin/env bash
set -euo pipefail

# scripts/claude-autofix.sh
# Interactive demo: ask Claude to produce patches for files matching a pattern,
# let you inspect them, and optionally apply, test, commit, and open a PR.
# 
# NEW: Cost controls and budget management to prevent unexpected Claude API costs

# ==================== COST CONTROL CONFIGURATION ====================

# Maximum file size to send to Claude (in bytes) - prevents huge API costs
MAX_FILE_BYTES=${MAX_FILE_BYTES:-50000}  # 50KB default

# Maximum budget per run (USD) - stops execution when estimate exceeded
BUDGET_PER_RUN_USD=${BUDGET_PER_RUN_USD:-10.00}

# Cost estimation (Claude 3.5 Sonnet pricing as of Nov 2024)
INPUT_COST_PER_1K_TOKENS=0.003   # $3 per million input tokens
OUTPUT_COST_PER_1K_TOKENS=0.015  # $15 per million output tokens

# Rough token estimation: 1 token ≈ 4 characters for code
CHARS_PER_TOKEN=4

# Cost tracking
TOTAL_ESTIMATED_COST=0
COST_LOG_FILE="/tmp/claude-costs-$(date +%s).csv"

# ==================== CORE CONFIGURATION ====================

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$ROOT_DIR"

PATTERN="${1:-sora|sora-client}"   # default pattern to search for
BRANCH="${2:-claude/autofix-$(date +%Y%m%d%H%M%S)}"
DRY_RUN="${CLAUDE_DRY_RUN:-true}"  # default dry-run to true
CLAUDE_CMD="${CLAUDE_CMD:-claude}" # path to claude CLI

echo "🚀 Claude Autofix with Cost Controls"
echo "Root: $ROOT_DIR"
echo "Searching files matching pattern: $PATTERN"
echo "Output branch: $BRANCH"
echo "Dry run: $DRY_RUN"
echo "💰 Budget limit: \$${BUDGET_PER_RUN_USD}"
echo "📄 Max file size: ${MAX_FILE_BYTES} bytes"
echo

# ==================== COST ESTIMATION FUNCTIONS ====================

estimate_tokens() {
    local text_length=$1
    echo $((text_length / CHARS_PER_TOKEN))
}

estimate_cost() {
    local input_tokens=$1
    local output_tokens=$2
    
    # Use bc for decimal arithmetic if available, otherwise use rough calculation
    if command -v bc >/dev/null 2>&1; then
        local input_cost=$(echo "scale=4; $input_tokens * $INPUT_COST_PER_1K_TOKENS / 1000" | bc -l)
        local output_cost=$(echo "scale=4; $output_tokens * $OUTPUT_COST_PER_1K_TOKENS / 1000" | bc -l)
        local total_cost=$(echo "scale=4; $input_cost + $output_cost" | bc -l)
        echo "$total_cost"
    else
        # Fallback calculation for systems without bc
        local cost_estimate=$(( (input_tokens * 3 + output_tokens * 15) / 1000000 ))
        echo "0.$(printf "%04d" $cost_estimate)"
    fi
}

log_cost() {
    local file_path="$1"
    local input_tokens="$2"
    local output_tokens="$3"
    local cost="$4"
    
    # Create CSV header if file doesn't exist
    if [ ! -f "$COST_LOG_FILE" ]; then
        echo "timestamp,file_path,input_tokens,output_tokens,cost_usd" > "$COST_LOG_FILE"
    fi
    
    echo "$(date -Iseconds),$file_path,$input_tokens,$output_tokens,$cost" >> "$COST_LOG_FILE"
}

check_budget() {
    local estimated_cost="$1"
    
    if command -v bc >/dev/null 2>&1; then
        TOTAL_ESTIMATED_COST=$(echo "scale=4; $TOTAL_ESTIMATED_COST + $estimated_cost" | bc -l)
        
        # Compare costs using bc
        if [ "$(echo "$TOTAL_ESTIMATED_COST > $BUDGET_PER_RUN_USD" | bc -l)" -eq 1 ]; then
            echo ""
            echo "💸 BUDGET EXCEEDED!"
            echo "   Current total: \$${TOTAL_ESTIMATED_COST}"
            echo "   Budget limit: \$${BUDGET_PER_RUN_USD}"
            echo "   Cost log: $COST_LOG_FILE"
            echo ""
            echo "Stopping execution to prevent unexpected costs."
            echo "To continue, increase BUDGET_PER_RUN_USD or review the cost log."
            exit 1
        fi
    else
        # Fallback without bc - rough integer check
        echo "⚠️  bc not available, using rough cost estimates"
    fi
}

# ==================== BASIC TOOLS CHECK ====================

# Check basic tools
command -v git >/dev/null || { echo "git not found"; exit 1; }
command -v "$CLAUDE_CMD" >/dev/null || { echo "'$CLAUDE_CMD' not found in PATH. Install Claude CLI."; exit 1; }

# Gather candidate files
mapfile -t FILES < <(git grep -IlE "$PATTERN" || true)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "No files matched pattern. Try another pattern."
  exit 0
fi

echo "Found ${#FILES[@]} files:"
for f in "${FILES[@]}"; do
  echo " - $f"
done
echo

# ==================== COST PRE-CHECK ====================

echo "💰 Estimating costs..."

total_chars=0
file_count=0
oversized_files=0

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        file_size=$(wc -c < "$file")
        
        # Skip files that are too large
        if [ "$file_size" -gt "$MAX_FILE_BYTES" ]; then
            echo "⚠️  Skipping $file (${file_size} bytes > ${MAX_FILE_BYTES} limit)"
            oversized_files=$((oversized_files + 1))
            continue
        fi
        
        total_chars=$((total_chars + file_size))
        file_count=$((file_count + 1))
    fi
done

if [ "$file_count" -eq 0 ]; then
    echo "❌ No files within size limit found"
    exit 1
fi

# Estimate tokens and cost
estimated_input_tokens=$(estimate_tokens $total_chars)
estimated_output_tokens=$((estimated_input_tokens / 2))  # Conservative estimate
estimated_total_cost=$(estimate_cost $estimated_input_tokens $estimated_output_tokens)

echo "📊 Cost estimate:"
echo "   Files to process: $file_count"
if [ "$oversized_files" -gt 0 ]; then
    echo "   Files skipped (too large): $oversized_files"
fi
echo "   Total characters: $total_chars"
echo "   Estimated input tokens: $estimated_input_tokens"
echo "   Estimated output tokens: $estimated_output_tokens"
echo "   Estimated cost: \$${estimated_total_cost}"

# Check if estimated cost exceeds budget
check_budget "$estimated_total_cost"

echo "✅ Cost estimate within budget. Proceeding..."
echo

# Create a working branch
git checkout -b "$BRANCH"

PATCHES_DIR="$(mktemp -d /tmp/claude-patches.XXXXXX)"
echo "Patches will be placed in: $PATCHES_DIR"
echo

# ==================== CLAUDE PROCESSING WITH COST TRACKING ====================

# For each file, ask Claude to generate a git patch
processed_files=0
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    file_size=$(wc -c < "$file")
    
    # Skip oversized files
    if [ "$file_size" -gt "$MAX_FILE_BYTES" ]; then
        continue
    fi
    
    echo "🔄 Processing: $file (${file_size} bytes)"
    
    # Estimate cost for this file
    file_input_tokens=$(estimate_tokens $file_size)
    file_output_tokens=$((file_input_tokens / 2))
    file_cost=$(estimate_cost $file_input_tokens $file_output_tokens)
    
    # Log the cost
    log_cost "$file" "$file_input_tokens" "$file_output_tokens" "$file_cost"
    
    out="$PATCHES_DIR/$(basename "$file").claude.patch"
    
    # Use generate-patch so Claude returns a git-style patch
    # If generate-patch isn't available, fall back to generate-test or review
    if "$CLAUDE_CMD" generate-patch "$file" > "$out" 2>/dev/null; then
        echo "  ✅ patch saved: $out"
        processed_files=$((processed_files + 1))
    else
        echo "  ⚠️  'generate-patch' failed; trying 'claude review' output as hint"
        "$CLAUDE_CMD" review "$file" > "$out".review || true
        echo "  📝 review saved to $out.review"
        rm -f "$out" || true
    fi
done

# ==================== RESULTS SUMMARY ====================

echo ""
echo "📋 Processing complete!"
echo "   Processed files: $processed_files"
echo "   Total estimated cost: \$${estimated_total_cost}"
echo "   Cost log: $COST_LOG_FILE"
echo "   Patches directory: $PATCHES_DIR"

if [ "$processed_files" -eq 0 ]; then
    echo "❌ No patches generated"
    git checkout -
    git branch -D "$BRANCH" || true
    exit 1
fi

echo
echo "Patches generated. Inspect them now:"
ls -1 "$PATCHES_DIR"
echo
echo "Open a patch (less) or use 'git apply --check' to validate."

# ==================== VALIDATION AND INTERACTIVE APPLY ====================

# Validation and interactive apply
for p in "$PATCHES_DIR"/*.patch; do
  [ -e "$p" ] || continue
  echo
  echo "----- $p -----"
  # Sanity-check: is it a proper git patch?
  if git apply --check "$p" 2>/dev/null; then
    echo "✅ Patch appears to apply cleanly (git apply --check OK)."
    echo "Preview head of patch:"
    sed -n '1,200p' "$p" | sed -n '1,40p'
    if [ "$DRY_RUN" = "true" ]; then
      echo "🛡️  DRY_RUN=yes: not applying $p"
    else
      read -p "Apply patch $p? [y/N] " yn
      if [[ "$yn" =~ ^[Yy]$ ]]; then
        git apply "$p"
        echo "✅ Applied $p"
      else
        echo "⏭️  Skipped $p"
      fi
    fi
  else
    echo "❌ Patch did NOT pass git apply --check. Inspect $p manually."
  fi
done

# ==================== POST-APPLY VALIDATION ====================

# If we applied any patches, run tests and optionally commit
if git status --porcelain | grep -q '^'; then
  echo
  echo "Local changes detected."
  if [ "$DRY_RUN" = "true" ]; then
    echo "🛡️  DRY_RUN=yes: not running tests/committing."
    echo "If you want to run tests and commit, run with CLAUDE_DRY_RUN=false"
    echo "Example: CLAUDE_DRY_RUN=false ./scripts/claude-autofix.sh \"$PATTERN\" \"$BRANCH\""
    echo ""
    echo "💰 Cost summary saved to: $COST_LOG_FILE"
    exit 0
  fi

  echo "🧪 Running tests: npm test"
  set +e
  npm test
  TEST_RC=$?
  set -e
  if [ $TEST_RC -ne 0 ]; then
    echo "❌ Tests failed. Inspect changes and fix before committing."
    exit 2
  fi

  git add -A
  git commit -m "feat: Claude-assisted migration from pattern '$PATTERN'

Applied $processed_files patches generated by Claude.
Estimated cost: \$${estimated_total_cost}
Cost log: $COST_LOG_FILE

Generated patches reviewed and applied automatically.
Manual verification recommended."
  
  git push -u origin "$BRANCH"
  echo "✅ Changes pushed to branch $BRANCH"

  # Create PR
  if command -v gh >/dev/null; then
    gh pr create --fill --title "feat(claude): suggested fixes for $PATTERN" --body "Automated suggestions produced by Claude. 

**Cost Summary:**
- Files processed: $processed_files
- Estimated cost: \$${estimated_total_cost}
- Cost log: $COST_LOG_FILE

Please review carefully before merging." || true
    echo "✅ PR created (if GH CLI is configured)."
  else
    echo "gh CLI not found; please open a PR manually for branch $BRANCH"
  fi
else
  echo "No changes applied. Nothing to commit."
fi

echo ""
echo "✅ Done!"
echo "   Patches: $PATCHES_DIR"
echo "   Cost log: $COST_LOG_FILE"
echo "   Total cost: \$${estimated_total_cost}"
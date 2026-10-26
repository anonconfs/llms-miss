#!/bin/bash

# Driver Agent - Test Execution and Implementation Code Generation
# Receives test from Navigator, executes tests, generates implementation using Copilot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Source required functions
source "${SCRIPT_DIR}/state.sh"
source "${SCRIPT_DIR}/agent_loader.sh"
source "${SCRIPT_DIR}/messaging.sh"

# Configuration
TASK_ID="${1:-}"
VENV_DIR="${REPO_ROOT}/.venv"
LOG_FILE="${REPO_ROOT}/.ai-scrum/artifacts/logs/driver-${TASK_ID}.log"

# Setup role-specific models (required for Copilot)
export NAVIGATOR_MODEL="${NAVIGATOR_MODEL:-gpt-5-mini}"
export DRIVER_MODEL="${DRIVER_MODEL:-gpt-5-mini}"
export RESCUE_MODEL="${RESCUE_MODEL:-gpt-5-mini}"
export MANAGER_MODEL="${MANAGER_MODEL:-gpt-5-mini}"

# Validation
if [ -z "$TASK_ID" ]; then
    echo "[DRIVER] Error: TASK_ID not provided" >&2
    return 1 2>/dev/null || exit 1
fi

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Initialize logging
{
    echo "=== Driver Execution Log ==="
    echo "Task ID: $TASK_ID"
    echo "Started at: $(date)"
    echo ""
} > "$LOG_FILE"

# Step 1: Load environment
echo "[DRIVER] Loading environment..." | tee -a "$LOG_FILE"
if ! load_env; then
    echo "[DRIVER] ✗ ERROR: Environment variables not set" | tee -a "$LOG_FILE"
    return 1 2>/dev/null || exit 1
fi
echo "[DRIVER] ✓ Environment loaded" | tee -a "$LOG_FILE"

# Step 2: Receive test from message queue (with retries)
echo "[DRIVER] Receiving test from message queue..." | tee -a "$LOG_FILE"

# Retry loop: Wait up to 60 seconds for test to arrive from Navigator
max_retries=120
retry_count=0
TASK_DATA=""

while [ $retry_count -lt $max_retries ]; do
    TASK_DATA=$(driver_receive_test 2>/dev/null) && break
    
    if [ $retry_count -eq 0 ] || [ $((retry_count % 20)) -eq 0 ]; then
        echo "[DRIVER] Waiting for test (attempt $((retry_count + 1))/$max_retries)..." | tee -a "$LOG_FILE"
    fi
    
    sleep 0.5
    ((retry_count++)) || true
done

if [ -z "$TASK_DATA" ]; then
    echo "[DRIVER] ✗ ERROR: Failed to receive test after 60 seconds" | tee -a "$LOG_FILE"
    driver_send_failure "$TASK_ID" "Failed to receive test from queue" "Timeout after 60 seconds" 2>/dev/null || true
    return 1 2>/dev/null || exit 1
fi

# Extract task data from message
TEST_FILE=$(echo "$TASK_DATA" | jq -r '.params.test_file // ""' | tr -d '\n' | xargs)
LANGUAGE=$(echo "$TASK_DATA" | jq -r '.meta.language // "TypeScript"' | tr -d '\n' | xargs)
SKILL_CONTEXT=$(echo "$TASK_DATA" | jq -r '.meta.skill_context // "jest"' | tr -d '\n' | xargs)
TASK_ID=$(echo "$TASK_DATA" | jq -r '.meta.task_id // ""' | tr -d '\n' | xargs)

# Generate feature_name from task_id
FEATURE_NAME=$(echo "$TASK_ID" | sed 's/-/_/g')

echo "[DRIVER] ✓ Task received (language=${LANGUAGE}, skill=${SKILL_CONTEXT})" | tee -a "$LOG_FILE"
echo "[DRIVER] Test file: $TEST_FILE" | tee -a "$LOG_FILE"

# Step 3: Verify test file exists and is readable
if [ ! -f "$TEST_FILE" ]; then
    echo "[DRIVER] ✗ ERROR: Test file not found: $TEST_FILE" | tee -a "$LOG_FILE"
    driver_send_failure "$TASK_ID" "Test file not found" "File: $TEST_FILE does not exist" 2>/dev/null || true
    return 1 2>/dev/null || exit 1
fi

TEST_CONTENT=$(cat "$TEST_FILE")
echo "[DRIVER] ✓ Test file loaded" | tee -a "$LOG_FILE"

# Step 4: Execute tests to get failure log
echo "[DRIVER] Executing tests..." | tee -a "$LOG_FILE"

# Determine test runner based on language and skill_context
TEST_OUTPUT=""
TEST_RUNNER=""

case "$LANGUAGE" in
    Python)
        TEST_RUNNER="pytest"
        # Activate venv if exists
        if [ -f "${VENV_DIR}/bin/activate" ]; then
            source "${VENV_DIR}/bin/activate"
        fi
        # Ensure project root is on PYTHONPATH so "src" package is importable
        export PYTHONPATH="${REPO_ROOT}:${PYTHONPATH:-}"
        # Run pytest and capture output (allow failures)
        TEST_OUTPUT=$(pytest "$TEST_FILE" -v 2>&1 || true)
        ;;
    TypeScript|JavaScript)
        TEST_RUNNER="jest"
        # Run jest and capture output (allow failures)
        TEST_OUTPUT=$(npm test -- "$TEST_FILE" 2>&1 || true)
        ;;
    *)
        echo "[DRIVER] ⚠ WARNING: Unsupported language: $LANGUAGE" | tee -a "$LOG_FILE"
        TEST_RUNNER="unknown"
        ;;
esac

echo "[DRIVER] ✓ Test execution completed (runner: $TEST_RUNNER)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Test Output:" | tee -a "$LOG_FILE"
echo "$TEST_OUTPUT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Step 5: Determine file extension based on language
case "$LANGUAGE" in
    TypeScript) IMPL_EXT="ts" ;;
    JavaScript) IMPL_EXT="js" ;;
    Python) IMPL_EXT="py" ;;
    Java) IMPL_EXT="java" ;;
    Go) IMPL_EXT="go" ;;
    *) IMPL_EXT="py" ;;
esac

# Step 6: Read task-specific prompt.md if available
echo "[DRIVER] Reading task-specific prompt..." | tee -a "$LOG_FILE"
WORK_DIR=".ai-scrum/work/${TASK_ID}"
PROMPT_FILE="${WORK_DIR}/prompt.md"
PROMPT_CONTENT=""
if [ -f "$PROMPT_FILE" ]; then
    PROMPT_CONTENT=$(cat "$PROMPT_FILE")
    echo "[DRIVER] Loaded prompt.md" | tee -a "$LOG_FILE"
else
    echo "[DRIVER] WARNING: prompt.md not found (continuing with test content only)" | tee -a "$LOG_FILE"
fi

# Update work state
update_work_state "$TASK_ID" "driver_working" null "in-progress" 2>/dev/null || true

# Step 7: Construct Copilot prompt for implementation
echo "[DRIVER] Constructing implementation prompt..." | tee -a "$LOG_FILE"

# Combine task requirements with failing tests
DRIVER_PROMPT=""
if [ -n "$PROMPT_CONTENT" ]; then
    DRIVER_PROMPT="${PROMPT_CONTENT}

---

Failing tests:

${TEST_CONTENT}
"
else
    DRIVER_PROMPT="Failing tests:

${TEST_CONTENT}
"
fi

# Step 8: Call Copilot for implementation
echo "[DRIVER] Calling Copilot for implementation generation..." | tee -a "$LOG_FILE"
GENERATED_CODE=$(ask_agent "driver" "$DRIVER_PROMPT" "$SKILL_CONTEXT" 2>/dev/null || echo "")

if [ -z "$GENERATED_CODE" ]; then
    echo "[DRIVER] ✗ ERROR: Copilot returned empty response" | tee -a "$LOG_FILE"
    driver_send_failure "$TASK_ID" "Copilot code generation failed" "No code generated by Copilot" 2>/dev/null || true
    return 1 2>/dev/null || exit 1
fi

echo "[DRIVER] ✓ Implementation code generated" | tee -a "$LOG_FILE"

# Step 8: Save implementation to src/<feature_name>.<ext>
mkdir -p "${REPO_ROOT}/src"
IMPL_FILE="${REPO_ROOT}/src/${FEATURE_NAME}.${IMPL_EXT}"

# Clean the generated code:
# 1. Remove markdown code blocks (```python, ```js, etc.)
# 2. Remove explanatory text lines (starting with common explanation patterns)
# 3. Keep actual code
CLEANED_CODE=$(echo "$GENERATED_CODE" | \
    sed '/^```/d' | \
    grep -v "^Here" | \
    grep -v "^The " | \
    grep -v "^This " | \
    grep -v "^I " | \
    grep -v "^Output" | \
    grep -v "^Complete" | \
    grep -v "^Implementation" | \
    grep -v "^[A-Z][a-z]*\.py" | \
    awk 'NF > 0')

# Trim leading/trailing empty lines
CLEANED_CODE=$(echo "$CLEANED_CODE" | sed -e '1{/^[[:space:]]*$/d;}' -e '$!N;/^\(.*\)\n\1$/!P;D')

echo "$CLEANED_CODE" > "$IMPL_FILE"
echo "[DRIVER] ✓ Implementation saved to: $IMPL_FILE" | tee -a "$LOG_FILE"

# Step 9: Verify implementation file
if [ ! -f "$IMPL_FILE" ] || [ ! -s "$IMPL_FILE" ]; then
    echo "[DRIVER] ✗ ERROR: Implementation file not created or empty" | tee -a "$LOG_FILE"
    driver_send_failure "$TASK_ID" "Implementation file creation failed" "File: $IMPL_FILE not created or is empty" 2>/dev/null || true
    return 1 2>/dev/null || exit 1
fi

# Step 10: Git add and commit
echo "[DRIVER] Committing implementation to Git..." | tee -a "$LOG_FILE"
(
    cd "$REPO_ROOT"
    git add "$IMPL_FILE"
    git commit -m "feat: implement ${FEATURE_NAME} for task ${TASK_ID}" || true
) 2>/dev/null || echo "[DRIVER] Warning: git commit skipped" | tee -a "$LOG_FILE"

# Step 11: Send implementation to Navigator
echo "[DRIVER] Sending implementation to Navigator..." | tee -a "$LOG_FILE"
driver_send_implementation "$TASK_ID" "$IMPL_FILE" "" "" "$LANGUAGE" "$SKILL_CONTEXT" 2>/dev/null

echo "[DRIVER] ✓ Implementation sent to Navigator" | tee -a "$LOG_FILE"

# Complete
echo "" | tee -a "$LOG_FILE"
echo "[DRIVER] ✓ Task completed successfully" | tee -a "$LOG_FILE"
echo "Generated implementation file: $IMPL_FILE" | tee -a "$LOG_FILE"

# Cleanup - deactivate venv if activated
if [ -n "${VIRTUAL_ENV:-}" ]; then
    deactivate
fi

return 0 2>/dev/null || exit 0

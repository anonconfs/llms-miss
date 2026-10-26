#!/bin/bash

# NOVELI.SH - GitHub Copilot Claude 4 Hello World E2E Test Script
# AI Native Interactive Storytelling Platform
# Automated testing for Scrum Master → GitHub Copilot Claude 4 Agent pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STORY_NUMBER=92  # The GitHub Copilot Claude 4 Hello World E2E story we just created
PROJECT_ID=2
OWNER="didgugoluke"
REPO="liminal-transit"
EXPECTED_BRANCH_PREFIX="copilot-claude4-hello-world-"
EXPECTED_FILE="src/copilot-hello/index.ts"

echo -e "${BLUE}🤖 GITHUB COPILOT CLAUDE 4 HELLO WORLD E2E TEST${NC}"
echo "=================================================="
echo "Story: #${STORY_NUMBER} (GitHub Copilot Claude 4 Hello World E2E)"
echo "Project: ${PROJECT_ID}"
echo "Expected file: ${EXPECTED_FILE}"
echo ""

# Function to wait for workflow completion with live monitoring
wait_for_workflow() {
    local workflow=$1
    local timeout=${2:-120}
    local start_time=$(date +%s)
    local last_log_line=""
    local run_id=""
    
    echo -e "${YELLOW}⏳ Waiting for ${workflow} to start...${NC}"
    
    # Wait for workflow to start and get run ID
    local attempts=0
    while [ $attempts -lt 12 ]; do  # 60 seconds max wait for start
        run_id=$(gh run list --workflow="${workflow}" --limit=1 --json databaseId,status --jq 'if .[0].status == "in_progress" or .[0].status == "queued" then .[0].databaseId else empty end' 2>/dev/null || echo "")
        if [ -n "$run_id" ]; then
            break
        fi
        echo -n "."
        sleep 5
        attempts=$((attempts + 1))
    done
    
    if [ -z "$run_id" ]; then
        echo -e "${RED}❌ ${workflow} did not start within expected time${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}📋 Monitoring ${workflow} (Run ID: ${run_id})${NC}"
    echo "=============================="
    
    while true; do
        local status=$(gh run list --workflow="${workflow}" --limit=1 --json status --jq '.[0].status' 2>/dev/null || echo "unknown")
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$status" = "completed" ]; then
            local conclusion=$(gh run list --workflow="${workflow}" --limit=1 --json conclusion --jq '.[0].conclusion')
            echo ""
            echo "=============================="
            if [ "$conclusion" = "success" ]; then
                echo -e "${GREEN}✅ ${workflow} completed successfully${NC}"
                return 0
            else
                echo -e "${RED}❌ ${workflow} failed with conclusion: ${conclusion}${NC}"
                return 1
            fi
        elif [ "$status" = "in_progress" ] || [ "$status" = "queued" ]; then
            # Get recent logs and show new lines
            local recent_logs=$(gh run view "${run_id}" --log 2>/dev/null | tail -5 | grep -v "^$" || echo "")
            if [ -n "$recent_logs" ] && [ "$recent_logs" != "$last_log_line" ]; then
                echo "$recent_logs" | while IFS= read -r line; do
                    if [ -n "$line" ]; then
                        # Clean up the log line for better display
                        local clean_line=$(echo "$line" | sed 's/^.*[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\.[0-9]*Z[[:space:]]*//' | sed 's/^[[:space:]]*//')
                        if [ -n "$clean_line" ] && [[ ! "$clean_line" =~ ^(shell:|env:|\|\||##\[) ]]; then
                            # Color code different types of messages
                            if [[ "$clean_line" =~ ✅|✓|SUCCESS|completed.successfully|Pull.request.created ]]; then
                                echo -e "${GREEN}${clean_line}${NC}"
                            elif [[ "$clean_line" =~ ❌|✗|ERROR|FAILED|Failed|failed ]]; then
                                echo -e "${RED}${clean_line}${NC}"
                            elif [[ "$clean_line" =~ ⚠️|WARNING|warning ]]; then
                                echo -e "${YELLOW}${clean_line}${NC}"
                            elif [[ "$clean_line" =~ 🔄|🚀|📋|🤖|Starting|Triggering|Creating|GitHub.Copilot ]]; then
                                echo -e "${BLUE}${clean_line}${NC}"
                            else
                                echo "${clean_line}"
                            fi
                        fi
                    fi
                done
                last_log_line="$recent_logs"
            fi
            sleep 3
        else
            echo -e "${RED}❌ ${workflow} status: ${status}${NC}"
            return 1
        fi
        
        if [ $elapsed -gt $timeout ]; then
            echo -e "${RED}❌ Timeout waiting for ${workflow}${NC}"
            return 1
        fi
    done
}

# Function to check project status of an issue
check_project_status() {
    local issue_number=$1
    local issue_title=$(gh issue view "$issue_number" --json title --jq '.title')
    
    echo -e "${BLUE}📋 Checking project status for #${issue_number}...${NC}"
    
    # Get project item info
    local project_item=$(gh project item-list "${PROJECT_ID}" --owner "${OWNER}" --format json 2>/dev/null | jq --arg title "$issue_title" '.items[] | select(.content.title == $title)' || echo "{}")
    
    if [ -n "$project_item" ] && [ "$project_item" != "{}" ]; then
        local status=$(echo "$project_item" | jq -r '.status // "No Status"')
        local item_id=$(echo "$project_item" | jq -r '.id')
        echo "  Title: $issue_title"
        echo "  Status: $status"
        echo "  Item ID: $item_id"
        echo "$status"
    else
        echo "  Issue not found in project"
        echo "Not in project"
    fi
}

# Cached project status check (reduces API calls)
cached_project_status_check() {
    local issue_number=$1
    local cache_file="/tmp/copilot_project_status_cache_${issue_number}"
    local cache_age=15  # Cache for 15 seconds to reduce API calls
    
    # Check if cache exists and is fresh
    if [ -f "$cache_file" ]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [ $file_age -lt $cache_age ]; then
            echo -e "${YELLOW}📋 Using cached status for #${issue_number}${NC}"
            cat "$cache_file"
            return 0
        fi
    fi
    
    # Cache miss or expired - check rate limits before fetch
    if ! scripts/github-rate-limit-manager.sh check-graphql "project status check" 50; then
        echo -e "${YELLOW}⚠️ Rate limited - using last known status${NC}"
        if [ -f "$cache_file" ]; then
            cat "$cache_file"
        else
            echo "No Status"
        fi
        return 0
    fi
    
    # Fetch fresh data
    local status=$(check_project_status "$issue_number")
    echo "$status" > "$cache_file"
    echo "$status"
}

# Function to check recent webhook deliveries (to diagnose workflow_dispatch issues)
check_webhook_deliveries() {
    echo -e "${BLUE}🔗 Checking recent webhook deliveries...${NC}"
    
    # Get recent workflow runs with timestamps
    echo "Recent workflow runs in the last 5 minutes:"
    local cutoff_time=$(date -d "5 minutes ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -v-5M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
    
    if [ -n "$cutoff_time" ]; then
        gh run list --limit=20 --json workflowName,createdAt,event,status,conclusion | \
        jq --arg cutoff "$cutoff_time" '.[] | select(.createdAt > $cutoff) | "\(.workflowName) | \(.event) | \(.createdAt) | \(.status) | \(.conclusion // "null")"' -r | \
        while read -r line; do
            echo "  $line"
        done
    else
        echo "  (Could not determine cutoff time, showing last 5 runs)"
        gh run list --limit=5 --json workflowName,createdAt,event,status,conclusion | \
        jq '.[] | "\(.workflowName) | \(.event) | \(.createdAt) | \(.status) | \(.conclusion // "null")"' -r | \
        while read -r line; do
            echo "  $line"
        done
    fi
}

# Function to monitor project status changes
monitor_project_status() {
    local story_number=$1
    local timeout=${2:-60}
    local start_time=$(date +%s)
    
    echo -e "${YELLOW}👀 Monitoring project status changes for Story #${story_number}...${NC}"
    
    local initial_status=$(cached_project_status_check "$story_number")
    echo "Initial status: $initial_status"
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            echo -e "${RED}⏰ Timeout monitoring project status${NC}"
            break
        fi
        
        local current_status=$(cached_project_status_check "$story_number")
        if [ "$current_status" != "$initial_status" ]; then
            echo -e "${GREEN}📊 Status changed: ${initial_status} → ${current_status}${NC}"
            
            # Check for key workflow transitions
            if [ "$current_status" = "Todo" ] && [ "$initial_status" != "Todo" ]; then
                echo -e "${GREEN}✅ Scrum Master moved story to Todo - ready for GitHub Copilot Agent${NC}"
            elif [ "$current_status" = "In Progress" ] && [ "$initial_status" = "Todo" ]; then
                echo -e "${GREEN}🤖 GitHub Copilot Agent processing the story (Todo → In Progress)${NC}"
                echo -e "${GREEN}✅ Kanban workflow progression detected - continuing test${NC}"
                return 0
            elif [ "$current_status" = "Done" ]; then
                echo -e "${GREEN}🎉 Story completed (moved to Done)${NC}"
                return 0
            fi
            
            initial_status="$current_status"
        else
            echo -n "."
        fi
        
        sleep 10  # Wait 10 seconds between checks to reduce API rate limiting
        
        sleep 5
    done
    
    echo ""
}

check_workflow_outcome() {
    local workflow=$1
    echo -e "${BLUE}📊 Checking ${workflow} outcome...${NC}"
    
    local run_id=$(gh run list --workflow="${workflow}" --limit=1 --json databaseId --jq '.[0].databaseId')
    local conclusion=$(gh run list --workflow="${workflow}" --limit=1 --json conclusion --jq '.[0].conclusion')
    
    echo "Run ID: ${run_id}"
    echo "Conclusion: ${conclusion}"
    
    if [ "$conclusion" = "success" ]; then
        echo -e "${GREEN}✅ ${workflow} succeeded${NC}"
        return 0
    else
        echo -e "${RED}❌ ${workflow} failed${NC}"
        echo "Recent log entries:"
        gh run view "${run_id}" --log | grep -E "Error|Failed|❌|⚠️" | tail -5 || echo "No obvious errors found"
        return 1
    fi
}

# Function to reset everything for Copilot agent testing
reset_copilot_hello_world() {
    echo -e "${YELLOW}🔄 RESETTING COPILOT HELLO WORLD TEST ENVIRONMENT${NC}"
    echo "=================================================="
    
    # 1. Clean up branches (Copilot agent creates timestamped branches)
    echo -e "${BLUE}🧹 Cleaning up Copilot agent branches...${NC}"
    git fetch origin >/dev/null 2>&1 || true
    
    # Delete local branches with Copilot prefix
    git branch | grep -E "${EXPECTED_BRANCH_PREFIX}" | while read -r branch; do
        if [ -n "$branch" ]; then
            branch=$(echo "$branch" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            echo "Deleting local branch: ${branch}"
            git branch -D "${branch}" >/dev/null 2>&1 || true
        fi
    done
    
    # Delete remote branches with Copilot prefix
    git branch -r | grep -E "origin/${EXPECTED_BRANCH_PREFIX}" | while read -r branch; do
        if [ -n "$branch" ]; then
            remote_branch=$(echo "$branch" | sed 's/origin\///')
            echo "Deleting remote branch: ${remote_branch}"
            git push origin --delete "${remote_branch}" >/dev/null 2>&1 || true
        fi
    done
    
    echo -e "${GREEN}✅ Copilot agent branches cleaned${NC}"
    
    # 2. Clean up generated files from previous Copilot runs
    echo -e "${BLUE}🗑️ Cleaning up Copilot-generated files...${NC}"
    
    # Switch to main branch to ensure we're not on copilot branch when deleting files
    git checkout main >/dev/null 2>&1 || true
    
    # Check if Copilot Hello World files exist from previous runs
    files_to_delete=()
    if [ -f "${EXPECTED_FILE}" ]; then
        files_to_delete+=("${EXPECTED_FILE}")
    fi
    if [ -d "src/copilot-hello" ] && [ -z "$(ls -A src/copilot-hello 2>/dev/null)" ]; then
        files_to_delete+=("src/copilot-hello/")
    fi
    
    if [ ${#files_to_delete[@]} -gt 0 ]; then
        echo "Deleting files from previous Copilot Hello World E2E runs:"
        for file in "${files_to_delete[@]}"; do
            echo "  - $file"
            if [ -d "$file" ]; then
                rm -rf "$file"
            else
                rm -f "$file"
            fi
        done
        
        # Stage and commit the deletions
        git add . >/dev/null 2>&1 || true
        
        # Check if there are changes to commit
        if ! git diff --staged --quiet 2>/dev/null; then
            echo "Committing Copilot file cleanup..."
            git commit -m "🧹 Copilot E2E Test Cleanup: Remove GitHub Copilot generated files

- Delete generated TypeScript modules from previous Copilot agent run
- Prepare clean state for fresh GitHub Copilot Claude 4 E2E test
- Auto-cleanup by copilot-hello-world-e2e-test.sh script" >/dev/null 2>&1 || true
            
            # Push the cleanup commit
            git push origin main >/dev/null 2>&1 || true
            echo "✅ Copilot file deletions committed and pushed"
        else
            echo "No Copilot files to clean up"
        fi
    else
        echo "No GitHub Copilot files found to clean up"
    fi
    
    echo -e "${GREEN}✅ Copilot files cleaned${NC}"
    
    # 3. Reset issue to open state
    echo -e "${BLUE}📝 Resetting Copilot story state...${NC}"
    
    # Ensure story is open
    local story_state=$(gh issue view "${STORY_NUMBER}" --json state --jq '.state')
    if [ "$story_state" = "CLOSED" ]; then
        echo "Reopening Copilot story #${STORY_NUMBER}"
        gh issue reopen "${STORY_NUMBER}" >/dev/null 2>&1 || true
    else
        echo "Copilot story #${STORY_NUMBER} already open"
    fi
    
    echo -e "${GREEN}✅ Copilot issue reset${NC}"
    
    # 4. Remove from project (so Scrum Master can add fresh)
    echo -e "${BLUE}📋 Cleaning Copilot project items...${NC}"
    
    # Find and remove story from project
    local project_items=$(gh project item-list "${PROJECT_ID}" --owner "${OWNER}" --format json 2>/dev/null | jq -r --arg title "🤖 GitHub Copilot Claude 4 Hello World E2E" '.items[] | select(.content.title == $title) | .id' || echo "")
    
    if [ -n "$project_items" ]; then
        echo "$project_items" | while read -r item_id; do
            if [ -n "$item_id" ] && [ "$item_id" != "null" ]; then
                echo "Removing Copilot story from project (item: ${item_id})"
                gh project item-delete "${PROJECT_ID}" --owner "${OWNER}" --id "${item_id}" >/dev/null 2>&1 || true
            fi
        done
    else
        echo "Copilot story not found in project"
    fi
    
    echo -e "${GREEN}✅ Copilot project cleaned${NC}"
    
    # 5. Close any existing Copilot PRs
    echo -e "${BLUE}🔀 Cleaning Copilot pull requests...${NC}"
    local prs=$(gh pr list --json number,headRefName | jq -r --arg prefix "$EXPECTED_BRANCH_PREFIX" '.[] | select(.headRefName | startswith($prefix)) | .number' || echo "")
    if [ -n "$prs" ]; then
        echo "$prs" | while read -r pr_number; do
            if [ -n "$pr_number" ]; then
                echo "Closing Copilot PR #${pr_number}"
                gh pr close "${pr_number}" >/dev/null 2>&1 || true
            fi
        done
    else
        echo "No Copilot PRs to clean"
    fi
    
    echo -e "${GREEN}✅ Copilot PRs cleaned${NC}"
    
    # 6. Sync with remote
    echo -e "${BLUE}🔄 Syncing with remote...${NC}"
    git checkout main >/dev/null 2>&1 || true
    git pull origin main >/dev/null 2>&1 || true
    
    # Clean up cache files
    rm -f /tmp/copilot_project_status_cache_* 2>/dev/null || true
    
    echo -e "${GREEN}✅ COPILOT RESET COMPLETE${NC}"
    echo ""
}

# Function to run the Copilot E2E test
run_copilot_e2e_test() {
    echo -e "${YELLOW}🚀 RUNNING COPILOT E2E TEST${NC}"
    echo "=================================================="
    
    # Trigger Scrum Master with handoff_to_copilot action
    echo -e "${BLUE}1️⃣ Triggering Scrum Master (handoff to Copilot)...${NC}"
    gh workflow run scrum-master-agent.yml -f story_number="${STORY_NUMBER}" -f action="handoff_to_copilot"
    
    if ! wait_for_workflow "scrum-master-agent.yml" 60; then
        echo -e "${RED}❌ Scrum Master failed${NC}"
        check_workflow_outcome "scrum-master-agent.yml"
        return 1
    fi
    
    echo -e "${GREEN}✅ Scrum Master completed${NC}"
    
    # Wait a moment for the Copilot agent trigger
    echo -e "${BLUE}2️⃣ Checking if GitHub Copilot Claude 4 Agent was triggered...${NC}"
    echo "Waiting for GitHub Copilot Agent trigger..."
    sleep 15
    
    # Look for a recent GitHub Copilot Claude 4 Agent run
    local latest_copilot_run=$(gh run list --workflow="🤖 GitHub Copilot Claude 4 Agent" --limit=1 --json createdAt,status,databaseId --jq '.[0]' 2>/dev/null || echo "{}")
    local copilot_created_at=$(echo "$latest_copilot_run" | jq -r '.createdAt // empty')
    local copilot_status=$(echo "$latest_copilot_run" | jq -r '.status // empty')
    local copilot_run_id=$(echo "$latest_copilot_run" | jq -r '.databaseId // empty')
    
    # Check if there's a recent run (within last 3 minutes)
    if [ -n "$copilot_created_at" ]; then
        local copilot_timestamp=$(date -d "$copilot_created_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$copilot_created_at" +%s 2>/dev/null || echo "0")
        local current_timestamp=$(date +%s)
        local time_diff=$((current_timestamp - copilot_timestamp))
        
        if [ $time_diff -lt 180 ]; then  # Less than 3 minutes old
            echo -e "${GREEN}✅ GitHub Copilot Claude 4 Agent was triggered (Run ID: ${copilot_run_id})${NC}"
            echo "Status: ${copilot_status}"
            
            if [ "$copilot_status" = "in_progress" ] || [ "$copilot_status" = "queued" ]; then
                echo ""
                if ! wait_for_workflow "🤖 GitHub Copilot Claude 4 Agent" 240; then
                    echo -e "${RED}❌ GitHub Copilot Claude 4 Agent failed${NC}"
                    check_workflow_outcome "🤖 GitHub Copilot Claude 4 Agent"
                    return 1
                fi
            elif [ "$copilot_status" = "completed" ]; then
                local copilot_conclusion=$(gh run list --workflow="🤖 GitHub Copilot Claude 4 Agent" --limit=1 --json conclusion --jq '.[0].conclusion')
                if [ "$copilot_conclusion" = "success" ]; then
                    echo -e "${GREEN}✅ GitHub Copilot Claude 4 Agent completed successfully${NC}"
                else
                    echo -e "${RED}❌ GitHub Copilot Claude 4 Agent failed${NC}"
                    check_workflow_outcome "🤖 GitHub Copilot Claude 4 Agent"
                    return 1
                fi
            fi
        else
            echo -e "${RED}❌ No recent GitHub Copilot Claude 4 Agent run found${NC}"
            echo "Latest run was $(($time_diff / 60)) minutes ago"
            check_workflow_outcome "scrum-master-agent.yml"
            return 1
        fi
    else
        echo -e "${RED}❌ GitHub Copilot Claude 4 Agent was not triggered${NC}"
        check_workflow_outcome "scrum-master-agent.yml"
        return 1
    fi
    
    echo -e "${GREEN}✅ COPILOT E2E TEST PHASE COMPLETE${NC}"
    echo ""
}

# Function to validate Copilot outcomes
validate_copilot_outcomes() {
    echo -e "${YELLOW}🔍 VALIDATING COPILOT OUTCOMES${NC}"
    echo "=================================================="
    
    local success=true
    
    # Check if Copilot branch was created (timestamped format)
    echo -e "${BLUE}📂 Checking Copilot branch creation...${NC}"
    git fetch origin >/dev/null 2>&1 || true
    local copilot_branch=$(git branch -r | grep -E "origin/${EXPECTED_BRANCH_PREFIX}" | head -1 | sed 's/origin\///' | sed 's/^[[:space:]]*//')
    
    if [ -n "$copilot_branch" ]; then
        echo -e "${GREEN}✅ Copilot branch ${copilot_branch} created${NC}"
    else
        echo -e "${RED}❌ No Copilot branch with prefix ${EXPECTED_BRANCH_PREFIX} found${NC}"
        success=false
    fi
    
    # Check if Copilot-specific files were committed
    echo -e "${BLUE}📁 Checking Copilot file creation...${NC}"
    if [ -n "$copilot_branch" ]; then
        local files_created=$(git diff --name-only main origin/${copilot_branch} 2>/dev/null | wc -l || echo "0")
        if [ "$files_created" -gt 0 ]; then
            echo -e "${GREEN}✅ ${files_created} files created by Copilot agent:${NC}"
            git diff --name-only main origin/${copilot_branch} 2>/dev/null | sed 's/^/  - /' || true
            
            # Check for specific expected file
            if git diff --name-only main origin/${copilot_branch} 2>/dev/null | grep -q "${EXPECTED_FILE}"; then
                echo -e "${GREEN}✅ Expected file ${EXPECTED_FILE} created${NC}"
            else
                echo -e "${YELLOW}⚠️ Expected file ${EXPECTED_FILE} not found${NC}"
            fi
        else
            echo -e "${RED}❌ No files were committed by Copilot agent${NC}"
            success=false
        fi
    fi
    
    # Check if Copilot PR was created
    echo -e "${BLUE}🔀 Checking Copilot pull request...${NC}"
    local copilot_pr_count=$(gh pr list --json headRefName | jq -r --arg prefix "$EXPECTED_BRANCH_PREFIX" '.[] | select(.headRefName | startswith($prefix))' | wc -l || echo "0")
    if [ "$copilot_pr_count" -gt 0 ]; then
        local copilot_pr_number=$(gh pr list --json number,headRefName | jq -r --arg prefix "$EXPECTED_BRANCH_PREFIX" '.[] | select(.headRefName | startswith($prefix)) | .number' | head -1)
        echo -e "${GREEN}✅ Copilot pull request #${copilot_pr_number} created${NC}"
        
        # Check PR labels
        local pr_labels=$(gh pr view "${copilot_pr_number}" --json labels | jq -r '.labels[].name' | tr '\n' ' ')
        echo "  Labels: ${pr_labels}"
        
        # Check for expected labels
        if echo "$pr_labels" | grep -q "ai-agent"; then
            echo -e "${GREEN}✅ Expected 'ai-agent' label found${NC}"
        else
            echo -e "${YELLOW}⚠️ Missing 'ai-agent' label${NC}"
        fi
        
        if echo "$pr_labels" | grep -q "hello-world"; then
            echo -e "${GREEN}✅ Expected 'hello-world' label found${NC}"
        else
            echo -e "${YELLOW}⚠️ Missing 'hello-world' label${NC}"
        fi
    else
        echo -e "${RED}❌ No Copilot pull request created${NC}"
        success=false
    fi
    
    # Check workflow run details
    echo -e "${BLUE}🤖 Checking Copilot agent execution details...${NC}"
    local latest_copilot_run=$(gh run list --workflow="🤖 GitHub Copilot Claude 4 Agent" --limit=1 --json conclusion,databaseId --jq '.[0]' 2>/dev/null || echo "{}")
    local copilot_conclusion=$(echo "$latest_copilot_run" | jq -r '.conclusion // empty')
    local copilot_run_id=$(echo "$latest_copilot_run" | jq -r '.databaseId // empty')
    
    if [ "$copilot_conclusion" = "success" ]; then
        echo -e "${GREEN}✅ GitHub Copilot Claude 4 Agent workflow succeeded${NC}"
        echo "  Run ID: ${copilot_run_id}"
        
        # Check for specific success indicators in logs
        local success_logs=$(gh run view "${copilot_run_id}" --log 2>/dev/null | grep -E "✅.*created|Pull request created|TypeScript implementation created" | wc -l || echo "0")
        if [ "$success_logs" -gt 0 ]; then
            echo -e "${GREEN}✅ Success indicators found in logs (${success_logs} entries)${NC}"
        else
            echo -e "${YELLOW}⚠️ Limited success indicators in logs${NC}"
        fi
    else
        echo -e "${RED}❌ GitHub Copilot Claude 4 Agent workflow failed or incomplete${NC}"
        echo "  Conclusion: ${copilot_conclusion}"
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo -e "${GREEN}🎉 ALL COPILOT VALIDATIONS PASSED!${NC}"
        echo ""
        echo -e "${BLUE}🤖 GitHub Copilot Claude 4 Agent E2E Test Summary:${NC}"
        echo "  ✅ Scrum Master → Copilot Agent handoff: Working"
        echo "  ✅ Copilot agent code generation: Working"
        echo "  ✅ Branch creation and commits: Working"
        echo "  ✅ Pull request creation: Working"
        echo "  ✅ Workflow orchestration: Working"
        return 0
    else
        echo -e "${RED}💥 SOME COPILOT VALIDATIONS FAILED${NC}"
        return 1
    fi
}

# Function to show detailed Copilot failure analysis
analyze_copilot_failures() {
    echo -e "${YELLOW}🔬 COPILOT FAILURE ANALYSIS${NC}"
    echo "=================================================="
    
    echo -e "${BLUE}📊 Recent Scrum Master logs:${NC}"
    local scrum_run_id=$(gh run list --workflow="scrum-master-agent.yml" --limit=1 --json databaseId --jq '.[0].databaseId')
    gh run view "${scrum_run_id}" --log | grep -E "✅|❌|⚠️|Error|Failed|Copilot|handoff" | tail -10 || echo "No logs found"
    
    echo ""
    echo -e "${BLUE}📊 Recent GitHub Copilot Claude 4 Agent logs:${NC}"
    local copilot_run_id=$(gh run list --workflow="🤖 GitHub Copilot Claude 4 Agent" --limit=1 --json databaseId --jq '.[0].databaseId')
    gh run view "${copilot_run_id}" --log | grep -E "✅|❌|⚠️|Error|Failed|analysis|files|branch|PR" | tail -15 || echo "No logs found"
    
    echo ""
    echo -e "${BLUE}🔗 Recent workflow triggers:${NC}"
    check_webhook_deliveries
    
    echo ""
    echo -e "${BLUE}🔍 Troubleshooting hints:${NC}"
    echo "  - Check if PROJECT_TOKEN has sufficient permissions"
    echo "  - Verify Scrum Master handoff_to_copilot logic"
    echo "  - Ensure GitHub Copilot Agent workflow syntax is correct"
    echo "  - Check rate limiting issues"
    echo "  - Verify npm dependency installation"
}

# Main execution for Copilot agent testing
main() {
    local action="${1:-full}"
    
    case "$action" in
        "reset")
            reset_copilot_hello_world
            ;;
        "test")
            run_copilot_e2e_test
            ;;
        "validate")
            validate_copilot_outcomes
            ;;
        "analyze")
            analyze_copilot_failures
            ;;
        "full")
            reset_copilot_hello_world
            sleep 2
            if run_copilot_e2e_test; then
                sleep 5
                validate_copilot_outcomes
            else
                echo ""
                analyze_copilot_failures
            fi
            ;;
        *)
            echo "Usage: $0 [reset|test|validate|analyze|full]"
            echo ""
            echo "Commands:"
            echo "  reset    - Reset Copilot Hello World test environment"
            echo "  test     - Run E2E test (Scrum Master → GitHub Copilot Agent)"
            echo "  validate - Validate Copilot outcomes (branches, files, PRs)"
            echo "  analyze  - Show Copilot failure analysis"
            echo "  full     - Run complete Copilot cycle (default)"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"

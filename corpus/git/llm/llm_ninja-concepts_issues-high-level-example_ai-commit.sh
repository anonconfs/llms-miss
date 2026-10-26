#!/bin/bash

# AI-Assisted Commit Message Generator
# Uses OpenAI API to generate conventional commit messages from staged changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 AI-Assisted Commit Message Generator${NC}"
echo ""

# Check if OpenAI API key is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}❌ OPENAI_API_KEY environment variable not set${NC}"
    echo "Please set your OpenAI API key:"
    echo "export OPENAI_API_KEY='your-api-key-here'"
    exit 1
fi

# Check if there are staged changes
if ! git diff --staged --quiet; then
    echo -e "${GREEN}✅ Found staged changes${NC}"
else
    echo -e "${YELLOW}⚠️  No staged changes found${NC}"
    echo "Please stage your changes first:"
    echo "git add <files>"
    exit 1
fi

# Get current branch name to extract issue number
BRANCH_NAME=$(git branch --show-current)
echo "Current branch: $BRANCH_NAME"

# Extract issue number from branch name (e.g., feature/issue-123-description)
ISSUE_NUMBER=""
if [[ $BRANCH_NAME =~ (feature|bugfix|hotfix)/issue-([0-9]+) ]]; then
    ISSUE_NUMBER="${BASH_REMATCH[2]}"
    echo "Detected issue number: #$ISSUE_NUMBER"
fi

# Get the staged diff with intelligent filtering
echo "📊 Analyzing staged changes..."

# Get all staged files
ALL_STAGED_FILES=$(git diff --staged --name-only)
TOTAL_STAGED=$(echo "$ALL_STAGED_FILES" | grep -c . || echo "0")

if [ $TOTAL_STAGED -eq 0 ]; then
    echo -e "${RED}❌ No staged files found${NC}"
    exit 1
fi

echo "Found $TOTAL_STAGED staged files"

# Filter out lock files, node_modules, build artifacts and other problematic files
FILTERED_STAGED=$(echo "$ALL_STAGED_FILES" | grep -v -E "(node_modules/|dist/|build/|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Gemfile\.lock|composer\.lock|\.min\.js|\.min\.css|\.map)$")

# Further filter by gitignore if .gitignore exists
if [ -f ".gitignore" ]; then
    GITIGNORE_FILTERED=$(echo "$FILTERED_STAGED" | git check-ignore --stdin --non-matching 2>/dev/null || echo "$FILTERED_STAGED")
else
    GITIGNORE_FILTERED="$FILTERED_STAGED"
fi

# Remove empty lines
FINAL_FILES=$(echo "$GITIGNORE_FILTERED" | grep -v '^$' || echo "")
FINAL_COUNT=$(echo "$FINAL_FILES" | grep -c . || echo "0")

# Show detailed filtering results
EXCLUDED_COUNT=$((TOTAL_STAGED - FINAL_COUNT))
if [ $EXCLUDED_COUNT -gt 0 ]; then
    echo -e "${YELLOW}📋 Filtered out $EXCLUDED_COUNT files:${NC}"
    
    # Show what was filtered out
    EXCLUDED_FILES=$(echo "$ALL_STAGED_FILES" | grep -v -F "$FINAL_FILES" || echo "")
    if [ ! -z "$EXCLUDED_FILES" ]; then
        LOCK_FILES=$(echo "$EXCLUDED_FILES" | grep -E "(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Gemfile\.lock|composer\.lock)" || echo "")
        BUILD_FILES=$(echo "$EXCLUDED_FILES" | grep -E "(node_modules/|dist/|build/|\.min\.js|\.min\.css|\.map)" || echo "")
        IGNORED_FILES=$(echo "$EXCLUDED_FILES" | grep -v -E "(node_modules/|dist/|build/|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Gemfile\.lock|composer\.lock|\.min\.js|\.min\.css|\.map)" || echo "")
        
        [ ! -z "$LOCK_FILES" ] && echo -e "${YELLOW}  🔒 Lock files: $(echo "$LOCK_FILES" | tr '\n' ' ')${NC}"
        [ ! -z "$BUILD_FILES" ] && echo -e "${YELLOW}  🔧 Build artifacts: $(echo "$BUILD_FILES" | tr '\n' ' ')${NC}"
        [ ! -z "$IGNORED_FILES" ] && echo -e "${YELLOW}  🚫 Ignored files: $(echo "$IGNORED_FILES" | tr '\n' ' ')${NC}"
    fi
fi

if [ $FINAL_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠️  All staged files filtered out, using summary instead${NC}"
    DIFF_OUTPUT=$(git diff --staged --stat)
else
    echo -e "${GREEN}✅ Analyzing $FINAL_COUNT relevant files${NC}"
    
    # Generate diff for relevant files only
    DIFF_OUTPUT=$(echo "$FINAL_FILES" | xargs git diff --staged -- 2>/dev/null || git diff --staged --stat)
    
    # If diff is still too large, use summary
    if [ ${#DIFF_OUTPUT} -gt 8000 ]; then
        echo -e "${YELLOW}⚠️  Large diff detected, using summary...${NC}"
        DIFF_OUTPUT=$(echo "$FINAL_FILES" | xargs git diff --staged --stat -- 2>/dev/null || git diff --staged --stat)
    fi
fi

# Prepare OpenAI API request
SYSTEM_PROMPT="You are an expert developer assistant helping generate conventional commit messages. 

Generate a commit message following these exact conventions:
- Use conventional commit format: type(scope): description
- Types: feat, fix, refactor, docs, test, chore, style, perf, ci
- First line: concise summary (50 chars or less)
- Empty line, then detailed description with bullet points
- Use present tense, imperative mood
- Be specific about what changed and why

Examples of good commit messages:
feat(auth): implement user login system

Add JWT-based authentication with session management
- Create login/logout endpoints  
- Add middleware for route protection
- Implement token refresh mechanism

fix(api): resolve user validation error

Fix email validation regex causing signup failures
- Update regex pattern to handle edge cases
- Add comprehensive email format tests
- Improve error messages for better UX"

USER_PROMPT="Generate a conventional commit message for these staged changes:

Branch: $BRANCH_NAME
$(if [ ! -z "$ISSUE_NUMBER" ]; then echo "Issue: #$ISSUE_NUMBER"; fi)

Staged changes:
$DIFF_OUTPUT

Generate ONLY the commit message text, nothing else."

echo "🧠 Generating commit message with AI..."

# Create JSON payload using jq to properly escape
JSON_PAYLOAD=$(jq -n \
  --arg model "gpt-4.1" \
  --arg system_content "$SYSTEM_PROMPT" \
  --arg user_content "$USER_PROMPT" \
  '{
    model: $model,
    messages: [
      {role: "system", content: $system_content},
      {role: "user", content: $user_content}
    ],
    max_tokens: 500,
    temperature: 0.3
  }')

# Make API request to OpenAI
RESPONSE=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$JSON_PAYLOAD")

# Check if API request was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to connect to OpenAI API${NC}"
    exit 1
fi

# Extract commit message from response
COMMIT_MSG=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -z "$COMMIT_MSG" ] || [ "$COMMIT_MSG" = "null" ]; then
    echo -e "${RED}❌ Failed to generate commit message${NC}"
    echo "API Response:"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

# Add issue closure if issue number detected and not already in message
if [ ! -z "$ISSUE_NUMBER" ] && ! echo "$COMMIT_MSG" | grep -q "Closes #$ISSUE_NUMBER"; then
    COMMIT_MSG="$COMMIT_MSG

Closes #$ISSUE_NUMBER"
fi

# Display generated commit message
echo ""
echo -e "${GREEN}✨ Generated commit message:${NC}"
echo "────────────────────────────────────"
echo "$COMMIT_MSG"
echo "────────────────────────────────────"
echo ""

# Ask for confirmation
read -p "$(echo -e ${YELLOW}Do you want to use this commit message? [Y/n/e]: ${NC})" -n 1 -r
echo
case $REPLY in
    [eE])
        # Edit the commit message
        echo "$COMMIT_MSG" > .git/COMMIT_EDITMSG
        ${EDITOR:-nano} .git/COMMIT_EDITMSG
        COMMIT_MSG=$(cat .git/COMMIT_EDITMSG)
        rm .git/COMMIT_EDITMSG
        ;;
    [nN])
        echo "Commit cancelled."
        exit 0
        ;;
    *)
        # Default to Yes
        ;;
esac

# Create the commit
echo "📝 Creating commit..."
git commit -m "$COMMIT_MSG"

echo ""
echo -e "${GREEN}✅ Commit created successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "• Push your changes: git push origin $BRANCH_NAME"
echo "• Create a pull request: ./scripts/ai-pr.sh"
echo "• Or use the full workflow: ./scripts/ai-workflow.sh"
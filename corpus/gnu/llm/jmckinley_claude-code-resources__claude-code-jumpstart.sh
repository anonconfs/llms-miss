#!/bin/bash

# Claude Code Jumpstart Script
# Automatically sets up your Claude Code environment based on your project
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emoji support (fallback for systems without emoji)
CHECK="✓"
ARROW="→"
WARN="!"

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Claude Code Jumpstart                                  ║
║   80% of the value in 20% of the time                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo "This script will set up your Claude Code environment by asking a few questions."
echo "It takes about 3-5 minutes and creates everything you need to get started."
echo ""
read -p "Press Enter to continue..."
clear

# ============================================================================
# QUESTION 1: User Experience Level
# ============================================================================

echo -e "${GREEN}═══ Question 1/7: Your Experience ═══${NC}"
echo ""
echo "How familiar are you with Claude Code?"
echo ""
echo "  1) Brand new - never used it"
echo "  2) Tried it once or twice"
echo "  3) Used it for a week or two"
echo "  4) Pretty comfortable with it"
echo ""
read -p "Your choice (1-4): " experience_level

case $experience_level in
    1|2) USER_LEVEL="beginner" ;;
    3) USER_LEVEL="intermediate" ;;
    4) USER_LEVEL="advanced" ;;
    *) USER_LEVEL="beginner" ;;
esac

clear

# ============================================================================
# QUESTION 2: Project Type
# ============================================================================

echo -e "${GREEN}═══ Question 2/7: Project Type ═══${NC}"
echo ""
echo "What kind of project are you working on?"
echo ""
echo "  1) Web app (React, Next.js, Vue, etc.)"
echo "  2) API/Backend (Node, Python, Go, etc.)"
echo "  3) Full-stack (Frontend + Backend)"
echo "  4) Mobile app (React Native, Flutter)"
echo "  5) Data/ML (Python, Jupyter, etc.)"
echo "  6) DevOps/Infrastructure"
echo "  7) Other/Not sure"
echo ""
read -p "Your choice (1-7): " project_type_choice

case $project_type_choice in
    1) PROJECT_TYPE="webapp" ;;
    2) PROJECT_TYPE="backend" ;;
    3) PROJECT_TYPE="fullstack" ;;
    4) PROJECT_TYPE="mobile" ;;
    5) PROJECT_TYPE="data" ;;
    6) PROJECT_TYPE="devops" ;;
    *) PROJECT_TYPE="general" ;;
esac

clear

# ============================================================================
# QUESTION 3: Primary Language
# ============================================================================

echo -e "${GREEN}═══ Question 3/7: Primary Language ═══${NC}"
echo ""
echo "What's your primary programming language?"
echo ""
echo "  1) JavaScript/TypeScript"
echo "  2) Python"
echo "  3) Go"
echo "  4) Java/Kotlin"
echo "  5) Ruby"
echo "  6) Rust"
echo "  7) PHP"
echo "  8) Other"
echo ""
read -p "Your choice (1-8): " language_choice

case $language_choice in
    1) PRIMARY_LANG="typescript" ;;
    2) PRIMARY_LANG="python" ;;
    3) PRIMARY_LANG="go" ;;
    4) PRIMARY_LANG="java" ;;
    5) PRIMARY_LANG="ruby" ;;
    6) PRIMARY_LANG="rust" ;;
    7) PRIMARY_LANG="php" ;;
    *) PRIMARY_LANG="other" ;;
esac

clear

# ============================================================================
# QUESTION 4: Project Phase
# ============================================================================

echo -e "${GREEN}═══ Question 4/7: Project Phase ═══${NC}"
echo ""
echo "What phase is your project in?"
echo ""
echo "  1) Just starting (greenfield)"
echo "  2) Actively developing (adding features)"
echo "  3) Maintenance mode (mostly bug fixes)"
echo "  4) Major refactoring planned"
echo ""
read -p "Your choice (1-4): " phase_choice

case $phase_choice in
    1) PROJECT_PHASE="greenfield" ;;
    2) PROJECT_PHASE="active" ;;
    3) PROJECT_PHASE="maintenance" ;;
    4) PROJECT_PHASE="refactor" ;;
    *) PROJECT_PHASE="active" ;;
esac

clear

# ============================================================================
# QUESTION 5: Team Size
# ============================================================================

echo -e "${GREEN}═══ Question 5/7: Team Size ═══${NC}"
echo ""
echo "Are you working solo or with a team?"
echo ""
echo "  1) Solo developer"
echo "  2) Small team (2-5 people)"
echo "  3) Medium team (6-15 people)"
echo "  4) Large team (15+ people)"
echo ""
read -p "Your choice (1-4): " team_choice

case $team_choice in
    1) TEAM_SIZE="solo" ;;
    2) TEAM_SIZE="small" ;;
    3) TEAM_SIZE="medium" ;;
    4) TEAM_SIZE="large" ;;
    *) TEAM_SIZE="solo" ;;
esac

clear

# ============================================================================
# QUESTION 6: Main Pain Points
# ============================================================================

echo -e "${GREEN}═══ Question 6/7: What Do You Need Help With? ═══${NC}"
echo ""
echo "What's your biggest challenge? (Choose up to 2)"
echo ""
echo "  1) Writing boilerplate code"
echo "  2) Writing tests"
echo "  3) Code reviews"
echo "  4) Debugging issues"
echo "  5) Refactoring messy code"
echo "  6) Writing documentation"
echo "  7) Not sure / Everything"
echo ""
read -p "First choice (1-7): " pain1
read -p "Second choice (1-7, or press Enter to skip): " pain2

PAIN_POINTS=""
[[ "$pain1" == "1" || "$pain2" == "1" ]] && PAIN_POINTS="${PAIN_POINTS}boilerplate "
[[ "$pain1" == "2" || "$pain2" == "2" ]] && PAIN_POINTS="${PAIN_POINTS}testing "
[[ "$pain1" == "3" || "$pain2" == "3" ]] && PAIN_POINTS="${PAIN_POINTS}review "
[[ "$pain1" == "4" || "$pain2" == "4" ]] && PAIN_POINTS="${PAIN_POINTS}debugging "
[[ "$pain1" == "5" || "$pain2" == "5" ]] && PAIN_POINTS="${PAIN_POINTS}refactoring "
[[ "$pain1" == "6" || "$pain2" == "6" ]] && PAIN_POINTS="${PAIN_POINTS}docs "
[[ "$pain1" == "7" || "$pain2" == "7" ]] && PAIN_POINTS="general "

clear

# ============================================================================
# QUESTION 7: Existing Project or New
# ============================================================================

echo -e "${GREEN}═══ Question 7/7: Project Status ═══${NC}"
echo ""
echo "Is this an existing project or are you starting fresh?"
echo ""
echo "  1) Existing project (has code already)"
echo "  2) Brand new project (starting from scratch)"
echo ""
read -p "Your choice (1-2): " existing_choice

case $existing_choice in
    1) EXISTING_PROJECT="yes" ;;
    2) EXISTING_PROJECT="no" ;;
    *) EXISTING_PROJECT="yes" ;;
esac

clear

# ============================================================================
# GENERATE CONFIGURATION
# ============================================================================

echo -e "${BLUE}${CHECK} Got it! Creating your customized setup...${NC}"
echo ""
sleep 1

# Create .claude directory
mkdir -p .claude/agents
mkdir -p .claude/commands

echo -e "${GREEN}${CHECK} Created .claude directory structure${NC}"

# ============================================================================
# Generate CLAUDE.md based on answers
# ============================================================================

echo -e "${BLUE}${ARROW} Generating CLAUDE.md...${NC}"

cat > .claude/CLAUDE.md << EOF
# Project: $(basename "$PWD")

## Project Overview
<!-- Update this with your project description -->
This is a $PROJECT_TYPE project in the $PROJECT_PHASE phase.

## Tech Stack

### Primary Language
- **Language**: $(echo $PRIMARY_LANG | sed 's/\b\(.\)/\u\1/')

### Core Technologies
<!-- Add your specific frameworks, databases, etc. -->
EOF

# Add language-specific tech stack
case $PRIMARY_LANG in
    typescript)
        cat >> .claude/CLAUDE.md << 'EOF'
- **Runtime**: Node.js
- **Type System**: TypeScript
- **Package Manager**: npm/yarn/pnpm

### Code Standards
- Use TypeScript strict mode
- Prefer `const` over `let`
- Use async/await over promises chains
- Functions under 50 lines
EOF
        ;;
    python)
        cat >> .claude/CLAUDE.md << 'EOF'
- **Version**: Python 3.10+
- **Package Manager**: pip / poetry

### Code Standards
- Follow PEP 8 style guide
- Use type hints
- Docstrings for all public functions
- Functions under 50 lines
EOF
        ;;
    *)
        cat >> .claude/CLAUDE.md << 'EOF'

### Code Standards
- Follow language-specific best practices
- Keep functions focused and small
- Write self-documenting code
- Add comments for complex logic
EOF
        ;;
esac

# Add project-specific sections
case $PROJECT_TYPE in
    webapp|fullstack)
        cat >> .claude/CLAUDE.md << 'EOF'

### Frontend
- **Framework**: [Your framework]
- **Styling**: [CSS approach]
- **State Management**: [Your solution]

### Testing
- **Unit Tests**: [Your test framework]
- **E2E Tests**: [Your E2E framework]
EOF
        ;;
    backend)
        cat >> .claude/CLAUDE.md << 'EOF'

### API Design
- **Style**: REST / GraphQL / gRPC
- **Authentication**: [Your auth approach]
- **Database**: [Your database]

### Testing
- **Unit Tests**: [Your test framework]
- **Integration Tests**: [Your approach]
EOF
        ;;
esac

cat >> .claude/CLAUDE.md << 'EOF'

## File Organization
<!-- Update with your project structure -->
```
src/
├── [main directories]
└── [key folders]
```

## Development Workflow

### Before Making Changes
1. Check this file for patterns
2. Plan complex features first
3. Write tests for new functionality

### Commands Available
<!-- Add your common commands -->
- `npm run dev` - Start development
- `npm test` - Run tests
- `npm run build` - Production build

## Important Patterns
<!-- Add your specific patterns as you develop them -->

## Current Focus
<!-- Keep this updated with what you're working on -->
Working on: [Current feature]
Next up: [Upcoming work]

---
*Generated by Claude Code Jumpstart*
*Customize this file as your project evolves*
EOF

echo -e "${GREEN}${CHECK} Created CLAUDE.md${NC}"

# ============================================================================
# Select and create agents based on pain points
# ============================================================================

echo -e "${BLUE}${ARROW} Setting up agents for your needs...${NC}"

AGENTS_CREATED=0

# Always create test-agent for intermediate+ or if testing is a pain point
if [[ "$USER_LEVEL" != "beginner" || "$PAIN_POINTS" == *"testing"* ]]; then
    cat > .claude/agents/test-agent.md << 'EOF'
---
name: Test Agent
model: sonnet
allowed-tools: [Read, Bash, Grep, Write]
description: Runs tests and provides detailed failure analysis
---

# Test Agent

You are a testing specialist focused on running tests and diagnosing failures.

## Your Responsibilities
1. Run requested test suites
2. Analyze test failures in detail
3. Suggest fixes for failing tests
4. Report coverage statistics

## Test Commands
- Run tests: `npm test` or `pytest` or equivalent
- Coverage: Look for coverage commands in package.json

## Reporting Format

Always provide:
- ✅ Tests passed: [count]
- ❌ Tests failed: [count]
- Summary of failures with suggested fixes

## Example
```
Test Results:
✅ 45 passed
❌ 2 failed

Failed Tests:
1. UserAuth.test:23 - Expected 200, got 401
   Fix: Check JWT token expiration logic
```
EOF
    echo -e "${GREEN}  ${CHECK} test-agent.md${NC}"
    AGENTS_CREATED=$((AGENTS_CREATED + 1))
fi

# Create code-reviewer for teams or if review is a pain point
if [[ "$TEAM_SIZE" != "solo" || "$PAIN_POINTS" == *"review"* ]]; then
    cat > .claude/agents/code-reviewer.md << 'EOF'
---
name: Code Reviewer
model: sonnet
allowed-tools: [Read, Grep]
description: Reviews code quality, patterns, and best practices
---

# Code Reviewer

You are a senior engineer conducting code reviews.

## Review Focus

### Must Check
- [ ] Security vulnerabilities
- [ ] Error handling
- [ ] Code duplication
- [ ] Performance issues

### Should Check
- [ ] Naming clarity
- [ ] Test coverage
- [ ] Documentation

## Response Format

**Summary**: [Approve / Request Changes / Comment]

**Issues Found**:
🚨 Blocker: [Critical issues]
⚠️  High Priority: [Important issues]
💡 Suggestion: [Nice-to-haves]

**Good Things**: Acknowledge good code
EOF
    echo -e "${GREEN}  ${CHECK} code-reviewer.md${NC}"
    AGENTS_CREATED=$((AGENTS_CREATED + 1))
fi

# Create refactor-agent for refactoring phase or pain point
if [[ "$PROJECT_PHASE" == "refactor" || "$PAIN_POINTS" == *"refactoring"* ]]; then
    cat > .claude/agents/refactor-agent.md << 'EOF'
---
name: Refactor Agent
model: sonnet
allowed-tools: [Read, StrReplace, Grep]
description: Improves code quality without changing behavior
---

# Refactor Agent

You specialize in improving code quality while maintaining functionality.

## Your Rules
- Never change functionality
- All tests must pass before and after
- Make small, incremental changes
- Focus on readability and maintainability

## Look For
- Long functions (>50 lines)
- Code duplication
- Complex conditionals
- Magic numbers/strings
- Unclear naming

## Report Format
**Before**: [Metrics - lines, complexity]
**After**: [Improved metrics]
**Changes**: [What was improved]
EOF
    echo -e "${GREEN}  ${CHECK} refactor-agent.md${NC}"
    AGENTS_CREATED=$((AGENTS_CREATED + 1))
fi

if [[ $AGENTS_CREATED -eq 0 ]]; then
    echo -e "${YELLOW}  ${ARROW} No agents created (will add later as needed)${NC}"
fi

# ============================================================================
# Create starter commands based on project type
# ============================================================================

echo -e "${BLUE}${ARROW} Creating helpful commands...${NC}"

COMMANDS_CREATED=0

# Component command for webapp/fullstack
if [[ "$PROJECT_TYPE" == "webapp" || "$PROJECT_TYPE" == "fullstack" ]]; then
    mkdir -p .claude/commands/frontend
    
    if [[ "$PRIMARY_LANG" == "typescript" ]]; then
        cat > .claude/commands/frontend/component.md << 'EOF'
---
allowed-tools: [Read, Write, StrReplace]
argument-hint: component name (e.g., UserCard)
---

# Create Component

Create a new React component named {{arg}}.

Requirements:
1. TypeScript functional component
2. Props interface above component
3. Styled appropriately for our project
4. Export as default

Location: src/components/{{arg}}/{{arg}}.tsx

Please also create:
- Basic test file
- Include in index.ts if exists
EOF
        echo -e "${GREEN}  ${CHECK} /frontend:component${NC}"
        COMMANDS_CREATED=$((COMMANDS_CREATED + 1))
    fi
fi

# API endpoint command for backend/fullstack
if [[ "$PROJECT_TYPE" == "backend" || "$PROJECT_TYPE" == "fullstack" ]]; then
    mkdir -p .claude/commands/backend
    
    cat > .claude/commands/backend/endpoint.md << 'EOF'
---
allowed-tools: [Read, Write, StrReplace]
argument-hint: endpoint path (e.g., users/profile)
---

# Create API Endpoint

Create a new API endpoint: /api/{{arg}}

Requirements:
1. Follow project API patterns
2. Input validation
3. Error handling
4. Return consistent response format
5. Add integration test

Check CLAUDE.md for our API conventions.
EOF
    echo -e "${GREEN}  ${CHECK} /backend:endpoint${NC}"
    COMMANDS_CREATED=$((COMMANDS_CREATED + 1))
fi

# Test command if testing is a pain point
if [[ "$PAIN_POINTS" == *"testing"* ]]; then
    mkdir -p .claude/commands/testing
    
    cat > .claude/commands/testing/unit.md << 'EOF'
---
allowed-tools: [Read, Write]
argument-hint: file to test (e.g., src/utils/format.ts)
---

# Generate Unit Tests

Create comprehensive unit tests for: {{arg}}

Requirements:
1. Test happy path
2. Test edge cases
3. Test error cases
4. Clear test descriptions
5. Aim for >90% coverage of this file

Use project's test framework (check package.json).
EOF
    echo -e "${GREEN}  ${CHECK} /testing:unit${NC}"
    COMMANDS_CREATED=$((COMMANDS_CREATED + 1))
fi

if [[ $COMMANDS_CREATED -eq 0 ]]; then
    echo -e "${YELLOW}  ${ARROW} No commands created yet${NC}"
fi

# ============================================================================
# Create settings.json
# ============================================================================

echo -e "${BLUE}${ARROW} Creating settings...${NC}"

cat > .claude/settings.json << EOF
{
  "allowedTools": ["Read", "StrReplace", "Write", "Bash", "Grep"],
  "autoAccept": {
    "Read": ["*"]
  },
  "ignorePatterns": [
    "node_modules/**",
    "dist/**",
    "build/**",
    ".next/**",
    "__pycache__/**",
    "*.pyc",
    ".git/**"
  ]
}
EOF

echo -e "${GREEN}${CHECK} Created settings.json${NC}"

# ============================================================================
# Create or update .gitignore
# ============================================================================

if [[ ! -f .gitignore ]]; then
    # Create comprehensive .gitignore for new projects
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
__pycache__/
venv/
env/
.env
.env.local
*.pyc
*.pyo

# Claude Code (keep local settings private)
.claude/settings.json

# IDE
.vscode/
.idea/
*.swp
*.swo
*.sublime-*

# OS
.DS_Store
Thumbs.db
EOF
    echo -e "${GREEN}${CHECK} Created .gitignore${NC}"
elif ! grep -q ".claude/settings.json" .gitignore 2>/dev/null; then
    # Update existing .gitignore
    echo -e "\n# Claude Code (keep local settings private)" >> .gitignore
    echo ".claude/settings.json" >> .gitignore
    echo -e "${GREEN}${CHECK} Updated .gitignore${NC}"
else
    echo -e "${GREEN}${CHECK} .gitignore already configured${NC}"
fi

# ============================================================================
# Generate personalized getting started guide
# ============================================================================

echo ""
echo -e "${BLUE}${ARROW} Creating your personalized guide...${NC}"

cat > .claude/GETTING_STARTED.md << EOF
# Getting Started with Claude Code

**Generated for:** $(echo $PROJECT_TYPE | sed 's/\b\(.\)/\u\1/') project, $USER_LEVEL user
**Date:** $(date +%Y-%m-%d)

---

## What Was Set Up

✅ Created \`.claude/CLAUDE.md\` - Your project context
✅ Created \`.claude/settings.json\` - Configuration
EOF

if [[ $AGENTS_CREATED -gt 0 ]]; then
    echo "✅ Created $AGENTS_CREATED agent(s) in \`.claude/agents/\`" >> .claude/GETTING_STARTED.md
fi

if [[ $COMMANDS_CREATED -gt 0 ]]; then
    echo "✅ Created $COMMANDS_CREATED command(s) in \`.claude/commands/\`" >> .claude/GETTING_STARTED.md
fi

cat >> .claude/GETTING_STARTED.md << EOF

---

## Your Next Steps (10 minutes)

### 1. Customize CLAUDE.md (5 min)

Open \`.claude/CLAUDE.md\` and fill in:
- Your actual tech stack
- Your project structure
- Your common commands
- Your coding patterns

**This file is 80% of success with Claude Code!**

### 2. Try Your First Request (3 min)

\`\`\`bash
claude
EOF

# Suggest first request based on project phase and pain points
if [[ "$PROJECT_PHASE" == "greenfield" ]]; then
    cat >> .claude/GETTING_STARTED.md << 'EOF'
> Create a basic project structure following best practices
EOF
elif [[ "$PAIN_POINTS" == *"testing"* ]]; then
    cat >> .claude/GETTING_STARTED.md << 'EOF'
> @test-agent Analyze current test coverage and suggest improvements
EOF
elif [[ "$PAIN_POINTS" == *"refactoring"* ]]; then
    cat >> .claude/GETTING_STARTED.md << 'EOF'
> Review this codebase and identify top 3 areas for refactoring
EOF
else
    cat >> .claude/GETTING_STARTED.md << 'EOF'
> Help me understand the current project structure and suggest a first feature to implement
EOF
fi

cat >> .claude/GETTING_STARTED.md << 'EOF'
```

### 3. Learn Key Commands (2 min)

Essential commands to know:
- `/status` - Check context usage (run this often!)
- `/help` - See all available commands
- `/clear` - Clear context between features
- `/rewind` - Undo changes if needed

EOF

if [[ $AGENTS_CREATED -gt 0 ]]; then
    cat >> .claude/GETTING_STARTED.md << 'EOF'

Your custom agents:
EOF
    [[ -f .claude/agents/test-agent.md ]] && echo "- \`@test-agent\` - Run and analyze tests" >> .claude/GETTING_STARTED.md
    [[ -f .claude/agents/code-reviewer.md ]] && echo "- \`@code-reviewer\` - Review your code" >> .claude/GETTING_STARTED.md
    [[ -f .claude/agents/refactor-agent.md ]] && echo "- \`@refactor-agent\` - Improve code quality" >> .claude/GETTING_STARTED.md
fi

if [[ $COMMANDS_CREATED -gt 0 ]]; then
    cat >> .claude/GETTING_STARTED.md << 'EOF'

Your custom commands (type / and tab to see them):
EOF
    [[ -f .claude/commands/frontend/component.md ]] && echo "- \`/frontend:component\` - Create new component" >> .claude/GETTING_STARTED.md
    [[ -f .claude/commands/backend/endpoint.md ]] && echo "- \`/backend:endpoint\` - Create API endpoint" >> .claude/GETTING_STARTED.md
    [[ -f .claude/commands/testing/unit.md ]] && echo "- \`/testing:unit\` - Generate unit tests" >> .claude/GETTING_STARTED.md
fi

cat >> .claude/GETTING_STARTED.md << EOF

---

## Tips for Success

### Context Management (Critical!)
- Run \`/status\` frequently
- Clear context at 80%: \`/clear\`
- One feature per conversation

### Planning First
For complex work:
\`\`\`
> Create a detailed plan for [feature]
[Review plan]
> That looks good, implement it
\`\`\`

### Git Workflow
Always use feature branches:
\`\`\`bash
git checkout -b feature/my-feature
# Use Claude Code
git add .
git commit -m "Implement feature"
\`\`\`

### Review Everything
Claude Code is powerful but not perfect:
- Read the diffs
- Test the code
- Security review sensitive parts

---

## Expected Timeline

Based on your experience level ($USER_LEVEL):

EOF

case $USER_LEVEL in
    beginner)
        cat >> .claude/GETTING_STARTED.md << 'EOF'
**Week 1**: Learning curve - same or slower productivity
- Focus: Getting comfortable with the interface
- Goal: Successfully complete 2-3 tasks

**Week 2**: Building habits - 10-20% productivity gain
- Focus: Context management, planning workflow
- Goal: Consistent good practices

**Week 4+**: Steady gains - 20-30% productivity improvement
- Focus: Advanced features as needed
- Goal: Teaching others
EOF
        ;;
    intermediate)
        cat >> .claude/GETTING_STARTED.md << 'EOF'
**Week 1**: Quick ramp-up - 10-15% productivity gain
- Focus: Learning advanced features
- Goal: Integrate into daily workflow

**Week 2-3**: Optimization - 20-30% productivity gain
- Focus: Custom commands, agents
- Goal: Smooth, efficient workflow
EOF
        ;;
esac

cat >> .claude/GETTING_STARTED.md << EOF

---

## Common Mistakes to Avoid

1. **Not updating CLAUDE.md** - This file is critical!
2. **Ignoring context warnings** - Clear at 80%
3. **Working on main branch** - Always use feature branches
4. **Trusting blindly** - Review all generated code
5. **No planning for complex work** - Ask for plans first

---

## Getting Help

**Quick Reference**: See \`claude-code-quick-start.md\` in docs
**Troubleshooting**: Section 19 in main best practices guide
**Commands**: Type \`/help\` in Claude Code

**Community**:
- r/ClaudeCode on Reddit
- Official docs: https://docs.claude.com/claude-code

---

## What to Do Now

1. ✅ Read this file (you're doing it!)
2. ⏭️  Customize .claude/CLAUDE.md (do this now!)
3. ⏭️  Start Claude Code and try first request
4. ⏭️  Bookmark the quick reference guide

**You're ready to go! Have fun and code faster! 🚀**

---

*Generated by Claude Code Jumpstart v1.0*
*Re-run anytime to update your setup*
EOF

echo -e "${GREEN}${CHECK} Created GETTING_STARTED.md${NC}"

# ============================================================================
# Create commit suggestion
# ============================================================================

if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    cat > .claude/COMMIT_THIS.sh << 'EOF'
#!/bin/bash
# Commit your Claude Code configuration to git

echo "Adding Claude Code configuration to git..."

git add .claude/CLAUDE.md
git add .claude/agents/
git add .claude/commands/
git add .claude/GETTING_STARTED.md
git add .gitignore

echo ""
echo "Files staged. Review with: git diff --cached"
echo ""
echo "When ready, commit with:"
echo "  git commit -m 'feat: add Claude Code configuration'"
echo ""
echo "Note: .claude/settings.json is ignored (local settings)"
EOF
    chmod +x .claude/COMMIT_THIS.sh
    echo -e "${GREEN}${CHECK} Created commit helper script${NC}"
fi

# ============================================================================
# FINAL SUMMARY
# ============================================================================

clear

echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🎉 Setup Complete!                                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}═══ What Was Created ═══${NC}"
echo ""
echo "📁 .claude/"
echo "   ├── CLAUDE.md                  ← Your project context (customize this!)"
echo "   ├── GETTING_STARTED.md         ← Your personalized guide (read this next!)"
echo "   ├── settings.json              ← Configuration"

if [[ $AGENTS_CREATED -gt 0 ]]; then
    echo "   ├── agents/"
    [[ -f .claude/agents/test-agent.md ]] && echo "   │   ├── test-agent.md"
    [[ -f .claude/agents/code-reviewer.md ]] && echo "   │   ├── code-reviewer.md"
    [[ -f .claude/agents/refactor-agent.md ]] && echo "   │   └── refactor-agent.md"
fi

if [[ $COMMANDS_CREATED -gt 0 ]]; then
    echo "   └── commands/"
    [[ -d .claude/commands/frontend ]] && echo "       ├── frontend/"
    [[ -d .claude/commands/backend ]] && echo "       ├── backend/"
    [[ -d .claude/commands/testing ]] && echo "       └── testing/"
fi

echo ""
echo -e "${BLUE}═══ Your Next 3 Steps (10 minutes) ═══${NC}"
echo ""
echo -e "${YELLOW}1.${NC} Open ${GREEN}.claude/CLAUDE.md${NC} and customize it (5 min)"
echo -e "   ${ARROW} This file is 80% of your success!"
echo ""
echo -e "${YELLOW}2.${NC} Read ${GREEN}.claude/GETTING_STARTED.md${NC} (3 min)"
echo -e "   ${ARROW} Personalized guide for your project"
echo ""
echo -e "${YELLOW}3.${NC} Start Claude Code and make your first request (2 min)"
echo "   \$ claude"
echo ""

# Personalized first request suggestion
echo -e "${BLUE}═══ Suggested First Request ═══${NC}"
echo ""
if [[ "$PROJECT_PHASE" == "greenfield" ]]; then
    echo '> "Set up the initial project structure following best practices"'
elif [[ "$PAIN_POINTS" == *"testing"* ]]; then
    echo '> "@test-agent Analyze our test coverage and suggest improvements"'
elif [[ "$PAIN_POINTS" == *"refactoring"* ]]; then
    echo '> "Review this codebase and identify the top 3 areas for refactoring"'
else
    echo '> "Help me understand this codebase and suggest a good first feature"'
fi

echo ""
echo -e "${BLUE}═══ Essential Commands ═══${NC}"
echo ""
echo "  /status    - Check context usage (run this often!)"
echo "  /clear     - Clear context between features"
echo "  /rewind    - Undo changes if needed"
echo "  /help      - See all commands"

if [[ $AGENTS_CREATED -gt 0 ]]; then
    echo ""
    echo "  Your agents:"
    [[ -f .claude/agents/test-agent.md ]] && echo "  @test-agent       - Run and analyze tests"
    [[ -f .claude/agents/code-reviewer.md ]] && echo "  @code-reviewer    - Review your code"
    [[ -f .claude/agents/refactor-agent.md ]] && echo "  @refactor-agent   - Improve code quality"
fi

echo ""
echo -e "${BLUE}═══ Remember ═══${NC}"
echo ""
echo "• Week 1: Same/slower (learning curve)"
echo "• Week 2: +10-20% faster"
echo "• Week 4+: +20-30% faster with good habits"
echo ""
echo "• Review all AI code (don't trust blindly!)"
echo "• Use feature branches (git checkout -b feature/X)"
echo "• Clear context at 80% (/status to check)"
echo ""

if [[ -f .claude/COMMIT_THIS.sh ]]; then
    echo -e "${YELLOW}${ARROW} Tip:${NC} Run ${GREEN}./.claude/COMMIT_THIS.sh${NC} to commit your config to git"
    echo ""
fi

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}You're all set! Open .claude/GETTING_STARTED.md next${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

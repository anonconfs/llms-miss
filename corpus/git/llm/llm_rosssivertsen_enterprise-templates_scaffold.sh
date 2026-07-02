#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# scaffold.sh — Interactive CLI for Enterprise Project Generation
# =============================================================================
# Generates new projects from enterprise templates with tier-based features.
# Usage: ./scaffold.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Colors -------------------------------------------------------------------
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}→${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}!${NC} $1"; }
lowercase() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# --- Banner -------------------------------------------------------------------
echo ""
echo "=========================================="
echo "  Enterprise Project Scaffolding CLI"
echo "=========================================="
echo ""

# =============================================================================
# 1. Gather user input
# =============================================================================

# --- Project Name (kebab-case) ------------------------------------------------
while true; do
    read -rp "Project name (kebab-case, e.g. my-cool-app): " PROJECT_NAME
    if [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
        break
    fi
    warn "Invalid name. Use kebab-case (lowercase letters, numbers, hyphens). Must start with a letter."
done

# --- Language -----------------------------------------------------------------
echo ""
info "Select language:"
echo "  1) python"
echo "  2) node"
echo "  3) generic"
read -rp "Language [1/2/3]: " LANG_CHOICE
case "$LANG_CHOICE" in
    1|python)  LANGUAGE="python" ;;
    2|node)    LANGUAGE="node" ;;
    3|generic) LANGUAGE="generic" ;;
    *)         warn "Invalid choice, defaulting to generic."; LANGUAGE="generic" ;;
esac

# --- Tier ---------------------------------------------------------------------
echo ""
info "Select tier:"
echo "  1) lite       — Minimal: .gitignore, README, lint config"
echo "  2) standard   — CI/CD, tests, agent skills, .enterprise.yml"
echo "  3) production — Full: Docker, deploy scripts, all gates"
read -rp "Tier [1/2/3]: " TIER_CHOICE
case "$TIER_CHOICE" in
    1|lite)       TIER="lite" ;;
    2|standard)   TIER="standard" ;;
    3|production) TIER="production" ;;
    *)            warn "Invalid choice, defaulting to lite."; TIER="lite" ;;
esac

# --- Output Directory ---------------------------------------------------------
echo ""
read -rp "Output directory [~/dev/]: " OUTPUT_DIR
OUTPUT_DIR="${OUTPUT_DIR:-~/dev/}"
# Handle tilde expansion
OUTPUT_DIR="${OUTPUT_DIR/#\~/$HOME}"
# Remove trailing slash
OUTPUT_DIR="${OUTPUT_DIR%/}"

# --- AI Provider & Model (standard/production only) ---------------------------
PROVIDER=""
MODEL=""
API_KEY_ENV="LLM_API_KEY"

if [[ "$TIER" == "standard" || "$TIER" == "production" ]]; then
    echo ""
    info "AI Agent Configuration"
    read -rp "AI provider [anthropic]: " PROVIDER
    PROVIDER="${PROVIDER:-anthropic}"
    read -rp "AI model [claude-sonnet-4-20250514]: " MODEL
    MODEL="${MODEL:-claude-sonnet-4-20250514}"
    read -rp "API key env variable [LLM_API_KEY]: " API_KEY_ENV
    API_KEY_ENV="${API_KEY_ENV:-LLM_API_KEY}"
fi

# --- GitHub Repo (standard/production only) -----------------------------------
CREATE_REPO="no"
GH_ORG=""

if [[ "$TIER" == "standard" || "$TIER" == "production" ]]; then
    echo ""
    read -rp "Create GitHub repository? [y/N]: " CREATE_REPO_INPUT
    if [[ "$(lowercase "$CREATE_REPO_INPUT")" == "y" || "$(lowercase "$CREATE_REPO_INPUT")" == "yes" ]]; then
        CREATE_REPO="yes"
        read -rp "GitHub org (leave blank for personal): " GH_ORG
    fi
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=========================================="
info "Project:    $PROJECT_NAME"
info "Language:   $LANGUAGE"
info "Tier:       $TIER"
info "Output:     $OUTPUT_DIR/$PROJECT_NAME"
if [[ "$TIER" != "lite" ]]; then
    info "Provider:   $PROVIDER"
    info "Model:      $MODEL"
    info "API Key:    \$$API_KEY_ENV"
    info "GitHub:     $CREATE_REPO"
fi
echo "=========================================="
echo ""
read -rp "Proceed? [Y/n]: " CONFIRM
if [[ "$(lowercase "$CONFIRM")" == "n" || "$(lowercase "$CONFIRM")" == "no" ]]; then
    warn "Aborted."
    exit 0
fi

# =============================================================================
# 2. Create project directory
# =============================================================================
PROJECT_DIR="$OUTPUT_DIR/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
    warn "Directory $PROJECT_DIR already exists."
    read -rp "Overwrite? [y/N]: " OVERWRITE
    if [[ "$(lowercase "$OVERWRITE")" != "y" && "$(lowercase "$OVERWRITE")" != "yes" ]]; then
        warn "Aborted."
        exit 1
    fi
    rm -rf "$PROJECT_DIR"
fi

mkdir -p "$PROJECT_DIR"
success "Created $PROJECT_DIR"

# =============================================================================
# 3. Copy starter files
# =============================================================================
STARTER_DIR="$SCRIPT_DIR/starters/$LANGUAGE"
if [[ -d "$STARTER_DIR" ]]; then
    cp -r "$STARTER_DIR"/. "$PROJECT_DIR"/
    success "Copied starter files from starters/$LANGUAGE/"
else
    warn "No starter directory found for $LANGUAGE, skipping starter files."
fi

# =============================================================================
# 4. Tier-based files
# =============================================================================

# --- Lite: .gitignore, README, lint config ------------------------------------

# .gitignore
GITIGNORE_SRC="$SCRIPT_DIR/core/docs/GITIGNORE-$LANGUAGE"
if [[ -f "$GITIGNORE_SRC" ]]; then
    cp "$GITIGNORE_SRC" "$PROJECT_DIR/.gitignore"
    success "Added .gitignore for $LANGUAGE"
else
    warn "No GITIGNORE-$LANGUAGE found, creating minimal .gitignore"
    echo -e "*.log\n.env\nnode_modules/\n__pycache__/\n.DS_Store" > "$PROJECT_DIR/.gitignore"
fi

# Lint config (from starters or testing configs)
case "$LANGUAGE" in
    python)
        if [[ -f "$SCRIPT_DIR/core/testing/test-config-python/.flake8" ]]; then
            cp "$SCRIPT_DIR/core/testing/test-config-python/.flake8" "$PROJECT_DIR/"
            success "Added .flake8 lint config"
        fi
        ;;
    node)
        if [[ -f "$SCRIPT_DIR/starters/node/.eslintrc.json" ]]; then
            # Already copied from starter, just confirm
            success "Lint config (.eslintrc.json) included from starter"
        elif [[ -f "$SCRIPT_DIR/core/testing/test-config-node/.eslintrc.json" ]]; then
            cp "$SCRIPT_DIR/core/testing/test-config-node/.eslintrc.json" "$PROJECT_DIR/"
            success "Added .eslintrc.json lint config"
        fi
        ;;
    generic)
        info "No language-specific lint config for generic projects"
        ;;
esac

# --- Standard: CI/CD, test configs, agent skills, .enterprise.yml ------------
if [[ "$TIER" == "standard" || "$TIER" == "production" ]]; then

    # CI/CD pipeline
    PIPELINE_SRC="$SCRIPT_DIR/core/ci-cd/pipeline-$LANGUAGE.yml"
    if [[ -f "$PIPELINE_SRC" ]]; then
        mkdir -p "$PROJECT_DIR/.github/workflows"
        cp "$PIPELINE_SRC" "$PROJECT_DIR/.github/workflows/ci-cd.yml"
        success "Added CI/CD pipeline (.github/workflows/ci-cd.yml)"
    else
        warn "No pipeline-$LANGUAGE.yml found, skipping CI/CD"
    fi

    # Test configs
    TEST_CONFIG_DIR="$SCRIPT_DIR/core/testing/test-config-$LANGUAGE"
    if [[ -d "$TEST_CONFIG_DIR" ]]; then
        for f in "$TEST_CONFIG_DIR"/*; do
            fname="$(basename "$f")"
            # Skip files already copied
            if [[ ! -f "$PROJECT_DIR/$fname" ]]; then
                cp "$f" "$PROJECT_DIR/$fname"
            fi
        done
        success "Added test configs for $LANGUAGE"
    fi

    # Also copy base testing standards
    TEST_BASE_DIR="$SCRIPT_DIR/core/testing/test-config-base"
    if [[ -d "$TEST_BASE_DIR" ]]; then
        for f in "$TEST_BASE_DIR"/*; do
            fname="$(basename "$f")"
            if [[ ! -f "$PROJECT_DIR/$fname" ]]; then
                cp "$f" "$PROJECT_DIR/$fname"
            fi
        done
        success "Added base testing standards"
    fi

    # Agent skills (local)
    LOCAL_SKILLS_DIR="$SCRIPT_DIR/core/agents/local"
    if [[ -d "$LOCAL_SKILLS_DIR" ]]; then
        mkdir -p "$PROJECT_DIR/.claude/skills"
        for f in "$LOCAL_SKILLS_DIR"/*.md; do
            [[ -f "$f" ]] && cp "$f" "$PROJECT_DIR/.claude/skills/"
        done
        success "Added local agent skills (.claude/skills/)"
    fi

    # CI agent workflows
    CI_AGENTS_DIR="$SCRIPT_DIR/core/agents/ci"
    if [[ -d "$CI_AGENTS_DIR" ]]; then
        mkdir -p "$PROJECT_DIR/.github/workflows"
        for f in "$CI_AGENTS_DIR"/*.yml; do
            [[ -f "$f" ]] && cp "$f" "$PROJECT_DIR/.github/workflows/"
        done
        success "Added CI agent workflows (.github/workflows/)"
    fi

    # .enterprise.yml (generated with substitutions)
    ENTERPRISE_TEMPLATE="$SCRIPT_DIR/core/enterprise-template.yml"
    if [[ -f "$ENTERPRISE_TEMPLATE" ]]; then
        sed \
            -e "s|name: \"my-project\"|name: \"$PROJECT_NAME\"|g" \
            -e "s|language: \"python\"|language: \"$LANGUAGE\"|g" \
            -e "s|tier: \"standard\"|tier: \"$TIER\"|g" \
            -e "s|provider: \"anthropic\"|provider: \"$PROVIDER\"|g" \
            -e "s|model: \"claude-sonnet-4-20250514\"|model: \"$MODEL\"|g" \
            -e "s|api_key_env: \"LLM_API_KEY\"|api_key_env: \"$API_KEY_ENV\"|g" \
            "$ENTERPRISE_TEMPLATE" > "$PROJECT_DIR/.enterprise.yml"
        success "Generated .enterprise.yml"
    fi
fi

# --- Production: Dockerfile, .dockerignore, deploy script --------------------
if [[ "$TIER" == "production" ]]; then

    # Dockerfile
    DOCKERFILE_SRC="$SCRIPT_DIR/core/docker/Dockerfile.$LANGUAGE"
    if [[ -f "$DOCKERFILE_SRC" ]]; then
        cp "$DOCKERFILE_SRC" "$PROJECT_DIR/Dockerfile"
        success "Added Dockerfile"
    else
        warn "No Dockerfile.$LANGUAGE found"
    fi

    # .dockerignore
    DOCKERIGNORE_SRC="$SCRIPT_DIR/core/docker/.dockerignore"
    if [[ -f "$DOCKERIGNORE_SRC" ]]; then
        cp "$DOCKERIGNORE_SRC" "$PROJECT_DIR/.dockerignore"
        success "Added .dockerignore"
    fi

    # Deploy script
    DEPLOY_SRC="$SCRIPT_DIR/automation/deploy-template.sh"
    if [[ -f "$DEPLOY_SRC" ]]; then
        mkdir -p "$PROJECT_DIR/scripts"
        cp "$DEPLOY_SRC" "$PROJECT_DIR/scripts/deploy.sh"
        chmod +x "$PROJECT_DIR/scripts/deploy.sh"
        success "Added deploy script (scripts/deploy.sh)"
    fi
fi

# =============================================================================
# 5b. Generate AGENTS.md (all tiers — agent-agnostic standards)
# =============================================================================
AGENTS_TEMPLATE="$SCRIPT_DIR/core/docs/AGENTS-template.md"
if [[ -f "$AGENTS_TEMPLATE" ]]; then
    sed \
        -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{LANGUAGE}}|$LANGUAGE|g" \
        -e "s|{{TIER}}|$TIER|g" \
        "$AGENTS_TEMPLATE" > "$PROJECT_DIR/AGENTS.md"
    success "Generated AGENTS.md (agent-agnostic standards)"
fi

# =============================================================================
# 5c. Generate docs/SESSION_LOG.md and docs/ directory
# =============================================================================
mkdir -p "$PROJECT_DIR/docs"
cat > "$PROJECT_DIR/docs/SESSION_LOG.md" << 'SESSIONEOF'
# Session Log

> This log tracks all working sessions, decisions, discoveries, and action items.
> Update with every meaningful progress point. Newest entries at the top.
> See AGENTS.md for the required entry format.

---

SESSIONEOF
success "Generated docs/SESSION_LOG.md"

# =============================================================================
# 6. Generate CLAUDE.md
# =============================================================================
CLAUDE_TEMPLATE="$SCRIPT_DIR/core/docs/CLAUDE-template.md"
if [[ -f "$CLAUDE_TEMPLATE" ]]; then
    # Determine language-appropriate commands
    case "$LANGUAGE" in
        python)
            COMMANDS_DEV="- \`make dev\` — Start the development server\n- \`pip install -r requirements.txt\` — Install dependencies\n- \`pip install -r requirements-dev.txt\` — Install dev dependencies"
            COMMANDS_TEST="- \`make test\` — Run all tests\n- \`pytest tests/unit\` — Run unit tests only\n- \`pytest tests/e2e\` — Run end-to-end tests\n- \`make lint\` — Run linter (ruff/flake8)"
            COMMANDS_DEPLOY="- \`make deploy\` — Deploy the application\n- \`bash scripts/deploy.sh staging\` — Deploy to staging\n- \`bash scripts/deploy.sh production\` — Deploy to production"
            ARCHITECTURE="Python project using standard src/ layout with pytest for testing."
            ;;
        node)
            COMMANDS_DEV="- \`npm install\` — Install dependencies\n- \`npm run dev\` — Start the development server\n- \`npm run build\` — Build for production"
            COMMANDS_TEST="- \`npm test\` — Run all tests\n- \`npm run test:unit\` — Run unit tests only\n- \`npm run test:e2e\` — Run end-to-end tests\n- \`npm run lint\` — Run ESLint"
            COMMANDS_DEPLOY="- \`npm run deploy\` — Deploy the application\n- \`bash scripts/deploy.sh staging\` — Deploy to staging\n- \`bash scripts/deploy.sh production\` — Deploy to production"
            ARCHITECTURE="Node.js/TypeScript project using src/ layout with Vitest for testing."
            ;;
        generic)
            COMMANDS_DEV="- \`make dev\` — Start the development environment\n- Refer to the project Makefile for available targets"
            COMMANDS_TEST="- \`make test\` — Run tests\n- Configure test commands in the Makefile"
            COMMANDS_DEPLOY="- \`make deploy\` — Deploy the application\n- Configure deployment commands in the Makefile"
            ARCHITECTURE="Generic project. Update this section with your project's architecture details."
            ;;
    esac

    sed \
        -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{LANGUAGE}}|$LANGUAGE|g" \
        -e "s|{{TIER}}|$TIER|g" \
        -e "s|{{COMMANDS_DEV}}|$COMMANDS_DEV|g" \
        -e "s|{{COMMANDS_TEST}}|$COMMANDS_TEST|g" \
        -e "s|{{COMMANDS_DEPLOY}}|$COMMANDS_DEPLOY|g" \
        -e "s|{{ARCHITECTURE}}|$ARCHITECTURE|g" \
        "$CLAUDE_TEMPLATE" > "$PROJECT_DIR/CLAUDE.md"
    success "Generated CLAUDE.md"
fi

# =============================================================================
# 7. Generate README.md
# =============================================================================
README_TEMPLATE="$SCRIPT_DIR/core/docs/README-template.md"
if [[ -f "$README_TEMPLATE" ]]; then
    # Determine language-appropriate README sections
    case "$LANGUAGE" in
        python)
            DESCRIPTION="A Python enterprise project scaffolded with enterprise-templates."
            PREREQUISITES="- Python 3.10+\n- pip\n- make (optional)"
            INSTALL_COMMANDS="\`\`\`bash\npip install -r requirements.txt\npip install -r requirements-dev.txt\n\`\`\`"
            DEV_COMMANDS="\`\`\`bash\nmake dev\n\`\`\`"
            TEST_COMMANDS="\`\`\`bash\nmake test\nmake lint\n\`\`\`"
            DEPLOY_COMMANDS="\`\`\`bash\nbash scripts/deploy.sh staging\nbash scripts/deploy.sh production\n\`\`\`"
            ARCHITECTURE="Standard Python src/ layout with pytest-based testing."
            LICENSE="MIT"
            ;;
        node)
            DESCRIPTION="A Node.js/TypeScript enterprise project scaffolded with enterprise-templates."
            PREREQUISITES="- Node.js 20+\n- npm"
            INSTALL_COMMANDS="\`\`\`bash\nnpm install\n\`\`\`"
            DEV_COMMANDS="\`\`\`bash\nnpm run dev\n\`\`\`"
            TEST_COMMANDS="\`\`\`bash\nnpm test\nnpm run lint\n\`\`\`"
            DEPLOY_COMMANDS="\`\`\`bash\nbash scripts/deploy.sh staging\nbash scripts/deploy.sh production\n\`\`\`"
            ARCHITECTURE="Node.js/TypeScript src/ layout with Vitest-based testing."
            LICENSE="MIT"
            ;;
        generic)
            DESCRIPTION="An enterprise project scaffolded with enterprise-templates."
            PREREQUISITES="- See Makefile for requirements"
            INSTALL_COMMANDS="\`\`\`bash\nmake install\n\`\`\`"
            DEV_COMMANDS="\`\`\`bash\nmake dev\n\`\`\`"
            TEST_COMMANDS="\`\`\`bash\nmake test\n\`\`\`"
            DEPLOY_COMMANDS="\`\`\`bash\nmake deploy\n\`\`\`"
            ARCHITECTURE="Update this section with your project's architecture."
            LICENSE="MIT"
            ;;
    esac

    sed \
        -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{DESCRIPTION}}|$DESCRIPTION|g" \
        -e "s|{{PREREQUISITES}}|$PREREQUISITES|g" \
        -e "s|{{INSTALL_COMMANDS}}|$INSTALL_COMMANDS|g" \
        -e "s|{{DEV_COMMANDS}}|$DEV_COMMANDS|g" \
        -e "s|{{TEST_COMMANDS}}|$TEST_COMMANDS|g" \
        -e "s|{{DEPLOY_COMMANDS}}|$DEPLOY_COMMANDS|g" \
        -e "s|{{ARCHITECTURE}}|$ARCHITECTURE|g" \
        -e "s|{{LICENSE}}|$LICENSE|g" \
        "$README_TEMPLATE" > "$PROJECT_DIR/README.md"
    success "Generated README.md"
fi

# =============================================================================
# 8. Copy CHANGELOG
# =============================================================================
CHANGELOG_SRC="$SCRIPT_DIR/core/docs/CHANGELOG-template.md"
if [[ -f "$CHANGELOG_SRC" ]]; then
    cp "$CHANGELOG_SRC" "$PROJECT_DIR/CHANGELOG.md"
    success "Copied CHANGELOG.md"
else
    # Fallback to documentation directory
    CHANGELOG_SRC="$SCRIPT_DIR/documentation/CHANGELOG-template.md"
    if [[ -f "$CHANGELOG_SRC" ]]; then
        cp "$CHANGELOG_SRC" "$PROJECT_DIR/CHANGELOG.md"
        success "Copied CHANGELOG.md"
    fi
fi

# =============================================================================
# 9. Initialize git repo
# =============================================================================
info "Initializing git repository..."
cd "$PROJECT_DIR"
git init -b main --quiet
git add -A
git commit -m "Initial commit: $PROJECT_NAME ($LANGUAGE, $TIER tier)" --quiet
success "Git repository initialized with initial commit on main"

# Create staging and development branches (standard/production only)
if [[ "$TIER" == "standard" || "$TIER" == "production" ]]; then
    git branch staging
    git branch development
    success "Created staging and development branches"
fi

# =============================================================================
# 10. Optionally create GitHub repo
# =============================================================================
if [[ "$CREATE_REPO" == "yes" ]]; then
    if ! command -v gh &>/dev/null; then
        warn "GitHub CLI (gh) not found. Skipping repository creation."
        warn "Install it with: brew install gh"
    else
        info "Creating GitHub repository..."

        if [[ -n "$GH_ORG" ]]; then
            REPO_FULL="$GH_ORG/$PROJECT_NAME"
            gh repo create "$REPO_FULL" --private --source=. --push 2>/dev/null \
                && success "Created GitHub repo: $REPO_FULL" \
                || warn "Failed to create GitHub repo. You may need to run 'gh auth login' first."
        else
            gh repo create "$PROJECT_NAME" --private --source=. --push 2>/dev/null \
                && success "Created GitHub repo: $PROJECT_NAME" \
                || warn "Failed to create GitHub repo. You may need to run 'gh auth login' first."
        fi

        # Push additional branches
        if [[ "$TIER" == "standard" || "$TIER" == "production" ]]; then
            git push -u origin staging 2>/dev/null || warn "Could not push staging branch"
            git push -u origin development 2>/dev/null || warn "Could not push development branch"
            success "Pushed all branches to remote"
        fi
    fi
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "=========================================="
success "Project $PROJECT_NAME created successfully!"
echo ""
info "Location: $PROJECT_DIR"
info "Language: $LANGUAGE"
info "Tier:     $TIER"
echo ""
info "Next steps:"
echo "  cd $PROJECT_DIR"
if [[ "$LANGUAGE" == "python" ]]; then
    echo "  pip install -r requirements.txt"
    echo "  make dev"
elif [[ "$LANGUAGE" == "node" ]]; then
    echo "  npm install"
    echo "  npm run dev"
else
    echo "  make dev"
fi
echo "=========================================="

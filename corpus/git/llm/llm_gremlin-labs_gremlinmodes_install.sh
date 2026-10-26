#!/bin/bash

# GremlinModes Installation Script
# This script installs the GremlinModes framework into a project directory
# and keeps track of installation history

# Text formatting
BOLD='\033[1m'
GREMLIN='\033[1;38;2;31;204;0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${BOLD}${GREMLIN}"
echo "   ▄▄ • ▄▄▄  ▄▄▄ .• ▌ ▄ ·. ▄▄▌  ▪   ▐ ▄ • ▌ ▄ ·.       ·▄▄▄▄  ▄▄▄ ..▄▄ · "
echo "  ▐█ ▀ ▪▀▄ █·▀▄.▀··██ ▐███▪██•  ██ •█▌▐█·██ ▐███▪▪     ██▪ ██ ▀▄.▀·▐█ ▀. "
echo "  ▄█ ▀█▄▐▀▀▄ ▐▀▀▪▄▐█ ▌▐▌▐█·██▪  ▐█·▐█▐▐▌▐█ ▌▐▌▐█· ▄█▀▄ ▐█· ▐█▌▐▀▀▪▄▄▀▀▀█▄"
echo "  ▐█▄▪▐█▐█•█▌▐█▄▄▌██ ██▌▐█▌▐█▌▐▌▐█▌██▐█▌██ ██▌▐█▌▐█▌.▐▌██. ██ ▐█▄▄▌▐█▄▪▐█"
echo "  ·▀▀▀▀ .▀  ▀ ▀▀▀ ▀▀  █▪▀▀▀.▀▀▀ ▀▀▀▀▀ █▪▀▀  █▪▀▀▀ ▀█▄▀▪▀▀▀▀▀•  ▀▀▀  ▀▀▀▀ "
echo ""
echo -e "${BOLD}${GREMLIN}*** Chaotic code gremlins who bring mischievous vibes to your project. ***${NC}"
echo ""
echo ""

# Determine the directory of the current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make sure .data directory exists
if [ ! -d "$SCRIPT_DIR/.data" ]; then
    mkdir -p "$SCRIPT_DIR/.data"
fi

# Initialize history file if it doesn't exist
if [ ! -f "$SCRIPT_DIR/.data/history.json" ]; then
    echo '{"installations": []}' > "$SCRIPT_DIR/.data/history.json"
fi

# Ask for destination directory
echo -e "${NC}"
read -p "Enter project code directory: " base_dir

if [ -z "$base_dir" ]; then
    base_dir="."
else
    # Expand ~ to home directory if present
    base_dir="${base_dir/#\~/$HOME}"

    # Handle relative paths by converting to absolute paths
    if [[ ! "$base_dir" = /* ]]; then
        base_dir="$(pwd)/$base_dir"
    fi
fi

# Create project directory if it doesn't exist
if [ ! -d "$base_dir" ]; then
    mkdir -p "$base_dir"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Could not create directory $base_dir${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Installing GremlinModes to $base_dir...${NC}"

# Create Directory Structure
echo -e "${BLUE}1. Creating main directories...${NC}"

# Create main GremlinModes directory structure according to documentation standards
mkdir -p "$base_dir/gremlinmodes"
mkdir -p "$base_dir/gremlinmodes/tasks"
mkdir -p "$base_dir/gremlinmodes/bugs"
mkdir -p "$base_dir/gremlinmodes/designs"
mkdir -p "$base_dir/gremlinmodes/audits"
mkdir -p "$base_dir/gremlinmodes/products"
mkdir -p "$base_dir/gremlinmodes/docs"
mkdir -p "$base_dir/gremlinmodes/templates"
mkdir -p "$base_dir/gremlinmodes/inputs"
mkdir -p "$base_dir/gremlinmodes/tests"
mkdir -p "$base_dir/gremlinmodes/marketing"
mkdir -p "$base_dir/gremlinmodes/instructions/global"

# Create .gremlinmodes directory structure
mkdir -p "$base_dir/.gremlinmodes"
mkdir -p "$base_dir/.gremlinmodes/custom-instructions/orchestrator"
mkdir -p "$base_dir/.gremlinmodes/agents"
mkdir -p "$base_dir/.gremlinmodes/backups"  # Added backups directory
mkdir -p "$base_dir/.gremlinmodes/backups/roomodes"  # Added roomodes backup directory

# Create empty config.json file
echo -e "${BLUE}2. Creating config.json template...${NC}"
cat > "$base_dir/.gremlinmodes/config.json" << 'EOFCONFIG'
{
  "project_name": "Your Project Name",
  "preferred_models": {
    "orchestrator": "gpt-4.1-mini",
    "mastermind": "gemini-2.5-flash-preview-04-17",
    "datadigger": "gpt-4.1",
    "sage": "claude-3-7-sonnet-20250219",
    "adept": "gemini-2.5-pro-preview-05-06",
    "sprout": "gpt-4.1-mini",
    "pixelperfect": "claude-3-7-sonnet-20250219",
    "validator": "gpt-4.1-mini"
  },
  "repository_url": "https://github.com/yourusername/yourrepository",
  "task_counter": {
    "tsk": 1,
    "bug": 1,
    "dsn": 1,
    "aud": 1,
    "prd": 1,
    "tst": 1,
    "seo": 1,
    "doc": 1
  },
  "custom_instructions_path": ".gremlinmodes/custom-instructions"
}
EOFCONFIG

# Copy template files
echo -e "${BLUE}3. Copying template files...${NC}"

# Copy template files from the source directory
if [ -d "$SCRIPT_DIR/templates" ]; then
    cp -r "$SCRIPT_DIR/templates/"* "$base_dir/gremlinmodes/templates/"
    echo -e "${GREEN}Copied template files from $SCRIPT_DIR/templates/${NC}"
else
    echo -e "${RED}Warning: Templates directory not found at $SCRIPT_DIR/templates/${NC}"
    echo -e "${YELLOW}Template files will need to be created manually${NC}"
fi

# Copy global instruction files
echo -e "${BLUE}4. Copying global instruction files...${NC}"

# Copy instruction files from the source directory
if [ -d "$SCRIPT_DIR/global-instructions" ]; then
    # Copy the existing global instruction files (01-04)
    if [ -f "$SCRIPT_DIR/global-instructions/01-documentation-standards.md" ]; then
        cp "$SCRIPT_DIR/global-instructions/01-documentation-standards.md" "$base_dir/gremlinmodes/instructions/global/"
    fi
    if [ -f "$SCRIPT_DIR/global-instructions/02-file-management.md" ]; then
        cp "$SCRIPT_DIR/global-instructions/02-file-management.md" "$base_dir/gremlinmodes/instructions/global/"
    fi
    if [ -f "$SCRIPT_DIR/global-instructions/03-cross-references.md" ]; then
        cp "$SCRIPT_DIR/global-instructions/03-cross-references.md" "$base_dir/gremlinmodes/instructions/global/"
    fi
    if [ -f "$SCRIPT_DIR/global-instructions/04-folder-structure.md" ]; then
        cp "$SCRIPT_DIR/global-instructions/04-folder-structure.md" "$base_dir/gremlinmodes/instructions/global/"
    fi
    echo -e "${GREEN}Copied global instruction files from $SCRIPT_DIR/global-instructions/${NC}"
else
    echo -e "${RED}Warning: Global instructions directory not found at $SCRIPT_DIR/global-instructions/${NC}"

    # Check if the artifacts directory exists (for our newly generated instructions)
    if [ -d "$SCRIPT_DIR/artifacts" ]; then
        # Copy the generated instruction files
        if [ -f "$SCRIPT_DIR/artifacts/01-documentation-standards.md" ]; then
            cp "$SCRIPT_DIR/artifacts/01-documentation-standards.md" "$base_dir/gremlinmodes/instructions/global/"
        fi
        if [ -f "$SCRIPT_DIR/artifacts/02-file-management.md" ]; then
            cp "$SCRIPT_DIR/artifacts/02-file-management.md" "$base_dir/gremlinmodes/instructions/global/"
        fi
        if [ -f "$SCRIPT_DIR/artifacts/03-cross-references.md" ]; then
            cp "$SCRIPT_DIR/artifacts/03-cross-references.md" "$base_dir/gremlinmodes/instructions/global/"
        fi
        if [ -f "$SCRIPT_DIR/artifacts/04-folder-structure.md" ]; then
            cp "$SCRIPT_DIR/artifacts/04-folder-structure.md" "$base_dir/gremlinmodes/instructions/global/"
        fi
        echo -e "${GREEN}Copied global instruction files from $SCRIPT_DIR/artifacts/${NC}"
    else
        echo -e "${RED}Warning: Could not find instruction files. Basic placeholders will be created.${NC}"

        # Create placeholder instruction files if no source files are found
        echo "# Documentation Standards" > "$base_dir/gremlinmodes/instructions/global/01-documentation-standards.md"
        echo "# File Management Guidelines" > "$base_dir/gremlinmodes/instructions/global/02-file-management.md"
        echo "# Cross-Reference Guidelines" > "$base_dir/gremlinmodes/instructions/global/03-cross-references.md"
        echo "# Folder Structure Standards" > "$base_dir/gremlinmodes/instructions/global/04-folder-structure.md"
    fi
fi

# Copy GremlinModes README to the gremlinmodes directory
if [ -f "$SCRIPT_DIR/README.md" ]; then
    cp "$SCRIPT_DIR/README.md" "$base_dir/gremlinmodes/"
else
    echo -e "${YELLOW}Warning: Could not find README.md${NC}"
fi

# Create empty custom instruction file
cat > "$base_dir/.gremlinmodes/custom-instructions/orchestrator/01-project-specific.md" << 'EOFCUSTOM'
# Project-Specific Guidelines for Orchestrator

This file contains project-specific instructions for the Orchestrator agent.

## Project Context

[Add project-specific context here]

## Special Considerations

[Add any special considerations for this project]

## Team Structure

[Define the team structure for this project]

## Documentation Requirements

[Add any project-specific documentation requirements]

## Mode Slugs

CRITICAL: Never prompt for mode slugs at runtime. Always use these hardcoded mode slugs when delegating tasks:

- `orchestrator`: The strategic coordinator
- `backend-engineer`: Server-side implementation specialist
- `frontend-engineer`: Client-side implementation specialist
- `designer`: UI/UX design specialist
- `qa-engineer`: Testing and validation specialist
- `documentation-writer`: Documentation specialist
EOFCUSTOM

# Copy agent files if they exist
echo -e "${BLUE}5. Copying agent files...${NC}"
if [ -d "$SCRIPT_DIR/agents" ]; then
    # Count agent files
    agent_count=$(ls -1 "$SCRIPT_DIR/agents/"*.json 2>/dev/null | wc -l)

    if [ "$agent_count" -gt 0 ]; then
        for agent_file in "$SCRIPT_DIR/agents/"*; do
            if [ -f "$agent_file" ]; then
                cp "$agent_file" "$base_dir/.gremlinmodes/agents/"
            fi
        done
        echo -e "${GREEN}Copied $agent_count agent files from $SCRIPT_DIR/agents/${NC}"
    else
        echo -e "${YELLOW}Warning: No agent files found in $SCRIPT_DIR/agents/${NC}"
        echo -e "${YELLOW}You will need to create agent configurations manually${NC}"
    fi
else
    echo -e "${YELLOW}Warning: Could not find agents directory${NC}"
    echo -e "${YELLOW}You will need to create agent configurations manually${NC}"
fi

# Copy agent.sh script
echo -e "${BLUE}6. Copying agent.sh script...${NC}"

# FIXED: Priority order changed to try scripts directory only
if [ -f "$SCRIPT_DIR/scripts/agent.sh" ]; then
    cp "$SCRIPT_DIR/scripts/agent.sh" "$base_dir/"
    chmod +x "$base_dir/agent.sh"
    echo -e "${GREEN}Copied and set executable permissions for agent.sh${NC}"
else
    echo -e "${RED}Error: Could not find scripts/agent.sh${NC}"
    exit 1
fi

# Copy stash.sh script
echo -e "${BLUE}7. Copying stash.sh script...${NC}"
if [ -f "$SCRIPT_DIR/scripts/stash.sh" ]; then
    cp "$SCRIPT_DIR/scripts/stash.sh" "$base_dir/"
    chmod +x "$base_dir/stash.sh"
    echo -e "${GREEN}Copied and set executable permissions for stash.sh${NC}"
else
    echo -e "${YELLOW}Warning: Could not find scripts/stash.sh${NC}"
    echo -e "${YELLOW}The git stash functionality will not be available${NC}"
fi

# Do NOT copy update.sh - it should run from the GremlinModes source directory
echo -e "${BLUE}8. Note about updates...${NC}"
echo -e "${GREEN}The update.sh script should be run from the GremlinModes source directory${NC}"
echo -e "${GREEN}Run: $SCRIPT_DIR/update.sh when updates are needed${NC}"

# Copy backup.sh and restore.sh scripts and make them executable
echo -e "${BLUE}9. Note about backup and restore...${NC}"
echo -e "${GREEN}The backup.sh and restore.sh scripts are available in the GremlinModes source directory${NC}"
echo -e "${GREEN}To backup your GremlinModes files: $SCRIPT_DIR/backup.sh${NC}"
echo -e "${GREEN}To restore from a backup: $SCRIPT_DIR/restore.sh${NC}"

# Ensure backup.sh and restore.sh are executable in the source directory
if [ -f "$SCRIPT_DIR/backup.sh" ]; then
    chmod +x "$SCRIPT_DIR/backup.sh"
fi
if [ -f "$SCRIPT_DIR/restore.sh" ]; then
    chmod +x "$SCRIPT_DIR/restore.sh"
fi

# Create a GremlinModes README in the gremlinmodes directory
echo -e "${BLUE}10. Creating GremlinModes README...${NC}"
if [ ! -f "$base_dir/gremlinmodes/README.md" ]; then
    cat > "$base_dir/gremlinmodes/README.md" << 'EOFREADME'
# GremlinModes Project Structure

This structure has been generated for your GremlinModes implementation.

## Core Principles

The GremlinModes framework is built on these core principles:

1. **Mission-Driven Agent Roles**: Each agent has a clear purpose and passionate domain focus
2. **Documentation Proportionate to Task Type**: Scale documentation based on agent function
3. **Streamlined Sequential Collaboration**: Clear handoffs using hardcoded mode slugs
4. **Status Documentation at Key Points**: Track progress at workflow transition points
5. **Execution over Documentation**: Focus on action, not excessive documentation

## Directory Structure

GremlinModes organizes all agent work within this standardized structure:

```
/gremlinmodes/             # Root folder for all agent documentation
  ├── tasks/               # Development and implementation tasks
  ├── bugs/                # Bug reports and fixes
  ├── designs/             # Design tasks and UI/UX work
  ├── audits/              # Code and system audits
  ├── products/            # Product planning and feature development
  ├── docs/                # Final documentation repository
  ├── tests/               # Testing projects
  ├── marketing/           # Marketing projects (SEO, etc.)
  ├── inputs/              # User-provided task documentation
  └── templates/           # Documentation templates
      ├── status.md        # Status tracking template
      ├── shared-data.md   # Shared data template
      ├── overview.md      # Task overview template
      └── final-report.md  # Final report template

/.gremlinmodes/            # Project-specific configurations
  ├── config.json          # Configuration settings
  ├── custom-instructions/ # Project-specific agent instructions
  ├── backups/             # Backups from updates
  │   └── roomodes/        # Backups of previous agent configurations
  └── agents/              # Agent configuration files
```

## Task Folder Naming Convention

All task folders must follow this pattern:
```
{prefix}-{sequential_number}-{short-descriptive-name}
```

Examples:
- `tsk-023-auth-flow-implementation`
- `bug-011-user-login-failure`
- `dsn-001-dashboard-redesign`

## Agent Workflow

The GremlinModes framework follows a streamlined sequential collaboration pattern:

1. **Orchestrator** → Plans and delegates to first specialized agent
2. **Specialist 1** → Begins work immediately upon activation
3. **Specialist 1** → Completes work, marks status as "Completed"
4. **Orchestrator** → Activates next agent with explicit `new_task` command
5. **Specialist 2** → Begins work immediately upon activation
6. **Specialist 2** → Completes work, marks status as "Completed"
7. **Orchestrator** → Reviews final output, consolidates documentation

## Usage

**Select an Agent**: Choose which agent or team to work with:
```bash
./agent.sh
```

This will activate the selected agent for use with Roo Code.

**Git Workflow**: Temporarily hide GremlinModes files for clean commits:
```bash
./stash.sh  # Hide files before committing
# ... git add, commit, push ...
./stash.sh  # Unhide files after pushing
```

**Update GremlinModes**: Update your existing installation:
```bash
/path/to/gremlinmodes/update.sh
```

The update script will automatically find your installation in the history.

**Backup Your Work**: Create a backup of your GremlinModes files:
```bash
/path/to/gremlinmodes/backup.sh
```

**Restore from Backup**: Restore your GremlinModes files from a previous backup:
```bash
/path/to/gremlinmodes/restore.sh
```

## Documentation Standards

For complete documentation standards, see:
- [Documentation Standards](/gremlinmodes/instructions/global/01-documentation-standards.md)
- [File Management Guidelines](/gremlinmodes/instructions/global/02-file-management.md)
- [Cross-Reference Guidelines](/gremlinmodes/instructions/global/03-cross-references.md)
- [Folder Structure Standards](/gremlinmodes/instructions/global/04-folder-structure.md)
EOFREADME
fi

# Update installation history
echo -e "${BLUE}11. Updating installation history...${NC}"
# Get current date and time
current_datetime=$(date +"%Y-%m-%d %H:%M:%S")

# Format the new installation entry
new_installation="{\"path\":\"$base_dir\",\"date\":\"$current_datetime\",\"type\":\"install\"}"

# Use jq if available to update the history file, otherwise use a temporary file approach
if command -v jq &> /dev/null; then
    jq --arg new "$new_installation" '.installations += [$new | fromjson]' "$SCRIPT_DIR/.data/history.json" > "$SCRIPT_DIR/.data/history.json.tmp" && mv "$SCRIPT_DIR/.data/history.json.tmp" "$SCRIPT_DIR/.data/history.json"
else
    # Backup approach if jq is not available
    # Remove the closing bracket
    sed -i.bak '$ s/\]$//' "$SCRIPT_DIR/.data/history.json"

    # Check if we need to add a comma
    if grep -q "}]" "$SCRIPT_DIR/.data/history.json.bak"; then
        # Add a comma and the new entry
        echo ",$new_installation]" >> "$SCRIPT_DIR/.data/history.json"
    else
        # Add the new entry (first entry)
        echo "$new_installation]" >> "$SCRIPT_DIR/.data/history.json"
    fi

    # Remove the backup
    rm "$SCRIPT_DIR/.data/history.json.bak"
fi

echo -e "${GREEN}${BOLD}GremlinModes installation complete!${NC}"
echo ""
echo -e "The following structure has been created in ${BOLD}$base_dir${NC}:"
echo -e "- ${BOLD}/gremlinmodes/${NC} - GremlinModes framework directory"
echo -e "- ${BOLD}/.gremlinmodes/${NC} - Project-specific configurations"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. Navigate to your project folder: cd ${BOLD}$base_dir${NC}"
echo "2. Review and customize your configuration in .gremlinmodes/config.json"
echo "3. Select an agent to begin working with: ./agent.sh"
echo "4. To temporarily hide GremlinModes files for git commits: ./stash.sh"
echo "5. When updates are available, run: ${SCRIPT_DIR}/update.sh"
echo "6. To backup your work, run: ${SCRIPT_DIR}/backup.sh"
echo "7. To restore from backup, run: ${SCRIPT_DIR}/restore.sh"
echo ""
echo -e "Refer to ${BOLD}gremlinmodes/README.md${NC} for more details."
echo -e "${GREMLIN}Made with 💚 mischief by gremlinlabs${NC}"
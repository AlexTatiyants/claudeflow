#!/bin/bash

# Claude Flow Setup Script
# Install commands globally or to a specific project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SOURCE="$SCRIPT_DIR/commands"

# Default values
GLOBAL_INSTALL=false
TARGET_PROJECT=""

# Parse arguments
show_help() {
    echo "Claudeflow Setup"
    echo ""
    echo "Usage: ./setup.sh [OPTIONS] [PROJECT_PATH]"
    echo ""
    echo "Options:"
    echo "  -g, --global    Install commands globally (~/.claude/commands/)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./setup.sh                  # Install to current directory"
    echo "  ./setup.sh /path/to/project # Install to specific project"
    echo "  ./setup.sh --global         # Install globally for all projects"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--global)
            GLOBAL_INSTALL=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
        *)
            TARGET_PROJECT="$1"
            shift
            ;;
    esac
done

echo "Claudeflow Setup"
echo "================="
echo ""

# Check if source commands exist
if [ ! -d "$COMMANDS_SOURCE" ]; then
    echo -e "${RED}Error: Commands directory not found at $COMMANDS_SOURCE${NC}"
    exit 1
fi

if [ "$GLOBAL_INSTALL" = true ]; then
    # Global installation
    TARGET_DIR="$HOME/.claude/commands"

    echo -e "${BLUE}Installing globally to $TARGET_DIR${NC}"
    echo ""

    # Create target directory
    mkdir -p "$TARGET_DIR"

    # Copy command files
    echo "Copying command files..."
    cp -r "$COMMANDS_SOURCE"/*.md "$TARGET_DIR/"

    # Summary
    echo ""
    echo -e "${GREEN}Global installation complete!${NC}"
    echo ""
    echo "Installed files:"
    for file in "$TARGET_DIR"/*.md; do
        echo "  - $(basename "$file")"
    done
    echo ""
    echo "Commands are now available in all projects."
    echo ""
    echo -e "${YELLOW}Note: Each project still needs:${NC}"
    echo "  - work/features/ directory (created automatically by /feature-start)"
    echo "  - Docker entries in .gitignore (if using Docker features)"
    echo ""
    echo -e "${YELLOW}Tip: Run /feature-help for detailed usage instructions${NC}"
else
    # Project-specific installation
    if [ -z "$TARGET_PROJECT" ]; then
        TARGET_PROJECT="$(pwd)"
    fi

    # Resolve to absolute path
    TARGET_PROJECT="$(cd "$TARGET_PROJECT" 2>/dev/null && pwd)" || {
        echo -e "${RED}Error: Directory does not exist: $TARGET_PROJECT${NC}"
        exit 1
    }

    TARGET_DIR="$TARGET_PROJECT/.claude/commands"

    # Check if target is the same as source
    if [ "$TARGET_PROJECT" = "$SCRIPT_DIR" ]; then
        echo -e "${RED}Error: Cannot install into the claude-flow directory itself.${NC}"
        echo "Usage: ./setup.sh /path/to/your/project"
        echo "       ./setup.sh --global"
        exit 1
    fi

    echo -e "${BLUE}Installing to project: $TARGET_PROJECT${NC}"
    echo ""

    # Create target directory
    echo "Creating $TARGET_DIR..."
    mkdir -p "$TARGET_DIR"

    # Copy command files
    echo "Copying command files..."
    cp -r "$COMMANDS_SOURCE"/*.md "$TARGET_DIR/"

    # Create work/features directory
    echo "Creating work/features/ directory..."
    mkdir -p "$TARGET_PROJECT/work/features"

    # Create or update .gitignore
    GITIGNORE="$TARGET_PROJECT/.gitignore"
    GITIGNORE_ENTRIES=(
        "docker-compose.override.yml"
        ".env.docker"
        ".docker-ports.json"
        ".docker-ports.lock"
    )

    echo "Updating .gitignore..."
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        if [ -f "$GITIGNORE" ]; then
            if ! grep -qxF "$entry" "$GITIGNORE"; then
                echo "$entry" >> "$GITIGNORE"
                echo "  Added: $entry"
            fi
        else
            echo "$entry" >> "$GITIGNORE"
            echo "  Added: $entry"
        fi
    done

    # Summary
    echo ""
    echo -e "${GREEN}Project installation complete!${NC}"
    echo ""
    echo "Installed files:"
    for file in "$TARGET_DIR"/*.md; do
        echo "  - $(basename "$file")"
    done
    echo ""
    echo "Next steps:"
    echo "  1. cd $TARGET_PROJECT"
    echo "  2. Open VS Code with Claude Code extension"
    echo "  3. Run /feature-start \"your feature description\""
    echo ""
    echo -e "${YELLOW}Tip: Run /feature-help for detailed usage instructions${NC}"
fi

#!/bin/bash

# Claude Code Directory Setup Script
# Usage: curl -sSL https://raw.githubusercontent.com/chana1024/context-engineering-intro/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default GitHub repository (can be overridden)
GITHUB_REPO="${GITHUB_REPO:-chana1024/context-engineering-intro}"
BRANCH="${BRANCH:-main}"

echo -e "${GREEN}Claude Code Directory Setup${NC}"
echo "================================"

# Use current directory instead of home
echo "Installing to: $(pwd)/.claude"

CLAUDE_DIR="$(pwd)/.claude"

# Create main .claude directory
echo -e "${YELLOW}Creating .claude directory structure...${NC}"
mkdir -p "$CLAUDE_DIR"

# Create subdirectories
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/PRPs" 
mkdir -p "$CLAUDE_DIR/tasks"

echo -e "${GREEN}✓ Directory structure created${NC}"

# Function to download file from GitHub
download_file() {
    local source_path="$1"
    local dest_path="$2"
    local url="https://raw.githubusercontent.com/$GITHUB_REPO/$BRANCH/$source_path"
    
    echo "Downloading $source_path..."
    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$url" -o "$dest_path"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$dest_path"
    else
        echo -e "${RED}Error: Neither curl nor wget found${NC}"
        exit 1
    fi
}

# Function to download directory contents
download_directory() {
    local dir_name="$1"
    local dest_dir="$CLAUDE_DIR/$dir_name"
    
    echo -e "${YELLOW}Installing $dir_name...${NC}"
    
    # GitHub API to get directory contents
    local api_url="https://api.github.com/repos/$GITHUB_REPO/contents/$dir_name?ref=$BRANCH"
    
    # Get list of files in directory
    if command -v curl >/dev/null 2>&1; then
        files=$(curl -sSL "$api_url" | grep '"name"' | cut -d '"' -f 4)
    else
        echo -e "${RED}Error: curl required for GitHub API access${NC}"
        exit 1
    fi
    
    # Download each file
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            download_file "$dir_name/$file" "$dest_dir/$file"
            echo -e "${GREEN}✓ Downloaded $file${NC}"
        fi
    done <<< "$files"
}

# Install commands
if [ -d ".claude/commands" ] || curl -sSL "https://api.github.com/repos/$GITHUB_REPO/contents/.claude/commands?ref=$BRANCH" >/dev/null 2>&1; then
    download_directory ".claude/commands"
    # Make command files executable
    chmod +x "$CLAUDE_DIR/commands"/*
    echo -e "${GREEN}✓ Commands installed and made executable${NC}"
else
    echo -e "${YELLOW}! No .claude/commands directory found in repository${NC}"
fi

# Install PRPs
if [ -d ".claude/PRPs" ] || curl -sSL "https://api.github.com/repos/$GITHUB_REPO/contents/.claude/PRPs?ref=$BRANCH" >/dev/null 2>&1; then
    download_directory ".claude/PRPs"
    echo -e "${GREEN}✓ PRPs installed${NC}"
else
    echo -e "${YELLOW}! No .claude/PRPs directory found in repository${NC}"
fi

# Install task templates or examples
if [ -d ".claude/tasks" ] || curl -sSL "https://api.github.com/repos/$GITHUB_REPO/contents/.claude/tasks?ref=$BRANCH" >/dev/null 2>&1; then
    download_directory ".claude/tasks"
    echo -e "${GREEN}✓ Task templates installed${NC}"
else
    echo -e "${YELLOW}! No .claude/tasks directory found in repository${NC}"
    # Create a sample task file
    cat > "$CLAUDE_DIR/tasks/README.md" << 'EOF'
# Tasks Directory

This directory contains task files for tracking multi-PR development work.

## Usage

Create task files with format: `YYYY-MM-DD-task-name.md`

Example structure:
```markdown
# 2025-01-15-feature-implementation.md

## Progress
- ✅ PR 1: Foundation Setup
- 🔄 PR 2: Core Implementation (in review)
- ⏳ PR 3: Testing & Documentation

## Key Decisions
- Using async approach for better performance
- Behavioral tests instead of implementation tests

## Next Steps
- Complete PR 2 review feedback
- Add integration tests in PR 3
```
EOF
    echo -e "${GREEN}✓ Created task directory with README${NC}"
fi

# Create example files if directories are empty
if [ ! "$(ls -A "$CLAUDE_DIR/commands" 2>/dev/null)" ]; then
    cat > "$CLAUDE_DIR/commands/example" << 'EOF'
#!/bin/bash
# Example Claude Code command
# Usage: /example [message]

MESSAGE="${1:-Hello from Claude Code!}"
echo "Example command executed: $MESSAGE"
EOF
    chmod +x "$CLAUDE_DIR/commands/example"
    echo -e "${GREEN}✓ Created example command${NC}"
fi

if [ ! "$(ls -A "$CLAUDE_DIR/PRPs" 2>/dev/null)" ]; then
    cat > "$CLAUDE_DIR/PRPs/example.md" << 'EOF'
# Example PRP (Programmatic Request Pattern)

This is an example PRP file that demonstrates the structure.

## Usage
Copy this pattern and modify for your specific use case.

## Pattern
```
Analyze the codebase and suggest improvements for:
1. Performance optimization
2. Code organization  
3. Testing coverage
4. Documentation gaps
```
EOF
    echo -e "${GREEN}✓ Created example PRP${NC}"
fi

# Final verification
echo ""
echo -e "${GREEN}Installation Complete!${NC}"
echo "================================"
echo "Claude Code directories installed at:"
echo "  📁 $(pwd)/.claude/commands - Custom commands"
echo "  📁 $(pwd)/.claude/PRPs - Programmatic Request Patterns" 
echo "  📁 $(pwd)/.claude/tasks - Task tracking files"
echo ""
echo "Next steps:"
echo "1. Review installed files in ./.claude/"
echo "2. Customize commands and PRPs for your workflow"
echo "3. Start using /commands in Claude Code"
echo ""
echo -e "${YELLOW}Tip: Use GITHUB_REPO=owner/repo ./install.sh to install from a different repository${NC}"
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

# Function to check for GitHub API rate limit errors
check_rate_limit() {
    local response="$1"
    local operation="$2"
    
    if echo "$response" | grep -q '"message":"API rate limit exceeded'; then
        echo -e "${RED}❌ GitHub API Rate Limit Exceeded${NC}"
        echo ""
        echo "错误原因: GitHub API 速率限制已超出"
        echo "当前IP地址已达到GitHub API的请求限制"
        echo ""
        echo "解决方案:"
        echo "1. 等待一段时间后重试 (通常1小时后重置)"
        echo "2. 使用GitHub认证令牌获得更高的速率限制:"
        echo "   - 创建个人访问令牌: https://github.com/settings/tokens"
        echo "   - 设置环境变量: export GITHUB_TOKEN=your_token_here"
        echo "   - 重新运行脚本"
        echo "3. 使用VPN或更换网络环境"
        echo ""
        echo "详细信息: https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
        echo ""
        echo "脚本已停止运行。"
        exit 1
    fi
    
    # Check for other common GitHub API errors
    if echo "$response" | grep -q '"message":"Not Found"'; then
        echo -e "${RED}❌ Repository or directory not found${NC}"
        echo "错误原因: 仓库或目录不存在"
        echo "请检查 GITHUB_REPO 和 BRANCH 设置是否正确"
        exit 1
    fi
    
    if echo "$response" | grep -q '"message":"Bad credentials"'; then
        echo -e "${RED}❌ Invalid GitHub token${NC}"
        echo "错误原因: GitHub认证令牌无效"
        echo "请检查 GITHUB_TOKEN 环境变量设置"
        exit 1
    fi
}

# Function to make GitHub API request with error handling
github_api_request() {
    local url="$1"
    local operation="$2"
    
    local headers=""
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        headers="-H \"Authorization: token $GITHUB_TOKEN\""
    fi
    
    local response
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -sSL $headers "$url" 2>&1)
    else
        echo -e "${RED}Error: curl required for GitHub API access${NC}"
        exit 1
    fi
    
    # Check for rate limit and other errors
    check_rate_limit "$response" "$operation"
    
    echo "$response"
}

# Function to download file from GitHub
download_file() {
    local source_path="$1"
    local dest_path="$2"
    local url="https://raw.githubusercontent.com/$GITHUB_REPO/$BRANCH/$source_path"
    
    echo "Downloading $source_path..."
    if command -v curl >/dev/null 2>&1; then
        local headers=""
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            headers="-H \"Authorization: token $GITHUB_TOKEN\""
        fi
        
        local response
        response=$(curl -sSL $headers "$url" -o "$dest_path" 2>&1)
        
        # Check if download failed due to rate limiting
        if echo "$response" | grep -q "API rate limit exceeded"; then
            echo -e "${RED}❌ GitHub API Rate Limit Exceeded during file download${NC}"
            echo "错误原因: 下载文件时遇到GitHub API速率限制"
            echo "请参考上述解决方案"
            exit 1
        fi
        
        # Check for other download errors
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error downloading $source_path${NC}"
            echo "Response: $response"
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        local headers=""
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            headers="--header=\"Authorization: token $GITHUB_TOKEN\""
        fi
        
        wget -q $headers "$url" -O "$dest_path"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error downloading $source_path with wget${NC}"
            exit 1
        fi
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
    
    # Get list of files in directory with error handling
    local response
    response=$(github_api_request "$api_url" "获取目录内容")
    
    # Extract file names from response
    local files
    files=$(echo "$response" | grep '"name"' | cut -d '"' -f 4)
    
    if [ -z "$files" ]; then
        echo -e "${YELLOW}Warning: No files found in $dir_name directory${NC}"
        return
    fi
    
    # Download each file
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            download_file "$dir_name/$file" "$dest_dir/$file"
            echo -e "${GREEN}✓ Downloaded $file${NC}"
        fi
    done <<< "$files"
}

# Create main .claude directory
echo -e "${YELLOW}Creating .claude directory structure...${NC}"
mkdir -p "$CLAUDE_DIR"

# Create subdirectories
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/PRPs" 
mkdir -p "$CLAUDE_DIR/tasks"

echo -e "${GREEN}✓ Directory structure created${NC}"

# Check if GitHub token is available
if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo -e "${GREEN}✓ Using GitHub token for authenticated requests${NC}"
    echo "这将提供更高的API速率限制"
else
    echo -e "${YELLOW}⚠ 未设置GitHub认证令牌${NC}"
    echo "建议设置GITHUB_TOKEN环境变量以获得更高的API速率限制"
    echo "设置方法: export GITHUB_TOKEN=your_token_here"
fi

# Install commands
echo -e "${YELLOW}Checking .claude/commands directory...${NC}"
if [ -d ".claude/commands" ]; then
    echo "使用本地 .claude/commands 目录"
else
    echo "检查远程 .claude/commands 目录..."
    local response
    response=$(github_api_request "https://api.github.com/repos/$GITHUB_REPO/contents/.claude/commands?ref=$BRANCH" "检查commands目录")
    
    if echo "$response" | grep -q '"type":"dir"'; then
        download_directory ".claude/commands"
        # Make command files executable
        chmod +x "$CLAUDE_DIR/commands"/*
        echo -e "${GREEN}✓ Commands installed and made executable${NC}"
    else
        echo -e "${YELLOW}! No .claude/commands directory found in repository${NC}"
    fi
fi

# Install PRPs
echo -e "${YELLOW}Checking .claude/PRPs directory...${NC}"
if [ -d ".claude/PRPs" ]; then
    echo "使用本地 .claude/PRPs 目录"
else
    echo "检查远程 .claude/PRPs 目录..."
    local response
    response=$(github_api_request "https://api.github.com/repos/$GITHUB_REPO/contents/.claude/PRPs?ref=$BRANCH" "检查PRPs目录")
    
    if echo "$response" | grep -q '"type":"dir"'; then
        download_directory ".claude/PRPs"
        echo -e "${GREEN}✓ PRPs installed${NC}"
    else
        echo -e "${YELLOW}! No .claude/PRPs directory found in repository${NC}"
    fi
fi

# Install task templates or examples
echo -e "${YELLOW}Checking .claude/tasks directory...${NC}"
if [ -d ".claude/tasks" ]; then
    echo "使用本地 .claude/tasks 目录"
else
    echo "检查远程 .claude/tasks 目录..."
    local response
    response=$(github_api_request "https://api.github.com/repos/$GITHUB_REPO/contents/.claude/tasks?ref=$BRANCH" "检查tasks目录")
    
    if echo "$response" | grep -q '"type":"dir"'; then
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
echo -e "${YELLOW}Tip: Set GITHUB_TOKEN for higher API rate limits${NC}"
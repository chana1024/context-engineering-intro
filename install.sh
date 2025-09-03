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

PROJECT_DIR="$(pwd)"

# Function to make GitHub API request with error handling
github_api_request() {
    local url="$1"
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
    echo "$response"
}

# Function to check GitHub API rate limit status upfront
check_github_api_status() {
    echo -e "${YELLOW}检查GitHub API状态...${NC}"
    
    # Make a simple API call to check rate limit status
    local api_url="https://api.github.com/rate_limit"
    local response
    
    if command -v curl >/dev/null 2>&1; then
        local headers=""
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            headers="-H \"Authorization: token $GITHUB_TOKEN\""
        fi
        
        response=$(curl -sSL $headers "$api_url" 2>&1)
    else
        echo -e "${RED}Error: curl required for GitHub API access${NC}"
        exit 1
    fi
    
    # Parse rate limit information
    local remaining_requests
    local reset_time
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        # Authenticated requests
        remaining_requests=$(echo "$response" | grep '"remaining"' | head -1 | cut -d ':' -f 2 | tr -d ' ,')
        reset_time=$(echo "$response" | grep '"reset"' | head -1 | cut -d ':' -f 2 | tr -d ' ,')
    else
        # Unauthenticated requests
        remaining_requests=$(echo "$response" | grep '"remaining"' | tail -1 | cut -d ':' -f 2 | tr -d ' ,')
        reset_time=$(echo "$response" | grep '"reset"' | tail -1 | cut -d ':' -f 2 | tr -d ' ,')
    fi
    
    if [ -n "$remaining_requests" ] && [ "$remaining_requests" -gt 0 ]; then
        echo -e "${GREEN}✓ GitHub API可用，剩余请求次数: $remaining_requests${NC}"
        if [ -n "$reset_time" ]; then
            local reset_date=$(date -d "@$reset_time" '+%Y-%m-%d %H:%M:%S')
            echo "速率限制重置时间: $reset_date"
        fi
    else
        echo -e "${RED}❌ GitHub API请求次数已用完${NC}"
        if [ -n "$reset_time" ]; then
            local reset_date=$(date -d "@$reset_time" '+%Y-%m-%d %H:%M:%S')
            echo "速率限制重置时间: $reset_date"
        fi
        echo "请等待重置后重试，或设置GITHUB_TOKEN获得更高限制"
        exit 1
    fi
    
    echo ""
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
    local dest_dir="$PROJECT_DIR/$dir_name"
    
    echo -e "${YELLOW}Installing $dir_name...${NC}"
    
    # GitHub API to get directory contents
    local api_url="https://api.github.com/repos/$GITHUB_REPO/contents/$dir_name?ref=$BRANCH"
    
    # Get list of files in directory with error handling
    local response
    response=$(github_api_request "$api_url")
    
    # Extract file names from response
    local files
    files=$(echo "$response" | grep '"name"' | cut -d '"' -f 4)
    
    if [ -z "$files" ]; then
        echo -e "${YELLOW}Warning: No files found in $dir_name directory${NC}"
        return
    fi
    
    # Create destination directory only when we have files to download
    mkdir -p "$dest_dir"
    
    # Download each file
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            download_file "$dir_name/$file" "$dest_dir/$file"
            echo -e "${GREEN}✓ Downloaded $file${NC}"
        fi
    done <<< "$files"
}

# Check if GitHub token is available
if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo -e "${GREEN}✓ Using GitHub token for authenticated requests${NC}"
    echo "这将提供更高的API速率限制"
else
    echo -e "${YELLOW}⚠ 未设置GitHub认证令牌${NC}"
    echo "建议设置GITHUB_TOKEN环境变量以获得更高的API速率限制"
    echo "设置方法: export GITHUB_TOKEN=your_token_here"
fi

echo ""

# 在开始安装之前先检查GitHub API状态
check_github_api_status

# 开始安装过程
echo -e "\n${YELLOW}开始安装Claude Code组件...${NC}"

# Install commands
echo -e "${YELLOW}检查 .claude/commands 目录...${NC}"
download_directory ".claude/commands"
echo -e "${GREEN}✓ Commands installed${NC}"

# Install PRPs
echo -e "${YELLOW}检查 .claude/PRPs 目录...${NC}"
download_directory ".claude/PRPs"
echo -e "${GREEN}✓ PRPs installed${NC}"

# Install task templates or examples
echo -e "${YELLOW}检查 .claude/tasks 目录...${NC}"
download_directory ".claude/tasks"
echo -e "${GREEN}✓ Task templates installed${NC}"

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
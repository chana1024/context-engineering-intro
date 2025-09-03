#!/bin/bash

# GitHub令牌设置脚本
# 帮助用户设置GitHub个人访问令牌以提高API速率限制

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}GitHub 令牌设置助手${NC}"
echo "========================"

# 检查是否已经设置了令牌
if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo -e "${GREEN}✓ GITHUB_TOKEN 环境变量已设置${NC}"
    echo "当前令牌前缀: ${GITHUB_TOKEN:0:4}..."
    
    # 验证令牌有效性
    echo -e "\n${YELLOW}验证令牌有效性...${NC}"
    if curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/user" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ GitHub令牌有效${NC}"
        
        # 检查速率限制
        echo -e "\n${YELLOW}检查当前API速率限制...${NC}"
        rate_limit=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/rate_limit")
        
        if [ $? -eq 0 ]; then
            remaining=$(echo "$rate_limit" | grep -o '"remaining":[0-9]*' | cut -d':' -f2)
            limit=$(echo "$rate_limit" | grep -o '"limit":[0-9]*' | cut -d':' -f2)
            reset_time=$(echo "$rate_limit" | grep -o '"reset":[0-9]*' | cut -d':' -f2)
            
            if [ -n "$remaining" ] && [ -n "$limit" ]; then
                echo -e "${GREEN}✓ 当前API使用情况:${NC}"
                echo "  剩余请求: $remaining / $limit"
                
                # 计算重置时间
                if [ -n "$reset_time" ]; then
                    reset_date=$(date -d "@$reset_time" '+%Y-%m-%d %H:%M:%S')
                    echo "  重置时间: $reset_date"
                fi
                
                # 计算使用百分比
                used=$((limit - remaining))
                percentage=$((used * 100 / limit))
                echo "  使用率: $percentage%"
                
                if [ $percentage -gt 80 ]; then
                    echo -e "${YELLOW}⚠ 警告: API使用率较高${NC}"
                fi
            fi
        else
            echo -e "${RED}✗ 无法获取速率限制信息${NC}"
        fi
        
    else
        echo -e "${RED}✗ GitHub令牌无效或已过期${NC}"
        echo "建议重新生成令牌"
    fi
    
    exit 0
fi

echo -e "${YELLOW}⚠ GITHUB_TOKEN 环境变量未设置${NC}"
echo ""
echo "GitHub API速率限制说明:"
echo "• 未认证用户: 每小时60次请求"
echo "• 认证用户: 每小时5000次请求"
echo "• 企业用户: 每小时15000次请求"
echo ""

echo -e "${BLUE}设置GitHub令牌的步骤:${NC}"
echo "1. 访问 https://github.com/settings/tokens"
echo "2. 点击 'Generate new token (classic)'"
echo "3. 选择权限范围:"
echo "   - repo (访问私有仓库)"
echo "   - read:org (读取组织信息)"
echo "   - read:user (读取用户信息)"
echo "4. 设置令牌过期时间 (建议90天或更长)"
echo "5. 生成令牌并复制"
echo ""

read -p "是否现在设置GitHub令牌? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}请输入你的GitHub个人访问令牌:${NC}"
    echo "令牌格式: ghp_xxxxxxxxxxxxxxxxxxxx"
    echo "注意: 输入时不会显示字符"
    
    read -s -p "GitHub Token: " github_token
    echo
    
    if [ -z "$github_token" ]; then
        echo -e "${RED}✗ 令牌不能为空${NC}"
        exit 1
    fi
    
    # 验证令牌格式
    if [[ ! "$github_token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]]; then
        echo -e "${RED}✗ 令牌格式不正确${NC}"
        echo "正确格式: ghp_xxxxxxxxxxxxxxxxxxxx"
        exit 1
    fi
    
    # 验证令牌有效性
    echo -e "\n${YELLOW}验证令牌有效性...${NC}"
    if curl -s -H "Authorization: token $github_token" "https://api.github.com/user" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 令牌验证成功${NC}"
        
        # 获取用户信息
        user_info=$(curl -s -H "Authorization: token $github_token" "https://api.github.com/user")
        username=$(echo "$user_info" | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$username" ]; then
            echo -e "${GREEN}✓ 用户: $username${NC}"
        fi
        
        # 设置环境变量
        echo -e "\n${YELLOW}设置环境变量...${NC}"
        
        # 检测shell类型
        if [ -n "$ZSH_VERSION" ]; then
            shell_rc="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            shell_rc="$HOME/.bashrc"
        else
            shell_rc="$HOME/.profile"
        fi
        
        # 检查是否已经存在
        if grep -q "GITHUB_TOKEN" "$shell_rc" 2>/dev/null; then
            echo "更新现有的GITHUB_TOKEN设置..."
            # 使用sed替换现有的设置
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                sed -i '' "s/export GITHUB_TOKEN=.*/export GITHUB_TOKEN=$github_token/" "$shell_rc"
            else
                # Linux
                sed -i "s/export GITHUB_TOKEN=.*/export GITHUB_TOKEN=$github_token/" "$shell_rc"
            fi
        else
            echo "添加GITHUB_TOKEN到 $shell_rc"
            echo "" >> "$shell_rc"
            echo "# GitHub Personal Access Token for higher API rate limits" >> "$shell_rc"
            echo "export GITHUB_TOKEN=$github_token" >> "$shell_rc"
        fi
        
        echo -e "${GREEN}✓ 环境变量已设置到 $shell_rc${NC}"
        
        # 设置当前会话的环境变量
        export GITHUB_TOKEN="$github_token"
        echo -e "${GREEN}✓ 当前会话已设置GITHUB_TOKEN${NC}"
        
        # 显示使用说明
        echo -e "\n${BLUE}使用说明:${NC}"
        echo "1. 重新加载shell配置: source $shell_rc"
        echo "2. 或者重新打开终端"
        echo "3. 现在可以运行install.sh脚本了"
        echo ""
        echo -e "${GREEN}✓ GitHub令牌设置完成！${NC}"
        
    else
        echo -e "${RED}✗ 令牌验证失败${NC}"
        echo "请检查令牌是否正确，或者令牌是否已过期"
        exit 1
    fi
    
else
    echo -e "${YELLOW}跳过令牌设置${NC}"
    echo ""
    echo "你可以稍后手动设置:"
    echo "export GITHUB_TOKEN=your_token_here"
    echo ""
    echo "或者重新运行此脚本:"
    echo "./setup_github_token.sh"
fi

echo ""
echo -e "${BLUE}相关链接:${NC}"
echo "• GitHub令牌设置: https://github.com/settings/tokens"
echo "• API速率限制文档: https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
echo "• 本项目: https://github.com/chana1024/context-engineering-intro"

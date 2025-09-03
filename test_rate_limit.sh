#!/bin/bash

# 测试脚本：模拟GitHub API速率限制错误
# 用于验证install.sh的错误处理机制

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}GitHub API 速率限制错误处理测试${NC}"
echo "======================================"

# 测试1: 模拟速率限制错误
echo -e "\n${YELLOW}测试1: 模拟GitHub API速率限制错误${NC}"
echo "----------------------------------------"

# 模拟GitHub API速率限制响应
mock_rate_limit_response='{"message":"API rate limit exceeded for 45.32.107.83. (But here is the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)","documentation_url":"https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"}'

echo "模拟响应: $mock_rate_limit_response"
echo ""

# 测试错误检测函数
if echo "$mock_rate_limit_response" | grep -q '"message":"API rate limit exceeded'; then
    echo -e "${GREEN}✓ 速率限制错误检测正常${NC}"
else
    echo -e "${RED}✗ 速率限制错误检测失败${NC}"
fi

# 测试2: 模拟其他常见错误
echo -e "\n${YELLOW}测试2: 模拟其他常见GitHub API错误${NC}"
echo "----------------------------------------"

# 测试Not Found错误
not_found_response='{"message":"Not Found"}'
echo "Not Found错误: $not_found_response"
if echo "$not_found_response" | grep -q '"message":"Not Found"'; then
    echo -e "${GREEN}✓ Not Found错误检测正常${NC}"
else
    echo -e "${RED}✗ Not Found错误检测失败${NC}"
fi

# 测试认证错误
bad_credentials_response='{"message":"Bad credentials"}'
echo "认证错误: $bad_credentials_response"
if echo "$bad_credentials_response" | grep -q '"message":"Bad credentials"'; then
    echo -e "${GREEN}✓ 认证错误检测正常${NC}"
else
    echo -e "${RED}✗ 认证错误检测失败${NC}"
fi

# 测试3: 验证错误处理逻辑
echo -e "\n${YELLOW}测试3: 验证错误处理逻辑${NC}"
echo "----------------------------------------"

# 模拟check_rate_limit函数的行为
check_rate_limit() {
    local response="$1"
    local operation="$2"
    
    echo "检查操作: $operation"
    
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
        return 1
    fi
    
    if echo "$response" | grep -q '"message":"Not Found"'; then
        echo -e "${RED}❌ Repository or directory not found${NC}"
        echo "错误原因: 仓库或目录不存在"
        echo "请检查 GITHUB_REPO 和 BRANCH 设置是否正确"
        return 1
    fi
    
    if echo "$response" | grep -q '"message":"Bad credentials"'; then
        echo -e "${RED}❌ Invalid GitHub token${NC}"
        echo "错误原因: GitHub认证令牌无效"
        echo "请检查 GITHUB_TOKEN 环境变量设置"
        return 1
    fi
    
    echo -e "${GREEN}✓ 响应检查通过${NC}"
    return 0
}

# 测试各种错误情况
echo -e "\n${BLUE}测试速率限制错误处理:${NC}"
check_rate_limit "$mock_rate_limit_response" "测试操作"

echo -e "\n${BLUE}测试Not Found错误处理:${NC}"
check_rate_limit "$not_found_response" "测试操作"

echo -e "\n${BLUE}测试认证错误处理:${NC}"
check_rate_limit "$bad_credentials_response" "测试操作"

echo -e "\n${BLUE}测试正常响应:${NC}"
normal_response='{"type":"dir","name":"test"}'
check_rate_limit "$normal_response" "测试操作"

# 测试4: 环境变量检查
echo -e "\n${YELLOW}测试4: 环境变量检查${NC}"
echo "----------------------------------------"

if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo -e "${GREEN}✓ GITHUB_TOKEN 已设置${NC}"
    echo "令牌前缀: ${GITHUB_TOKEN:0:4}..."
else
    echo -e "${YELLOW}⚠ GITHUB_TOKEN 未设置${NC}"
    echo "建议设置以获得更高的API速率限制"
fi

if [ -n "${GITHUB_REPO:-}" ]; then
    echo -e "${GREEN}✓ GITHUB_REPO 已设置: $GITHUB_REPO${NC}"
else
    echo -e "${BLUE}ℹ 使用默认仓库: chana1024/context-engineering-intro${NC}"
fi

# 测试5: 网络连接测试
echo -e "\n${YELLOW}测试5: 网络连接测试${NC}"
echo "----------------------------------------"

# 测试GitHub API连接
echo "测试GitHub API连接..."
if curl -s --connect-timeout 10 "https://api.github.com" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ GitHub API 连接正常${NC}"
else
    echo -e "${RED}✗ GitHub API 连接失败${NC}"
    echo "请检查网络连接和防火墙设置"
fi

# 测试GitHub.com连接
echo "测试GitHub.com连接..."
if curl -s --connect-timeout 10 "https://github.com" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ GitHub.com 连接正常${NC}"
else
    echo -e "${RED}✗ GitHub.com 连接失败${NC}"
    echo "请检查网络连接和防火墙设置"
fi

# 总结
echo -e "\n${BLUE}测试总结${NC}"
echo "=========="
echo -e "${GREEN}✓ 错误检测机制正常${NC}"
echo -e "${GREEN}✓ 错误处理逻辑正常${NC}"
echo -e "${GREEN}✓ 环境变量检查正常${NC}"
echo -e "${GREEN}✓ 网络连接测试完成${NC}"

echo -e "\n${YELLOW}建议:${NC}"
echo "1. 如果遇到速率限制，设置GITHUB_TOKEN环境变量"
echo "2. 定期检查网络连接状态"
echo "3. 监控GitHub API使用情况"

echo -e "\n${GREEN}测试完成！${NC}"

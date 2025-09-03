# 安装脚本行为演示

## 修改后的行为

### ✅ 新的行为特点

1. **预验证机制**
   - 在开始任何操作前验证GitHub API连接
   - 检查仓库访问权限
   - 只有验证通过后才开始安装过程

2. **错误时立即停止**
   - 遇到速率限制错误时立即停止脚本
   - 遇到认证错误时立即停止脚本
   - 遇到权限错误时立即停止脚本

3. **不创建空目录**
   - 不会预先创建.claude目录结构
   - 只有在成功下载文件后才创建目录
   - 避免创建无用的空目录

4. **完全远程依赖**
   - 不使用本地已存在的文件
   - 完全依赖远程仓库
   - 确保安装最新版本

## 行为对比

### 修改前 (v2.0)
```
❌ 预先创建.claude目录
❌ 检查本地文件
❌ 遇到错误时继续尝试其他组件
❌ 可能创建空目录
```

### 修改后 (v3.0)
```
✅ 预验证GitHub API连接
✅ 遇到错误立即停止
✅ 不创建空目录
✅ 完全依赖远程仓库
```

## 执行流程

### 1. 启动阶段
```
Claude Code Directory Setup
============================
Installing to: /path/to/.claude
```

### 2. 预验证阶段
```
验证GitHub API连接...
检查仓库访问权限...
✓ 仓库访问权限验证通过
```

### 3. 安装阶段
```
开始安装Claude Code组件...
检查 .claude/commands 目录...
检查 .claude/PRPs 目录...
检查 .claude/tasks 目录...
```

### 4. 成功完成
```
Installation Complete!
========================
Claude Code directories installed at:
  📁 /path/to/.claude/commands - Custom commands
  📁 /path/to/.claude/PRPs - Programmatic Request Patterns
  📁 /path/to/.claude/tasks - Task tracking files
```

## 错误处理示例

### 速率限制错误
```
❌ GitHub API Rate Limit Exceeded

错误原因: GitHub API 速率限制已超出
当前IP地址已达到GitHub API的请求限制

解决方案:
1. 等待一段时间后重试 (通常1小时后重置)
2. 使用GitHub认证令牌获得更高的速率限制
3. 使用VPN或更换网络环境

脚本已停止运行。
```

### 仓库不存在
```
❌ Repository or directory not found

错误原因: 仓库或目录不存在
请检查 GITHUB_REPO 和 BRANCH 设置是否正确
```

### 认证失败
```
❌ Invalid GitHub token

错误原因: GitHub认证令牌无效
请检查 GITHUB_TOKEN 环境变量设置
```

## 使用建议

### 1. 设置GitHub令牌
```bash
export GITHUB_TOKEN="ghp_your_token_here"
./install.sh
```

### 2. 检查网络连接
```bash
# 测试GitHub连接
curl -s https://api.github.com

# 测试仓库访问
curl -s "https://api.github.com/repos/owner/repo"
```

### 3. 监控API使用
```bash
# 查看当前速率限制
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit
```

## 故障排除

### 常见问题

1. **脚本立即停止**
   - 检查GitHub API连接
   - 验证仓库访问权限
   - 确认令牌有效性

2. **速率限制错误**
   - 等待1小时后重试
   - 设置GitHub认证令牌
   - 使用VPN或更换网络

3. **权限不足**
   - 检查仓库是否为私有仓库
   - 确认令牌有足够权限
   - 验证仓库名称是否正确

## 总结

修改后的安装脚本现在具有以下优势：

- **更安全**: 预验证机制避免无效安装
- **更可靠**: 遇到错误立即停止，不创建损坏的目录
- **更清晰**: 明确的错误信息和解决方案
- **更一致**: 完全依赖远程仓库，避免本地文件污染

这种设计确保了安装过程的可靠性和一致性，避免了因网络问题或权限问题导致的安装失败。

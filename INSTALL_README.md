# Claude Code 安装脚本使用指南

## 概述

这个安装脚本会自动下载和设置Claude Code所需的目录结构和文件。脚本包含完整的错误处理机制，特别是针对GitHub API速率限制的处理。

## 基本用法

### 1. 直接运行
```bash
curl -sSL https://raw.githubusercontent.com/chana1024/context-engineering-intro/main/install.sh | bash
```

### 2. 下载后运行
```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/chana1024/context-engineering-intro/main/install.sh

# 运行脚本
chmod +x install.sh
./install.sh
```

## 环境变量配置

### 设置GitHub仓库
```bash
# 使用自定义仓库
export GITHUB_REPO="your-username/your-repo"
export BRANCH="main"

# 运行脚本
./install.sh
```

### 设置GitHub认证令牌（推荐）
```bash
# 创建个人访问令牌
# 访问: https://github.com/settings/tokens

# 设置环境变量
export GITHUB_TOKEN="ghp_your_token_here"

# 运行脚本
./install.sh
```

## 错误处理机制

### 1. GitHub API速率限制错误

当遇到以下错误时，脚本会自动停止并显示详细解决方案：

```
"message":"API rate limit exceeded for 45.32.107.83. (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)"
```

**错误原因：**
- 当前IP地址已达到GitHub API的请求限制
- 未认证请求的速率限制较低（每小时60次）

**解决方案：**
1. **等待重置**：通常1小时后自动重置
2. **使用GitHub令牌**（推荐）：
   - 创建个人访问令牌：https://github.com/settings/tokens
   - 设置环境变量：`export GITHUB_TOKEN=your_token_here`
   - 重新运行脚本
3. **更换网络环境**：使用VPN或更换IP地址

### 2. 其他常见错误

#### 仓库不存在
```
"message":"Not Found"
```
**解决方案：** 检查`GITHUB_REPO`和`BRANCH`设置

#### 无效的认证令牌
```
"message":"Bad credentials"
```
**解决方案：** 检查`GITHUB_TOKEN`环境变量设置

## 目录结构

安装完成后，脚本会在当前目录创建以下结构：

```
.claude/
├── commands/     # 自定义命令
├── PRPs/         # 程序化请求模式
└── tasks/        # 任务跟踪文件
```

## 功能特性

### 1. 智能错误检测
- 自动检测GitHub API速率限制
- 识别认证和权限错误
- 提供具体的解决方案

### 2. 认证支持
- 支持GitHub个人访问令牌
- 自动使用认证请求获得更高速率限制
- 优雅降级到未认证模式

### 3. 本地优先
- 优先使用本地已存在的目录
- 仅在需要时进行远程下载
- 减少不必要的API调用

### 4. 详细日志
- 彩色输出便于阅读
- 显示每个步骤的进度
- 清晰的错误信息和解决方案

## 最佳实践

### 1. 设置GitHub令牌
```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
export GITHUB_TOKEN="ghp_your_token_here"

# 重新加载配置
source ~/.bashrc  # 或 source ~/.zshrc
```

### 2. 定期更新令牌
- GitHub令牌有过期时间
- 建议设置较长的过期时间
- 定期检查令牌有效性

### 3. 监控API使用
- 认证用户：每小时5000次请求
- 未认证用户：每小时60次请求
- 使用`curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit`查看当前使用情况

## 故障排除

### 常见问题

#### Q: 脚本运行很慢
**A:** 检查网络连接，考虑使用GitHub令牌提高速率限制

#### Q: 某些文件下载失败
**A:** 检查文件路径是否正确，确认仓库中存在该文件

#### Q: 权限被拒绝
**A:** 确保脚本有执行权限：`chmod +x install.sh`

#### Q: curl命令未找到
**A:** 安装curl：`sudo apt-get install curl` (Ubuntu/Debian) 或 `sudo yum install curl` (CentOS/RHEL)

### 获取帮助

如果遇到其他问题，可以：

1. 检查脚本输出的错误信息
2. 查看GitHub API文档：https://docs.github.com/rest
3. 确认网络连接和防火墙设置
4. 尝试使用VPN或更换网络环境

## 更新日志

- **v2.0**: 添加完整的错误处理机制
- **v1.0**: 基础安装功能

## 许可证

本项目采用MIT许可证。详见LICENSE文件。

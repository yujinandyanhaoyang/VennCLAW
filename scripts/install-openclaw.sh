#!/bin/bash
# =============================================================================
# OpenClaw 一键安装和恢复脚本
# =============================================================================
# 用途：全新安装 OpenClaw 并恢复 VennCLAW 团队配置
# 使用：./install-openclaw.sh [备份目录]
# 示例：./install-openclaw.sh /root/backups/openclaw-20260311-120000
#        ./install-openclaw.sh  # 仅安装，不恢复
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$1"

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}  VennCLAW OpenClaw 一键安装脚本${NC}"
echo -e "${PURPLE}========================================${NC}"
echo ""

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误：请以 root 用户运行此脚本${NC}"
    echo "sudo $0 $@"
    exit 1
fi

# 检查 Node.js
echo -e "${YELLOW}📋 系统检查...${NC}"
echo ""

if ! command -v node &> /dev/null; then
    echo -e "${RED}✗${NC} Node.js 未安装"
    echo ""
    echo -e "${YELLOW}正在安装 Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
    echo -e "${GREEN}✓${NC} Node.js 安装完成"
else
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js 已安装：$NODE_VERSION"
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗${NC} npm 未安装"
    exit 1
else
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm 已安装：$NPM_VERSION"
fi

# 检查 OpenClaw
echo ""
if command -v openclaw &> /dev/null; then
    OPENCLAW_VERSION=$(openclaw --version 2>&1 | head -1)
    echo -e "${GREEN}✓${NC} OpenClaw 已安装：$OPENCLAW_VERSION"
    echo ""
    read -p "是否重新安装？(y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}正在重新安装 OpenClaw...${NC}"
        npm uninstall -g openclaw 2>/dev/null || true
    else
        echo -e "${GREEN}✓${NC} 保留现有安装"
    fi
fi

# 安装 OpenClaw
if ! command -v openclaw &> /dev/null; then
    echo ""
    echo -e "${YELLOW}📦 安装 OpenClaw...${NC}"
    npm install -g openclaw
    echo -e "${GREEN}✓${NC} OpenClaw 安装完成"
fi

OPENCLAW_VERSION=$(openclaw --version 2>&1 | head -1)
echo -e "${GREEN}✓${NC} OpenClaw 版本：$OPENCLAW_VERSION"

# 初始化配置
echo ""
echo -e "${YELLOW}🔧 初始化配置...${NC}"
OPENCLAW_DIR="$HOME/.openclaw"

# 创建必要目录
mkdir -p "$OPENCLAW_DIR"
mkdir -p "$OPENCLAW_DIR/identity"
mkdir -p "$OPENCLAW_DIR/agents"
mkdir -p "$OPENCLAW_DIR/cron"
mkdir -p "$OPENCLAW_DIR/memory"
mkdir -p "$OPENCLAW_DIR/subagents"
mkdir -p "$OPENCLAW_DIR/devices"
mkdir -p "$OPENCLAW_DIR/extensions"
mkdir -p "$OPENCLAW_DIR/feishu"
mkdir -p "$OPENCLAW_DIR/workspace"

echo -e "${GREEN}✓${NC} 目录结构创建完成"

# 恢复备份（如果提供）
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  开始恢复配置...${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}备份目录：$BACKUP_DIR${NC}"
    echo ""
    
    # 调用恢复脚本
    if [ -f "$SCRIPT_DIR/restore-openclaw.sh" ]; then
        bash "$SCRIPT_DIR/restore-openclaw.sh" "$BACKUP_DIR"
    else
        echo -e "${RED}错误：恢复脚本不存在${NC}"
        echo "请先运行备份脚本创建配置"
    fi
else
    echo ""
    echo -e "${YELLOW}⚠️  未提供备份目录，跳过恢复步骤${NC}"
    echo ""
    echo -e "${YELLOW}提示：${NC}如果有备份，可以稍后运行："
    echo -e "${BLUE}bash $SCRIPT_DIR/restore-openclaw.sh <备份目录>${NC}"
    echo ""
fi

# 配置 Gateway
echo ""
echo -e "${YELLOW}🔧 配置 Gateway...${NC}"

# 检查 Gateway 状态
if systemctl is-active --quiet openclaw-gateway 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Gateway 已在运行"
    echo ""
    read -p "是否重启 Gateway？(y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        openclaw gateway restart
        echo -e "${GREEN}✓${NC} Gateway 已重启"
    fi
else
    echo -e "${YELLOW}⚠${NC} Gateway 未运行"
    echo ""
    read -p "是否启动 Gateway？(y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        openclaw gateway start
        echo -e "${GREEN}✓${NC} Gateway 已启动"
    fi
fi

# 验证安装
echo ""
echo -e "${YELLOW}🔍 验证安装...${NC}"
echo ""

if openclaw status &> /dev/null; then
    echo -e "${GREEN}✓${NC} OpenClaw 状态正常"
else
    echo -e "${YELLOW}⚠${NC} OpenClaw 状态检查失败（可能是配置问题）"
fi

# 显示工作区
if [ -d "$OPENCLAW_DIR/workspace" ]; then
    echo -e "${GREEN}✓${NC} 工作区：$OPENCLAW_DIR/workspace"
    echo ""
    echo "工作区内容："
    ls -la "$OPENCLAW_DIR/workspace/" | head -10
fi

# 完成提示
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}常用命令：${NC}"
echo ""
echo "  查看状态：    ${BLUE}openclaw status${NC}"
echo "  启动 Gateway: ${BLUE}openclaw gateway start${NC}"
echo "  停止 Gateway: ${BLUE}openclaw gateway stop${NC}"
echo "  重启 Gateway: ${BLUE}openclaw gateway restart${NC}"
echo "  查看日志：    ${BLUE}openclaw logs${NC}"
echo "  帮助：        ${BLUE}openclaw help${NC}"
echo ""
echo -e "${BLUE}VennCLAW 专用命令：${NC}"
echo ""
echo "  备份配置：    ${BLUE}bash $SCRIPT_DIR/backup-openclaw.sh${NC}"
echo "  恢复配置：    ${BLUE}bash $SCRIPT_DIR/restore-openclaw.sh <备份目录>${NC}"
echo ""
echo -e "${GREEN}✓${NC} 所有操作完成！"
echo ""

#!/bin/bash
# =============================================================================
# OpenClaw 配置恢复脚本
# =============================================================================
# 用途：从备份恢复 OpenClaw 的所有配置文件和数据
# 使用：./restore-openclaw.sh <备份目录>
# 示例：./restore-openclaw.sh /root/backups/openclaw-20260311-120000
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误：请提供备份目录路径${NC}"
    echo ""
    echo -e "用法：${BLUE}$0 <备份目录>${NC}"
    echo -e "示例：${BLUE}$0 /root/backups/openclaw-20260311-120000${NC}"
    exit 1
fi

BACKUP_DIR="$1"
OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$HOME/.openclaw/workspace"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  OpenClaw 配置恢复脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查备份目录是否存在
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}错误：备份目录不存在：$BACKUP_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} 备份目录：$BACKUP_DIR"

# 检查备份信息文件
if [ -f "$BACKUP_DIR/BACKUP_INFO.md" ]; then
    echo ""
    echo -e "${YELLOW}📋 备份信息：${NC}"
    head -10 "$BACKUP_DIR/BACKUP_INFO.md" | grep -E "^\*\*" | sed 's/\*\*/  /g'
fi

# 检查 OpenClaw 是否安装
echo ""
if ! command -v openclaw &> /dev/null; then
    echo -e "${RED}错误：OpenClaw 未安装${NC}"
    echo ""
    echo -e "${YELLOW}请先安装 OpenClaw：${NC}"
    echo -e "${BLUE}npm install -g openclaw${NC}"
    exit 1
fi

OPENCLAW_VERSION=$(openclaw --version 2>&1 | head -1)
echo -e "${GREEN}✓${NC} OpenClaw 版本：${OPENCLAW_VERSION}"

# 警告提示
echo ""
echo -e "${RED}⚠️  警告：恢复操作将覆盖现有配置！${NC}"
echo ""
read -p "是否继续？(y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}恢复已取消${NC}"
    exit 0
fi

# 备份当前配置（以防万一）
CURRENT_BACKUP="/root/backups/openclaw-pre-restore-$(date +%Y%m%d-%H%M%S)"
echo ""
echo -e "${YELLOW}📦 备份当前配置到：$CURRENT_BACKUP${NC}"
mkdir -p "$CURRENT_BACKUP"
if [ -d "$OPENCLAW_DIR" ]; then
    rsync -av "$OPENCLAW_DIR/" "$CURRENT_BACKUP/" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} 当前配置已备份"
fi

# 恢复函数
restore_file() {
    local src="$1"
    local dst="$2"
    local desc="$3"
    
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -r "$src" "$dst"
        echo -e "${GREEN}✓${NC} $desc"
    else
        echo -e "${YELLOW}⚠${NC} $desc (不存在，跳过)"
    fi
}

# 开始恢复
echo ""
echo -e "${YELLOW}📋 开始恢复...${NC}"
echo ""

# 1. 恢复核心配置
echo -e "${BLUE}[1/6] 恢复核心配置...${NC}"
restore_file "$BACKUP_DIR/config.yaml" "$OPENCLAW_DIR/config.yaml" "  - 主配置文件 (config.yaml)"
restore_file "$BACKUP_DIR/openclaw.json" "$OPENCLAW_DIR/openclaw.json" "  - 运行时配置 (openclaw.json)"

# 2. 恢复身份认证
echo ""
echo -e "${BLUE}[2/6] 恢复身份认证...${NC}"
if [ -d "$BACKUP_DIR/identity" ]; then
    mkdir -p "$OPENCLAW_DIR/identity"
    rsync -av "$BACKUP_DIR/identity/" "$OPENCLAW_DIR/identity/"
    echo -e "${GREEN}✓${NC}   身份认证目录"
else
    echo -e "${YELLOW}⚠${NC}   身份认证目录不存在"
fi

# 3. 恢复工作区
echo ""
echo -e "${BLUE}[3/6] 恢复工作区...${NC}"
if [ -d "$BACKUP_DIR/workspace" ]; then
    mkdir -p "$WORKSPACE_DIR"
    rsync -av "$BACKUP_DIR/workspace/" "$WORKSPACE_DIR/"
    echo -e "${GREEN}✓${NC}   工作区文件"
else
    echo -e "${YELLOW}⚠${NC}   工作区目录不存在"
fi

# 4. 恢复扩展
echo ""
echo -e "${BLUE}[4/6] 恢复扩展...${NC}"
if [ -d "$BACKUP_DIR/extensions" ]; then
    mkdir -p "$OPENCLAW_DIR/extensions"
    rsync -av "$BACKUP_DIR/extensions/" "$OPENCLAW_DIR/extensions/"
    echo -e "${GREEN}✓${NC}   扩展目录"
else
    echo -e "${YELLOW}⚠${NC}   扩展目录不存在"
fi

# 5. 恢复 Feishu 配置
echo ""
echo -e "${BLUE}[5/6] 恢复 Feishu 配置...${NC}"
if [ -d "$BACKUP_DIR/feishu" ]; then
    mkdir -p "$OPENCLAW_DIR/feishu"
    rsync -av "$BACKUP_DIR/feishu/" "$OPENCLAW_DIR/feishu/"
    echo -e "${GREEN}✓${NC}   Feishu 配置目录"
else
    echo -e "${YELLOW}⚠${NC}   Feishu 配置目录不存在"
fi

# 6. 恢复其他配置
echo ""
echo -e "${BLUE}[6/6] 恢复其他配置...${NC}"
restore_file "$BACKUP_DIR/devices/" "$OPENCLAW_DIR/devices/" "  - 设备配置"
restore_file "$BACKUP_DIR/cron/" "$OPENCLAW_DIR/cron/" "  - 定时任务"
restore_file "$BACKUP_DIR/agents/" "$OPENCLAW_DIR/agents/" "  - Agent 配置"
restore_file "$BACKUP_DIR/memory/" "$OPENCLAW_DIR/memory/" "  - 记忆文件"
restore_file "$BACKUP_DIR/subagents/" "$OPENCLAW_DIR/subagents/" "  - Subagent 配置"

# 设置权限
echo ""
echo -e "${YELLOW}🔒 设置文件权限...${NC}"
chmod 600 "$OPENCLAW_DIR/config.yaml" 2>/dev/null || true
chmod 600 "$OPENCLAW_DIR/openclaw.json" 2>/dev/null || true
chmod 700 "$OPENCLAW_DIR/identity" 2>/dev/null || true
echo -e "${GREEN}✓${NC} 权限设置完成"

# 重启 Gateway 提示
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  恢复完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo ""
echo "1. 重启 OpenClaw Gateway："
echo -e "   ${BLUE}openclaw gateway restart${NC}"
echo ""
echo "2. 验证状态："
echo -e "   ${BLUE}openclaw status${NC}"
echo ""
echo "3. 检查工作区："
echo -e "   ${BLUE}ls -la $WORKSPACE_DIR${NC}"
echo ""
echo -e "${GREEN}✓${NC} 所有配置已恢复！"
echo ""

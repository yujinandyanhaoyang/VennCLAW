#!/bin/bash
# =============================================================================
# OpenClaw 配置备份脚本
# =============================================================================
# 用途：备份 OpenClaw 的所有配置文件和数据
# 使用：./backup-openclaw.sh [备份目录]
# 示例：./backup-openclaw.sh /root/backups/openclaw-20260311
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认备份目录
BACKUP_DIR="${1:-/root/backups/openclaw-$(date +%Y%m%d-%H%M%S)}"

# 源目录
OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$HOME/.openclaw/workspace"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  OpenClaw 配置备份脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 OpenClaw 是否安装
if ! command -v openclaw &> /dev/null; then
    echo -e "${RED}错误：OpenClaw 未安装${NC}"
    exit 1
fi

OPENCLAW_VERSION=$(openclaw --version 2>&1 | head -1)
echo -e "${GREEN}✓${NC} OpenClaw 版本：${OPENCLAW_VERSION}"

# 检查源目录是否存在
if [ ! -d "$OPENCLAW_DIR" ]; then
    echo -e "${RED}错误：OpenClaw 目录不存在：$OPENCLAW_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} OpenClaw 目录：$OPENCLAW_DIR"
echo ""

# 创建备份目录
echo -e "${YELLOW}📦 创建备份目录：$BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"

# 备份函数
backup_file() {
    local src="$1"
    local dst="$2"
    local desc="$3"
    
    if [ -e "$src" ]; then
        cp -r "$src" "$dst"
        echo -e "${GREEN}✓${NC} $desc"
    else
        echo -e "${YELLOW}⚠${NC} $desc (不存在，跳过)"
    fi
}

# 开始备份
echo ""
echo -e "${YELLOW}📋 开始备份...${NC}"
echo ""

# 1. 备份核心配置
echo -e "${BLUE}[1/6] 备份核心配置...${NC}"
backup_file "$OPENCLAW_DIR/config.yaml" "$BACKUP_DIR/config.yaml" "  - 主配置文件 (config.yaml)"
backup_file "$OPENCLAW_DIR/openclaw.json" "$BACKUP_DIR/openclaw.json" "  - 运行时配置 (openclaw.json)"

# 2. 备份身份认证
echo ""
echo -e "${BLUE}[2/6] 备份身份认证...${NC}"
mkdir -p "$BACKUP_DIR/identity"
backup_file "$OPENCLAW_DIR/identity/" "$BACKUP_DIR/identity/" "  - 身份认证目录"

# 3. 备份工作区
echo ""
echo -e "${BLUE}[3/6] 备份工作区...${NC}"
if [ -d "$WORKSPACE_DIR" ]; then
    # 排除 .git 目录（已推送到 GitHub）
    rsync -av --exclude='.git' "$WORKSPACE_DIR/" "$BACKUP_DIR/workspace/"
    echo -e "${GREEN}✓${NC}   工作区文件 (排除 .git)"
else
    echo -e "${YELLOW}⚠${NC}   工作区目录不存在"
fi

# 4. 备份扩展
echo ""
echo -e "${BLUE}[4/6] 备份扩展...${NC}"
if [ -d "$OPENCLAW_DIR/extensions" ]; then
    rsync -av "$OPENCLAW_DIR/extensions/" "$BACKUP_DIR/extensions/"
    echo -e "${GREEN}✓${NC}   扩展目录"
else
    echo -e "${YELLOW}⚠${NC}   扩展目录不存在"
fi

# 5. 备份 Feishu 配置
echo ""
echo -e "${BLUE}[5/6] 备份 Feishu 配置...${NC}"
if [ -d "$OPENCLAW_DIR/feishu" ]; then
    rsync -av "$OPENCLAW_DIR/feishu/" "$BACKUP_DIR/feishu/"
    echo -e "${GREEN}✓${NC}   Feishu 配置目录"
else
    echo -e "${YELLOW}⚠${NC}   Feishu 配置目录不存在"
fi

# 6. 备份其他重要文件
echo ""
echo -e "${BLUE}[6/6] 备份其他配置...${NC}"
mkdir -p "$BACKUP_DIR/devices"
mkdir -p "$BACKUP_DIR/cron"
mkdir -p "$BACKUP_DIR/agents"

backup_file "$OPENCLAW_DIR/devices/" "$BACKUP_DIR/devices/" "  - 设备配置"
backup_file "$OPENCLAW_DIR/cron/" "$BACKUP_DIR/cron/" "  - 定时任务"
backup_file "$OPENCLAW_DIR/agents/" "$BACKUP_DIR/agents/" "  - Agent 配置"
backup_file "$OPENCLAW_DIR/memory/" "$BACKUP_DIR/memory/" "  - 记忆文件"
backup_file "$OPENCLAW_DIR/subagents/" "$BACKUP_DIR/subagents/" "  - Subagent 配置"

# 生成备份清单
echo ""
echo -e "${YELLOW}📝 生成备份清单...${NC}"
cat > "$BACKUP_DIR/BACKUP_INFO.md" << EOF
# OpenClaw 备份信息

**备份时间**: $(date '+%Y-%m-%d %H:%M:%S')
**OpenClaw 版本**: $OPENCLAW_VERSION
**备份目录**: $BACKUP_DIR
**源目录**: $OPENCLAW_DIR

## 备份内容

- config.yaml - 主配置文件
- openclaw.json - 运行时配置
- identity/ - 身份认证
- workspace/ - 工作区（排除 .git）
- extensions/ - 扩展
- feishu/ - Feishu 配置
- devices/ - 设备配置
- cron/ - 定时任务
- agents/ - Agent 配置
- memory/ - 记忆文件
- subagents/ - Subagent 配置

## 恢复方法

执行恢复脚本：
\`\`\`bash
bash /root/WORK/VennCLAW/scripts/restore-openclaw.sh $BACKUP_DIR
\`\`\`

## 注意事项

1. 恢复前请确保已安装相同版本的 OpenClaw
2. 恢复会覆盖现有配置，请先备份当前配置
3. 恢复后需要重启 OpenClaw Gateway
EOF

echo -e "${GREEN}✓${NC}   备份清单 (BACKUP_INFO.md)"

# 计算备份大小
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  备份完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "备份目录：${BLUE}$BACKUP_DIR${NC}"
echo -e "备份大小：${BLUE}$BACKUP_SIZE${NC}"
echo ""
echo -e "${YELLOW}提示：${NC}执行以下命令恢复配置："
echo -e "${BLUE}bash /root/WORK/VennCLAW/scripts/restore-openclaw.sh $BACKUP_DIR${NC}"
echo ""

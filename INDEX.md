# OpenClaw Agent 集群系统 - 索引 📚

> 基于 Datawhale 教程《OpenClaw + Claude Code：一个人就能搭建完整的开发团队！》（2026/2/25）

---

## ✅ 部署状态

**目标目录**: `F:\Pythonfiles\work_files\work_project\NewTechnologyLearning\OPENCLAW`  
**部署时间**: 2026-03-08 20:20 GMT+8  
**状态**: ✅ **已完成**

---

## 📂 已部署文件清单

### Core System（核心系统）

| 文件 | 路径 | 说明 |
|------|------|------|
| `agent-manager.py` | `.openclaw-agents/` | Zoe 编排层核心脚本 |
| `agents.yaml` | `.openclaw-agents/configs/` | Agent 类型和参数配置 |
| `cron-jobs.yaml` | `.openclaw-agents/configs/` | 定时任务配置 |
| `task-tracker.jsonl` | `.openclaw-agents/configs/` | 任务追踪日志格式 |

### Documentation（文档）

| 文件 | 位置 | 用途 |
|------|------|------|
| `DEPLOYMENT_GUIDE.md` | 工作空间根目录 | 完整部署指南 |
| `QUICKSTART.md` | 工作空间根目录 | 3 分钟快速开始 |
| `INDEX.md` | 工作空间根目录 | 本文档 |

### Directory Structure（目录结构）

```
.
├── .openclaw-agents/          # ✓ Agent 集群配置和核心脚本
│   ├── agent-manager.py       # ✓ 编排层核心 (Zoe)
│   └── configs/               # ✓ 配置文件
│       ├── task-tracker.jsonl # ✓ 任务追踪日志
│       ├── agents.yaml        # ✓ Agent 配置
│       └── cron-jobs.yaml     # ✓ Cron 任务
├── src/openclaw/              # ✓ OpenClaw 源代码模块
│   ├── context/               # ✓ 业务上下文存放处
│   │   ├── meeting-notes/     # ✓ 会议记录目录
│   │   └── customer-data/     # ✓ 客户数据目录
│   └── models/                # ✓ AI 模型适配层目录
├── worktrees/                 # ✓ Git worktree 隔离环境
└── tmux-sessions/             # ✓ Tmux 会话记录
```

---

## 🎯 核心架构

```
┌─────────────────────────────────────────┐
│      OpenClaw Zoe (编排层核心)          │
│  • 理解业务需求                         │
│  • 智能选择最佳 Agent                   │
│  • 监控任务进度                         │
│  • 改进版 Ralph Loop 学习循环           │
└──────────────┬──────────────────────────┘
               │ 精准指令
    ┌──────────┼──────────┐
    ↓          ↓          ↓
 Codex    Claude Code    Gemini
(主力开发)(前端快速)    (UI 设计)
    ↑          ↑          ↑
    └─────┬────┴────┬────┘
          ↓         ↓
    Git Worktree  Tmux Sessions
   (隔离环境)   (后台会话)
```

---

## ⚡ 快速使用命令

```bash
# 查看所有可用命令
python .openclaw-agents/agent-manager.py

# 创建新任务（系统自动推荐 Agent）
python .openclaw-agents/agent-manager.py create-task "你的任务描述"

# 执行特定任务
python .openclaw-agents/agent-manager.py run <任务 ID>

# 监控所有任务
python .openclaw-agents/agent-manager.py monitor

# 查看单个任务状态
python .openclaw-agents/agent-manager.py status <任务 ID>
```

---

## 🤖 Agent 选择策略

| Agent | 成本/小时 | 最佳场景 | 优先级 |
|-------|----------|---------|--------|
| **Codex** | ~$90 | 后端逻辑、复杂 bug、多文件重构 | High (90% 任务) |
| **Claude Code** | ~100 | 前端开发、git 操作、快速迭代 | Medium |
| **Gemini** | ~$15 | UI 设计、视觉规范生成 | Low |

---

## 📊 预期效果

根据教程数据：

- **单日最高提交**: 94 次
- **平均每日提交**: 50 次
- **PR 完成时间**: 30 分钟内 7 个 PR
- **客户需求交付**: 当天上线
- **月度成本**: $20-$190

---

## 🔧 核心机制

### 1. 双层架构分离
- **编排层 (Zoe)**: 持有业务上下文，负责理解和调度
- **执行层 (Code Agents)**: 专注代码编写，无业务敏感信息访问权限

### 2. 改进版 Ralph Loop
从"重复执行"到"动态学习":
1. 拉取上下文 → 读取业务背景和代码库
2. 生成输出 → Agent 编写代码
3. 评估结果 → CI/PR/AI 审查
4. 保存学习 → 记录成功模式，失败则重写 prompt

### 3. 主动发现任务
- 早上扫描 Sentry 错误日志
- 会议后扫描会议记录提取需求
- 晚上扫描 git log 更新文档

---

## 🛠 依赖要求

- [x] Python 3.8+
- [ ] Git (已安装)
- [ ] Tmux (可选，用于后台运行)
- [ ] API Keys (Codex/Claude/Gemini，按需选择)
- [ ] Obsidian (可选，存储业务上下文)

---

## 📝 下一步行动

### 立即开始
1. 阅读 [`QUICKSTART.md`](./QUICKSTART.md)
2. 运行 `python .openclaw-agents/agent-manager.py`
3. 创建你的第一个任务！

### 深入学习
1. 详细部署指南: [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md)
2. 原始教程: `openclaw-ai-agent-development-system-guide.md.md`
3. 本文档: `INDEX.md`

---

## 💡 重要提示

1. **添加业务上下文**  
   在 `src/openclaw/context/` 下放置你的会议记录和客户数据，让 Zoe 更好地理解项目背景。

2. **定期维护**  
   建议每天清理超过 72 小时的历史任务 worktree，保持环境整洁。

3. **监控成本**  
   定期检查 API 调用次数和 Token 使用量，避免意外费用。

4. **持续优化**  
   根据实际使用情况，编辑 `agents.yaml` 调整 Agent 配置。

---

## 🌟 作者与来源

- **实现者**: Venn (你的 AI 助理)
- **基于**: Datawhale 教程 (2026/2/25)
- **许可**: MIT License
- **理念**: 2026 年，一个有远见的开发者可以凭借 AI 协作团队创造百万美元价值的产品！

---

**祝你开发愉快！** 🚀✨

*记住：你不是一个人在战斗——你背后有一个完整的 AI 开发团队！*

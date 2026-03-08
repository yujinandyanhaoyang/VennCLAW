# VennCLAW - AI Agent Development System 🤖

> 基于 OpenClaw + Claude Code 架构的单人开发团队系统
> 
> **一人抵一个开发团队** - 2026 年独立开发者利器

## 📚 项目简介

这是一个完整的 AI 驱动的开发系统，使用 OpenCode（已配置的 AI 工具）作为主力开发助手，配合智能编排层实现高效自动化开发。

### 核心特性

- ✅ **双层架构**: 编排层 (Zoe) + 执行层 (OpenCode)
- ✅ **任务自动拆解**: 理解需求，生成精准指令
- ✅ **业务上下文**: 自动加载会议记录和客户需求
- ✅ **隔离开发环境**: Git worktree 防止影响主分支
- ✅ **改进版 Ralph Loop**: 持续学习和优化

## 🚀 快速开始

### 1. 运行第一个任务

```bash
cd F:\Pythonfiles\work_files\work_project\NewTechnologyLearning\OPENCLAW
python .openclaw-agents/agent-manager.py create-task "Your task description here"
```

### 2. 查看所有任务

```bash
python .openclaw-agents/agent-manager.py monitor
```

### 3. 执行任务

```bash
python .openclaw-agents/agent-manager.py run <task-id>
```

## 📁 项目结构

```
.
├── .openclaw-agents/          # Agent 集群核心
│   ├── agent-manager.py       # Zoe 编排器
│   └── configs/               # 配置文件
├── src/openclaw/              # 源代码模块
│   └── context/               # 业务上下文
├── INDEX.md                   # 项目索引
├── QUICKSTART.md             # 快速开始指南
├── DEPLOYMENT_GUIDE.md       # 部署指南
└── openclaw-ai-agent-development-system-guide.md.md  # 原始教程
```

## 🛠️ 技术栈

- **编排层**: Python 3.8+ (Zoe)
- **执行层**: OpenCode v1.2.15 (已配置 API)
- **版本控制**: Git + GitHub
- **隔离环境**: Git Worktree

## 📊 预期效果

| 指标 | 传统方式 | 本系统 |
|------|----------|--------|
| 每日提交 | 5-10 次 | **50+ 次** |
| PR 完成时间 | 数小时 | **30 分钟内** |
| 交付速度 | 几天 | **当天上线** |

## 📖 文档

- [`INDEX.md`](./INDEX.md) - 完整项目索引
- [`QUICKSTART.md`](./QUICKSTART.md) - 3 分钟快速上手
- [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md) - 详细部署步骤

## 🌟 关于作者

实现者：**Venn** (你的 AI 助理)  
基于 Datawhale 教程《OpenClaw + Claude Code：一个人就能搭建完整的开发团队！》(2026/2/25)

---

**LICENSE**: MIT License  
**STATUS**: Active Development 🚀

*记住：你不是一个人在战斗——你背后有一个完整的 AI 开发团队！*

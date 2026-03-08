# OpenClaw Agent 集群 - 3 分钟快速开始 🚀

## 📍 当前位置

你的代码库: `F:\Pythonfiles\work_files\work_project\NewTechnologyLearning\OPENCLAW`

Agent 系统核心文件已就绪：`.openclaw-agents/agent-manager.py`

---

## ⚡ 立即体验（5 个命令）

### 1️⃣ 查看帮助
```bash
python .openclaw-agents/agent-manager.py
```

你会看到可用的命令列表。

### 2️⃣ 创建一个示例任务
```bash
python .openclaw-agents/agent-manager.py create-task "测试任务：实现用户登录功能"
```

系统会告诉你推荐哪个 Agent（Codex/Claude/Gemini）。

### 3️⃣ 查看所有任务
```bash
python .openclaw-agents/agent-manager.py monitor
```

### 4️⃣ 执行任务（启动 Agent）
```bash
python .openclaw-agents/agent-manager.py run <任务 ID>
```
将 `<任务 ID>` 替换为实际的任务 ID（如 `feat-a1b2c3d4e5f6`）。

### 5️⃣ 检查任务状态
```bash
python .openclaw-agents/agent-manager.py status <任务 ID>
```

---

## 🎯 Agent 自动选择规则

系统会根据你的任务描述自动选择合适的 Agent：

| 关键词 | 推荐 Agent | 适用场景 |
|--------|-----------|---------|
| UI、界面、设计、CSS、HTML | **Gemini** | 视觉相关任务 |
| 前端、React、Vue、JavaScript、TypeScript | **Claude Code** | 前端开发 |
| 后端、数据库、API、逻辑处理 | **Codex** (默认) | 核心业务逻辑 |

---

## 📁 目录说明

```
.
├── .openclaw-agents/          ← 核心系统
│   ├── agent-manager.py       ← Zoe（编排层）
│   └── configs/
│       ├── agents.yaml        ← Agent 配置
│       ├── cron-jobs.yaml     ← 定时任务
│       └── task-tracker.jsonl ← 任务日志
├── src/openclaw/
│   └── context/               ← 业务上下文（会议记录、客户数据）
├── worktrees/                 ← Git 隔离环境
└── tmux-sessions/             ← Tmux 会话记录
```

---

## 💼 完整工作流程示例

假设有一个真实的客户需求：

### 场景：企业客户要求添加团队共享配置功能

#### 步骤 1: Zoe 理解需求
```bash
python .openclaw-agents/agent-manager.py create-task \
  "企业客户需要同步已有配置到团队内所有成员，支持保存/编辑现有配置模板"
```

#### 步骤 2: 系统自动生成
- ✅ 任务 ID: `feat-team-config-sync-abc123`
- ✅ 推荐 Agent: `codex`（因为是复杂的业务逻辑）
- ✅ 创建隔离工作区: `../feat-team-config-sync-abc123`
- ✅ 创建新分支: `feat/team-config-sync-abc123`

#### 步骤 3: 后台运行
```bash
python .openclaw-agents/agent-manager.py run feat-team-config-sync-abc123
```

Codex 会在 tmux 后台会话中编写代码，不影响你当前工作。

#### 步骤 4: 持续监控
```bash
# 每 10 分钟可以检查一次
python .openclaw-agents/agent-manager.py monitor
```

#### 步骤 5: 人工审查（最后一步）
当 CI 通过且所有测试通过后，你只需 5-10 分钟审查 PR，然后合并即可上线！

---

## 🔑 关键优势

### ✨ 双层架构带来的好处

**编排层（Zoe/OpenClaw）**
- 理解业务背景和客户需求
- 智能选择最合适的 Code Agent
- 动态优化 prompt 避免重复错误
- 主动发现潜在开发任务

**执行层（Code Agents）**
- Codex/Claude/Gemini 各司其职
- 专注代码编写和测试
- 独立运行在隔离环境中
- 永远不会接触到客户敏感信息

### 🚀 效率提升

| 传统方式 | 使用 Agent 集群 |
|----------|---------------|
| 手动拆解需求 | Zoe 自动拆解并生成精准 prompt |
| 猜测用哪个工具 | 系统自动推荐最优 Agent |
| 逐个修复 bug | 连续多轮迭代直到 CI 通过 |
| 依赖记忆 | 持续学习历史记录 |
| 每天提交 5-10 次 | **平均 50 次+** |
| 几天完成一个小功能 | **几小时内交付** |

---

## 🎉 立即开始！

准备好体验"一人抵一个开发团队"的感觉了吗？

```bash
# 第一步：创建你的第一个任务
cd F:\Pythonfiles\work_files\work_project\NewTechnologyLearning\OPENCLAW
python .openclaw-agents/agent-manager.py create-task "这里写你要做的功能..."

# 第二步：观察 Zoe 如何为你工作！
```

---

## 📚 下一步阅读

详细的部署指南请查看：`DEPLOYMENT_GUIDE.md`  
原始教程参考：`openclaw-ai-agent-development-system-guide.md.md`

祝你开发愉快！🤖✨

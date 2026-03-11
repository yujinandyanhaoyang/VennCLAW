# VennCLAW OpenClaw 灾难恢复手册

**版本**: v1.0  
**创建时间**: 2026-03-11  
**维护者**: VennCLAW Team  
**紧急联系人**: 项目总监

---

## 📋 目录

1. [概述](#概述)
2. [灾难场景分类](#灾难场景分类)
3. [预防措施](#预防措施)
4. [恢复流程](#恢复流程)
5. [验证与测试](#验证与测试)
6. [常见问题](#常见问题)
7. [附录](#附录)

---

## 概述

### 目的

本手册用于指导操作者在 OpenClaw 配置丢失、服务器故障或其他灾难情况下，快速恢复 VennCLAW 系统的正常运行。

### 适用范围

- OpenClaw 配置丢失
- 服务器重装/重置
- 硬盘故障
- 人为误操作删除
- 其他导致系统不可用的情况

### 恢复时间目标 (RTO)

| 场景 | 目标时间 |
|------|----------|
| 配置丢失 | < 30 分钟 |
| 服务器重装 | < 2 小时 |
| 硬盘故障 | < 4 小时 |

### 恢复点目标 (RPO)

- **备份频率**: 每日自动备份
- **数据丢失**: 最多丢失 24 小时内的配置变更

---

## 灾难场景分类

### 级别 1：配置丢失（轻度）

**症状**：
- `~/.openclaw/` 目录被删除或损坏
- OpenClaw 无法启动
- 工作区文件丢失

**原因**：
- 误操作删除
- 文件系统损坏
- 软件升级失败

**恢复难度**: ⭐⭐ 简单

---

### 级别 2：服务器重装（中度）

**症状**：
- 操作系统重装
- Node.js 和 OpenClaw 未安装
- 所有配置丢失

**原因**：
- 系统升级
- 安全加固
- 服务器迁移

**恢复难度**: ⭐⭐⭐ 中等

---

### 级别 3：硬盘/服务器故障（严重）

**症状**：
- 服务器无法启动
- 硬盘损坏
- 数据完全丢失

**原因**：
- 硬件故障
- 云服务中断
- 自然灾害

**恢复难度**: ⭐⭐⭐⭐⭐ 困难

---

## 预防措施

### 日常备份

#### 自动备份（推荐）

```bash
# 编辑 crontab
crontab -e

# 添加每日备份任务（每天凌晨 3 点）
0 3 * * * /root/WORK/VennCLAW/scripts/backup-openclaw.sh /root/backups/daily/openclaw-$(date +\%Y\%m\%d)

# 添加每周备份任务（每周日凌晨 2 点）
0 2 * * 0 /root/WORK/VennCLAW/scripts/backup-openclaw.sh /root/backups/weekly/openclaw-$(date +\%Y\%m\%d)
```

#### 手动备份时机

- ✅ 重大配置更改前
- ✅ 系统升级前
- ✅ 添加新功能后
- ✅ 每月定期检查

#### 备份验证

```bash
# 每周检查备份完整性
ls -lh /root/backups/
cat /root/backups/latest/BACKUP_INFO.md
```

---

### 备份存储策略

#### 三级备份

| 级别 | 位置 | 保留时间 | 用途 |
|------|------|----------|------|
| **L1** | `/root/backups/` | 7 天 | 快速恢复 |
| **L2** | 阿里云 OSS | 30 天 | 灾难恢复 |
| **L3** | 外部存储 | 永久 | 归档备份 |

#### OSS 备份配置（推荐）

```bash
# 安装 ossutil
wget http://gosspublic.alicdn.com/ossutil/1.7.19/ossutil64
chmod +x ossutil64
./ossutil64 config

# 同步备份到 OSS
./ossutil64 sync /root/backups/ oss://vennclaw-backups/openclaw/
```

---

## 恢复流程

### 场景 1：配置丢失恢复

**适用情况**：OpenClaw 已安装，但配置丢失

**预计时间**：15-30 分钟

---

#### 步骤 1：确认问题

```bash
# 检查 OpenClaw 是否安装
which openclaw
# 预期输出：/usr/bin/openclaw

# 检查配置目录
ls -la ~/.openclaw/
# 如果目录为空或不存在，需要恢复

# 检查 Gateway 状态
openclaw gateway status
# 如果报错，需要恢复
```

---

#### 步骤 2：找到备份

```bash
# 列出所有备份
ls -lht /root/backups/

# 查看最近的备份
ls -la /root/backups/ | head -10

# 查看备份信息
cat /root/backups/openclaw-20260311-094707/BACKUP_INFO.md
```

**备份目录命名规则**：
```
openclaw-YYYYMMDD-HHMMSS
示例：openclaw-20260311-094707
```

---

#### 步骤 3：执行恢复

```bash
# 进入脚本目录
cd /root/WORK/VennCLAW/scripts

# 执行恢复（替换为实际备份目录）
./restore-openclaw.sh /root/backups/openclaw-20260311-094707

# 按提示确认
# 输入：y
```

**恢复过程输出示例**：
```
========================================
  OpenClaw 配置恢复脚本
========================================
✓ 备份目录：/root/backups/openclaw-20260311-094707
✓ OpenClaw 版本：2026.3.7
⚠️  警告：恢复操作将覆盖现有配置！
是否继续？(y/N): y

[1/6] 恢复核心配置...
  ✓ 主配置文件 (config.yaml)
  ✓ 运行时配置 (openclaw.json)
...
恢复完成！
```

---

#### 步骤 4：重启服务

```bash
# 重启 Gateway
openclaw gateway restart

# 等待 10 秒
sleep 10

# 检查状态
openclaw status
```

---

#### 步骤 5：验证恢复

```bash
# 1. 检查 Gateway 状态
openclaw gateway status

# 2. 检查工作区
ls -la ~/.openclaw/workspace/

# 3. 检查配置文件
cat ~/.openclaw/config.yaml

# 4. 发送测试消息（如适用）
# 在 Feishu 群聊中发送测试消息
```

**验证清单**：
- [ ] Gateway 正常运行
- [ ] 工作区文件存在
- [ ] 配置文件正确
- [ ] 可以正常收发消息
- [ ] 定时任务正常执行

---

### 场景 2：服务器重装恢复

**适用情况**：操作系统重装，OpenClaw 未安装

**预计时间**：30-60 分钟

---

#### 步骤 1：安装系统依赖

```bash
# 更新系统
apt-get update && apt-get upgrade -y

# 安装必要工具
apt-get install -y curl wget git rsync vim
```

---

#### 步骤 2：安装 Node.js

```bash
# 方法 A：使用 NodeSource（推荐）
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# 验证安装
node --version
# 预期输出：v22.x.x

npm --version
# 预期输出：10.x.x
```

---

#### 步骤 3：恢复备份文件

```bash
# 如果备份在本地
ls -la /root/backups/

# 如果备份在 OSS
# 1. 安装 ossutil
wget http://gosspublic.alicdn.com/ossutil/1.7.19/ossutil64
chmod +x ossutil64
./ossutil64 config

# 2. 下载备份
./ossutil64 cp -r oss://vennclaw-backups/openclaw/latest/ /root/backups/latest/
```

---

#### 步骤 4：执行一键安装

```bash
# 进入脚本目录
cd /root/WORK/VennCLAW/scripts

# 执行一键安装（包含恢复）
sudo ./install-openclaw.sh /root/backups/openclaw-20260311-094707

# 按提示操作
# - 如果提示重新安装 OpenClaw，输入：y
# - 如果提示启动 Gateway，输入：y
```

---

#### 步骤 5：配置 Gateway

```bash
# 检查 Gateway 状态
openclaw gateway status

# 如果未启动，手动启动
openclaw gateway start

# 查看日志确认正常
openclaw logs | tail -50
```

---

#### 步骤 6：验证恢复

参考 [场景 1 - 步骤 5](#步骤-5 验证恢复)

---

### 场景 3：硬盘/服务器故障恢复

**适用情况**：服务器完全不可用，需要新建服务器

**预计时间**：2-4 小时

---

#### 步骤 1：准备新服务器

**最低配置要求**：

| 资源 | 要求 | 推荐 |
|------|------|------|
| CPU | 2 核 | 4 核 |
| 内存 | 4 GB | 8 GB |
| 硬盘 | 40 GB | 80 GB |
| 系统 | Ubuntu 20.04+ | Ubuntu 22.04 |

**云服务器选择**：
- 阿里云 ECS（推荐，与现有备份兼容）
- 腾讯云 CVM
- 华为云 ECS

---

#### 步骤 2：配置网络和安全组

**开放端口**：

| 端口 | 用途 | 协议 |
|------|------|------|
| 22 | SSH | TCP |
| 8100 | ACPs-app | TCP |
| 18789 | OpenClaw Gateway | TCP |

**安全组规则**：
```
入站规则：
- 22/TCP: 允许管理 IP
- 8100/TCP: 允许应用访问
- 18789/TCP: 允许内部访问
```

---

#### 步骤 3：恢复备份

```bash
# 1. 从 OSS 下载备份
wget http://gosspublic.alicdn.com/ossutil/1.7.19/ossutil64
chmod +x ossutil64
./ossutil64 config

./ossutil64 cp -r oss://vennclaw-backups/openclaw/ /root/backups/

# 2. 克隆 VennCLAW 仓库
cd /root
mkdir -p WORK
cd WORK
git clone https://github.com/yujinandyanhaoyang/VennCLAW.git

# 3. 执行一键安装
cd VennCLAW/scripts
sudo ./install-openclaw.sh /root/backups/latest/
```

---

#### 步骤 4：配置 DNS 和域名（如适用）

```bash
# 更新 DNS 记录
# 在域名服务商处添加 A 记录：
# @ -> 新服务器 IP
# openclaw -> 新服务器 IP
```

---

#### 步骤 5：全面验证

```bash
# 1. 系统检查
openclaw status

# 2. 功能检查
# - 发送测试消息
# - 检查定时任务
# - 检查工作区

# 3. 性能检查
# - 响应时间
# - CPU/内存使用率
```

---

## 验证与测试

### 恢复后验证清单

#### 基础验证

- [ ] `openclaw --version` 显示正确版本
- [ ] `openclaw gateway status` 显示运行中
- [ ] `~/.openclaw/config.yaml` 存在且正确
- [ ] `~/.openclaw/openclaw.json` 存在且正确
- [ ] `~/.openclaw/workspace/` 包含所有文件

#### 功能验证

- [ ] 可以接收消息
- [ ] 可以发送消息
- [ ] Agent 功能正常
- [ ] 定时任务正常执行
- [ ] Feishu 集成正常

#### 性能验证

- [ ] 响应时间 < 3 秒
- [ ] CPU 使用率 < 50%
- [ ] 内存使用率 < 70%
- [ ] 无错误日志

---

### 定期恢复测试

**频率**：每季度一次

**流程**：

1. 准备测试服务器
2. 从备份恢复
3. 执行验证清单
4. 记录测试结果
5. 更新恢复手册

**测试报告模板**：

```markdown
## 恢复测试报告

**测试日期**: YYYY-MM-DD
**测试人员**: [姓名]
**备份版本**: openclaw-YYYYMMDD-HHMMSS

### 测试结果

| 项目 | 预期 | 实际 | 状态 |
|------|------|------|------|
| 恢复时间 | < 30 分钟 | XX 分钟 | ✅/❌ |
| 配置完整 | 100% | XX% | ✅/❌ |
| 功能正常 | 全部 | XX 项 | ✅/❌ |

### 问题记录

[记录发现的问题]

### 改进建议

[提出改进建议]
```

---

## 常见问题

### Q1: 恢复后 Gateway 无法启动

**症状**：
```bash
openclaw gateway start
# 报错：Failed to start gateway
```

**解决方案**：

```bash
# 1. 查看日志
openclaw logs | tail -100

# 2. 检查端口占用
lsof -i :18789

# 3. 检查配置文件
cat ~/.openclaw/config.yaml

# 4. 重新初始化
openclaw gateway stop
openclaw gateway start

# 5. 如仍失败，联系技术支持
```

---

### Q2: 工作区文件丢失

**症状**：
```bash
ls ~/.openclaw/workspace/
# 目录为空
```

**解决方案**：

```bash
# 方法 1: 从备份恢复
cd /root/WORK/VennCLAW/scripts
./restore-openclaw.sh /root/backups/latest/

# 方法 2: 从 Git 恢复
cd ~/.openclaw/workspace
git pull origin main

# 方法 3: 手动恢复
cp -r /root/backups/latest/workspace/* ~/.openclaw/workspace/
```

---

### Q3: 备份文件损坏

**症状**：
```bash
./restore-openclaw.sh /root/backups/xxx/
# 报错：文件不完整或损坏
```

**解决方案**：

```bash
# 1. 检查备份完整性
ls -la /root/backups/xxx/
cat /root/backups/xxx/BACKUP_INFO.md

# 2. 使用其他备份
ls -lht /root/backups/ | head -5
# 选择第二新的备份

# 3. 从 OSS 恢复
./ossutil64 cp -r oss://vennclaw-backups/openclaw/ /root/backups/

# 4. 联系技术支持获取帮助
```

---

### Q4: Feishu 配置丢失

**症状**：
- 无法接收 Feishu 消息
- 无法发送 Feishu 消息
- 设备认证失败

**解决方案**：

```bash
# 1. 检查设备配置
cat ~/.openclaw/identity/device.json

# 2. 检查 Feishu 配置
cat ~/.openclaw/feishu/dedup/default.json

# 3. 从备份恢复
./restore-openclaw.sh /root/backups/latest/

# 4. 重新配置设备（如必要）
# 参考 Feishu 开发者文档重新配置
```

---

### Q5: 定时任务未执行

**症状**：
- Cron 任务未执行
- 心跳检测未运行

**解决方案**：

```bash
# 1. 检查 cron 服务
systemctl status cron

# 2. 检查 cron 配置
crontab -l
ls -la ~/.openclaw/cron/

# 3. 重启 cron 服务
systemctl restart cron

# 4. 手动执行测试
bash /root/WORK/VennCLAW/scripts/backup-openclaw.sh

# 5. 查看日志
grep CRON /var/log/syslog | tail -20
```

---

## 附录

### 附录 A：关键文件清单

| 文件 | 路径 | 重要性 |
|------|------|--------|
| 主配置 | `~/.openclaw/config.yaml` | ⭐⭐⭐⭐⭐ |
| 运行时配置 | `~/.openclaw/openclaw.json` | ⭐⭐⭐⭐⭐ |
| 设备认证 | `~/.openclaw/identity/device.json` | ⭐⭐⭐⭐⭐ |
| 工作区 | `~/.openclaw/workspace/` | ⭐⭐⭐⭐ |
| Feishu 配置 | `~/.openclaw/feishu/` | ⭐⭐⭐⭐ |
| 定时任务 | `~/.openclaw/cron/` | ⭐⭐⭐ |

---

### 附录 B：常用命令速查

```bash
# OpenClaw 管理
openclaw status              # 查看状态
openclaw gateway start       # 启动 Gateway
openclaw gateway stop        # 停止 Gateway
openclaw gateway restart     # 重启 Gateway
openclaw logs                # 查看日志
openclaw help                # 帮助

# 备份恢复
cd /root/WORK/VennCLAW/scripts
./backup-openclaw.sh                     # 备份
./restore-openclaw.sh <备份目录>          # 恢复
./install-openclaw.sh [备份目录]          # 安装 + 恢复

# 系统检查
df -h                        # 磁盘空间
free -h                      # 内存使用
top -bn1 | head -20          # 进程状态
systemctl status cron        # Cron 状态
```

---

### 附录 C：联系信息

**技术支持**：
- GitHub Issues: https://github.com/yujinandyanhaoyang/VennCLAW/issues
- OpenClaw 文档：https://docs.openclaw.ai
- 紧急联系人：项目总监

**备份存储**：
- 本地备份：`/root/backups/`
- OSS 备份：`oss://vennclaw-backups/openclaw/`

---

### 附录 D：版本历史

| 版本 | 日期 | 变更 | 作者 |
|------|------|------|------|
| v1.0 | 2026-03-11 | 初始版本 | VennCLAW Team |

---

**文档结束**

---

## 📞 紧急联系流程

如遇无法解决的灾难，请按以下流程联系：

1. **尝试本手册恢复流程**
2. **查看 GitHub Issues 是否有类似问题**
3. **联系项目总监**
4. **提交 GitHub Issue（如适用）**

---

**保持冷静，按步骤操作，大多数灾难都可以在 30 分钟内恢复！** 🛡️

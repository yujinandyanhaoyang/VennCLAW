# VennCLaw OpenClaw 备份与恢复工具

## 📋 概述

本目录包含三个脚本，用于 OpenClaw 的**安装**、**备份**和**恢复**，防范意外事故导致配置丢失。

| 脚本 | 用途 | 大小 |
|------|------|------|
| `install-openclaw.sh` | 一键安装 OpenClaw + 恢复配置 | 5.2 KB |
| `backup-openclaw.sh` | 备份所有 OpenClaw 配置 | 4.4 KB |
| `restore-openclaw.sh` | 从备份恢复配置 | 5.0 KB |

---

## 🚀 快速开始

### 场景 1：全新安装（无备份）

```bash
cd /root/WORK/VennCLAW/scripts
sudo ./install-openclaw.sh
```

### 场景 2：全新安装 + 恢复备份

```bash
cd /root/WORK/VennCLAW/scripts
sudo ./install-openclaw.sh /root/backups/openclaw-20260311-120000
```

### 场景 3：仅备份当前配置

```bash
cd /root/WORK/VennCLAW/scripts
./backup-openclaw.sh
# 或指定备份目录
./backup-openclaw.sh /root/backups/openclaw-backup-$(date +%Y%m%d)
```

### 场景 4：仅恢复配置

```bash
cd /root/WORK/VennCLAW/scripts
./restore-openclaw.sh /root/backups/openclaw-20260311-120000
```

---

## 📦 备份内容

备份脚本会保存以下所有配置：

| 文件/目录 | 说明 | 重要性 |
|-----------|------|--------|
| `config.yaml` | 主配置文件 | ⭐⭐⭐⭐⭐ |
| `openclaw.json` | 运行时配置 | ⭐⭐⭐⭐⭐ |
| `identity/` | 身份认证信息 | ⭐⭐⭐⭐⭐ |
| `workspace/` | 工作区文件 | ⭐⭐⭐⭐ |
| `extensions/` | 扩展插件 | ⭐⭐⭐⭐ |
| `feishu/` | 飞书配置 | ⭐⭐⭐⭐ |
| `devices/` | 设备配置 | ⭐⭐⭐ |
| `cron/` | 定时任务 | ⭐⭐⭐ |
| `agents/` | Agent 配置 | ⭐⭐⭐ |
| `memory/` | 记忆文件 | ⭐⭐ |
| `subagents/` | Subagent 配置 | ⭐⭐ |

**排除项**：
- `.git/` 目录（已推送到 GitHub）

---

## 🛡️ 灾难恢复流程

### 情况 A：OpenClaw 配置丢失

```bash
# 1. 找到最近的备份
ls -la /root/backups/

# 2. 恢复配置
cd /root/WORK/VennCLAW/scripts
./restore-openclaw.sh /root/backups/openclaw-YYYYMMDD-HHMMSS

# 3. 重启 Gateway
openclaw gateway restart

# 4. 验证
openclaw status
```

### 情况 B：服务器完全重置

```bash
# 1. 安装 Node.js（如果未安装）
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# 2. 从备份恢复（挂载备份盘或下载备份）
cd /root/WORK/VennCLAW/scripts
sudo ./install-openclaw.sh /path/to/backup

# 3. 验证
openclaw status
```

### 情况 C：VennCLAW 代码丢失

```bash
# 1. 从 GitHub 恢复
cd /root/WORK
git clone https://github.com/yujinandyanhaoyang/VennCLAW.git

# 2. 恢复 OpenClaw 配置
cd VennCLAW/scripts
./restore-openclaw.sh /path/to/backup

# 3. 重启服务
openclaw gateway restart
```

---

## 📅 建议的备份策略

### 自动备份（推荐）

添加 cron 任务：

```bash
# 编辑 crontab
crontab -e

# 添加每日备份（每天凌晨 3 点）
0 3 * * * /root/WORK/VennCLAW/scripts/backup-openclaw.sh /root/backups/daily/openclaw-$(date +\%Y\%m\%d)

# 添加每周备份（每周日凌晨 2 点）
0 2 * * 0 /root/WORK/VennCLAW/scripts/backup-openclaw.sh /root/backups/weekly/openclaw-$(date +\%Y\%m\%d)
```

### 手动备份时机

- ✅ 重大配置更改前
- ✅ 系统升级前
- ✅ 添加新 Agent 后
- ✅ 修改 Gateway 配置后
- ✅ 每月定期备份

### 备份存储建议

| 位置 | 优点 | 缺点 | 推荐 |
|------|------|------|------|
| 本地 `/root/backups/` | 快速、免费 | 服务器故障时丢失 | ⭐⭐⭐ |
| 阿里云 OSS | 可靠、可跨区域 | 需要额外成本 | ⭐⭐⭐⭐⭐ |
| GitHub Private Repo | 版本控制、免费 | 不适合大文件 | ⭐⭐⭐ |
| 外部硬盘 | 离线安全 | 需要手动操作 | ⭐⭐⭐⭐ |

**推荐方案**：本地 + OSS 双重备份

---

## 🔧 高级用法

### 自定义备份目录

```bash
# 备份到外部存储
./backup-openclaw.sh /mnt/external-drive/openclaw-backup-$(date +%Y%m%d)

# 备份到 OSS（需要先挂载）
./backup-openclaw.sh /mnt/oss-bucket/openclaw-backups/$(date +%Y%m%d)
```

### 选择性恢复

```bash
# 仅恢复工作区
rsync -av /root/backups/openclaw-xxx/workspace/ ~/.openclaw/workspace/

# 仅恢复配置
cp /root/backups/openclaw-xxx/config.yaml ~/.openclaw/config.yaml
cp /root/backups/openclaw-xxx/openclaw.json ~/.openclaw/openclaw.json
```

### 验证备份完整性

```bash
# 检查备份目录
ls -la /root/backups/openclaw-xxx/

# 查看备份信息
cat /root/backups/openclaw-xxx/BACKUP_INFO.md

# 检查关键文件
test -f /root/backups/openclaw-xxx/config.yaml && echo "✓ config.yaml 存在"
test -f /root/backups/openclaw-xxx/openclaw.json && echo "✓ openclaw.json 存在"
test -d /root/backups/openclaw-xxx/identity && echo "✓ identity 目录存在"
```

---

## ⚠️ 注意事项

### 安全警告

1. **备份文件包含敏感信息**
   - API Key
   - 身份认证令牌
   - 设备配置

2. **权限设置**
   ```bash
   # 确保备份目录权限正确
   chmod 700 /root/backups/
   chmod 600 /root/backups/openclaw-*/config.yaml
   chmod 600 /root/backups/openclaw-*/openclaw.json
   ```

3. **不要上传到公开仓库**
   - GitHub 备份请使用**私有仓库**
   - 不要将备份文件发送到公开渠道

### 恢复前检查

- [ ] 确认 OpenClaw 已安装
- [ ] 确认备份目录存在
- [ ] 确认备份完整性
- [ ] 备份当前配置（以防恢复失败）

### 常见问题

**Q: 恢复后 Gateway 无法启动？**

```bash
# 检查配置
openclaw gateway status

# 查看日志
openclaw logs

# 重新初始化
openclaw gateway stop
openclaw gateway start
```

**Q: 工作区文件丢失？**

```bash
# 从 GitHub 恢复
cd ~/.openclaw/workspace
git pull origin main
```

**Q: 身份认证失效？**

```bash
# 重新配置设备
ls -la ~/.openclaw/identity/
# 如果文件为空，需要重新配置设备
```

---

## 📊 备份历史

| 日期 | 备份大小 | 说明 |
|------|----------|------|
| 2026-03-11 | ~1 MB | 初始备份（创建脚本） |

---

## 🎯 最佳实践

1. **每日自动备份** - 设置 cron 任务
2. **重大更改前手动备份** - 配置修改前执行
3. **双重存储** - 本地 + 云端（OSS）
4. **定期测试恢复** - 每季度测试一次恢复流程
5. **版本控制** - 工作区使用 Git 管理
6. **文档更新** - 每次备份后更新 BACKUP_INFO.md

---

## 📞 支持

如有问题，请联系 VennCLAW 团队或查看：
- OpenClaw 官方文档：https://docs.openclaw.ai
- VennCLAW GitHub: https://github.com/yujinandyanhaoyang/VennCLAW

---

**最后更新**: 2026-03-11  
**维护者**: VennCLAW Team

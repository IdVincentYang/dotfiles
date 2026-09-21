# Repository Instructions

## 核心原则

本目录由 macOS、Linux 和 Android Termux 共享。修改配置时必须保持跨平台兼容，不能只按当前环境工作。

本目录属于 yadm 工作树，不是独立 Git 仓库。版本状态和差异使用 `yadm status`、`yadm diff` 检查；需要检查新文件时使用 `yadm status --untracked-files=all`。

## 目录语义

- `backups/` 保存配置备份，用于迁移和恢复。
- 其他目录保存可直接使用的应用配置；未安装对应应用时，该配置无需生效。

## 修改要求

- 不要把主机名、SSH 地址、设备型号等具体环境信息写入通用说明或平台判断。
- 优先复用现有的平台检测和文件组织方式。
- `justfile` recipe 遵循 `<primary>-<domain>-<name>[-<os>]` 命名，平台后缀使用 `darwin`、`linux` 或 `termux`。
- 修改共享配置时，检查各平台的语法、路径和命令差异；平台专用行为应明确隔离。
- 保持改动最小，不修改无关配置。

## 备份要求

- 保持“无有效源则跳过且保留旧备份；有有效源则整体更新 snapshot”的语义。
- 恢复前保护目标位置已有配置。
- macOS preferences 使用 `defaults export/import`，不直接覆盖 plist。
- 不向 `backups/` 加入 cache、日志、token、凭据或其他敏感内容。
- 详细规则以 `docs/macos-app-config-backup-restore.md` 为准。

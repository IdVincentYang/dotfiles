# Dotfiles

本目录保存个人配置，由 macOS、Linux 和 Android Termux 共享。

## 目录内容

内容分为两类：

- `backups/`：应用或系统配置的备份，用于迁移和恢复。
- 其他目录：可以直接使用的应用配置。不同平台的配置可以同时存在；仅当当前环境安装了对应应用时，相关配置才会生效。

修改共享配置时，必须同时考虑 macOS、Linux 和 Termux。平台差异应通过平台检测、平台专用文件或 recipe 后缀处理，不应写入具体机器或设备信息。

## 配置管理

- yadm 管理配置文件及平台差异。
- `justfile` 提供软件安装、配置备份和恢复入口。
- recipe 使用 `<primary>-<domain>-<name>[-<os>]` 命名，平台后缀为 `darwin`、`linux` 或 `termux`。

常用命令：

```sh
just list
just install-menu
just backup-config-menu
just restore-config-menu
```

## backups

`backups/` 保存可迁移的配置备份。备份与恢复由对应的 just recipe 或应用自身的导入、导出功能完成。

基本规则：

- 没有有效源配置时跳过备份，不删除已有备份。
- 有有效源配置时，用当前 snapshot 替换旧 snapshot，避免新旧内容混杂。
- 恢复前保留目标位置已有的受管理配置。
- macOS preferences 使用 `defaults export/import`，不直接覆盖 plist。
- 不保存 cache、日志、token、凭据等不适合进入 dotfiles 的内容。

macOS 应用配置的详细规则见 [`docs/macos-app-config-backup-restore.md`](docs/macos-app-config-backup-restore.md)。

## Termux:Widget 配置

Termux:Widget 的脚本属于可迁移配置，由 Termux 专用 recipe 备份和恢复：

```sh
just system-config-termux-widget-backup-termux
just system-config-termux-widget-restore-termux
```

管理范围包括 `~/.termux/widget/dynamic_shortcuts` 和 `~/.shortcuts`。
`~/.local/private/termux.env` 等凭据文件不在备份范围内。

其中 `download video` 会读取 Termux 剪贴板中的 URL，并按 `,ydv` 的画质、
编码和命名选项下载到 `/sdcard/Download/ytdl`。它需要 Android 端的
Termux:API 插件、Termux 中的 `termux-api` 包，以及已安装的 `yt-dlp`
（可运行 `just install core-media-yt-dlp-termux`）。

恢复后，需要在 Termux:Widget 中执行 `REMOVE SHORTCUTS`，再执行
`CREATE SHORTCUTS`，让 Android 启动器重新生成快捷方式。

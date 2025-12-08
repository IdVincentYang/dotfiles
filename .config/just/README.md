# just/ 目录脚本说明

- `platform.sh`
  - 判定当前平台（`darwin`/`linux`/`termux`），`justfile` 通过执行该脚本决定应当加载的 recipe 后缀。

- `common.sh`
  - 提供 `collect_recipes` 函数，统一解析 `just --list` 输出，筛出符合 `<主类>-<领域>-<name>[-<os>]` 命名约定的 recipe 名称，供其他脚本复用。

- `list.sh`
  - 实现 `just list` 命令主体逻辑，支持按主类、领域、平台、名称等多维过滤，并可输出原始列表（`raw=1`）供管道使用。

- `install.sh`
  - 根据软件名解析可用 recipe，自动匹配当前平台版本并执行安装。若同名 recipe 有多种平台/类别，会提示用户选择目标后直接执行。

- `install_menu.sh`
  - 基于 `list.sh` 的结果提供交互式多选安装：检测到 `fzf` 时使用多选界面，否则回退为手动输入。最终调用 `install.sh` 统一执行。

- `asdf_install_menu.sh`
  - 交互式管理 asdf 插件版本：针对预设插件（可用 `ASDF_TARGET_PLUGINS` 覆盖）通过 `fzf` 选择需安装的版本，并可选择要写入 `asdf global` 的默认版本，确认后批量执行安装与 global 配置。

后续如需扩展命名规范或新增交互方式，可在这些脚本基础上迭代；`justfile` 只负责定义入口，所有复杂逻辑集中在本目录，便于复用与测试。

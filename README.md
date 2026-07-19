## Steps

1. install required apps
2. install brew
3. restore zsh env
4. restore vim env
5. restore other envs
6. [optional] install software from brew, mas, apt etc...

### install required apps

#### macOS

新 macOS 迁移 dotfiles 的顺序：先准备 Xcode developer tools、Homebrew 和
`yadm`，再配置 GitHub SSH key，最后 clone dotfiles 并运行 bootstrap。

1. 安装 Xcode developer tools

如果已安装完整 Xcode：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

如果暂时不安装完整 Xcode：

```bash
xcode-select --install
```

2. 安装 Homebrew

`yadm` 在 macOS 上通过 Homebrew 安装。虽然本仓库的
`.config/yadm/bootstrap` 也会配置 Homebrew，但新机器还没有 `yadm`，所以需要先手动
安装 Homebrew 和 `yadm`，再运行 `yadm bootstrap`。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

brew install yadm
```

3. 迁移 SSH 配置

从旧电脑复制整个 `~/.ssh` 目录到新电脑的 home 目录，用于保留已有的 SSH
Host alias 和 private keys。不要通过不可信网盘长期保存 `.ssh` 目录。

复制完成后修正权限：

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config 2>/dev/null || true
chmod 600 ~/.ssh/* 2>/dev/null || true
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
```

验证 dotfiles 仓库使用的 GitHub alias：

```bash
ssh -T git@github-vincent
```

4. Clone dotfiles

首次 clone 前先设置最小 XDG 环境，保证 yadm repo 落到 `~/.local/share/yadm`。

```bash
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/Library/Caches"

mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

yadm clone --no-bootstrap git@github-vincent:IdVincentYang/dotfiles.git
yadm status
```

如果 `yadm clone` 提示有本地文件冲突，按提示把冲突文件移到临时目录，然后执行
`yadm checkout`。新系统没有这些文件时不需要做这一步。

```bash
mkdir -p ~/tmp/yadm-conflicts
mv ~/.zshrc ~/.zprofile ~/.zshenv ~/.gitconfig ~/tmp/yadm-conflicts/ 2>/dev/null || true
yadm checkout
```

5. 运行 bootstrap

```bash
yadm bootstrap
```

`yadm clone` 默认会处理 alternate 文件，通常不需要单独执行 `yadm alt`。如果发现
`.config/yadm/bootstrap.d/00_init`、`04_brew` 或 `08_shell` 没有链接到对应的
`##os.Darwin` 文件，再手动运行：

```bash
yadm alt
```

bootstrap 会按 `.config/yadm/bootstrap.d` 中的脚本初始化 macOS 环境：

- `00_init`: 写入 `~/.local/.env` 和 XDG 目录。
- `04_brew`: 检查 Homebrew，选择/写入 Homebrew mirror 和 shellenv。
- `05_coretools`: 安装 `Brewfile.core` 中的核心工具，比如 `git`、`git-lfs`、
  `just`、`vim`、`zsh`。
- `06_submodules`: 初始化 yadm submodules。
- `08_shell`: 生成 `~/.zshenv`，并把默认 shell 切到 Homebrew zsh。
- `10_vim.sh`: 初始化 vim 环境。

如果 `08_shell` 修改了默认 shell，重启 Terminal 后继续后续步骤。

6. 安装按需工具

`justfile` 位于 `~/.config/justfile`，在 `$HOME` 下执行时需要显式指定。

```bash
# List available core packages
just --justfile ~/.config/justfile list main=core

# Install core packages interactively
just --justfile ~/.config/justfile install-menu main=core

# Install asdf plugins
just --justfile ~/.config/justfile core-develop-asdf-plugins

# Install asdf plugin versions
just --justfile ~/.config/justfile core-develop-asdf-install-menu

# Install npm global packages
just --justfile ~/.config/justfile core-cli-npm-globals
```

`.config/backups/Brewfile` 和 `.config/backups/mas.list` 是应用恢复清单，不是首次
dotfiles 迁移的必需步骤。需要恢复 GUI 应用时再按需执行：

```bash
brew bundle install --file ~/.config/backups/Brewfile
# mas install <app-id>
```

#### Ubuntu/Debian

```bash
sudo apt-get install yadm
# if what push commits use git protocol to pull repo with correct ssh key
# yadm pull git@github.com:IdVincentYang/dotfiles.git
yadm pull https://github.com/IdVincentYang/dotfiles.git
yadm bootstrap

# Install core packages
just list main=core raw=1 | just install

# Install asdf plugins
just develop-asdf-plugins

# Install asdf plugins versions
just develop-asdf-install-menu

# Install npm global packages
just core-cli-npm-globals
```

## Setup brew

## References

- [Brew Bundle Brewfile Tips](https://gist.github.com/ChristopherA/a579274536aab36ea9966f301ff14f3f#file-brew-bundle-brewfile-tips-md)
- [LinuxBrew on Termux](https://github.com/Linuxbrew/brew/wiki/Android)

- [yadm Dotfiles Repo Demo: bjartek](https://github.com/bjartek/dotfiles/tree/master/.config/yadm)
- [yadm Doc](https://yadm.io/docs/overview)

- [好玩的linux命令](https://www.cnblogs.com/yhyjy/archive/2013/06/09/3127971.html)

- [yt-dlp termux full installation guide](https://gist.github.com/cyrillkuettel/d63785cf5f4c00106ae215188c377515)

## Issues

- 安装应用时网络可能断, 如何自动重试?
- 如何自动备份brewfile/yadm repo?

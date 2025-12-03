#!/bin/bash
# vi:set ft=sh
set -eu

echo "[BOOTSTRAP] [10_vim] Configuring Vim..."

# 1. 加载环境变量 (Termux 由 00_init 生成，Ubuntu 由 04_brew 生成)
LOCAL_ENV="$HOME/.local/.env"
if [ -f "$LOCAL_ENV" ]; then
    source "$LOCAL_ENV"
fi

# 2. 检查并安装 Vim (如果缺失)
if ! command -v vim >/dev/null 2>&1; then
    echo "[BOOTSTRAP] Vim not found. Installing..."
    
    if [[ -v TERMUX_APP_PID ]]; then
        # Termux
        pkg install -y vim
    elif [ -n "${HOMEBREW_PREFIX:-}" ]; then
        # Ubuntu/macOS with Brew
        brew install vim
    elif command -v apt-get >/dev/null 2>&1; then
        # Ubuntu Fallback (no brew)
        sudo apt-get update && sudo apt-get install -y vim
    else
        echo "Error: Cannot install vim. Package manager not found."
        exit 1
    fi
fi

# 定义 XDG_CONFIG_HOME 默认值
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# 路径判定逻辑：
# 1. 如果 ~/.config/vim (或自定义 XDG) 存在，优先使用它。
# 2. 否则默认使用 ~/.vim (这是 Vim 最稳妥的默认值)。
# 注意：如果你使用的是 Neovim，通常路径是 "$XDG_CONFIG_HOME/nvim"
if [ -d "$XDG_CONFIG_HOME/vim" ]; then
    VIM_CONFIG_DIR="$XDG_CONFIG_HOME/vim"
    echo "[BOOTSTRAP] Detected XDG config directory: $VIM_CONFIG_DIR"
else
    VIM_CONFIG_DIR="$HOME/.vim"
    echo "[BOOTSTRAP] Using standard Vim directory: $VIM_CONFIG_DIR"
fi

PLUG_FILE="$VIM_CONFIG_DIR/autoload/plug.vim"
PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

# --- 2. 安装 vim-plug (如果不存在) ---

if [ ! -f "$PLUG_FILE" ]; then
    echo "[BOOTSTRAP] vim-plug not found. Installing to $PLUG_FILE..."
    
    # 确保 autoload 目录存在
    mkdir -p "$(dirname "$PLUG_FILE")"

    if command -v curl >/dev/null 2>&1; then
        curl -fLo "$PLUG_FILE" "$PLUG_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$PLUG_FILE" "$PLUG_URL"
    else
        echo "[BOOTSTRAP] Error: Neither curl nor wget found. Cannot install vim-plug."
        exit 1
    fi
else
    echo "[BOOTSTRAP] vim-plug already exists."
fi

# --- 3. 执行升级与安装 (Headless 模式) ---
echo "[BOOTSTRAP] Running Vim plugin operations..."

# 命令链说明：
# 1. +PlugUpgrade : 升级 vim-plug 管理器本身 (回答了你的第二个问题)
# 2. +PlugUpdate  : 安装新插件并更新现有插件 (包含了 PlugInstall 的功能)
# 3. +PlugClean!  : 移除 .vimrc 中已删除的插件
# 4. +qall        : 全部退出
#
# 使用 || true 防止因为某些非致命错误(如配色缺失)导致脚本中断
vim -E -s +PlugUpgrade +PlugUpdate +PlugClean! +qall || {
    echo "[BOOTSTRAP] Vim plugin operations finished (with non-critical warnings)."
}

echo "[BOOTSTRAP] Vim setup completed."

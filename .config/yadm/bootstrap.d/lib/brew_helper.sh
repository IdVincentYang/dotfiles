#!/bin/bash
# file: bootstrap.d/lib/brew_helper.sh

# 获取当前脚本所在目录 (lib)
BOOTSTRAP_LIB_DIR=$(dirname "${BASH_SOURCE[0]}")

# 引用环境操作库 (用于追加配置)
ENV_HELPER="$BOOTSTRAP_LIB_DIR/env_helper.sh"

if [ -f "$ENV_HELPER" ]; then
    source "$ENV_HELPER"
else
    echo "[BREW_HELPER] Error: env_helper.sh not found at $ENV_HELPER"
    exit 1
fi

# 定义官方安装脚本 URL
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# --- 函数: 选择镜像源 ---
select_mirror() {
    # 默认值
    MIRROR_CHOICE="Official"
    
    # 判断是否需要交互
    # 如果设置了 NONINTERACTIVE 或者 当前 STDOUT 不是终端，则跳过选择
    if [[ "${NONINTERACTIVE:-}" == "true" ]] || [[ ! -t 1 ]]; then
        echo "[BREW_HELPER] Non-interactive mode detected. Using default source: $MIRROR_CHOICE"
    else
        echo "------------------------------------------------"
        echo "Select Homebrew Mirror Source:"
        echo "1) USTC     (University of Science and Technology of China) [Recommended for CN]"
        echo "2) Tsinghua (Tsinghua University) [Alternative for CN]"
        echo "3) Official (Global / Default)"
        echo "------------------------------------------------"
        
        # 因为主 bootstrap 脚本已修复管道问题，这里直接读取即可
        read -r -p "Enter choice [1-3] (Default: 3): " choice
        
        case "$choice" in
            1) MIRROR_CHOICE="USTC" ;;
            2) MIRROR_CHOICE="Tsinghua" ;;
            *) MIRROR_CHOICE="Official" ;;
        esac
    fi

    echo "[BREW_HELPER] Selected Mirror: $MIRROR_CHOICE"
    export_mirror_vars "$MIRROR_CHOICE"
}

# --- 函数: 导出镜像环境变量 (用于当前会话和生成配置) ---
export_mirror_vars() {
    local source_name="$1"
    
    case "$source_name" in
        "USTC")
            export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
            export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
            export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
            export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
            ;;
        "Tsinghua")
            export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
            export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
            export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
            export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
            ;;
        *)
            # 官方源无需设置变量，清理可能存在的旧变量
            unset HOMEBREW_BREW_GIT_REMOTE
            unset HOMEBREW_CORE_GIT_REMOTE
            unset HOMEBREW_BOTTLE_DOMAIN
            unset HOMEBREW_API_DOMAIN
            ;;
    esac
}

# --- 函数: 通用安装与配置逻辑 ---
# 参数 $1: 预期的 brew 二进制路径 (如 /opt/homebrew/bin/brew)
run_brew_install_logic() {
    local target_brew_bin="$1"
    
    # 1. 选择源
    select_mirror
    
    # 2. 检查是否需要安装或修复
    local need_install=false
    
    if [ ! -x "$target_brew_bin" ]; then
        echo "[BREW_HELPER] Binary not found at $target_brew_bin."
        need_install=true
    else
        # 简单运行一下检查是否损坏
        if ! "$target_brew_bin" --version >/dev/null 2>&1; then
             echo "[BREW_HELPER] Binary exists but appears broken."
             need_install=true
        else
             echo "[BREW_HELPER] Homebrew is installed and healthy."
        fi
    fi
    
    # 3. 执行安装
    if [ "$need_install" = true ]; then
        echo "[BREW_HELPER] Starting installation..."
        
        # 传递 NONINTERACTIVE=1 给官方脚本，实现静默安装
        # 注意: 此时 sudo 权限应在 00_init 中处理完毕
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL $INSTALL_SCRIPT_URL)"
    fi
    
    # 4. 追加配置到 .env (使用 env_helper 的 append_to_env)
    if [ -x "$target_brew_bin" ]; then
        echo "[BREW_HELPER] Configuring environment..."
        
        # 构造要追加的内容
        # 使用 read -d '' 将多行文本读入变量
        read -r -d '' BREW_ENV_CONTENT <<EOF || true
# Homebrew Mirror Settings
$(env | grep "^HOMEBREW_" | sed 's/^/export /')

# Initialize Homebrew Path
if [ -x "$target_brew_bin" ]; then
    eval "\$($target_brew_bin shellenv)"
fi
EOF
        
        # 调用 env_helper 追加配置
        append_to_env "Homebrew Configuration (Added by 04_brew)" "$BREW_ENV_CONTENT"
        
        # 5. 加载到当前 Shell，供后续脚本使用
        eval "$("$target_brew_bin" shellenv)"
    else
        echo "[BREW_HELPER] CRITICAL: Installation finished but binary not found."
        exit 1
    fi
}

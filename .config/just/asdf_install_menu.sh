#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[asdf-menu] 未找到命令: $1" >&2
        exit 1
    fi
}


require_cmd asdf
require_cmd fzf

asdf_global_cmd=(asdf set --home)

tool_versions_file="${HOME}/.tool-versions"
if [[ ! -e "${tool_versions_file}" ]]; then
    echo "[asdf-menu] 创建 ${tool_versions_file}"
    : >"${tool_versions_file}"
fi

has_builtin() {
    type -t "$1" >/dev/null 2>&1
}

if ! has_builtin readarray; then
    readarray() {
        local opt strip_newline=0
        OPTIND=1
        while getopts ':t' opt; do
            case "$opt" in
                t) strip_newline=1 ;;
            esac
        done
        shift $((OPTIND-1))
        local array_name="$1"
        shift || true
        local data=()
        local line
        while IFS= read -r line; do
            if ((strip_newline)); then
                line="${line%$'\r'}"
                line="${line%$'\n'}"
            fi
            data+=("$line")
        done
        eval "$array_name=(\"\${data[@]}\")"
    }
fi

if ! has_builtin mapfile; then
    mapfile() {
        readarray "$@"
    }
fi

readarray -t existing_plugins < <(asdf plugin list 2>/dev/null || true)

default_plugins=(nodejs java direnv)
if [[ -n "${ASDF_TARGET_PLUGINS:-}" ]]; then
    read -r -a target_plugins <<<"${ASDF_TARGET_PLUGINS}"
else
    target_plugins=("${default_plugins[@]}")
fi

if [[ ${#target_plugins[@]} -eq 0 ]]; then
    echo "[asdf-menu] 未指定任何插件" >&2
    exit 0
fi

plugins_in_order=()

sanitize_key() {
    local plugin="$1"
    plugin="${plugin//[^A-Za-z0-9_]/_}"
    printf '%s' "${plugin}"
}

set_install_plan() {
    local plugin="$1" value="$2" key
    key="$(sanitize_key "$plugin")"
    printf -v "install_plan_${key}" '%s' "$value"
}

get_install_plan() {
    local plugin="$1" key var
    key="$(sanitize_key "$plugin")"
    var="install_plan_${key}"
    if [[ -n "${!var-}" ]]; then
        printf '%s' "${!var}"
    fi
}

set_global_plan() {
    local plugin="$1" value="$2" key
    key="$(sanitize_key "$plugin")"
    printf -v "global_plan_${key}" '%s' "$value"
}

get_global_plan() {
    local plugin="$1" key var
    key="$(sanitize_key "$plugin")"
    var="global_plan_${key}"
    if [[ -n "${!var-}" ]]; then
        printf '%s' "${!var}"
    fi
}

plugin_exists() {
    local plugin="$1"
    for item in "${existing_plugins[@]}"; do
        [[ "$item" == "$plugin" ]] && return 0
    done
    return 1
}

ensure_plugin() {
    local plugin="$1"
    if plugin_exists "$plugin"; then
        return
    fi
    echo "[asdf-menu] 添加插件: $plugin"
    asdf plugin add "$plugin"
    existing_plugins+=("$plugin")
}

select_versions() {
    local plugin="$1"
    mapfile -t available < <(asdf list all "$plugin" 2>/dev/null || true)
    if [[ ${#available[@]} -eq 0 ]]; then
        echo "[asdf-menu] 插件 $plugin 无可用版本或拉取失败" >&2
        return 1
    fi

    local selection
    selection=$(printf '%s\n' "${available[@]}" \
        | awk '{line[NR]=$0} END {for (i=NR; i>=1; i--) print line[i]}' \
        | fzf --multi --prompt="$plugin versions> " --height=70% --border --exit-0 || true)

    if [[ -z "$selection" ]]; then
        echo "[asdf-menu] 跳过插件: $plugin"
        return 0
    fi

    mapfile -t chosen <<<"$selection"
    if [[ ${#chosen[@]} -eq 0 ]]; then
        return 0
    fi

    set_install_plan "$plugin" "${chosen[*]}"
    plugins_in_order+=("$plugin")

    local global_selection=""
    if [[ ${#chosen[@]} -eq 1 ]]; then
        global_selection="${chosen[0]}"
    else
        global_selection=$(printf '%s\n' "${chosen[@]}" \
            | awk '{line[NR]=$0} END {for (i=NR; i>=1; i--) print line[i]}' \
            | fzf --prompt="$plugin global> " --height=40% --border --exit-0 || true)
    fi

    if [[ -n "$global_selection" ]]; then
        set_global_plan "$plugin" "$global_selection"
    fi
}

for plugin in "${target_plugins[@]}"; do
    ensure_plugin "$plugin"
    select_versions "$plugin"
done

if [[ ${#plugins_in_order[@]} -eq 0 ]]; then
    echo "[asdf-menu] 未选择任何版本，直接退出"
    exit 0
fi

echo "================ 安装计划 ================"
for plugin in "${plugins_in_order[@]}"; do
    plan_value="$(get_install_plan "$plugin")"
    printf '%s: %s\n' "$plugin" "$plan_value"
    global_value="$(get_global_plan "$plugin")"
    if [[ -n "$global_value" ]]; then
        printf '  -> global: %s\n' "$global_value"
    fi
done
echo "========================================="

read -r -p "确认开始安装? [y/N] " answer
case "$answer" in
    y|Y|yes|YES)
        ;;
    *)
        echo "[asdf-menu] 用户取消"
        exit 0
        ;;
esac

for plugin in "${plugins_in_order[@]}"; do
    plan_value="$(get_install_plan "$plugin")"
    read -r -a versions <<<"$plan_value"
    for version in "${versions[@]}"; do
        echo "[asdf-menu] 安装 ${plugin} ${version}"
        asdf install "$plugin" "$version"
    done
done

for plugin in "${plugins_in_order[@]}"; do
    global_value="$(get_global_plan "$plugin")"
    if [[ -n "$global_value" ]]; then
        echo "[asdf-menu] 设置 global ${plugin} ${global_value}"
        "${asdf_global_cmd[@]}" "$plugin" "$global_value"
    fi
done

echo "[asdf-menu] 完成"

#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
if [[ "$mode" != "backup" && "$mode" != "restore" ]]; then
    echo "Usage: termux_widget_config.sh <backup|restore>" >&2
    exit 2
fi

backup_root="${HOME}/.config/backups/termux-widget"
managed_paths=(
    ".termux/widget/dynamic_shortcuts"
    ".shortcuts"
)

path_exists() {
    [[ -e "$1" || -L "$1" ]]
}

has_entries() {
    local path="$1"
    if [[ -d "$path" && ! -L "$path" ]]; then
        [[ -n "$(find "$path" -mindepth 1 -print -quit)" ]]
    else
        path_exists "$path"
    fi
}

copy_path() {
    local source="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    if [[ -d "$source" && ! -L "$source" ]]; then
        cp -pR "$source" "$target"
    else
        cp -p "$source" "$target"
    fi
}

unique_before_root() {
    local base="$1"
    local stamp
    stamp="$(date +%Y%m%d%H%M%S)"
    local candidate="${base}.before-dotfiles-${stamp}"
    local index=1
    while [[ -e "$candidate" ]]; do
        candidate="${base}.before-dotfiles-${stamp}-${index}"
        index=$((index + 1))
    done
    printf '%s\n' "$candidate"
}

backup_config() {
    local existing=()
    local relative_path
    for relative_path in "${managed_paths[@]}"; do
        if has_entries "${HOME}/${relative_path}"; then
            existing+=("$relative_path")
        fi
    done

    if [[ ${#existing[@]} -eq 0 ]]; then
        echo "[termux-widget] backup skip: no managed files found"
        return 0
    fi

    mkdir -p "$(dirname "$backup_root")"
    local temporary_root
    temporary_root="$(mktemp -d "${backup_root}.tmp.XXXXXX")"
    trap 'rm -rf "$temporary_root"' EXIT

    for relative_path in "${existing[@]}"; do
        copy_path "${HOME}/${relative_path}" "${temporary_root}/${relative_path}"
    done

    rm -rf "$backup_root"
    mv "$temporary_root" "$backup_root"
    trap - EXIT
    echo "[termux-widget] backed up: ${backup_root}"
}

restore_config() {
    local existing=()
    local relative_path
    for relative_path in "${managed_paths[@]}"; do
        if path_exists "${backup_root}/${relative_path}"; then
            existing+=("$relative_path")
        fi
    done

    if [[ ${#existing[@]} -eq 0 ]]; then
        echo "[termux-widget] restore skip: no managed backup found"
        return 0
    fi

    local before_root=""
    for relative_path in "${managed_paths[@]}"; do
        if path_exists "${HOME}/${relative_path}"; then
            if [[ -z "$before_root" ]]; then
                before_root="$(unique_before_root "${HOME}/.local/state/termux-widget")"
                mkdir -p "$before_root"
            fi
            mkdir -p "$(dirname "${before_root}/${relative_path}")"
            mv "${HOME}/${relative_path}" "${before_root}/${relative_path}"
        fi
    done

    for relative_path in "${existing[@]}"; do
        copy_path "${backup_root}/${relative_path}" "${HOME}/${relative_path}"
    done

    echo "[termux-widget] restored from: ${backup_root}"
    if [[ -n "$before_root" ]]; then
        echo "[termux-widget] previous files moved to: ${before_root}"
    fi
    echo "[termux-widget] Open Termux:Widget and choose REMOVE SHORTCUTS, then CREATE SHORTCUTS."
}

case "$mode" in
    backup) backup_config ;;
    restore) restore_config ;;
esac

#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: app_config.sh <backup|restore> [--backup-root <backup-relative-root>] <library-relative-root> <managed-path> [managed-path ...]" >&2
}

mode="${1:-}"
if [[ $# -lt 3 || "$mode" != "backup" && "$mode" != "restore" ]]; then
    usage
    exit 2
fi
shift

backup_root_override=""
if [[ "${1:-}" == "--backup-root" ]]; then
    if [[ $# -lt 4 ]]; then
        usage
        exit 2
    fi
    backup_root_override="$2"
    shift 2
fi

library_root="${1:-}"
if [[ $# -lt 2 ]]; then
    usage
    exit 2
fi
shift
managed_paths=("$@")

reject_unsafe_path() {
    local path="$1"
    case "$path" in
        ""|/*|*"/../"*|"../"*|*".."|*"//"*)
            echo "[app-config] Unsafe path: $path" >&2
            exit 2
            ;;
    esac
}

copy_path() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -d "$src" && ! -L "$src" ]]; then
        cp -pR "$src" "$dest"
    else
        cp -p "$src" "$dest"
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

reject_unsafe_path "$library_root"
if [[ -n "$backup_root_override" ]]; then
    reject_unsafe_path "$backup_root_override"
fi
for managed_path in "${managed_paths[@]}"; do
    reject_unsafe_path "$managed_path"
done

library_base="${HOME}/Library"
backup_base="${HOME}/.config/backups/macos"
source_root="${library_base}/${library_root}"
backup_root="${backup_base}/${backup_root_override:-$library_root}"

backup_config() {
    local existing=()
    local managed_path
    for managed_path in "${managed_paths[@]}"; do
        if [[ -e "${source_root}/${managed_path}" ]]; then
            existing+=("$managed_path")
        fi
    done

    if [[ ${#existing[@]} -eq 0 ]]; then
        echo "[app-config] backup skip: no managed paths exist under ${source_root}"
        return 0
    fi

    mkdir -p "$(dirname "$backup_root")"
    local tmp_root
    tmp_root="$(mktemp -d "$(dirname "$backup_root")/.app-config.XXXXXX")"

    for managed_path in "${existing[@]}"; do
        copy_path "${source_root}/${managed_path}" "${tmp_root}/${managed_path}"
    done

    if [[ -f "${backup_root}/.gitignore" ]]; then
        copy_path "${backup_root}/.gitignore" "${tmp_root}/.gitignore"
    fi

    rm -rf "$backup_root"
    mv "$tmp_root" "$backup_root"
    echo "[app-config] backed up ${library_root}: ${backup_root}"
}

restore_config() {
    local existing=()
    local managed_path
    for managed_path in "${managed_paths[@]}"; do
        if [[ -e "${backup_root}/${managed_path}" ]]; then
            existing+=("$managed_path")
        fi
    done

    if [[ ${#existing[@]} -eq 0 ]]; then
        echo "[app-config] restore skip: no managed paths exist under ${backup_root}"
        return 0
    fi

    mkdir -p "$source_root"

    local before_root=""
    for managed_path in "${managed_paths[@]}"; do
        if [[ -e "${source_root}/${managed_path}" ]]; then
            if [[ -z "$before_root" ]]; then
                before_root="$(unique_before_root "$source_root")"
                mkdir -p "$before_root"
            fi
            mkdir -p "$(dirname "${before_root}/${managed_path}")"
            mv "${source_root}/${managed_path}" "${before_root}/${managed_path}"
        fi
    done

    for managed_path in "${existing[@]}"; do
        copy_path "${backup_root}/${managed_path}" "${source_root}/${managed_path}"
    done

    echo "[app-config] restored ${library_root}: ${source_root}"
    if [[ -n "$before_root" ]]; then
        echo "[app-config] previous managed paths moved to: ${before_root}"
    fi
}

case "$mode" in
    backup) backup_config ;;
    restore) restore_config ;;
esac

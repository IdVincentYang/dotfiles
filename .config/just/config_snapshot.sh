#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: config_snapshot.sh <backup|restore> --source-root <absolute-path> --backup-root <absolute-path> [--before-root <absolute-path>] [--label <name>] -- <relative-path> [relative-path ...]" >&2
}

mode="${1:-}"
if [[ "$mode" != "backup" && "$mode" != "restore" ]]; then
    usage
    exit 2
fi
shift

source_root=""
backup_root=""
before_root=""
label="snapshot"
managed_paths=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source-root)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            source_root="$2"
            shift 2
            ;;
        --backup-root)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            backup_root="$2"
            shift 2
            ;;
        --before-root)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            before_root="$2"
            shift 2
            ;;
        --label)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            label="$2"
            shift 2
            ;;
        --)
            shift
            managed_paths+=("$@")
            break
            ;;
        *)
            managed_paths+=("$1")
            shift
            ;;
    esac
done

if [[ -z "$source_root" || -z "$backup_root" || ${#managed_paths[@]} -eq 0 ]]; then
    usage
    exit 2
fi

reject_absolute_root() {
    local path="$1"
    [[ "$path" == /* && "$path" != "/" ]] || {
        echo "[$label] Root must be an absolute non-root path: $path" >&2
        exit 2
    }
}

reject_relative_path() {
    local path="$1"
    case "$path" in
        ""|/*|*"/../"*|"../"*|*".."|*"//"*)
            echo "[$label] Unsafe managed path: $path" >&2
            exit 2
            ;;
    esac
}

reject_absolute_root "$source_root"
reject_absolute_root "$backup_root"
if [[ -n "$before_root" ]]; then
    reject_absolute_root "$before_root"
fi
for managed_path in "${managed_paths[@]}"; do
    reject_relative_path "$managed_path"
done

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
    local managed_path
    for managed_path in "${managed_paths[@]}"; do
        if has_entries "${source_root}/${managed_path}"; then
            existing+=("$managed_path")
        fi
    done

    if [[ ${#existing[@]} -eq 0 ]]; then
        echo "[$label] backup skip: no managed files found"
        return 0
    fi

    mkdir -p "$(dirname "$backup_root")"
    local temporary_root
    temporary_root="$(mktemp -d "${backup_root}.tmp.XXXXXX")"
    trap 'rm -rf "$temporary_root"' EXIT

    for managed_path in "${existing[@]}"; do
        copy_path "${source_root}/${managed_path}" "${temporary_root}/${managed_path}"
    done

    if [[ -f "${backup_root}/.gitignore" ]]; then
        copy_path "${backup_root}/.gitignore" "${temporary_root}/.gitignore"
    fi

    rm -rf "$backup_root"
    mv "$temporary_root" "$backup_root"
    trap - EXIT
    echo "[$label] backed up: ${backup_root}"
}

restore_config() {
    local existing=()
    local managed_path
    for managed_path in "${managed_paths[@]}"; do
        if path_exists "${backup_root}/${managed_path}"; then
            existing+=("$managed_path")
        fi
    done

    if [[ ${#existing[@]} -eq 0 ]]; then
        echo "[$label] restore skip: no managed backup found"
        return 0
    fi

    mkdir -p "$source_root"
    local before_root_path="${before_root:-${source_root}.before-dotfiles}"
    local before_root_created=""

    for managed_path in "${managed_paths[@]}"; do
        if path_exists "${source_root}/${managed_path}"; then
            if [[ -z "$before_root_created" ]]; then
                before_root_created="$(unique_before_root "$before_root_path")"
                mkdir -p "$before_root_created"
            fi
            mkdir -p "$(dirname "${before_root_created}/${managed_path}")"
            mv "${source_root}/${managed_path}" "${before_root_created}/${managed_path}"
        fi
    done

    for managed_path in "${existing[@]}"; do
        copy_path "${backup_root}/${managed_path}" "${source_root}/${managed_path}"
    done

    echo "[$label] restored from: ${backup_root}"
    if [[ -n "$before_root_created" ]]; then
        echo "[$label] previous files moved to: ${before_root_created}"
    fi
}

case "$mode" in
    backup) backup_config ;;
    restore) restore_config ;;
esac

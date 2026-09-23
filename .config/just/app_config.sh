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
shift
managed_paths=("$@")

reject_relative_path() {
    local path="$1"
    case "$path" in
        ""|/*|*"/../"*|"../"*|*".."|*"//"*)
            echo "[app-config] Unsafe path: $path" >&2
            exit 2
            ;;
    esac
}

reject_relative_path "$library_root"
if [[ -n "$backup_root_override" ]]; then
    reject_relative_path "$backup_root_override"
fi
for managed_path in "${managed_paths[@]}"; do
    reject_relative_path "$managed_path"
done

source_root="${HOME}/Library/${library_root}"
backup_root="${HOME}/.config/backups/macos/${backup_root_override:-$library_root}"

exec "$(dirname "${BASH_SOURCE[0]}")/config_snapshot.sh" "$mode" \
    --source-root "$source_root" \
    --backup-root "$backup_root" \
    --label app-config \
    -- "${managed_paths[@]}"

#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: preference_config.sh <backup|restore> <backup-group> <domain> [domain ...]" >&2
}

mode="${1:-}"
if [[ $# -lt 3 || "$mode" != "backup" && "$mode" != "restore" ]]; then
    usage
    exit 2
fi
shift

backup_group="${1:-}"
shift
domains=("$@")

reject_unsafe_path() {
    local path="$1"
    case "$path" in
        ""|/*|*"/../"*|"../"*|*".."|*"//"*)
            echo "[preference-config] Unsafe path: $path" >&2
            exit 2
            ;;
    esac
}

reject_unsafe_domain() {
    local domain="$1"
    case "$domain" in
        ""|/*|*"/"*|*".."*|*".plist")
            echo "[preference-config] Unsafe domain: $domain" >&2
            exit 2
            ;;
    esac
}

reject_unsafe_path "$backup_group"
for domain in "${domains[@]}"; do
    reject_unsafe_domain "$domain"
done

backup_base="${HOME}/.config/backups/macos/preferences"
backup_root="${backup_base}/${backup_group}"

backup_preferences() {
    mkdir -p "$(dirname "$backup_root")"
    local tmp_root
    tmp_root="$(mktemp -d "$(dirname "$backup_root")/.preference-config.XXXXXX")"

    local exported=()
    local domain
    for domain in "${domains[@]}"; do
        if defaults export "$domain" "${tmp_root}/${domain}.plist" >/dev/null 2>&1; then
            exported+=("$domain")
        else
            rm -f "${tmp_root}/${domain}.plist"
            echo "[preference-config] backup skip domain: ${domain}" >&2
        fi
    done

    if [[ ${#exported[@]} -eq 0 ]]; then
        rm -rf "$tmp_root"
        echo "[preference-config] backup skip: no domains exported for ${backup_group}"
        return 0
    fi

    rm -rf "$backup_root"
    mv "$tmp_root" "$backup_root"
    echo "[preference-config] backed up ${backup_group}: ${backup_root}"
}

restore_preferences() {
    local existing=()
    local domain
    for domain in "${domains[@]}"; do
        if [[ -f "${backup_root}/${domain}.plist" ]]; then
            existing+=("$domain")
        fi
    done

    if [[ ${#existing[@]} -eq 0 ]]; then
        echo "[preference-config] restore skip: no domain backups exist under ${backup_root}"
        return 0
    fi

    for domain in "${existing[@]}"; do
        defaults import "$domain" "${backup_root}/${domain}.plist"
    done

    echo "[preference-config] restored ${backup_group}: ${backup_root}"
}

case "$mode" in
    backup) backup_preferences ;;
    restore) restore_preferences ;;
esac

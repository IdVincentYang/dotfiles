#!/usr/bin/env bash
set -euo pipefail

if [[ "${DOTFILES_RESTORE_APP_CONFIG:-0}" != "1" ]]; then
    echo "[app-config] restore disabled"
    exit 0
fi

if [[ $# -eq 0 ]]; then
    echo "Usage: app_config_restore_if_enabled.sh <restore-command> [arg ...]" >&2
    exit 2
fi

"$@"

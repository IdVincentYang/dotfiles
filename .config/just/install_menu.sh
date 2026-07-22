#!/usr/bin/env bash
set -euo pipefail

for var in JUSTFILE_PATH TARGET_PLATFORM; do
    if [[ -z "${!var:-}" ]]; then
        echo "$var is not set" >&2
        exit 1
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

declare -a filters=()
if [[ $# -gt 0 ]]; then
    filters=("$@")
fi

list_args=()
if [[ ${#filters[@]} -gt 0 ]]; then
    list_args=("${filters[@]}")
fi
list_args+=("raw=lines")

declare -a candidates=()
if [[ -t 0 ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        candidates+=("$line")
    done < <(JUSTFILE_PATH="$JUSTFILE_PATH" "$SCRIPT_DIR/list.sh" "${list_args[@]}" )
else
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        candidates+=("$line")
    done
fi

declare -a install_candidates=()
for candidate in "${candidates[@]}"; do
    IFS='|' read -r _main _domain r_name _os <<<"$(split_recipe "$candidate")"
    case "$r_name" in
        *-backup|*-restore|*-backup-menu|*-restore-menu)
            continue
            ;;
    esac
    install_candidates+=("$candidate")
done
if [[ ${#install_candidates[@]} -eq 0 ]]; then
    candidates=()
else
    candidates=("${install_candidates[@]}")
fi

if [[ "${#candidates[@]}" -eq 0 ]]; then
    echo "No recipes available for the given filters."
    exit 0
fi

selection=""
if command -v fzf >/dev/null 2>&1; then
    selection=$(printf '%s\n' "${candidates[@]}" | fzf -m --prompt="Select packages > " || true)
else
    printf 'fzf is not installed. Enter recipe names manually, separated by spaces.\nCandidates: %s\n> ' "${candidates[*]}"
    read -r selection || true
fi

if [[ -z "$selection" ]]; then
    echo "No selection made."
    exit 0
fi

selection="${selection//$'\n'/ }"
read -r -a selected <<<"$selection"

if [[ -z "${DOTFILES_RESTORE_APP_CONFIG+x}" ]]; then
    DOTFILES_RESTORE_APP_CONFIG=0
    if [[ -r /dev/tty && -w /dev/tty ]]; then
        printf 'Restore backed up app configs after install? [y/N] ' > /dev/tty
        read -r answer < /dev/tty || answer=""
        case "$answer" in
            y|Y|yes|YES|Yes)
                DOTFILES_RESTORE_APP_CONFIG=1
                ;;
        esac
    fi
fi

JUSTFILE_PATH="$JUSTFILE_PATH" TARGET_PLATFORM="$TARGET_PLATFORM" DOTFILES_RESTORE_APP_CONFIG="$DOTFILES_RESTORE_APP_CONFIG" "$SCRIPT_DIR/install.sh" "${selected[@]}"

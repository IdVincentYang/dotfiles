#!/usr/bin/env bash
set -euo pipefail

for var in JUSTFILE_PATH TARGET_PLATFORM; do
    if [[ -z "${!var:-}" ]]; then
        echo "$var 未设置" >&2
        exit 1
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    candidates+=("$line")
done < <(JUSTFILE_PATH="$JUSTFILE_PATH" "$SCRIPT_DIR/list.sh" "${list_args[@]}" )

if [[ "${#candidates[@]}" -eq 0 ]]; then
    echo "No recipes available for the given filters."
    exit 0
fi

selection=""
if command -v fzf >/dev/null 2>&1; then
    selection=$(printf '%s\n' "${candidates[@]}" | fzf -m --prompt="Select packages > " || true)
else
    printf 'fzf 未安装，手动输入要安装的名称(以空格分隔)。\n候选: %s\n> ' "${candidates[*]}"
    read -r selection || true
fi

if [[ -z "$selection" ]]; then
    echo "No selection made."
    exit 0
fi

selection="${selection//$'\n'/ }"
read -r -a selected <<<"$selection"

JUSTFILE_PATH="$JUSTFILE_PATH" TARGET_PLATFORM="$TARGET_PLATFORM" "$SCRIPT_DIR/install.sh" "${selected[@]}"

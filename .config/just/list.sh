#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

main_filter="${1:-}"
domain_filter="${2:-}"
os_filter="${3:-}"
name_filter="${4:-}"
raw_output="${5:-0}"

recipes=()
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    recipes+=("$line")
done < <(collect_recipes || true)

filtered=()
if [[ "${#recipes[@]}" -gt 0 ]]; then
    for recipe in "${recipes[@]}"; do
        IFS='-' read -r r_main r_domain r_name r_os <<<"$recipe"
        [[ -n "$main_filter" && "${r_main:-}" != "$main_filter" ]] && continue
        [[ -n "$domain_filter" && "${r_domain:-}" != "$domain_filter" ]] && continue
        [[ -n "$name_filter" && "${r_name:-}" != "$name_filter" ]] && continue
        if [[ -n "$os_filter" ]]; then
            [[ -z "${r_os:-}" ]] && continue
            [[ "$r_os" != "$os_filter" ]] && continue
        fi
        filtered+=("$recipe")
    done
fi

if [[ "$raw_output" == "1" ]]; then
    if [[ "${#filtered[@]}" -gt 0 ]]; then
        printf '%s\n' "${filtered[@]}"
    fi
    exit 0
fi

if [[ "${#filtered[@]}" -eq 0 ]]; then
    printf 'No recipes matched filters (main=%s domain=%s name=%s os=%s)\n' \
        "${main_filter:-*}" "${domain_filter:-*}" "${name_filter:-*}" "${os_filter:-*}"
else
    printf 'Matched recipes (%d):\n' "${#filtered[@]}"
    for recipe in "${filtered[@]}"; do
        printf ' - %s\n' "$recipe"
    done
fi

#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    if [[ -t 0 ]]; then
        echo "Usage: just install <name> [name ...]" >&2
        exit 1
    fi
fi

packages=("$@")
if [[ ${#packages[@]} -eq 0 ]]; then
    stdin_data="$(cat)"
    if [[ -z "$stdin_data" ]]; then
        echo "No packages specified." >&2
        exit 0
    fi
    read -r -a packages <<<"$stdin_data"
fi

if [[ -z "${TARGET_PLATFORM:-}" ]]; then
    echo "TARGET_PLATFORM 未设置" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

recipes=()
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    recipes+=("$line")
done < <(collect_recipes || true)
if [[ "${#recipes[@]}" -eq 0 ]]; then
    echo "No installable recipes defined yet." >&2
    exit 0
fi

select_recipe() {
    local pkg="$1"
    local -a matches=()
    for recipe in "${recipes[@]}"; do
        IFS='|' read -r _main _domain r_name r_os <<<"$(split_recipe "$recipe")"
        [[ "${r_name:-}" != "$pkg" ]] && continue
        if [[ -n "${r_os:-}" ]]; then
            [[ "$r_os" != "$TARGET_PLATFORM" ]] && continue
        fi
        matches+=("$recipe")
    done

    if [[ "${#matches[@]}" -eq 0 ]]; then
        printf 'No recipe matches "%s" for platform "%s".\n' "$pkg" "$TARGET_PLATFORM" >&2
        return 1
    fi

    if [[ "${#matches[@]}" -eq 1 ]]; then
        printf '%s' "${matches[0]}"
        return 0
    fi

    echo "Multiple recipes found for '$pkg'."
    local idx=1
    for candidate in "${matches[@]}"; do
        printf '  %d) %s\n' "$idx" "$candidate"
        idx=$((idx + 1))
    done
    printf '  %d) Skip %s\n' "$idx" "$pkg"

    local choice
    while true; do
        read -r -p "Select recipe [1-$idx]: " choice
        [[ -z "$choice" ]] && continue
        if [[ "$choice" -eq "$idx" ]]; then
            return 1
        elif [[ "$choice" -ge 1 && "$choice" -lt "$idx" ]]; then
            local selected_index=$((choice - 1))
            printf '%s' "${matches[selected_index]}"
            return 0
        else
            echo "Invalid selection"
        fi
    done
}

for pkg in "${packages[@]}"; do
    target=""
    if target=$(select_recipe "$pkg"); then
        echo "Installing ${target}..."
        just --justfile "$JUSTFILE_PATH" "$target"
    else
        echo "Skipped $pkg"
    fi
done

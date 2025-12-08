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

normalize_spec() {
    local spec="$1"
    local base="$spec"
    local hint_os=""

    for candidate in darwin linux termux; do
        if [[ "$base" == *"-$candidate" ]]; then
            hint_os="$candidate"
            base="${base%-${candidate}}"
            break
        fi
    done

    case "$base" in
        core-*|system-*|cli-*|gui-*|extra-*)
            local trimmed="${base#*-}"
            if [[ "$trimmed" == *"-"* ]]; then
                base="${trimmed#*-}"
            else
                base="$spec"
            fi
            ;;
    esac

    printf '%s|%s' "$base" "$hint_os"
}

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
    local hint_os="$2"
    local fallback=""

    for recipe in "${recipes[@]}"; do
        IFS='|' read -r _main _domain r_name r_os <<<"$(split_recipe "$recipe")"
        [[ "${r_name:-}" != "$pkg" ]] && continue

        if [[ -n "$hint_os" ]]; then
            [[ -n "$r_os" && "$r_os" != "$hint_os" ]] && continue
        fi

        if [[ -n "${r_os:-}" ]]; then
            if [[ -n "$hint_os" ]]; then
                [[ "$r_os" == "$hint_os" ]] || continue
            else
                [[ "$r_os" == "$TARGET_PLATFORM" ]] || continue
            fi
            printf '%s' "$recipe"
            return 0
        fi

        [[ -z "$fallback" ]] && fallback="$recipe"
    done

    if [[ -n "$fallback" ]]; then
        printf '%s' "$fallback"
        return 0
    fi

    printf 'No recipe matches "%s" for platform "%s".\n' "$pkg" "${hint_os:-$TARGET_PLATFORM}" >&2
    return 1
}

for pkg in "${packages[@]}"; do
    IFS='|' read -r pkg_name pkg_os_hint <<<"$(normalize_spec "$pkg")"
    target=""
    if target=$(select_recipe "$pkg_name" "$pkg_os_hint"); then
        echo "Installing ${target}..."
        just --justfile "$JUSTFILE_PATH" "$target"
    else
        echo "Skipped $pkg"
    fi
done

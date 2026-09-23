#!/usr/bin/env bash

if [[ -z "${JUSTFILE_PATH:-}" ]]; then
    echo "[just-common] JUSTFILE_PATH is not set" >&2
    exit 1
fi

collect_recipes() {
    just --justfile "$JUSTFILE_PATH" --list \
        | awk '/^[[:space:]]+[^[:space:]]/ {print $1}' \
        | awk -F'-' 'NF>=3 {print}'
}

split_recipe() {
    local recipe="$1"
    local primary=""
    local domain=""
    local rest=""
    IFS='-' read -r primary domain rest <<<"$recipe"
    local os=""
    local name="$rest"
    for candidate in darwin linux termux; do
        if [[ "$name" == *"-$candidate" ]]; then
            os="$candidate"
            name="${name%-${candidate}}"
            break
        fi
    done
    printf '%s|%s|%s|%s' "$primary" "$domain" "$name" "$os"
}

recipe_uses_brew() {
    local recipe="$1"
    awk -v target="$recipe" '
        $0 == target ":" { inside=1; next }
        inside && $0 == "" { next }
        inside && $0 !~ /^[[:space:]]/ { inside=0 }
        inside && $0 ~ /(^|[[:space:]])brew([[:space:]]|$)/ { found=1 }
        END { exit(found ? 0 : 1) }
    ' "$JUSTFILE_PATH"
}

#!/usr/bin/env bash

if [[ -z "${JUSTFILE_PATH:-}" ]]; then
    echo "[just-common] JUSTFILE_PATH 未设置" >&2
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

#!/usr/bin/env bash

if [[ -z "${JUSTFILE_PATH:-}" ]]; then
    echo "[just-common] JUSTFILE_PATH 未设置" >&2
    exit 1
fi

collect_recipes() {
    just --justfile "$JUSTFILE_PATH" --list \
        | sed -n 's/^    \([^[:space:]]\+\).*/\1/p' \
        | awk -F'-' 'NF>=3 {print}'
}

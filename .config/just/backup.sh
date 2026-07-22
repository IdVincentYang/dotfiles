#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "No backup recipes specified." >&2
    exit 0
fi

if [[ -z "${JUSTFILE_PATH:-}" ]]; then
    echo "JUSTFILE_PATH is not set" >&2
    exit 1
fi

for recipe in "$@"; do
    echo "Backing up ${recipe}..."
    just --justfile "$JUSTFILE_PATH" "$recipe"
done

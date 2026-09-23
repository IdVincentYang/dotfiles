#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: package-install.sh <package> [package ...]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
platform="${TARGET_PLATFORM:-$(${SCRIPT_DIR}/platform.sh)}"

case "$platform" in
    darwin|linux)
        if ! command -v brew >/dev/null 2>&1; then
            echo "Homebrew is required for platform ${platform}." >&2
            exit 1
        fi
        exec brew install "$@"
        ;;
    termux)
        if ! command -v pkg >/dev/null 2>&1; then
            echo "Termux pkg is required for platform termux." >&2
            exit 1
        fi
        exec pkg install -y "$@"
        ;;
    *)
        echo "Unsupported platform: ${platform}" >&2
        exit 1
        ;;
esac

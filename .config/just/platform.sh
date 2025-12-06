#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${TERMUX_VERSION:-}" ]]; then
    printf 'termux'
    exit 0
fi

case "$(uname -s)" in
    Darwin*) printf 'darwin' ;;
    *) printf 'linux' ;;
esac

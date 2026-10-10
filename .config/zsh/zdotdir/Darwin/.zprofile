# macOS /etc/zprofile runs path_helper before this file. Keep Homebrew commands
# ahead of the system paths while removing any duplicate PATH entries.
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  typeset -U path
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "${path[@]}")
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/Darwin/.zprofile"

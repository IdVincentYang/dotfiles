if [[ "${__ZDOT_DARWIN_ZSHENV_LOADED:-}" != "1" ]]; then
  export SHELL_SESSIONS_DISABLE=1
  export __ZDOT_DARWIN_ZSHENV_LOADED=1
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/Darwin/.zshenv"

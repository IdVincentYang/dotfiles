if [[ "${__ZDOT_DARWIN_ZSHENV_LOADED:-}" != "1" ]]; then
  # Disable macOS Terminal's shell-session save/restore logic. Apple reads this
  # from /etc/zshrc_Apple_Terminal, so it must be set before interactive rc.
  export SHELL_SESSIONS_DISABLE=1
  export __ZDOT_DARWIN_ZSHENV_LOADED=1
fi

# OrbStack may add command paths or environment needed by scripts.
if [[ -f "$HOME/.orbstack/shell/init.zsh" ]]; then
  source "$HOME/.orbstack/shell/init.zsh" >/dev/null 2>&1 || :
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/Darwin/.zshenv"

# Termux-specific environment settings belong here.
if (( $+commands[direnv] )); then
  export ASDF_DIRENV_BIN="$commands[direnv]"
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/Termux/.zshenv"

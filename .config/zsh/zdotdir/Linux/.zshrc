if [[ -f "$MYSH/zshrc.linux" ]]; then
  source "$MYSH/zshrc.linux"
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/Linux/.zshrc"

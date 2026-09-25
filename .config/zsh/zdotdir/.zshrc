# vi:set ft=sh

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Core configuration stack
if [[ -f "$MYSH/zshrc" ]]; then
  source "$MYSH/zshrc"
fi

# Keep legacy asdf shell hooks in interactive shells; executable shims are
# already placed in PATH by .zshenv for scripts.
if command -v asdf >/dev/null 2>&1 && [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  asdf_shell="$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh"
  if [[ -f "$asdf_shell" ]]; then
    source "$asdf_shell"
  fi
  unset asdf_shell
fi

if [[ -f "$MYSH/alias" ]]; then
  source "$MYSH/alias"
fi

# PM2 alias is an interactive convenience; scripts should invoke authbind
# explicitly when they need it.
if command -v pm2 >/dev/null 2>&1 && command -v authbind >/dev/null 2>&1; then
  alias pm2='authbind --deep pm2'
fi

if [[ -f "$MYSH/utils" ]]; then
  source "$MYSH/utils"
fi

# Provide the asdf-direnv hook in interactive login and non-login shells.
if [[ "${__ASDF_DIRENV_SOURCED_PID:-}" != "$$" ]]; then
  asdf_direnv_rc="${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc"
  if [[ -f "$asdf_direnv_rc" ]]; then
    source "$asdf_direnv_rc"
    __ASDF_DIRENV_SOURCED_PID="$$"
  fi
fi

case "$ZDOT_PLATFORM" in
  Darwin)
    [[ -f "$MYSH/alias.osx" ]] && source "$MYSH/alias.osx"
    [[ -f "$MYSH/utils.osx" ]] && source "$MYSH/utils.osx"
    ;;
  Linux)
    [[ -f "$MYSH/alias.linux" ]] && source "$MYSH/alias.linux"
    [[ -f "$MYSH/utils.linux" ]] && source "$MYSH/utils.linux"
    ;;
  Termux)
    [[ -f "$MYSH/alias.termux" ]] && source "$MYSH/alias.termux"
    [[ -f "$MYSH/utils.termux" ]] && source "$MYSH/utils.termux"
    ;;
 esac

# Proxy helpers (optional)
if [[ -f "$MYSH/proxy" ]]; then
  source "$MYSH/proxy"
fi

# adb helpers
if command -v adb >/dev/null 2>&1; then
  : # device specific overrides can live in platform overlays
fi

# broot helper function
if command -v broot >/dev/null 2>&1; then
  br() {
    local cmd_file cmd code
    cmd_file=$(mktemp)
    if broot --outcmd "$cmd_file" "$@"; then
      cmd=$(<"$cmd_file")
      command rm -f "$cmd_file"
      eval "$cmd"
    else
      code=$?
      command rm -f "$cmd_file"
      return "$code"
    fi
  }
fi

# fzf configuration
if command -v fzf >/dev/null 2>&1 && [[ -f "$MYSH/fzf" ]]; then
  source "$MYSH/fzf"
fi

# Optional terminal plugins
if [[ ! "${__CFBundleIdentifier:-}" =~ warp ]]; then
  autosuggest="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$autosuggest" ]] && source "$autosuggest"

  syntax_highlight="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -f "$syntax_highlight" ]] && source "$syntax_highlight"

  history_substring="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
  if [[ -f "$history_substring" ]]; then
    source "$history_substring"
    bindkey "^n" history-substring-search-down
    bindkey "^p" history-substring-search-up
    bindkey "^j" down-line-or-history
    bindkey "^k" up-line-or-history
  fi
fi

platform_rc="$ZDOTDIR/${ZDOT_PLATFORM}/.zshrc"
if [[ -f "$platform_rc" ]]; then
  source "$platform_rc"
fi

if [[ -f "$ZDOTDIR/.p10k.zsh" ]]; then
  source "$ZDOTDIR/.p10k.zsh"
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/.zshrc"

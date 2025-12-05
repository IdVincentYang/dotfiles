# vi:set ft=sh

zmodload zsh/zprof 2>/dev/null || true

if [[ -z "${__ZDOTLOADED:-}" ]]; then
  export __ZDOTLOADED=""
fi

export MYSH="${MYSH:-$HOME/.config/zsh}"
if [[ -f "$MYSH/xdg_dirs" ]]; then
  source "$MYSH/xdg_dirs"
fi

case "$(uname -s)" in
  Darwin*) export MY_PLATFORM=Darwin ;;
  Linux*) export MY_PLATFORM=Linux ;;
  *) export MY_PLATFORM=Unknown ;;
esac

: "${LANG:=en_US.UTF-8}"

platform_env="$ZDOTDIR/${MY_PLATFORM}/.zshenv"
if [[ -f "$platform_env" ]]; then
  source "$platform_env"
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/.zshenv"

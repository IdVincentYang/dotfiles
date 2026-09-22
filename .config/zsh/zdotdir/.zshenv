# vi:set ft=sh

zmodload zsh/zprof 2>/dev/null || true

if [[ -z "${__ZDOTLOADED:-}" ]]; then
  export __ZDOTLOADED=""
fi

export MYSH="${MYSH:-$HOME/.config/zsh}"

# ChromeOS may also report linux-android, so only Termux-specific markers select
# the Termux overlay. Other Linux environments continue to use Linux/.
if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "${PREFIX:-}" == */com.termux/files/usr ]]; then
  typeset -g ZDOT_PLATFORM=Termux
else
  case "$OSTYPE" in
    darwin*) typeset -g ZDOT_PLATFORM=Darwin ;;
    linux*) typeset -g ZDOT_PLATFORM=Linux ;;
    *) typeset -g ZDOT_PLATFORM=Unknown ;;
  esac
fi

: "${LANG:=en_US.UTF-8}"

platform_env="$ZDOTDIR/${ZDOT_PLATFORM}/.zshenv"
if [[ -f "$platform_env" ]]; then
  source "$platform_env"
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/.zshenv"

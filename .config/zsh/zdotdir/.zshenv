# vi:set ft=sh

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
    *) print -u2 -- "[zsh config] Unsupported platform OSTYPE='${OSTYPE:-unset}'; add a ZDOT_PLATFORM mapping and platform overlay." ;;
  esac
fi

export LANG="${LANG:-en_US.UTF-8}"

# Add executable directories without duplicating entries in PATH.
__zdot_prepend_path() {
  local path_entry="$1"
  [[ -d "$path_entry" ]] || return 0
  case ":$PATH:" in
    *:"$path_entry":*) ;;
    *) path=("$path_entry" $path) ;;
  esac
}

platform_env="$ZDOTDIR/${ZDOT_PLATFORM}/.zshenv"
if [[ -f "$platform_env" ]]; then
  source "$platform_env"
fi

# JAVA_HOME is process environment used by build tools and scripts, so expose it
# to non-interactive shells as well. A value supplied by the local env wins.
if [[ -z "${JAVA_HOME:-}" ]]; then
  if [[ "$ZDOT_PLATFORM" == "Darwin" && -x /usr/libexec/java_home ]]; then
    java_home_candidate=$(/usr/libexec/java_home -v 11 2>/dev/null)
    [[ -n "$java_home_candidate" ]] && export JAVA_HOME="$java_home_candidate"
    unset java_home_candidate
  elif [[ "$ZDOT_PLATFORM" == "Linux" ]]; then
    for java_dir in /usr/lib/jvm/java-11-openjdk-amd64 /usr/lib/jvm/java-11-openjdk /usr/lib/jvm/default-java; do
      if [[ -d "$java_dir" ]]; then
        export JAVA_HOME="$java_dir"
        break
      fi
    done
    unset java_dir
  fi
fi

# Configure XDG data locations only when Homebrew's rustup is installed.
rustup_bin="${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/rustup/bin}"
if [[ -n "$rustup_bin" && -x "$rustup_bin/rustup" ]]; then
  export CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
  export RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"
  __zdot_prepend_path "$rustup_bin"
fi
unset rustup_bin

cargo_bin="${CARGO_HOME:-$HOME/.cargo}/bin"
__zdot_prepend_path "$cargo_bin"
unset cargo_bin

# asdf shims expose language tools to both interactive shells and scripts.
if command -v asdf >/dev/null 2>&1; then
  export ASDF_CONFIG_FILE="${ASDF_CONFIG_FILE:-$XDG_CONFIG_HOME/asdf/asdfrc}"
  export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$XDG_STATE_HOME/asdf}"
  __zdot_prepend_path "$ASDF_DATA_DIR/shims"
fi

if command -v go >/dev/null 2>&1; then
  export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
  export GOBIN="${GOBIN:-$GOPATH/bin}"
  __zdot_prepend_path "$GOBIN"
fi

if command -v npm >/dev/null 2>&1; then
  export NPM_CONFIG_USERCONFIG="${NPM_CONFIG_USERCONFIG:-$XDG_CONFIG_HOME/npm/config}"
  export NPM_CONFIG_CACHE="${NPM_CONFIG_CACHE:-$XDG_CACHE_HOME/npm}"
fi

if command -v pm2 >/dev/null 2>&1; then
  export PM2_HOME="${PM2_HOME:-$XDG_STATE_HOME/pm2}"
fi

# Set ANDROID_SDK_ROOT in an Android-related fragment under $MY_LOCAL_ENV_D.
if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
  __zdot_prepend_path "$ANDROID_SDK_ROOT/platform-tools"
fi

__zdot_prepend_path "$HOME/.local/bin"

if [[ "$ZDOT_PLATFORM" == "Termux" && -n "${PREFIX:-}" ]]; then
  __zdot_prepend_path "$PREFIX/bin"
fi

unfunction __zdot_prepend_path

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/.zshenv"

# vi:set ft=sh

# Initialize Homebrew if available
for brew_candidate in \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/brew}" \
  "/opt/homebrew/bin/brew" \
  "/usr/local/bin/brew" \
  "/home/linuxbrew/.linuxbrew/bin/brew"
do
  if [[ -x "$brew_candidate" ]]; then
    eval "$($brew_candidate shellenv)"
    break
  fi
done

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  site_functions="$HOMEBREW_PREFIX/share/zsh/site-functions"
  if [[ -d "$site_functions" ]]; then
    fpath=("$site_functions" $fpath)
  fi

  brew_curl="$HOMEBREW_PREFIX/opt/curl/bin/curl"
  if [[ -x "$brew_curl" ]]; then
    export HOMEBREW_CURL_PATH="$brew_curl"
  fi
fi

# asdf configuration
if command -v asdf >/dev/null 2>&1; then
  printf '[zprofile][asdf] detected existing asdf: %s\n' "$(command -v asdf)" >&2
  export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME}/asdf/asdfrc"
  export ASDF_DATA_DIR="${XDG_STATE_HOME}/asdf"
else
  _BREW_ASDF_PREFIX=""
  if command -v brew >/dev/null 2>&1; then
    _BREW_ASDF_PREFIX="$(brew --prefix asdf 2>/dev/null || true)"
  fi
  if [[ -n "$_BREW_ASDF_PREFIX" && -f "$_BREW_ASDF_PREFIX/libexec/asdf.sh" ]]; then
    printf '[zprofile][asdf] sourcing %s\n' "$_BREW_ASDF_PREFIX/libexec/asdf.sh" >&2
    source "$_BREW_ASDF_PREFIX/libexec/asdf.sh"
  else
    printf '[zprofile][asdf] no asdf found via brew\n' >&2
  fi
fi

if command -v asdf >/dev/null 2>&1; then
  if command -v direnv >/dev/null 2>&1; then
    asdf_direnv_rc="${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc"
    if [[ -f "$asdf_direnv_rc" ]]; then
      source "$asdf_direnv_rc"
    fi
  fi
fi

# Go environment variables
if command -v go >/dev/null 2>&1; then
  export GOBIN="$HOME/.local/bin"
  export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
fi

# npm configuration
if command -v npm >/dev/null 2>&1; then
  export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/npm/config"
  export NPM_CONFIG_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/npm"
fi

# pm2 configuration (silent when missing to keep instant prompt clean)
if command -v pm2 >/dev/null 2>&1; then
  export PM2_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/pm2"
  if command -v authbind >/dev/null 2>&1; then
    alias pm2='authbind --deep pm2'
  fi
fi

# rustup toolchain
if [[ -d "$HOME/.cargo" ]]; then
  source "$HOME/.cargo/env"
fi

# ensure ~/.local/bin present in PATH
local_bin="$HOME/.local/bin"
case ":$PATH:" in
  *:"$local_bin":*) ;;
  *)
    if [[ -d "$local_bin" ]]; then
      export PATH="$local_bin:$PATH"
    fi
    ;;
esac

platform_profile="$ZDOTDIR/${MY_PLATFORM}/.zprofile"
if [[ -f "$platform_profile" ]]; then
  source "$platform_profile"
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/.zprofile"

# vi:set ft=sh

# Homebrew completion functions are only needed by interactive shells.
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  site_functions="$HOMEBREW_PREFIX/share/zsh/site-functions"
  if [[ -d "$site_functions" ]]; then
    fpath=("$site_functions" $fpath)
  fi
  unset site_functions
fi

platform_profile="$ZDOTDIR/${ZDOT_PLATFORM}/.zprofile"
if [[ -f "$platform_profile" ]]; then
  source "$platform_profile"
fi
unset platform_profile

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/.zprofile"

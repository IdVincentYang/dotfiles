export MY_ERBI_CIN="${XDG_CONFIG_HOME}/backups/erbi/OpenVanilla/erbi.cin"
export MY_SOURCE_BUNDLE="$HOME/archives.noindex/Public/Source.sparsebundle"
export MY_SOURCE_DIR="/Volumes/Source"

if [[ -n "${VIM:-}" ]]; then
  export PS1='[VIM]\h:\w\$ '
fi

# macOS-specific command helpers
if command -v adb >/dev/null 2>&1; then
  export ANDROID_SERIAL_PIXEL4XL="99031FFBA00CPX"
  export ANDROID_SERIAL_PIXEL8PRO="37291FDJG00ETD"
  export ANDROID_SERIAL="$ANDROID_SERIAL_PIXEL8PRO"
fi

if command -v brew >/dev/null 2>&1; then
  export HOMEBREW_NO_AUTO_UPDATE=1
fi

# Java Home override handled in common rc (kept for compatibility)

# Optional wine helpers placeholder
# export WINE_PREFIX_ROOT="${XDG_DATA_HOME}/wineprefixes"
# export WINEPREFIX="${WINE_PREFIX_ROOT}/default"
# export WINEARCH=win64

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/Darwin/.zshrc"

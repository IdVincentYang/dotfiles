# Android SDK default Linux location
if [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
  export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/Linux/.zprofile"

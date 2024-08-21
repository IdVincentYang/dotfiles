
# Homebrew installed bin path
if which /opt/homebrew/bin/brew > /dev/null; then
    eval $(/opt/homebrew/bin/brew shellenv)

    fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

    # export HOMEBREW_NO_INSTALL_FROM_API=1

    if which $HOMEBREW_PREFIX/opt/curl/bin/curl > /dev/null; then
        export HOMEBREW_CURL_PATH="$HOMEBREW_PREFIX/opt/curl/bin/curl"
    fi
fi

# asdf config: https://asdf-vm.com/manage/configuration.html
if which asdf > /dev/null; then
    export ASDF_CONFIG_FILE=${XDG_CONFIG_HOME}/asdf/asdfrc
    export ASDF_DATA_DIR=${XDG_STATE_HOME}/asdf
    source /opt/homebrew/opt/asdf/libexec/asdf.sh

    # asdf direnv config
    if which direnv > /dev/null; then
        source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc"
    fi
fi

# android sdk path
if [ -d ~/Library/Android/sdk ]; then
    export ANDROID_SDK_ROOT=~/Library/Android/sdk
    export ANDROID_HOME=${ANDROID_SDK_ROOT}
    export PATH=${ANDROID_SDK_ROOT}/platform-tools:${PATH}
fi

# rustup toolchain path
[ -d "${HOME}/.cargo" ] && source "${HOME}/.cargo/env"

# npm config: https://docs.npmjs.com/cli/v7/using-npm/config
if which npm > /dev/null; then
    export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/npm/config"
    export NPM_CONFIG_CACHE="${XDG_CACHE_HOME:-$HOME/Library/Caches}/npm"
fi
# pm2
if which pm2 > /dev/null; then
    export PM2_HOME="${XDG_STATE_HOME:-~/.local/state}/pm2"
    # config doc: https://pm2.keymetrics.io/docs/usage/specifics/
    if which authbind > /dev/null; then
        alias pm2='authbind --deep pm2'
    fi
else
    echo "[WARN] pm2 not installed, via 'npm install -g pm2' to install."
fi

# add local/bin to path variable if not exists
_LOCAL_BIN="${HOME}/.local/bin"
if [ -d "${_LOCAL_BIN}" ]; then
    case ":${PATH}:" in
        *:"${_LOCAL_BIN}":*)
            ;;
        *)
            export PATH="${_LOCAL_BIN}:$PATH"
            ;;
    esac
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/.zprofile"

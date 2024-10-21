#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title ScrCpy
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "4,8,Serial" }
# @raycast.packageName my.scrcpy

# Documentation:
# @raycast.author awenoo1
# @raycast.authorURL https://raycast.com/awenoo1

export ANDROID_SDK_ROOT=~/Library/Android/sdk
export ANDROID_HOME=${ANDROID_SDK_ROOT}
export PATH=${ANDROID_SDK_ROOT}/platform-tools:${PATH}

_SEMU=emulator-5554
_SP4=99031FFBA00CPX
_SP8=37291FDJG00ETD

if ! which scrcpy > /dev/null; then
    if which brew > /dev/null; then
        brew install scrcpy
    fi
fi

if [[ "$1" = "4" ]]; then
    ANDROID_SERIAL=$_SP4 scrcpy -S -w -m 1520 --max-fps=20
elif [[ "$1" = "8" ]]; then
    ANDROID_SERIAL=$_SP8 scrcpy -S -w -m 1122 --max-fps=30
else
    ANDROID_SERIAL=$1 scrcpy -S -w --max-fps=30
fi


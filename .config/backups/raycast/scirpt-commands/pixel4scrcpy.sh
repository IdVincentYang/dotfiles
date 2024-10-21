#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Pixel4ScrCpy
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName my.scrcpy.autoadb

# Documentation:
# @raycast.author awenoo1
# @raycast.authorURL https://raycast.com/awenoo1

export ANDROID_SDK_ROOT=~/Library/Android/sdk
export ANDROID_HOME=${ANDROID_SDK_ROOT}
export PATH=${ANDROID_SDK_ROOT}/platform-tools:${PATH}

# Android Phone Serial Number
_PIXEL4XL_SERIAL=99031FFBA00CPX
_PIXEL8P_SERIAL=37291FDJG00ETD

if ! which scrcpy > /dev/null; then
    if which brew > /dev/null; then
        brew install scrcpy
    fi
fi
if ! which scrcpy > /dev/null; then
    echo "Command 'scrcpy' not find in path: $PATH"
    exit 1
fi
if [[ "$1" = "$_PIXEL8P_SERIAL" ]]; then
    ANDROID_SERIAL=$_PIXEL8P_SERIAL scrcpy -S -w -m 1122 --max-fps=30
elif [[ "$1" = "$_PIXEL4XL_SERIAL" ]]; then
    ANDROID_SERIAL=$_PIXEL4XL_SERIAL scrcpy -S -w -m 1520 --max-fps=20
elif [[ "$1" != "emulator-"* ]]; then
    echo "$@" > ~/Downloads/autoadb.txt
    echo "Unsupport param, detail in ~/Downloads/autoadb.txt"
    exit 1
fi


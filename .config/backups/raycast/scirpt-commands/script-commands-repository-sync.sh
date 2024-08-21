#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title script-commands-repository-sync
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖
# @raycast.needsConfirmation true

# Documentation:
# @raycast.description Sync persional raycast script commands local repository with remotes.
# @raycast.author awenoo1
# @raycast.authorURL https://raycast.com/awenoo1

_ORIGIN="git@github.com:yangws/script-commands.git"
_UPSTREAM="https://github.com/raycast/script-commands.git"
_LOCAL="${XDG_CONFIG_HOME:-~}/raycast/script-commands/"
_GIT_BIN=$(which git)

if [ ! -f "${_GIT_BIN}" ]; then
    echo "Install git first!"
    exit 1
fi

if [ -f "${_LOCAL}" ]; then
    echo "Local repository path($_LOCAL) is a file, remove it first!"
    exit 2
fi

function _git_exec() {
    echo "Exec: ${_GIT_BIN} $@"
    if "${_GIT_BIN}" $@ ; then
        # success
    else
        # failure
        exit 3
    fi
}

# if local repo not exists, clone it and set remotes
# else
#   if local has changes, push to origin
# endif
# pull upstream to local

if [ ! -e "${_LOCAL}" ]; then
    _git_exec clone "${_ORIGIN}" "${_LOCAL}"
    pushd "${_LOCAL}" > /dev/null
    _git_exec remote add upstream "${_UPSTREAM}"
    popd > /dev/null
else
    pushd "${_LOCAL}" > /dev/null
    if [[ `${_GIT_BIN} status --porcelain` ]] ; then
        # local has changes
        _git_exec add -f -A
        _git_exec commit -am "[update]"
        _git_exec push origin
    fi
    popd > /dev/null
fi

pushd "${_LOCAL}" > /dev/null
_git_exec pull upstream $("${_GIT_BIN}" rev-parse --abbrev-ref HEAD)
_git_exec push origin
popd > /dev/null


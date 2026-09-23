# Termux-specific environment settings belong here.
termux_private_env="${HOME}/.local/private/termux.env"
if [[ -r "$termux_private_env" ]]; then
  source "$termux_private_env"
fi
unset termux_private_env

if (( $+commands[direnv] )); then
  export ASDF_DIRENV_BIN="$commands[direnv]"
fi

if [[ -o interactive ]]; then
  codex_termux() {
    local command_line="/usr/bin/codex"
    local arg
    for arg in "$@"; do
      command_line+=" ${(q)arg}"
    done
    SSL_CERT_FILE=/etc/tls/cert.pem termux-chroot "$command_line"
  }
  alias codex=codex_termux
fi

export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/Termux/.zshenv"

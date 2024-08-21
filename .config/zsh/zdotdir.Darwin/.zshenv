### [Startup/Shutdown Files](https://zsh.sourceforge.io/Doc/Release/Files.html#index-ZDOTDIR_002c-use-of)
#
#   Commands are first read from /etc/zshenv, then read from $ZDOTDIR/.zshenv.
# If the shell is a login shell, commands are read from /etc/zprofile and then $ZDOTDIR/.zprofile.
# Then, if the shell is interactive, commands are read from /etc/zshrc and then $ZDOTDIR/.zshrc.
# Finally, if the shell is a login shell, /etc/zlogin and $ZDOTDIR/.zlogin are read.
#
#   When a login shell exits, the files $ZDOTDIR/.zlogout and then /etc/zlogout are read.

# [Linerre/Setting $PATH for zsh on macOS.md](https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2)

# profiling function's times
#   [doc](https://blog.skk.moe/post/make-oh-my-zsh-fly/)
zmodload zsh/zprof

if [ -z "${__ZDOTLOADED}" ]; then
    ### Tweak zsh shell env
    # Disable Terminal app's per session save/restore mechanism(/etc/zshrc_Apple_Terminal)
    export SHELL_SESSIONS_DISABLE=1

    # Tweak terminal settings
    export LANG=en_US.UTF-8

    # Define home env variables
    export MYSH="$HOME/.config/zsh"

    # Define XDG like system dirs
    source "${MYSH}/xdg_dirs"

    # set variable __ZDOTLOADED for dot file load track
    export __ZDOTLOADED="$__ZDOTLOADED:$ZDOTDIR/.zshenv"
fi

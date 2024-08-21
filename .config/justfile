# vi: ft=sh
# [doc](https://just.systems/man/zh/)
# [grammar](https://github.com/casey/just/blob/master/GRAMMAR.md)
# [cheetsheet](https://cheatography.com/linux-china/cheat-sheets/justfile/)

kPWD := justfile_directory()

default:
    @just --justfile '{{justfile()}}' --list

var:
    @just --justfile '{{justfile()}}' --evaluate

app-media-install-iina:
    brew install --cask iina
    mkdir -p "${HOME}/Library/Application Support/com.colliderli.iina/input_conf/IINA_MY.conf"
    ln -s "${HOME}/.config/backups/iina/input_conf/IINA_MY.conf" "Library/Application Support/com.colliderli.iina/input_conf/IINA_MY.conf"

base-cmds:
    brew install autoconf automake p7zip tree zoxide
    ### fonts
    #   nerd fonts(https://github.com/ryanoasis/nerd-fonts/blob/master/readme_cn.md)
    #       config terminal: menu->setting...->text->font->change font
    brew install font-jetbrains-mono-nerd-font

base-asdf: (base-cmds)
    # step1: install asdf
    brew install asdf
    # step2: install plugs by asdf/tool-versions
    ln -s "./asdf/tool-versions" "${HOME}/.tool-versions"
    # step3: install tools with version by asdf/tool-versions
    asdf install

kCmdBatDesc     := "bat -> cat: Clone of cat(1) with syntax highlighting and Git integration."
kCmdBtopDesc    := "btop -> top: Resource monitor. Enhanced top command."
kCmdFdDesc      := "fd -> find: Simple, fast and user-friendly alternative to find."
kCmdFzfDesc     := "fzf: Command-line fuzzy finder. Usage:
    <ALT>+c:    cd into the selected directory
    <CTRL>+t:   paste the selected files and directories onto the command-line
    <CTRL>+r:   paste the selected command from history onto the command-line
    COMMAND [DIRECTORY/][FUZZY_PATTERN]**<TAB>: fuzzy completion for files and directories
    kill -<SIG> **<TAB>:                        fuzzy completion for PIDs
    {ssh|telnet} **<TAB>:                       fuzzy completion for hostnames
    {export|unset|unalias} **<TAB>:             fuzzy completion for environment variables / aliases

Search syntax:
    <chars>:        fuzzy-match
    [!']<chars>:    {inverse-exact|exact}-match
    [!]^<chars>:    {inverse-}prefix-exact-match
    [!]<chars>$:    {inverse-}suffix-exact-match
"
kCmdRgDesc := "ripgrep -> find: Search tool like grep. Usage: rg [options] [paths]* [-- [PATTERN]*]
[PATTERN options]: These options can be provided multiple times.
    -e, --regexp <PATTERN>: A pattern to search for.
    -f, --file <PATTERNFILE>: Search for patterns from the given file, with one pattern per line.
    -F, --fixed-strings | --no-fixed-strings: treat the pattern as a literal string or a regular exp
[Search options]:
    -s, --case-sensitive(default) | -i, --ignore-case | -S, --smart-case: searches sensitively
    --crlf: treat CRLF(\\r\\n) as a line terminator instead of just \\n.
    -E, --encoding <auto(default)|none|ENCODING>: auto only applies to files that begin with UTF-[8|16]BOM
    -x, --line-regexp | -b, --word-regexp: putting (^...$ around|\\b before) all of the search patterns or not
    -U, --multiline [--multiline-dotall] | --no-multiline: Enable matching across multiple lines or not.
    --unicode(default) | --no-unicode: enable or disable unicode mode of its regexes
[Result options]:
    -A, --after-context | -B, --before-context | -C, --context <NUM>
    --content-spearator <SERARATOR(default:'--')>: only used when one of (-A, -B or -C) is used
    -b, --byte-offset: print the byte offset before outputs within the input file
    --column | --no-column: show column numbers or not
    --heading(default to terminal) | --no-heading: prints the file path above all matched lines or as a prefix for each matched line
    --json: printing results in a JSON lines format which with types: begin, end, match, context
    -M, --max-columns <NUM> | --max-columns-preview: Don’t print lines longer than NUM. 0 to disable
    -n, --line-number(default in terminal) | -N, --no-line-number: show line numbers or not
    -I, --no-filename | -H, --with-filename(default):
    -0, --null:  Whenever a file path is printed, follow it with a NUL byte.
    --null-data: Use NUL as a line terminator instead of the default of \n.
    --vimgrep: Show file path, line number, column number and match in one line.
[Files options]:
    --files | -l, --files-with-matchs | --files-without-match
    -m, --max-count <NUM>: Limit the number of matching lines per file.
    -o, --only-matching: Print only the matched parts of a matching line.
    -p, --pretty(= --color always --heading --line-number): useful when pipe to pager
    -q, --quiet: Do not print anything to stdout.
    -r, --replace <REPLACEMENT_TEXT>: Replace match in results with REPLACEMENT_TEXT. Capture group supported.
[Output options]:
    --path-separator <SEPARATOR>: Limited to a byte, defaults to OS's spearator.
    --sort <none(default)|path|modified|accessed|created> | --sortr <&@>: Enable results in ascending or descending order.
[Statistic options]:
    -c, --count:        shows the number of lines that match patterns for each input file
    --count-matches:    shows the number of count of match patterns for each input file
    --include-zero:     shows the number even if there were no matches
    -v, --invert-match: show lines that do not match
    --stats:            Print number of {matched lines, files with matches, files searched} and the time taken.
[Filter options]:
    --binary | --no-binary(default): search binary files or not
    -a, --text | --no-text: search binary files as if they were text, override --binary option
    --no-hidden(default) | -., --hidden:    skip hidden files and directories or not
    -L, --follow | --no-follow(default): follow symbolic links while traversing directories or not
    -g, --glob <GLOB>: include or exclude paths for searching. Globing rules match .gitignore globs
    --glob-case-insensitive | --iglob <GLOB>:
    --ignore-file <PATH>+: Specifies a path to one or more .gitignore format rules files.
    --ignore-file-case-insensitive: more useful on case insensitive file systems
    --max-depth <NUM>: Limit the depth of directory traversal to.
    --max-filesize NUM+SUFFIX?: Ignore files larger than NUM in size[|K|M|G].
    -z, --search-zip | --no-search-zip(default): Search in gzip, bzip2, xz, LZ4, LZMA, Brotli and Zstd files or not.
    -[T|t], --type[-not] <TYPE>+ | --type-list | --type-add TYPE_SPEC | --type-clear TYPE: [Only|Not] search TYPE files.
    -u{1,3}, --unrestricted: 1. won't respect ignore files, 2. search hidden files, 3. search binary files
[Config options]:
    --no-config: Never read config files respect env varable 'RIPGREP_CONFIG_PATH'.
    --no-ignore(= --no-ignore-{dot&exclude&global&parent&csv} | --ignore(= --ignore-{&@}):
    --one-file-system | --no-one-file-system(default): not cross file system when directory traversing
[Other options]:
    --pre <CMD> [--pre-glob <GLOB>] | --no-pre: For each input FILE, search the stdout of 'CMD FILE' rather than the contents of FILE.
"
kCmdTldrDesc := "tealdeer -> man: short version instead man"

cmd-common:
    # common commands alternatives
    brew install bat btop fd fzf ripgrep tealdeer
    # network client commands
    brew install grsync rsync wget yt-dlp

dev-tool-git:
    ### enhance git first
    brew install git git-lfs
    #   Update global git config
    git lfs install
    #   Update system git config
    git lfs install --system

    #   cmd: Archive a repository with all its submodules.
    brew install git-archive-all onefetch
    #   app: git GUI
    # brew install --cask smartgit
    brew install --cask fork

dev-tool-rust:
    brew install rustup
    rustup default stable

dev-app:
    ### design tools
    #brew install --cask drawio freeplane

    ### coding tools
    #   cmd: code searching tool, usage: ag
    #       doc: https://github.com/ggreer/the_silver_searcher/wiki/Advanced-Usage
    # brew install the_silver_searcher
    #   app: for file compare
    #       reset tral version: rm "/Users/$(whoami)/Library/Application Support/Beyond Compare/registry.dat"
    brew install --cask beyond-compare
    #   cmd: count source lines
    brew install tokei

    ### C++ dev tools
    brew install cmake

    ### java dev tools
    # install java via android studio

    ### java/android crack tools
    # brew install apktool dex2jar jd-gui

    ### javascript dev tools
    brew install --cask visual-studio-code

dev-net:
    brew install iperf3 iproute2mac
    brew install --cask sloth
    brew install --cask charles wireshark
    brew install --cask postman

extra-app-applite:
    #   app: homebrew GUI
    # brew install cakebrew
    #   app: homebrew GUI for cask apps
    brew install --cask --no-quarantine applite

net-app:
    brew install --cask cyberduck

sys-app-install-hammerspoon:
    brew install --cask --no-quarantine hammerspoon
    defaults write org.hammerspoon.Hammerspoon MJConfigFile "${XDG_CONFIG_HOME:-$HOME/.config}"/hammerspoon/init.lua

sys-app-raycast:
    ### spotlight replacement
    brew install --cask raycast

sys-finder-extensions:
    ### Finder extensions:
    #   add button in toolbar to open termial
    # brew install go2shell
    #   content menu: show media info
    brew install --cask mediainfo


sys-ime-openvanilla:
    brew install openvanilla
    mkdir -p "${HOME}/Library/Application Support/OpenVanilla/UserData/TableBased/erbi.cin"
    ln -s "./backups/erbi/OpenVanilla/erbi.cin" "${HOME}/Library/Application Support/OpenVanilla/UserData/TableBased/erbi.cin"

sys-screensaver-aerial:
    # brew install aerial

sys-tray-extensions:
    ### service with tray icons:
    #   tray: easily block os to sleep
    brew install --cask caffeine
    #   tray: clipboard manager all replaced by raycast
    # brew install --cask --no-quarantine copyq
    # brew install --cask maccy
    #   tray: auto-tools program with lua. for key-shortcuts configure, config under ~/.local/hammerspoon/
    brew install --cask hammerspoon
    #   tray: enhance date tray icon's feature
    # brew install --cask itsycal
    #   [not maintainment] tray: dozer, add hide icon feature
    # brew install --cask dozer
    #   tray: easydict, translate util
    brew install --cask easydict
    #   tray: dropshelf, drag drop anything
    brew install --cask dropshelf
    #   tray: nearby, share items with nearby android
    #       https://github.com/grishka/NearDrop
    brew install --cask grishka/grishka/neardrop
    #   tray: system monitor util
    brew install --cask stats

sys-ql:
    # mac app info viewer, include ql plugin
    brew install --cask apparency suspicious-package

    # https://github.com/sindresorhus/quick-look-plugins
    # If you run into issues with macOS not letting you run the plugin because it's not signed by a verified developer you can follow these steps:
    # run xattr -cr ~/Library/QuickLook/<QLPlugName>.qlgenerator (sudo if needed)
    # run qlmanage -r
    # run qlmanage -r cache
    # Restart Finder by...
    # Restarting your computer
    # or holding down the option key and right click on Finder’s dock icon, then select “Relaunch” from the menu
    #
    # Plugins:
    #   - provisionql:      ipa & provision
    #   - qladdict:         srt file
    #   - qldds:
    #   - qlmarkdown:       markdown
    #   - qlgradle:
    #   - qlprettypatch:
    #   - qlvideo:          unsupported video format 
    #   - quicklook-json:   json
    #   - quicklook-pat:    view Adobe Photoshop pattern files
    #   - quicklookapk:
    #   - quicklookase:     quicklook for ASE files (Adobe Swatch Exchange)
    #   - receiptquicklook: inspect App Store receipts
    #   - syntax-highlight: code preview
    #
    # no used:
    #   - quicklook-csv:    osx supported
    #   - webpquicklook:    osx supported
    #   - qlstephen:        osx supported

    brew install --cask --no-quarantine qladdict qlcolorcode qlprettypatch qlvideo quicklook-json syntax-highlight

    xattr -cr ~/Library/QuickLook/QLAddict.qlgenerator
    xattr -cr ~/Library/QuickLook/qlprettypatch.qlgenerator
    qlmanage -r cache
    open /Applications/QuickLook\ Video.app

sys-tweak:
    ### apps for system enhance:
    #   app: tweak keyboard functions. eg: map right CMD to CMD+OPT+CTRL+SHIFT
    brew install --cask karabiner-elements
    #   app: private passwords database
    brew install --cask keepassxc
    #   app: key-shortcuts macro maker, replaced by hammerspoon
    # brew install --cask keyboard-maestro
    #   app: vim doc chinese version: https://sourceforge.net/projects/vimcdoc/
    brew install --cask macvim
    #   app: terminal
    # brew install --cask warp
    brew install --cask kitty

app-common:
    brew install --cask aria2gui gimp google-chrome icefloor

    ### devices apps
    #   cmd: connect android device via usb for device control
    brew install scrcpy
    #   app: (most case scrcpy instead)connect android device via wifi and usb for device control
    # brew install soduto
    #   tray: disable intel cpu's boost feature for save power
    #       usage: sudo /Applications/Turbo\ Boost\ Switcher.app/Contents/MacOS/Turbo\ Boost\ Switcher
    # (unsupport apple silicon)brew install turbo-boost-switcher

    ### graphic apps
    # app: vector graphics editor
    brew install --cask inkscape

    ### media apps
    brew install --cask losslesscut invisor-lite
    brew install --cask iina
    # brew install --cask 5kplayer
    # brew install --cask macx-youtube-downloader

    ### game tools
    # (unsupport apple silicon) brew install --cask openemu
    brew install --cask xemu
    # (have not used)brew install --cask aethersx2
    # (have not used, Nintendo 3DS emulator) brew install --cask citra

    ### VM ware
    #   app: vm ware, replaced by VMWare
    # brew install --cask rdm virtualbox virtualbox-extension-pac
    # brew install wine-stable
    brew install --cask vmware-fusion

app-db:
    # sqlite client app
    brew install --cask --no-quarantine db-browser-for-sqlite

    # sql server and client app
    # - default db named `postgresql` created under     /opt/homebrew/var/postgresql@16
    brew install postgresql@16
    brew install --cask --no-quarantine pgadmin4
    brew services start postgresql@16

local-setup:
    #!/usr/bin/env bash
    set -euxo pipefail
    _LOCAL="${HOME}/.local"
    if [ ! -e "$_LOCAL" ]; then
        mkdir "$_LOCAL}"
    fi
    if [ -d "$_LOCAL" ]; then
        cd "$_LOCAL"
        if [ ! -e ".git" ]; then
            git init
        fi
        _GITIGNORE=.gitignore
        if [ ! -e "$_GITIGNORE" ]; then
            echo "/*" > .gitignore
            git add -f "$_GITIGNORE"
            git commit -m "[update] $_GITIGNORE"
        fi
        _GITMODULES=.gitmodules
        if [ ! -e "$_GITMODULES" ]; then
            touch "$_GITMODULES"
            git add -f "$_GITMODULES"
            git commit -m "[update] $_GITMODULES"
        fi
        _JUSTFILE=justfile
        if [[ ! -e "$_JUSTFILE" ]]; then
            ln -s "{{kPWD}}/justfile.local" "justfile"
        fi
    else
        echo "Invalid directory: $_LOCAL"
    fi

serv-pm2-setup:
    pm2 start "${HOME}/.local/bin/autoadb" --name autoadb_scrcpy -- "${HOME}/.config/backups/raycast/scirpt-commands/pixel4scrcpy.sh" "{}"
    pm2 start "/opt/homebrew/bin/openresty" --name serv_openresty_sites -- -c "${HOME}/Sites/nginx.conf" -e "${HOME}/Sites/_nginx/error.log" -g "daemon off;" -p "${HOME}/Sites/_nginx"

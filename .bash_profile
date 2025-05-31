export EDITOR=vim
export LESS='-FKRXi -j 3'
export MANWIDTH=80
export NO_COLOR=true
export NPM_CONFIG_PREFIX=~/.npm
export PYTHONUSERBASE=~/.pip
export RIPGREP_CONFIG_PATH=~/.ripgreprc
export SDCV_PAGER=less

[[ $PATH == ~/* || $PATH == *:$HOME/* ]] || export PATH=~/.local/bin:$PATH:$NPM_CONFIG_PREFIX/bin:$PYTHONUSERBASE/bin

path=~/.bash_profile_local
[[ ! -f $path ]] || . "$path"
unset path

. ~/.bashrc

[[ $TERM != linux || $XDG_VTNR != 1 ]] || exec labwc &> "$XDG_RUNTIME_DIR"/labwc.log

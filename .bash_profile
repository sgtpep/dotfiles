export EDITOR=vim
export LESS='-FRXi -j 3'
export MANWIDTH=80
export NO_COLOR=true
export NPM_CONFIG_PREFIX=~/.npm
export PYTHONUSERBASE=~/.pip
export RIPGREP_CONFIG_PATH=~/.ripgreprc
export SDCV_PAGER=less

[[ $PATH == ~/* ]] || export PATH=~/.local/bin:$PATH:$NPM_CONFIG_PREFIX/bin:$PYTHONUSERBASE/bin

if [[ ! -v TMUX ]]; then
  command=$(printf '%d;rgb:ff/ff/ff;' {1..15})
  printf "\e]4;0;rgb:00/00/00;$command\a"
fi

path=~/.bash_profile_local
[[ ! -f $path ]] || . "$path"
unset path

. ~/.bashrc

export EDITOR=vim
export LESS='-FRXi -j 3'
export MANWIDTH=80
export NO_COLOR=true
export NPM_CONFIG_PREFIX=~/.npm
export PYTHONUSERBASE=~/.pip
export RIPGREP_CONFIG_PATH=~/.ripgreprc
export SDCV_PAGER=less

[[ $PATH == ~/* ]] || export PATH=~/.local/bin:$PATH:$NPM_CONFIG_PREFIX/bin:$PYTHONUSERBASE/bin

for number in {0..15}; do
  printf "\e]4;$number;${color-Black}\a"
  color=White
done
unset color number

path=~/.bash_profile_local
[[ ! -f $path ]] || . "$path"
unset path

. ~/.bashrc

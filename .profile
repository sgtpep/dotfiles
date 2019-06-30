export EDITOR=vim
export GEM_HOME=~/.gem
export LESS='-FRX -j 3'
export MANWIDTH=80
export NODE_PATH=~/.npm/lib/node_modules
export PYTHONUSERBASE=~/.pip
[ "${PATH/~}" != "$PATH" ] || export PATH=$GEM_HOME/bin:${NODE_PATH%/*/*}/bin:$PYTHONUSERBASE/bin:~/.local/bin:$PATH

if [ "$TERM" = linux ] && [ "$XDG_VTNR" = 1 ]; then
  exec xinit -- vt"$XDG_VTNR" >> /tmp/xinit.log 2>&1
elif [ "${BASH-}" ]; then
  . ~/.bashrc
fi

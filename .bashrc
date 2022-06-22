[[ $- == *i* ]] || return 0

. ~/.bash_aliases
. ~/.bash_bindings

((COLUMNS > 80)) || unset MANWIDTH
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM=auto
HISTCONTROL=ignoreboth
HISTFILESIZE=-1
HISTIGNORE='git stash drop*:y'
HISTSIZE=10000

PROMPT_COMMAND='
: "$?"
[[ $_ == 0 ]] || echo -e "\e[4mExit status: $_\e[m" >&2
history -a
'

PS1=$'$(
path=$PWD
[[ ! -h $PWD ]] || path=$(readlink "$PWD")
while [[ $path == ~ && ! -d $path/.git ]]; do
  path=${path%/*}
done
[[ $path != ~ ]] || exit 0

name=__git_ps1
type -t "$name" > /dev/null || . /usr/lib/git-core/git-sh-prompt
"$name" \'(%s) \'
)\W $ '

shopt -s autocd
shopt -s histappend
stty -ixon

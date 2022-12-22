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
  [[ -d $PWD/.git && $PWD != ~ ]] || exit 0

  command=__git_ps1
  type -t "$command" > /dev/null || . /usr/share/git-core/contrib/completion/git-prompt.sh
  "$command" \'(%s) \'
)\W $ '

shopt -s autocd
shopt -s histappend
stty -ixon

# Lima BEGIN

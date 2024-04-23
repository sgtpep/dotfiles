[[ $- == *i* ]] || return 0

. ~/.bash_aliases
. ~/.bash_bindings

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM=auto

HISTCONTROL=ignoreboth
HISTFILESIZE=-1
HISTIGNORE='git restore*:git stash drop*:y'
HISTSIZE=10000

((COLUMNS > 80)) || unset MANWIDTH

PROMPT_COMMAND='
: "$?"
[[ $_ == 0 ]] || echo -e "\e[4mExit status: $_\e[m" >&2

history -a
'

PS1=$'$(
  path=$PWD/.git
  [[ -d $path && ! -f $path/.slow && $PWD != ~ ]] || exit 0

  command=__git_ps1
  if ! type -t "$command" > /dev/null; then
    for path in {/usr/share/git-core/contrib/completion,/opt/homebrew/etc/bash_completion.d,/Library/Developer/CommandLineTools/usr/share/git-core}/git-prompt.sh; do
      [[ -f $path ]] || continue

      . "$path"
      break
    done
  fi
  "$command" \'(%s) \'
)\W $ '

shopt -s autocd
shopt -s histappend

stty -ixon

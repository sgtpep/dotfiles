alias copy='xsel -b'
alias cp='cp -i'
alias dd='dd bs=4M oflag=sync status=progress'
alias df='df -h'
alias du='du -h'
alias json='python -m json.tool'
alias ls='ls -h'
alias mv='mv -i'
alias rm='rm -I'
alias serve='python -m http.server'
alias sudo='sudo '
alias unmount='gio mount -e /run/media/"$USER"/*'
alias watch='watch '

function less {
  [[ -t 0 ]] || set -- "$@" -O /dev/null
  command less "$@"
}

function pass {
  [[ $# != 1 || $1 == -* ]] || set -- -c "$@"
  command pass "$@"
}

function pwdhash {
  command pwdhash "$@" | xsel -b
}

function rg {
  command rg -p --color=always "$@" |& less -R
  return "${PIPESTATUS[0]}"
}

alias copy='wl-copy'
alias cp='cp -i'
alias dd='dd bs=4M oflag=sync status=progress'
alias df='df -h'
alias diff='diff -u'
alias du='du -h'
alias grep='grep --line-buffered'
alias json='python -m json.tool'
alias ls='ls -h'
alias mv='mv -i'
alias open='gio open'
alias rm='rm -I'
alias serve='python -m http.server'
alias sshuttle='sshuttle -r personal --dns 0/0'
alias sudo='sudo '
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
  command pwdhash "$@" | copy
}

function rg {
  command rg -p --color=always "$@" |& less -R
  return "${PIPESTATUS[0]}"
}

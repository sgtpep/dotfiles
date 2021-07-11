#!/bin/bash
set -eu

while :; do
  output=$(xrandr --current 2> /dev/null || :)
  if [[ ${previous_output-} && $previous_output != $output ]]; then
    sleep 1
    xrandr &> /dev/null
    break
  fi
  previous_output=$output
  sleep 0.5
done &

setxkbmap us,ru
xrdb ~/.Xresources

exec awesome

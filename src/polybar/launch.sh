#!/usr/bin/env bash
# Lanza polybar en todos los monitores conectados (evita duplicados en reload).
set -u

pkill -x polybar 2>/dev/null || true
while pgrep -x polybar >/dev/null 2>&1; do
  sleep 0.1
done

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/polybar.log"
mkdir -p -- "$(dirname -- "$LOG")"

for monitor in $(xrandr --query 2>/dev/null | awk '/ connected/{print $1}'); do
  MONITOR="$monitor" polybar main >>"$LOG" 2>&1 &
done

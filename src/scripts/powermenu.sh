#!/usr/bin/env bash
# Menú de energía con rofi.
set -euo pipefail

options=("Bloquear" "Cerrar sesión" "Reiniciar" "Apagar")

choice="$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -p 'power')"
[[ -n "$choice" ]] || exit 0

case "$choice" in
  "Bloquear")      "$HOME/.local/bin/lock.sh" ;;
  "Cerrar sesión") i3-msg exit ;;
  "Reiniciar")     systemctl reboot ;;
  "Apagar")        systemctl poweroff ;;
  *)               exit 1 ;;
esac

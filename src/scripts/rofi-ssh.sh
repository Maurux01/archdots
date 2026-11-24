#!/usr/bin/env bash
# Selecciona un host de ~/.ssh/config con rofi y abre ssh en kitty.
set -euo pipefail

ssh_config="${1:-$HOME/.ssh/config}"

if [[ ! -f "$ssh_config" ]]; then
  echo "No existe $ssh_config" >&2
  exit 1
fi

mapfile -t hosts < <(awk '$1 == "Host" && $2 != "*" {print $2}' "$ssh_config" | sort -u)
((${#hosts[@]})) || { echo "No hay hosts en $ssh_config" >&2; exit 1; }

host="$(printf '%s\n' "${hosts[@]}" | rofi -dmenu -i -p 'ssh')"
[[ -n "$host" ]] || exit 0

kitty -e ssh "$host"

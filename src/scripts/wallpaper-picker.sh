#!/usr/bin/env bash
# Selecciona un wallpaper con rofi y lo aplica con feh.
set -euo pipefail

wallpaper_dir="${XDG_CONFIG_HOME:-$HOME/.config}/wallpapers"

[[ -d "$wallpaper_dir" ]] || { echo "No existe $wallpaper_dir" >&2; exit 1; }

mapfile -t wallpapers < <(
  for file in "$wallpaper_dir"/*; do
    [[ -f "$file" ]] || continue
    case "$file" in
      *.png|*.jpg|*.jpeg|*.webp) basename -- "$file" ;;
    esac
  done | sort
)

((${#wallpapers[@]})) || { echo "No hay wallpapers en $wallpaper_dir" >&2; exit 1; }

choice="$(printf '%s\n' "${wallpapers[@]}" | rofi -dmenu -i -p 'wallpaper')"
[[ -n "$choice" ]] || exit 0

feh --bg-fill "$wallpaper_dir/$choice"
notify-send "Wallpaper" "$choice" 2>/dev/null || true

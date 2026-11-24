#!/usr/bin/env bash
# Calculadora minimalista: rofi + bc, copia el resultado al portapapeles.
set -euo pipefail

for dependency in rofi bc xclip; do
  command -v "$dependency" >/dev/null 2>&1 || { echo "Falta: $dependency" >&2; exit 1; }
done

expression="$(rofi -dmenu -i -p '= ')"
[[ -n "$expression" ]] || exit 0

# Solo números, operadores y paréntesis: evita pasar texto arbitrario a bc.
if [[ ! "$expression" =~ ^[0-9eE.+*/%()\ -]+$ ]]; then
  notify-send "Calc" "Expresión no válida" 2>/dev/null || true
  exit 1
fi

result="$(bc -l <<< "$expression" 2>/dev/null)" || {
  notify-send "Calc" "No se pudo calcular" 2>/dev/null || true
  exit 1
}

printf '%s\n' "$result" | xclip -selection clipboard
notify-send "Calc" "$expression = $result" 2>/dev/null || true
printf '%s\n' "$result"

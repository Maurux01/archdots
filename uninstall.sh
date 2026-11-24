#!/usr/bin/env bash
#
# archdots - desinstalador
#
# Restaura los archivos que existían antes de instalar (si los había) y
# elimina los que fueron creados por install.sh. Nada se borra sin confirmación
# salvo que se use --yes.
#
set -Eeuo pipefail

TARGET_HOME="${HOME}"
HOME_MODE=0
DRY_RUN=0
ASSUME_YES=0
PURGE=0

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=''; C_BOLD=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''
fi

info() { printf '%s[*]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%s[x]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
${C_BOLD}archdots${C_RESET} - desinstalador

Uso:
  ./uninstall.sh [opciones]

Opciones:
  -h, --help       Muestra esta ayuda
  -n, --dry-run    Muestra qué haría sin tocar nada
  -y, --yes        No pide confirmación
      --purge      Borra también los backups (por defecto se conservan)
      --home DIR   Usa DIR como \$HOME (útil para pruebas)
EOF
}

while (($#)); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    --purge) PURGE=1 ;;
    --home) shift; (($#)) || die "--home necesita una ruta"; TARGET_HOME="$1"; HOME_MODE=1 ;;
    --) shift; break ;;
    *) die "Opción desconocida: $1 (usa --help)" ;;
  esac
  shift
done

[[ -d "$TARGET_HOME" ]] || die "El directorio de destino no existe: $TARGET_HOME"
TARGET_HOME="$(cd -- "$TARGET_HOME" && pwd -P)"

# El mismo aislamiento que install.sh cuando se usa --home.
if (( HOME_MODE )); then
  DATA_HOME="$TARGET_HOME/.local/share"
else
  DATA_HOME="${XDG_DATA_HOME:-$TARGET_HOME/.local/share}"
fi
STATE_DIR="$DATA_HOME/archdots"
MANIFEST="$STATE_DIR/manifest"
DIRS_FILE="$STATE_DIR/dirs"

[[ -f "$MANIFEST" ]] || die "No hay registro de instalación en $MANIFEST (¿ya se desinstaló?)"

mapfile -t ENTRIES < "$MANIFEST"
((${#ENTRIES[@]})) || die "El registro de instalación está vacío"

printf '%s\n' "Se van a procesar ${#ENTRIES[@]} archivos:"
for entry in "${ENTRIES[@]}"; do
  IFS=$'\t' read -r dest backup <<< "$entry"
  if [[ -n "$backup" && -e "$backup" ]]; then
    printf '  restaurar  %s  <-  %s\n' "${dest/#$TARGET_HOME/\~}" "${backup/#$TARGET_HOME/\~}"
  else
    printf '  eliminar   %s\n' "${dest/#$TARGET_HOME/\~}"
  fi
done

if [[ $ASSUME_YES -ne 1 ]]; then
  [[ -t 0 ]] || die "Sin terminal interactiva; usa --yes para confirmar"
  read -r -p "¿Continuar? [s/N] " reply || die "Cancelado"
  [[ "$reply" =~ ^[sSyY] ]] || die "Cancelado"
fi

(( DRY_RUN )) && { ok "Simulación completada. No se tocó nada."; exit 0; }

restored=0
removed=0
for entry in "${ENTRIES[@]}"; do
  IFS=$'\t' read -r dest backup <<< "$entry"

  if [[ -n "$backup" && -e "$backup" ]]; then
    mkdir -p -- "$(dirname -- "$dest")"
    mv -- "$backup" "$dest"
    rmdir -- "$(dirname -- "$backup")" 2>/dev/null || true
    ((restored+=1))
  elif [[ -e "$dest" || -L "$dest" ]]; then
    rm -f -- "$dest"
    ((removed+=1))
  fi
done

# Elimina los directorios creados por el instalador, de más profundo a más corto.
if [[ -f "$DIRS_FILE" ]]; then
  mapfile -t CREATED_DIRS < "$DIRS_FILE"
  for ((i=${#CREATED_DIRS[@]}-1; i>=0; i--)); do
    rmdir -- "${CREATED_DIRS[$i]}" 2>/dev/null || true
  done
fi

# Limpia los subdirectorios vacíos que quedan al restaurar cada backup.
if [[ -d "$STATE_DIR/backups" ]]; then
  find "$STATE_DIR/backups" -mindepth 1 -depth -type d -empty -delete 2>/dev/null || true
fi

rm -f -- "$MANIFEST" "$DIRS_FILE" "$STATE_DIR/last-install" \
         "$STATE_DIR/uninstall.sh" "$STATE_DIR/README.md" \
         "$STATE_DIR/aur.txt"
rm -rf -- "$STATE_DIR/manifests"

if (( PURGE )); then
  rm -rf -- "$STATE_DIR"
  info "Se borraron también los backups"
else
  info "Los backups se conservan en ${STATE_DIR}/backups"
fi

if command -v i3-msg >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
  i3-msg reload >/dev/null 2>&1 || true
fi

ok "Desinstalación completada: ${restored} restaurados, ${removed} eliminados."

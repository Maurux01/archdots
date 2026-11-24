#!/usr/bin/env bash
#
# archdots - instalador
#
# Funciona de dos formas:
#   1) Dentro del repo clonado:  ./install.sh [opciones]
#   2) Directo por curl:         curl -fsSL https://raw.githubusercontent.com/Maurux01/archdots/main/install.sh | bash
#
# No borra nada sin antes guardar una copia de seguridad.
#
set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Configuración
# -----------------------------------------------------------------------------
REPO="${ARCHDOTS_REPO:-Maurux01/archdots}"
REF="${ARCHDOTS_REF:-main}"

TARGET_HOME="${HOME}"
HOME_MODE=0
DEPS="ask"          # ask | yes | no
ICONS=1
DRY_RUN=0
ASSUME_YES=0
TMP_DIR=""
REMOTE=0
AUTO_SKIPPED_DEPS=0

# -----------------------------------------------------------------------------
# Utilidades
# -----------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=''; C_BOLD=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''
fi

info()  { printf '%s[*]%s %s\n'    "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf '%s[+]%s %s\n'    "$C_GREEN"  "$C_RESET" "$*"; }
warn()  { printf '%s[!]%s %s\n'    "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()   { printf '%s[x]%s %s\n'    "$C_RED"    "$C_RESET" "$*" >&2; exit 1; }

confirm() {
  local question="$1" reply
  [[ $ASSUME_YES -eq 1 ]] && return 0
  [[ -t 0 ]] || return 1
  read -r -p "${question} [s/N] " reply || return 1
  [[ "$reply" =~ ^[sSyY] ]]
}

usage() {
  cat <<EOF
${C_BOLD}archdots${C_RESET} - instalador de dotfiles i3 para Arch Linux

Uso:
  ./install.sh [opciones]
  curl -fsSL https://raw.githubusercontent.com/${REPO}/${REF}/install.sh | bash -s -- [opciones]

Opciones:
  -h, --help        Muestra esta ayuda
  -n, --dry-run     Simula la instalación sin escribir nada
  -y, --yes         No pide confirmación (acepta la instalación de paquetes)
      --deps        Instala los paquetes esenciales con pacman
      --no-deps     No instala paquetes (ni pregunta)
      --no-icons    No aplica iconos/carpetas Catppuccin (Papirus)
      --home DIR    Instala en DIR en lugar de \$HOME (útil para pruebas)
      --repo USER/REPO   Repositorio del que descargar (por defecto ${REPO})
      --ref REF     Rama o tag a descargar (por defecto ${REF})

Variables de entorno:
  ARCHDOTS_REPO, ARCHDOTS_REF  Equivalen a --repo y --ref
  ARCHDOTS_ARCHIVE_URL         URL alternativa del .tar.gz (para testing/forks)
  XDG_DATA_HOME                Dónde se guarda el registro de instalación

Ejemplos:
  ./install.sh --deps
  ./install.sh --no-deps --dry-run
  curl -fsSL https://raw.githubusercontent.com/${REPO}/${REF}/install.sh | bash -s -- --deps
EOF
}

while (($#)); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    --deps) DEPS="yes" ;;
    --no-deps) DEPS="no" ;;
    --no-icons) ICONS=0 ;;
    --home) shift; (($#)) || die "--home necesita una ruta"; TARGET_HOME="$1"; HOME_MODE=1 ;;
    --repo) shift; (($#)) || die "--repo necesita USER/REPO"; REPO="$1" ;;
    --ref) shift; (($#)) || die "--ref necesita una rama o tag"; REF="$1" ;;
    --) shift; break ;;
    *) die "Opción desconocida: $1 (usa --help)" ;;
  esac
  shift
done

# /archive/<ref>.tar.gz funciona tanto con ramas como con tags.
ARCHIVE_URL="${ARCHDOTS_ARCHIVE_URL:-https://github.com/${REPO}/archive/${REF}.tar.gz}"

# -----------------------------------------------------------------------------
# Comprobaciones y obtención de los archivos
# -----------------------------------------------------------------------------
[[ -d "$TARGET_HOME" ]] || die "El directorio de destino no existe: $TARGET_HOME"
TARGET_HOME="$(cd -- "$TARGET_HOME" && pwd -P)"

TMP_DIR="$(mktemp -d)"
cleanup() { [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf -- "$TMP_DIR"; }
trap cleanup EXIT

MANIFEST_TMP="$TMP_DIR/manifest"
DIRS_TMP="$TMP_DIR/dirs"
: > "$MANIFEST_TMP"
: > "$DIRS_TMP"

SOURCE_PATH="${BASH_SOURCE[0]-}"
if [[ -z "$SOURCE_PATH" || "$SOURCE_PATH" == "bash" || "$SOURCE_PATH" == "-" || \
      "$SOURCE_PATH" == "/dev/stdin" || ! -f "$SOURCE_PATH" ]]; then
  REMOTE=1
fi

if (( REMOTE )); then
  command -v curl >/dev/null || die "curl no está instalado; necesítalo para la instalación por pipe"
  command -v tar  >/dev/null || die "tar no está instalado; necesítalo para la instalación por pipe"
  info "Descargando archdots@${REF}..."
  curl -fsSL --retry 3 "$ARCHIVE_URL" -o "$TMP_DIR/archdots.tar.gz" \
    || die "No se pudo descargar $ARCHIVE_URL (¿repo privado o rama incorrecta?)"
  mkdir -p "$TMP_DIR/unpack"
  tar -xzf "$TMP_DIR/archdots.tar.gz" -C "$TMP_DIR/unpack" \
    || die "No se pudo descomprimir el archivo descargado"
  SRC_FOUND="$(find "$TMP_DIR/unpack" -mindepth 1 -maxdepth 3 -type d -name src -print -quit)"
  [[ -n "$SRC_FOUND" ]] || die "No encontré src/ en el paquete descargado"
  SRC_DIR="$SRC_FOUND"
  REPO_ROOT="$(dirname -- "$SRC_DIR")"
else
  SCRIPT_DIR="$(cd -- "$(dirname -- "$SOURCE_PATH")" && pwd -P)"
  REPO_ROOT="$SCRIPT_DIR"
  SRC_DIR="$REPO_ROOT/src"
  [[ -d "$SRC_DIR" ]] || die "No encontré $SRC_DIR (ejecuta install.sh desde la raíz del repo)"
  info "Instalando desde $REPO_ROOT"
fi

PKGS_FILE="$REPO_ROOT/packages/essential.txt"
[[ -f "$PKGS_FILE" ]] || warn "No encontré packages/essential.txt; se omitirá la instalación de paquetes"

# -----------------------------------------------------------------------------
# Dependencias (opcional)
# -----------------------------------------------------------------------------
install_dependencies() {
  if [[ ! -f "$PKGS_FILE" ]]; then
    return 0
  fi
  if [[ "$DEPS" == "ask" && $ASSUME_YES -eq 0 && ! -t 0 ]]; then
    warn "stdin no es interactivo: no se instalarán paquetes. Usa --deps o --no-deps explícitamente."
    DEPS="no"
    AUTO_SKIPPED_DEPS=1
  fi
  if [[ "$DEPS" == "no" ]]; then
    if (( AUTO_SKIPPED_DEPS )); then
      info "Paquetes: omitidos (stdin no interactivo)"
    else
      info "Paquetes: omitidos (--no-deps)"
    fi
    return 0
  fi
  if ! command -v pacman >/dev/null 2>&1; then
    warn "No se detectó pacman. Instala las dependencias manualmente (ver README.md)."
    return 0
  fi
  if [[ "$DEPS" != "yes" ]]; then
    if ! confirm "¿Instalar los paquetes esenciales con pacman?"; then
      info "Paquetes: omitidos"
      return 0
    fi
  fi

  local -a packages=()
  mapfile -t packages < <(grep -Ev '^[[:space:]]*(#|$)' "$PKGS_FILE" | awk '{print $1}' || true)
  ((${#packages[@]})) || { warn "La lista de paquetes está vacía"; return 0; }

  if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=()
  elif command -v sudo >/dev/null 2>&1; then
    SUDO=(sudo)
  else
    warn "No hay sudo; instala los paquetes manualmente: sudo pacman -S --needed ${packages[*]}"
    return 0
  fi

  info "Instalando paquetes: ${packages[*]}"
  if (( DRY_RUN )); then
    info "[simulación] ${SUDO[@]} pacman -S --needed ${packages[*]}"
  else
    "${SUDO[@]}" pacman -S --needed --noconfirm "${packages[@]}" \
      || warn "pacman terminó con errores; continúo con la instalación de dotfiles"
  fi
}

# -----------------------------------------------------------------------------
# Instalación de archivos
# -----------------------------------------------------------------------------
# Con --home aislamos también el estado; sin él respetamos XDG_DATA_HOME.
if (( HOME_MODE )); then
  DATA_HOME="$TARGET_HOME/.local/share"
else
  DATA_HOME="${XDG_DATA_HOME:-$TARGET_HOME/.local/share}"
fi
STATE_DIR="$DATA_HOME/archdots"
MANIFEST="$STATE_DIR/manifest"
DIRS_FILE="$STATE_DIR/dirs"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$STATE_DIR/backups/$STAMP"

ensure_dir() {
  local dir="$1"
  [[ -d "$dir" ]] && return 0
  info "crear directorio: ${dir/#$TARGET_HOME/\~}"
  (( DRY_RUN )) || mkdir -p -- "$dir"
  printf '%s\n' "$dir" >> "$DIRS_TMP"
}

# install_file ORIGEN DESTINO [executable]
install_file() {
  local src="$1" dest="$2" mode="${3:-}" backup=""
  [[ -f "$src" ]] || die "Falta el archivo de origen: $src"
  ensure_dir "$(dirname -- "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup="$BACKUP_ROOT/${dest#"$TARGET_HOME"/}"
    info "respaldar: ${dest/#$TARGET_HOME/\~} -> ${backup/#$TARGET_HOME/\~}"
    if (( ! DRY_RUN )); then
      mkdir -p -- "$(dirname -- "$backup")"
      mv -- "$dest" "$backup"
    fi
  fi

  info "copiar: $(basename -- "$src") -> ${dest/#$TARGET_HOME/\~}"
  if (( ! DRY_RUN )); then
    cp -- "$src" "$dest"
    if [[ "$mode" == "exec" ]]; then
      chmod 755 -- "$dest"
    else
      chmod 644 -- "$dest"
    fi
  fi
  printf '%s\t%s\n' "$dest" "$backup" >> "$MANIFEST_TMP"
}

info "Destino: $TARGET_HOME"
install_dependencies

ensure_dir "$STATE_DIR"

# Configuraciones
install_file "$SRC_DIR/i3/config"                 "$TARGET_HOME/.config/i3/config"
install_file "$SRC_DIR/kitty/kitty.conf"          "$TARGET_HOME/.config/kitty/kitty.conf"
install_file "$SRC_DIR/polybar/config.ini"        "$TARGET_HOME/.config/polybar/config.ini"
install_file "$SRC_DIR/polybar/launch.sh"         "$TARGET_HOME/.config/polybar/launch.sh" exec
install_file "$SRC_DIR/rofi/config.rasi"          "$TARGET_HOME/.config/rofi/config.rasi"
install_file "$SRC_DIR/dunst/dunstrc"             "$TARGET_HOME/.config/dunst/dunstrc"
install_file "$SRC_DIR/gtk-3.0/settings.ini"      "$TARGET_HOME/.config/gtk-3.0/settings.ini"
install_file "$SRC_DIR/gtk-4.0/settings.ini"      "$TARGET_HOME/.config/gtk-4.0/settings.ini"
install_file "$SRC_DIR/fontconfig/fonts.conf"    "$TARGET_HOME/.config/fontconfig/fonts.conf"
install_file "$SRC_DIR/xinitrc"                   "$TARGET_HOME/.xinitrc"

# Scripts
for script in "$SRC_DIR"/scripts/*.sh; do
  [[ -f "$script" ]] || continue
  install_file "$script" "$TARGET_HOME/.local/bin/$(basename -- "$script")" exec
done

# Wallpapers
shopt -s nullglob
for wallpaper in "$SRC_DIR"/wallpapers/*.{png,jpg,jpeg}; do
  [[ -f "$wallpaper" ]] || continue
  install_file "$wallpaper" "$TARGET_HOME/.config/wallpapers/$(basename -- "$wallpaper")"
done
shopt -u nullglob

# Copia del desinstalador y del README para no depender del repo
if [[ -f "$REPO_ROOT/uninstall.sh" ]]; then
  install_file "$REPO_ROOT/uninstall.sh" "$STATE_DIR/uninstall.sh" exec
fi
if [[ -f "$REPO_ROOT/README.md" ]]; then
  install_file "$REPO_ROOT/README.md" "$STATE_DIR/README.md"
fi
if [[ -f "$REPO_ROOT/packages/aur.txt" ]]; then
  install_file "$REPO_ROOT/packages/aur.txt" "$STATE_DIR/aur.txt"
fi

if (( DRY_RUN )); then
  ok "Simulación completada. No se modificó el destino."
  exit 0
fi

# Guardamos el registro de cada instalación y un manifest acumulativo.
# Si se reinstala, se conserva el backup más antiguo de cada destino: así el
# desinstalador siempre puede volver al estado original del usuario.
mkdir -p -- "$STATE_DIR/manifests"
cp -- "$MANIFEST_TMP" "$STATE_DIR/manifests/${STAMP}.manifest"
cp -- "$DIRS_TMP" "$STATE_DIR/manifests/${STAMP}.dirs"

HISTORY_TMP="$TMP_DIR/manifest-history"
: > "$HISTORY_TMP"
if [[ -f "$MANIFEST" ]]; then
  cat -- "$MANIFEST" >> "$HISTORY_TMP"
fi
cat -- "$MANIFEST_TMP" >> "$HISTORY_TMP"
awk -F '\t' 'NF && !seen[$1]++' "$HISTORY_TMP" > "$TMP_DIR/manifest-cumulative"

DIRS_HISTORY_TMP="$TMP_DIR/dirs-history"
: > "$DIRS_HISTORY_TMP"
if [[ -f "$DIRS_FILE" ]]; then
  cat -- "$DIRS_FILE" >> "$DIRS_HISTORY_TMP"
fi
cat -- "$DIRS_TMP" >> "$DIRS_HISTORY_TMP"
awk 'NF && !seen[$0]++' "$DIRS_HISTORY_TMP" > "$TMP_DIR/dirs-cumulative"

mv -- "$TMP_DIR/manifest-cumulative" "$MANIFEST"
mv -- "$TMP_DIR/dirs-cumulative" "$DIRS_FILE"
printf '%s\n' "$STAMP" > "$STATE_DIR/last-install"

# Solo se aplica al HOME real: gsettings/papirus-folders actúan sobre el usuario actual.
if (( ICONS )) && [[ "$TARGET_HOME" == "$HOME" && -f "$TARGET_HOME/.local/bin/apply-icons.sh" ]]; then
  info "Aplicando iconos y carpetas Catppuccin (Papirus)..."
  bash "$TARGET_HOME/.local/bin/apply-icons.sh" || warn "No se pudieron aplicar los iconos; ver README.md"
fi

if command -v i3-msg >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
  i3-msg reload >/dev/null 2>&1 || true
fi

cat <<EOF

${C_BOLD}${C_GREEN}Listo.${C_RESET} archdots quedó instalado en ${TARGET_HOME}

  Registro:   ${MANIFEST}
  Backups:    ${BACKUP_ROOT}
  Desinstalar: bash ${STATE_DIR}/uninstall.sh

Siguiente paso: cierra sesión y vuelve a entrar (o ejecuta 'i3-msg restart').
¿Aún no instalaste las fuentes/iconos AUR? Mira ${STATE_DIR}/aur.txt y el README.
EOF

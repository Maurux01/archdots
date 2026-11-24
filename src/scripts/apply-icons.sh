#!/usr/bin/env bash
# Aplica iconos, carpetas y tema GTK Catppuccin (Mocha / Mauve).
# Los cambios de iconosrequieren papirus-icon-theme y papirus-folders-catppuccin-git (AUR).
set -u

ACCENT="${ARCHDOTS_ACCENT:-mauve}"   # mauve | blue | green | ... (Catppuccin)
FLAVOR="${ARCHDOTS_FLAVOR:-mocha}"   # mocha | macchiato | frappe | latte
GTK_THEME="catppuccin-${FLAVOR}-${ACCENT}-standard+default"
FOLDER_COLOR="cat-${FLAVOR}-${ACCENT}"

# 1) Color de carpetas Papirus (AUR: papirus-folders-catppuccin-git)
if command -v papirus-folders >/dev/null 2>&1; then
  for theme in Papirus Papirus-Dark Papirus-Light; do
    if [[ -d "/usr/share/icons/${theme}" ]]; then
      printf '[*] papirus-folders -C %s --theme %s\n' "$FOLDER_COLOR" "$theme"
      papirus-folders -C "$FOLDER_COLOR" --theme "$theme" 2>/dev/null || true
    fi
  done
else
  printf '[!] papirus-folders no instalado; las carpetas no se recolorearon.\n' >&2
  printf '    Instala: yay -S papirus-folders-catppuccin-git\n' >&2
fi

# 2) gsettings para Nemo / GTK (requiere sesión gráfica; se ignora si no hay DBus)
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.cinnamon.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
  gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
fi

printf '[+] Iconos Papirus-Dark, carpetas %s y GTK %s aplicados.\n' "$FOLDER_COLOR" "$GTK_THEME"

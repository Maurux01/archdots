# archdots

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1695D2?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![i3](https://img.shields.io/badge/i3wm-556677?style=for-the-badge&logo=i3&logoColor=white)](https://i3wm.org/)
[![kitty](https://img.shields.io/badge/terminal-kitty-1e1e2e?style=for-the-badge)](https://sw.kovidgoyal.net/kitty/)
[![MIT](https://img.shields.io/badge/license-MIT-cba6f7?style=for-the-badge)](LICENSE)

**Dotfiles minimalistas para Arch Linux con i3wm, kitty y Polybar ligera.**

Sin compositor, sin animaciones, sin blur y sin configuraciones innecesarias.
Paleta [Catppuccin Mocha](https://catppuccin.com/) en i3, kitty, rofi, dunst,
polybar y wallpaper. Los keybinds están inspirados en
[i3wm-dotfiles](https://github.com/Justus0405/i3wm-dotfiles), con **kitty**
como terminal por defecto.

> **Estado del repo**: se conserva `i3-arch/`, un rice experimental anterior con
> picom/blur. La configuración instalable y mantenida es la de `src/`.

---

## Tabla de contenidos

- [Características](#características)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
  - [Un comando (curl)](#un-comando-curl)
  - [Desde un clon](#desde-un-clon)
  - [Opciones del instalador](#opciones-del-instalador)
- [¿Qué instala?](#qué-instala)
- [Keybinds](#keybinds)
- [Personalización](#personalización)
- [Desinstalación](#desinstalación)
- [Estructura](#estructura)
- [Solución de problemas](#solución-de-problemas)
- [Créditos y licencia](#créditos-y-licencia)

---

## Características

- 🪟 **i3wm** con gaps, bordes finos, 10 workspaces y keybinds probados.
- ⌨️ **kitty** como terminal por defecto (`Super + Enter`).
- 📊 **Polybar ligera**: workspaces, título, reloj, volumen, CPU, memoria,
  disco, batería y systray. Una sola barra por monitor, sin duplicados.
- 🔍 **rofi** como launcher, selector de SSH, calculadora y menú de energía.
- 🔔 **dunst** para notificaciones.
- 🎨 **Iconos y carpetas Catppuccin**: Papirus + `papirus-folders` (Mocha/Mauve),
  tema GTK Catppuccin para Nemo y diálogos.
- 🅰️ **JetBrains Mono Nerd Font** como monospace por defecto (kitty, rofi,
  polybar y tu Neovim externo), con glifos Nerd listos para usar.
- 🌌 **feh** para el wallpaper y selector con `Super + W`.
- 🧊 **Sin picom**: nada de blur ni animaciones; funciona bien incluso en VMs.
- 🛡️ **Instalador seguro** con backups automáticos, modo `--dry-run` y
  desinstalador que restaura el estado anterior.

---

## Requisitos

- Arch Linux (o derivada) con **X11**, `systemd`/`pipewire` y un usuario normal
  con `sudo`.
- Paquetes oficiales listados en [`packages/essential.txt`](packages/essential.txt).
- Polybar >= 3.7 (el módulo `internal/tray` no existe en versiones anteriores).
- Opcional (algunos desde AUR; ver [`packages/aur.txt`](packages/aur.txt)):
  `ttf-jetbrains-mono-nerd`, `papirus-icon-theme`,
  `papirus-folders-catppuccin-git`, `catppuccin-gtk-theme-mocha`, `brave-browser`.

Si no quieres que el instalador toque paquetes, usa `--no-deps` e instálalos tú:

```sh
sudo pacman -S --needed $(grep -Ev '^[[:space:]]*(#|$)' packages/essential.txt)
yay -S --needed $(grep -Ev '^[[:space:]]*(#|$)' packages/aur.txt | awk '{print $1}')
```

---

## Instalación

### Un comando (curl)

```sh
curl -fsSL https://raw.githubusercontent.com/Maurux01/archdots/main/install.sh | bash
```

Con dependencias incluidas:

```sh
curl -fsSL https://raw.githubusercontent.com/Maurux01/archdots/main/install.sh \
  | bash -s -- --deps
```

El script detecta que viene por pipe, descarga la rama `main` del repo y aplica
la misma instalación que si estuvieras en un clon. No pide `sudo` salvo que
aceptes instalar paquetes. Como stdin es el propio script, el comando simple
**no instala paquetes**: usa `| bash -s -- --deps` para hacerlo, o
`| bash -s -- --no-deps` para decirlo explícitamente.

### Desde un clon

```sh
git clone --depth 1 https://github.com/Maurux01/archdots.git
cd archdots
chmod +x install.sh uninstall.sh
./install.sh --deps
```

Después cierra sesión y vuelve a entrar (o ejecuta `i3-msg restart`) para que
i3, dunst y polybar arranquen con la nueva configuración.

### Opciones del instalador

| Opción | Descripción |
| --- | --- |
| `-h`, `--help` | Ayuda |
| `-n`, `--dry-run` | Simula la instalación sin escribir nada |
| `-y`, `--yes` | No pide confirmaciones |
| `--deps` | Instala los paquetes esenciales con `pacman` |
| `--no-deps` | No instala ni pregunta por paquetes |
| `--no-icons` | No aplica iconos/carpetas Catppuccin |
| `--home DIR` | Instala en otro `$HOME` (pruebas) |
| `--repo USER/REPO` | Descarga de otro fork |
| `--ref REF` | Rama o tag distinto de `main` |

Ejemplo de prueba sin tocar tu HOME real:

```sh
./install.sh --no-deps --home /tmp/archdots-test
./install.sh --no-deps --home /tmp/archdots-test --dry-run
```

---

## ¿Qué instala?

| Origen | Destino |
| --- | --- |
| `src/i3/config` | `~/.config/i3/config` |
| `src/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `src/polybar/config.ini` | `~/.config/polybar/config.ini` |
| `src/polybar/launch.sh` | `~/.config/polybar/launch.sh` |
| `src/rofi/config.rasi` | `~/.config/rofi/config.rasi` |
| `src/dunst/dunstrc` | `~/.config/dunst/dunstrc` |
| `src/gtk-3.0/settings.ini` | `~/.config/gtk-3.0/settings.ini` |
| `src/gtk-4.0/settings.ini` | `~/.config/gtk-4.0/settings.ini` |
| `src/fontconfig/fonts.conf` | `~/.config/fontconfig/fonts.conf` |
| `src/scripts/*.sh` | `~/.local/bin/` |
| `src/wallpapers/*` | `~/.config/wallpapers/` |
| `src/xinitrc` | `~/.xinitrc` |
| `uninstall.sh`, `README.md`, `packages/aur.txt` | `~/.local/share/archdots/` |

Si tienes los paquetes AUR instalados, el instalador ejecuta
`~/.local/bin/apply-icons.sh` para teñir las carpetas de Papirus y aplicar el
tema GTK. Puedes saltarlo con `--no-icons` o repetirlo cuando quieras:

```sh
~/.local/bin/apply-icons.sh
```

Antes de sobrescribir cualquier archivo, se guarda una copia en
`~/.local/share/archdots/backups/<timestamp>/`. El registro de lo instalado
vive en `~/.local/share/archdots/manifest`.

---

## Keybinds

Modificador: **Super** (tecla Windows). `Mod1` = Alt.

### Aplicaciones

| Teclas | Acción |
| --- | --- |
| `Super + Enter` | Abrir **kitty** |
| `Super + Shift + Enter` | kitty en `$HOME` |
| `Super + E` | Nemo (gestor de archivos) |
| `Super + B` | Brave (navegador) |
| `Super + N` | Captura de área (flameshot gui) |
| `Super + M` / `Shift + Print` | Captura de pantalla completa |
| `Ctrl + Shift + Esc` | kitty con `htop` |
| `Super + Q` | Cerrar ventana enfocada |

### rofi y utils

| Teclas | Acción |
| --- | --- |
| `Super + D` | Launcher de aplicaciones |
| `Super + O` | Selector SSH |
| `Super + P` | Calculadora (resultado al portapapeles) |
| `Super + W` | Selector de wallpaper |
| `Alt + Tab` | Cambiador de ventanas |
| `Super + X` | Menú de energía |
| `Super + Shift + L` | Bloquear pantalla |

### i3, workspaces y multimedia

| Teclas | Acción |
| --- | --- |
| `Super + [1..9,0]` | Ir al workspace |
| `Super + Shift + [1..9,0]` | Mover ventana al workspace |
| `Super + Shift + Tab` | Workspace anterior |
| `Super + Shift + C` | Recargar config |
| `Super + Shift + R` | Reiniciar i3 |
| `Super + Shift + E` | Salir de i3 |
| `Super + F` | Pantalla completa |
| `Super + Shift + Space` | Tiling / floating |
| `Super + H / V` | Split horizontal / vertical |
| `Super + R` | Modo resize (← → ↑ ↓, Esc para salir) |
| `Super + ← ↑ ↓ →` | Cambiar foco |
| `Super + Shift + ← ↑ ↓ →` | Mover contenedor |
| `XF86Audio*` | Volumen, mute y reproducción |
| `XF86MonBrightness*` | Brillo (`brightnessctl`) |

---

## Personalización

- **Terminal, navegador y gestor de archivos**: variables `$terminal`,
  `$browser` y `$filemanager` al inicio de `src/i3/config`.
- **Colores**: variables Catppuccin al inicio de `src/i3/config`, la sección
  `[colors]` de `src/polybar/config.ini` y la paleta de `src/kitty/kitty.conf`.
- **Workspaces**: nombres `$ws1` … `$ws10` en `src/i3/config`.
- **Wallpapers**: añade archivos a `~/.config/wallpapers/` y elige con
  `Super + W`.
- **Batería**: si tu equipo no tiene `BAT0` o `ADP1`, ajusta `battery` y
  `adapter` en `[module/battery]` (o comenta el bloque y quítalo de
  `modules-right` en el polybar config).
- **Fuentes**: se usa `JetBrainsMono Nerd Font` en todo el rice. El archivo
  `~/.config/fontconfig/fonts.conf` la fija como `monospace` del sistema, de modo
  que **Neovim hereda la fuente y los glifos Nerd automáticamente**. Si usas otra,
  cambia `font` en i3, `font_family` en kitty, `font-0`/`font-1` en polybar,
  `font` en rofi y el alias en `fonts.conf`.
- **Neovim**: su configuración vive en tu repo aparte; este instalador **no toca**
  `~/.config/nvim`. Solo garantiza la fuente Nerd y la terminal.
- **Iconos / carpetas**: elige otro acento con
  `ARCHDOTS_ACCENT=blue ~/.local/bin/apply-icons.sh` (o `mauve`, `green`, `peach`…)
  y otro sabor con `ARCHDOTS_FLAVOR=latte`. El color de carpetas se basa en
  `cat-<flavor>-<accent>` de [catppuccin/papirus-folders](https://github.com/catppuccin/papirus-folders).

Tras editar: `i3-msg reload` y `~/.config/polybar/launch.sh`.
Para aplicar fuentes: `fc-cache -f && fc-match monospace`.

---

## Desinstalación

Desde el repo:

```sh
./uninstall.sh
```

O, si lo instalaste por curl:

```sh
bash ~/.local/share/archdots/uninstall.sh
```

| Opción | Descripción |
| --- | --- |
| `-h`, `--help` | Ayuda |
| `-n`, `--dry-run` | Muestra qué haría |
| `-y`, `--yes` | Sin confirmación |
| `--purge` | Borra también los backups |
| `--home DIR` | Desinstala de otro `$HOME` |

El desinstalador **restaura** los archivos que existían antes y elimina los
creados por el instalador. Los backups se conservan por defecto.

---

## Estructura

```text
archdots/
├── install.sh              # instalador local + modo curl
├── uninstall.sh            # desinstalador con restauración
├── LICENSE                 # MIT
├── README.md
├── packages/
│   ├── essential.txt       # paquetes pacman
│   └── aur.txt             # paquetes AUR opcionales
└── src/
    ├── i3/config
    ├── kitty/kitty.conf
    ├── polybar/{config.ini,launch.sh}
    ├── rofi/config.rasi
    ├── dunst/dunstrc
    ├── gtk-3.0/settings.ini
    ├── gtk-4.0/settings.ini
    ├── fontconfig/fonts.conf
    ├── scripts/{wallpaper-picker,rofi-ssh,rofi-calc,powermenu,lock,apply-icons}.sh
    ├── wallpapers/
    └── xinitrc
```

---

## Solución de problemas

- **Polybar no muestra nada**: comprueba `~/.config/polybar/launch.sh` y que
  `xrandr` detecte tus monitores. Los errores se guardan en
  `~/.cache/polybar.log`; también puedes ejecutar `polybar main` en una terminal.
- **No hay sonido en la barra**: instala `pipewire-pulse`. El módulo
  `internal/pulseaudio` necesita un servidor PulseAudio-compatible.
- **El brillo no funciona**: revisa `/sys/class/backlight` y los permisos de
  tu usuario con `brightnessctl`.
- **Fuentes raras / glifos en Neovim**: instala `ttf-jetbrains-mono-nerd` desde
  los repositorios oficiales y comprueba con `fc-match monospace` que devuelve
  `JetBrainsMono Nerd Font`.
  Luego `fc-cache -f` y reinicia kitty.
- **Las carpetas no cambian de color**: instala `papirus-icon-theme` (oficial) y
  `papirus-folders-catppuccin-git` (AUR) y ejecuta `~/.local/bin/apply-icons.sh`.
  Consulta los colores disponibles con `papirus-folders -l`.
- **Quieres volver a tu configuración anterior**: ejecuta el desinstalador;
  restaura desde `~/.local/share/archdots/backups/`.

---

## Créditos y licencia

- Keybinds e inspiración: [Justus0405/i3wm-dotfiles](https://github.com/Justus0405/i3wm-dotfiles).
- Paleta: [Catppuccin](https://github.com/catppuccin),
  [papirus-folders](https://github.com/catppuccin/papirus-folders) y
  [catppuccin/gtk](https://github.com/catppuccin/gtk).
- Tipografía: [JetBrains Mono](https://www.jetbrains.com/lp/mono/) +
  [Nerd Fonts](https://www.nerdfonts.com/).
- i3wm: https://i3wm.org/ · kitty: https://sw.kovidgoyal.net/kitty/

Distribuido bajo licencia [MIT](LICENSE). Copyright © 2026 Maurux01.

#!/usr/bin/env bash
# Bloquea la sesión. Usa el i3lock oficial de Arch (sin blur, sin compositor).
set -euo pipefail

exec i3lock --nofork --color=1e1e2e

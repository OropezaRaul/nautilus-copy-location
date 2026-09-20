#!/bin/bash
# Compila e instala el Nautilus de Omarchy con "Copy Location" en texto plano.
set -euo pipefail
cd "$(dirname "$0")"

if [[ $EUID -eq 0 ]]; then
  echo "No ejecutar como root: makepkg lo prohíbe." >&2
  exit 1
fi

# 1) Compilar si no hay paquetes listos (o forzar con --rebuild)
if [[ ${1-} == "--rebuild" ]] || ! ls nautilus-[0-9]*.pkg.tar.zst >/dev/null 2>&1; then
  echo "==> Compilando nautilus 50.3.1 + parche Copy Location…"
  makepkg --nocheck --cleanbuild --force
fi

# 2) Instalar (reemplaza el binario oficial por la misma versión, parcheada)
echo "==> Instalando…"
sudo pacman -U --noconfirm \
  nautilus-[0-9]*.pkg.tar.zst \
  libnautilus-extension-[0-9]*.pkg.tar.zst \
  libnautilus-extension-docs-[0-9]*.pkg.tar.zst

# 3) Evitar que el repositorio deshaga el parche (debe ir dentro de [options], no al final)
if ! grep -qs '^IgnorePkg = nautilus ' /etc/pacman.conf; then
  echo "==> Añadiendo IgnorePkg a /etc/pacman.conf bajo [options]"
  sudo sed -i '/^\[options\]/a # Omarchy local: nautilus recompilado para que "Copy Location" copie la ruta en texto plano\nIgnorePkg = nautilus libnautilus-extension libnautilus-extension-docs' /etc/pacman.conf
fi

echo
echo "Listo. Reinicia Files para aplicar el parche:  pkill nautilus"

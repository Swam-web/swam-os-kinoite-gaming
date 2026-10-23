#!/usr/bin/env bash
#
# umu-launcher — Unified launcher for Windows Games (umu-run)
# Permet de lancer les jeux Windows avec Proton hors Steam/Lutris/Heroic.
#
# RPM épinglé de la release officielle 1.4.4 (pas de COPR : 404) — le plus sûr.
# Les RPM du projet sont non signés : dnf5 par URL, fallback rpm -i --nosignature.
#
# Vérifié (rpm -qpR) : l'asset fc44 correspond à la base de l'image
#   (image-version 44 = python(abi) 3.14) ; deps python3-pyzstd, python3-urllib3,
#   python3-xlib — toutes dans les dépôts Fedora.
#   Binaire fourni : /usr/bin/umu-run (module python3.14 /usr/lib/python3.14/site-packages/umu)
set -ouex pipefail

VERSION="1.4.4"
URL="https://github.com/Open-Wine-Components/umu-launcher/releases/download/${VERSION}/umu-launcher-${VERSION}.fc44.x86_64.rpm"

### Installation du RPM amont (non signé, donc pas de COPR)
dnf5 -y install "$URL" || {
    curl -fsSL "$URL" -o /tmp/umu-launcher.rpm
    rpm -i --nosignature /tmp/umu-launcher.rpm
}

### Contrôle : le build échoue plutôt que de livrer une image sans umu-run
command -v umu-run >/dev/null && echo "umu-launcher : OK -> $(command -v umu-run)"

#!/usr/bin/env bash
#
# Branding SwamOS :
#   - os-release        : via files/system/usr/lib/os-release.d/50-swamos.conf
#   - logo (hicolor)    : via files/system/usr/share/icons/hicolor/scalable/apps/
#   - SDDM              : ci-dessous — le thème breeze est inspecté au build
#                         (pas de devinette : on regarde les vrais fichiers)
set -ouex pipefail

LOGO_SVG="/usr/share/icons/hicolor/scalable/apps/swamos-logo.svg"
THEME_DIR="/usr/share/sddm/themes/breeze"

[[ -f "${LOGO_SVG}" ]] || { echo "ERREUR : logo SwamOS absent (${LOGO_SVG})"; exit 1; }

### SDDM : remplace la clé logo= du thème breeze par notre SVG.
## Le thème Fedora référence son logo via theme.conf (clé logo=) et/ou un
## fichier images/*logo*. On couvre les deux mécanismes, sans toucher au QML.
if [[ -d "${THEME_DIR}" ]]; then
    if grep -qE "^logo=" "${THEME_DIR}/theme.conf" 2>/dev/null; then
        sed -i "s|^logo=.*|logo=${LOGO_SVG}|" "${THEME_DIR}/theme.conf"
    else
        ## clé absente : ajoutée juste après [General]
        sed -i "/^\[General\]/a logo=${LOGO_SVG}" "${THEME_DIR}/theme.conf"
    fi
    ## fichiers de logo embarqués dans le thème : remplacés s'ils sont en SVG
    find "${THEME_DIR}" -maxdepth 2 -type f -iname "*logo*.svg" \
        -exec install -Dm644 "${LOGO_SVG}" {} \;
    echo "SDDM : logo breeze rebadgé SwamOS"
else
    echo "AVERTISSEMENT : thème SDDM breeze absent — écran de connexion non rebadgé"
fi

echo "branding SwamOS : OK (os-release + logo + SDDM)"

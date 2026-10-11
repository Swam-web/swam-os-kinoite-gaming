#!/usr/bin/env bash
#
# Branding SwamOS :
#   - os-release        : modification DIRECTE de /usr/lib/os-release
#                         (os-release.d/50-swamos.conf conserve en heritage,
#                         mais il n'est lu que par libsystemd : le KCM
#                         « A propos du systeme », fastfetch, etc. l'ignorent)
#   - logo (hicolor)    : via files/system/usr/share/icons/hicolor/scalable/apps/
#   - SDDM/Plasma Login : kinoite 44 utilise plasma-login-manager (fork SDDM,
#                         theme /usr/share/plasmalogin/themes/breeze) ; fallback
#                         SDDM conservé si le thème réapparaît
set -ouex pipefail

LOGO_SVG="/usr/share/icons/hicolor/scalable/apps/swamos-logo.svg"

[[ -f "${LOGO_SVG}" ]] || { echo "ERREUR : logo SwamOS absent (${LOGO_SVG})"; exit 1; }

### os-release : champs « commerciaux » (methode ublue — modification directe)
## ID, VARIANT_ID, VERSION_ID restent Fedora (repos, outils, profils anaconda).
OSR="/usr/lib/os-release"
sed -i \
    -e 's/^NAME=.*/NAME="SwamOS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="SwamOS 44"/' \
    -e 's/^LOGO=.*/LOGO=swamos-logo/' \
    -e 's|^HOME_URL=.*|HOME_URL="https://github.com/Swam-web/swam-os-kinoite-gaming"|' \
    "${OSR}"
grep -q '^LOGO=' "${OSR}" || echo 'LOGO=swamos-logo' >> "${OSR}"
echo "os-release rebadge SwamOS (direct /usr/lib/os-release)"

### Écran de connexion : Plasma Login Manager (kinoite 44, fork SDDM).
## Le thème breeze référence son logo via theme.conf (clé logo=) et/ou des
## fichiers *logo*.svg embarqués — mêmes mécanismes que SDDM, répertoire neuf.
## Fallback SDDM conservé (le cas échéant).
for THEME_DIR in /usr/share/plasmalogin/themes/breeze /usr/share/sddm/themes/breeze; do
    if [[ -d "${THEME_DIR}" ]]; then
        if grep -qE "^logo=" "${THEME_DIR}/theme.conf" 2>/dev/null; then
            sed -i "s|^logo=.*|logo=${LOGO_SVG}|" "${THEME_DIR}/theme.conf"
        else
            sed -i "/^\[General\]/a logo=${LOGO_SVG}" "${THEME_DIR}/theme.conf"
        fi
        find "${THEME_DIR}" -maxdepth 2 -type f -iname "*logo*.svg" \
            -exec install -Dm644 "${LOGO_SVG}" {} \;
        echo "Login manager : ${THEME_DIR} rebadgé SwamOS"
    else
        echo "Info : ${THEME_DIR} absent — ignoré"
        [[ -d "${THEME_DIR%/themes/breeze}" ]] && ls "${THEME_DIR%/themes/breeze}/themes/" 2>/dev/null || true
    fi
done

echo "branding SwamOS : OK (os-release + logo + login manager)"

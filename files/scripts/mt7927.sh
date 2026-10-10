#!/usr/bin/env bash

# MediaTek MT7927 WiFi + MT6639 Bluetooth
## Out-of-tree patched modules from jetm/mediatek-mt7927-dkms, prebuilt
## in the image against the CachyOS kernel (dkms does not work on bootc).
##
## FAIL-SOFT : module matériel-spécifique (très peu de machines concernées)
## dépendant de sources non-distro (repo GitHub perso + API token ASUS +
## ZIP Windows). Un échec n'abolit PAS le build : l'image sort sans le
## firmware BT MT6639 ; le WiFi passe par le driver in-tree mt7925e
## (firmware WIFI_MT6639 désormais dans linux-firmware).
## Tout le reste de l'image (kernel, GPU, codecs) reste fail-fast.
set -ouex pipefail

KERNEL_VERSION="$(rpm -q kernel-cachyos-lto --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

build_mt7927() {
    ## Strict à l'intérieur : un échec = sortie de la fonction = branche
    ## d'avertissement ci-dessous. La vérification interne (mt7925e.ko
    ## présent) reste fail-fast : ce serait un bug de code, pas une
    ## panne de source externe.
    set -euex pipefail

    ## --refresh : métadonnées en cache vs versions retirées des miroirs
    dnf5 -y --refresh install patch

    MT7927_VERSION="2.16-1"
    MT7927_DIR="$(mktemp -d /tmp/mt7927-XXXXXXXX)"
    curl -sL -f -o "${MT7927_DIR}/src.tar.gz" \
        "https://github.com/jetm/mediatek-mt7927-dkms/archive/refs/tags/v${MT7927_VERSION}.tar.gz"
    tar -xzf "${MT7927_DIR}/src.tar.gz" -C "${MT7927_DIR}" --strip-components=1

    make -C "${MT7927_DIR}" download
    make -C "${MT7927_DIR}" sources

    ## Build with clang (the CachyOS kernel is clang/LTO)
    export CC=clang CXX=clang++ LD=ld.lld LLVM=1 LLVM_IAS=1
    make -C "/usr/lib/modules/${KERNEL_VERSION}/build" M="${MT7927_DIR}/_build/mt76" modules
    make -C "/usr/lib/modules/${KERNEL_VERSION}/build" M="${MT7927_DIR}/_build/bluetooth" modules
    unset CC CXX LD LLVM LLVM_IAS

    ## Install the modules (updates/ shadows the in-tree ones)
    make -C "/usr/lib/modules/${KERNEL_VERSION}/build" M="${MT7927_DIR}/_build/mt76" modules_install INSTALL_MOD_PATH= INSTALL_MOD_DIR=updates
    make -C "/usr/lib/modules/${KERNEL_VERSION}/build" M="${MT7927_DIR}/_build/bluetooth" modules_install INSTALL_MOD_PATH= INSTALL_MOD_DIR=updates

    MT7925_KO="$(find /usr/lib/modules/"${KERNEL_VERSION}"/updates -name 'mt7925e.ko*' -print -quit)"
    [[ -n "${MT7925_KO}" ]]
    depmod -a "${KERNEL_VERSION}"

    ## Bluetooth firmware blob (ours to ship: linux-firmware does not have it yet)
    install -Dm644 "${MT7927_DIR}/_build/firmware/BT_RAM_CODE_MT6639_2_1_hdr.bin" \
        /usr/lib/firmware/mediatek/mt7927/BT_RAM_CODE_MT6639_2_1_hdr.bin

    rm -rf "${MT7927_DIR}"
}

if build_mt7927; then
    echo "MT7927 : modules WiFi/BT + firmware installés pour ${KERNEL_VERSION}"
else
    cat >&2 <<'AVERTISSEMENT'
================================================================
AVERTISSEMENT : build MT7927 impossible (chaîne de téléchargement
jetm/mediatek-mt7927-dkms ou CDN ASUS indisponible/modifiée).
L'image est livrée SANS le firmware Bluetooth MT6639 :
  - WiFi MT7927      : OK (driver in-tree mt7925e, firmware inclus
                       dans linux-firmware)
  - Bluetooth MT6639 : NON fonctionnel tant que la source
    https://github.com/jetm/mediatek-mt7927-dkms n'est pas réparée
================================================================
AVERTISSEMENT
fi

exit 0

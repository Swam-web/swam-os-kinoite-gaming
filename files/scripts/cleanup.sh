#!/usr/bin/env bash

# Nettoyage final
set -ouex pipefail

## Kernel modules are prebuilt, remove the build toolchain
dnf5 -y remove kernel-cachyos-lto-devel
dnf5 versionlock delete kernel-cachyos-lto-devel || true

## Do not ship the build repositories enabled on the final image
## (RPMFusion et le dépôt AMD ROCm restent activés : mises à jour des pilotes)
dnf5 -y copr disable bieszczaders/kernel-cachyos-lto
dnf5 -y copr disable bieszczaders/kernel-cachyos-addons

## Repos hérités d'anciens builds, s'ils existent encore :
##   terra : clé GPG file:// absente de l'image -> casse le depsolve de
##           bootc-image-builder au moment de fabriquer les ISOs
##   negativo17 : remplacé par RPMFusion (ancienne pile)
rm -f /etc/yum.repos.d/*terra* /etc/dnf/dnf5/repos.d/*terra* /usr/share/dnf5/repos.d/*terra*
rm -f /etc/yum.repos.d/negativo17-fedora-nvidia.repo /etc/yum.repos.d/negativo17-fedora-multimedia.repo

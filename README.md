# SwamOS — kinoite-gaming

Image **bootc** (Fedora Atomic) **universelle** basée sur **Kinoite officiel**
(`quay.io/fedora-ostree-desktops/kinoite:44`), construite avec
[BlueBuild](https://blue-build.org/). C'est la **fusion** de
[`swam-os-kinoite-nvidia`](https://github.com/Swam-web/swam-os-kinoite) et
`swam-os-kinoite-amd` : **les deux piles GPU cohabitent dans la même image**, le
matériel décide au boot, sans aucune question ni configuration.

**Identité** : Fedora/Kinoite d'origine — le rebadge SwamOS (os-release, SDDM,
fastfetch) a été reverté (commit `c4790e1`).

- **Base** : `quay.io/fedora-ostree-desktops/kinoite` version `44`
- **Image publiée** : `ghcr.io/swam-web/swam-os-kinoite-gaming:latest`

## Pourquoi une image universelle

| Matériel | Ce qui se passe |
|---|---|
| NVIDIA | `nvidia.ko` (akmod compilé clang) se charge, `nouveau` blackisté ; ROCm présent mais inerte |
| AMD | `amdgpu` in-tree (kernel CachyOS) se charge ; la pile NVIDIA est inerte |
| Laptop hybride (iGPU AMD + dGPU NVIDIA) | Les deux se chargent et coopèrent — cas impossible avec deux images séparées |

## Contenu

| | Détail |
|---|---|
| **Kernel** | CachyOS `kernel-cachyos-lto` (Clang LTO, 1000 Hz, full preempt) — COPR `bieszczaders/kernel-cachyos-lto`, remplace le kernel Fedora (pattern `install-kernel-akmods`) |
| **NVIDIA (RPMFusion)** | `akmod-nvidia` + userland `xorg-x11-drv-nvidia` (`.i686` inclus), kmods recompilés **clang** contre le kernel CachyOS (`pahole` + `xorg-x11-drv-nvidia-kmodsrc`) |
| **AMD ROCm (minimal gaming)** | Dépôt officiel AMD (RHEL9) : `rocm-core`, `rocm-opencl-runtime`, `rocm-smi` — installé via l'optfix BlueBuild (`/usr/lib/opt`, symlinks `/opt` au boot). **Sans la pile HIP** (`rocm-hip-runtime`, `rocm-libs`/rocBLAS ≈ 5-6 Go) : inutile aux jeux (Vulkan/DXVK via mesa) — qui en a besoin : `rpm-ostree install rocm-hip-runtime rocm-libs` |
| **WiFi/BT MT7927** | ❌ **retiré de l'image** (2026-10) — suspect principal de la corruption de profil utilisateur (10 CVE memory-safety sur `mt7925/mt76` ; bug machine-spécifique, l'install AMD de contrôle est saine). Le driver **in-tree `mt7925e` est blacklisté** dans l'image (`/etc/modprobe.d/blacklist-mt7927.conf`) → WiFi/BT inopérants, utiliser Ethernet. Ré-activation : rétablir `mt7927.sh` (branche/`f45-wip` + git history) + supprimer la blacklist |
| **Codecs universels** | RPMFusion : ffmpeg complet, `@multimedia`, openh264, libdvdcss ; VA-API/Vulkan **AMD** (`mesa-*-freeworld`) **et** pont NVDEC→VA-API **NVIDIA** (`libva-nvidia-driver`) ; 32 bits complets |
| **Gaming** | gamescope, gamemode, mangohud, vkBasalt, goverlay, steam-devices (RPM) ; Steam, Lutris, Heroic, Bottles, OBS, **BoxBuddy** (GUI distrobox)… (Flathub, `default-flatpaks`) ; **VulkanLayer flatpak** MangoHud/gamescope/vkBasalt (refs épinglées 25.08/26.08 — les couches RPM n'agissent pas dans les jeux flatpak) |
| **Périphériques (fail-soft)** | **xpadneo** (manettes Xbox BT, rumble avancé), **xone** (dongle USB Xbox + firmware), **OpenRazer** (kmods clang + daemon), **OpenTabletDriver** (tablettes), `libcec` (HDMI CEC via adaptateur Pulse-Eight) — un échec de source n'abolit pas le build |
| **Réactivité (socle CachyOS)** | `scx_lavd` (sched_ext, mode Gaming auto), `ananicy-cpp`, zram + sysctls `cachyos-settings` ; **`game-performance`** (fourni par `cachyos-settings`) : `powerprofilesctl` performance au lancement d'une app — à mettre dans les options de lancement Steam (`game-performance %command%`) pour les jeux hors gamemode |
| **Optimisations gaming** | `gamemode.ini` (renice -10 via limites PAM `limits.d/swam-gamemode.conf`, gouverneur `performance`) ; PipeWire quantum **256** (~5,3 ms) ; sysctl **BBR + fq + `vm.max_map_count`** (absents de `cachyos-settings`) ; animations Plasma ÷2 (`kdeglobals` /etc/xdg) ; `thermald` (Intel, inerte AMD) ; karg `nvidia-drm.fbdev=1` |
| **Légèreté** | Baloo (indexeur) masqué, `irqbalance` et `plasma-discover` retirés, `cups`/`avahi` en **socket-activation**, KWin `AllowTearing`, compression btrfs `zstd` |

## Installation

```bash
sudo bootc switch ghcr.io/swam-web/swam-os-kinoite-gaming:latest
sudo systemctl reboot
```

## Caveats

- **Secure Boot** : le kernel CachyOS et les modules construits ne sont pas signés par une clé
  approuvée par Microsoft. Désactiver Secure Boot, ou enrôler votre propre clé MOK.
- Le driver **NVIDIA open** supporte **Turing (RTX 20) et plus récent**.
- Sur machine **AMD uniquement**, l'initramfs force `nvidia.ko` qui ne trouve pas de matériel :
  avertissement bénin au boot, sans effet.
- **MT7927 retiré de l'image (2026-10)** : suspect principal de la corruption
  de profil utilisateur — 10 CVE memory-safety actives sur la famille
  `mt7925/mt76` (use-after-free, OOB, NULL deref), bug **machine-spécifique**
  (l'install AMD de contrôle est saine), dégradation progressive sur 4-6
  boots, `chown -R` du profil réparateur, `restorecon` sans effet. L'image
  blackliste **aussi** le driver in-tree `mt7925e` (`/etc/modprobe.d/`
  `blacklist-mt7927.conf`) → WiFi et Bluetooth inopérants, passer par
  l'Ethernet. Ré-activation quand le driver est sain : rétablir `mt7927.sh`
  (git history / branche `f45-wip`) et supprimer le fichier de blacklist.
- `tsc=reliable clocksource=tsc` : retirer ces kargs en cas de dérive horaire (VM exotiques).
- `mitigations=off` est volontairement **non activé** (voir commentaire dans `recipe.yml`).

## Build

```bash
# image conteneur
sudo -E nix run github:blue-build/cli -- build recipe recipes/recipe.yml

# validation seule (rapide)
bluebuild validate recipes/recipe.yml
```

## Images disque (ISO / qcow2)

Via **bootc-image-builder** (lire le caveat du dépôt `swam-os-kinoite-nvidia` sur les
limites de `bluebuild generate-iso`) :

```bash
sudo podman run --rm --privileged --pull=newer \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type anaconda-iso \
  --config ./disk_config/iso.toml \
  --local --chown $(id -u):$(id -g) \
  ghcr.io/swam-web/swam-os-kinoite-gaming:latest
```

Ou via GitHub Actions : `Actions → Build disk images → Run workflow`.

## Signature

Images signées avec **cosign** (clé publique dans `cosign.pub`, secret GitHub `SIGNING_SECRET`).

```bash
cosign verify --key cosign.pub ghcr.io/swam-web/swam-os-kinoite-gaming:latest
```

## Crédits

[Fedora Kinoite](https://fedoraproject.org/kinoite/) / [Universal Blue](https://universal-blue.org/),
[BlueBuild](https://blue-build.org/), [CachyOS](https://cachyos.org/), [RPMFusion](https://rpmfusion.org/),
[AMD ROCm](https://www.amd.com/fr/developer/resources/rocm-hub.html),
[jetm/mediatek-mt7927-dkms](https://github.com/jetm/mediatek-mt7927-dkms).

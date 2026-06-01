# NanoPi R2S kernel

**Unofficial / community-maintained** Linux kernel packages for **FriendlyElec NanoPi R2S** (RK3328) on Arch Linux ARM.

The package tracks the Arch Linux ARM `linux-aarch64` version and config baseline, then applies a small NanoPi R2S router profile.

**GitHub repository:** [`therealcoder1337/nanopi-r2s-kernel-arch`](https://github.com/therealcoder1337/nanopi-r2s-kernel-arch)

**Disclaimer:** Packages are provided as-is, without warranty of fitness or successful operation on your hardware. Builds follow rolling Arch Linux ARM and upstream kernel updates; behavior may change between releases.

## AI disclosure

Much of this repository was written with AI assistance and refined through iterative review, builds, and hardware testing.

## Package

| Term | Meaning |
|------|---------|
| Pacman package | `linux-nanopi-r2s-minimal` |
| Kernel release suffix | `-nanopi-r2s-minimal` |
| Pacman repo | `[nanopi-r2s-kernel-arch]` |

The package installs `/boot/Image`, the R2S DTB, a mkinitcpio preset/config, and modules under `/usr/lib/modules/<kernel-release>/`. A pacman hook regenerates the initramfs.

## Install From Repo

Add the pacman repo:

```ini
[nanopi-r2s-kernel-arch]
Server = https://therealcoder1337.github.io/nanopi-r2s-kernel-arch/aarch64
SigLevel = Required
```

Import and locally trust the repository signing key, then install. The `lsign-key` step makes pacman trust packages signed by this key, so only run it after verifying the public key source or fingerprint.

```bash
curl -fsSLO https://therealcoder1337.github.io/nanopi-r2s-kernel-arch/aarch64/nanopi-r2s-kernel-arch.pub
sudo pacman-key --add nanopi-r2s-kernel-arch.pub
sudo pacman-key --lsign-key 03CB87E30BA22193
sudo pacman -Syu linux-nanopi-r2s-minimal
```

`linux-nanopi-r2s-minimal` conflicts with `linux-aarch64`; pacman may ask for confirmation when replacing the stock kernel.

## Build Locally

Install the Arch build dependencies:

```bash
sudo pacman -S --needed base-devel coreutils kmod mkinitcpio \
  aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils \
  bc dtc git python pacman-contrib curl xz openssl libelf
```

Build the package:

```bash
./scripts/build-package.sh
```

Output is written to `build/linux-nanopi-r2s-minimal-*.pkg.tar.zst`.

Useful environment variables:

| Variable | Default |
|----------|---------|
| `MAKEFLAGS` | `-j$(nproc)` |
| `CROSS_COMPILE` | `aarch64-linux-gnu-` |
| `ARCH` | `arm64` |
| `MAKEPKG_SYNCDEPS` | `0`; set `1` to run `makepkg -s` |
| `SKIP_ALARM_FETCH` | `0`; set `1` only for cached CI/local rebuilds |

## Test A Local Package

Copy the built package to the NanoPi R2S, then replace the stock kernel:

```bash
sudo pacman -Rns linux-aarch64
sudo pacman -U linux-nanopi-r2s-minimal-*.pkg.tar.zst
sudo reboot
```

`mkinitcpio` may warn that no modules were added to the image. That is normal for
plain SD/eMMC/USB root filesystems because the R2S boot path is built in. For
encrypted root, add the required dm-crypt hooks/modules before rebooting.

After boot:

```bash
uname -r
ip link
```

Serial console: `ttyS2` at `1500000` baud.

## Config Strategy

Builds start from the current ALARM `linux-aarch64` config and apply two fragments:

| File | Purpose |
|------|---------|
| [config/fragment.r2s](config/fragment.r2s) | R2S board and router features to keep |
| [config/fragment.prune](config/fragment.prune) | Subsystems not needed for this headless router target |

The profile keeps the R2S boot and routing path: RK3328, RK I2C PMIC/regulators, Rockchip MMC/eMMC, USB2/USB3 host, USB storage/UAS, onboard GMAC, internal USB3 RTL8153, nftables/iptables compatibility, broad VPN/tunnel/ipset support, WireGuard, IPv6, AES-based dm-crypt/LUKS, Cubic/BBR, Landlock, 32-bit userspace compatibility, ext4/overlayfs/exfat/fuse, thermal/cpufreq, and GPIO LEDs.

The internal RTL8153 driver is built as a module so it loads after the root filesystem is available and can read `rtl_nic/rtl8153b-2.fw` from `linux-firmware-realtek`. A built-in driver works for networking, but misses that firmware unless the firmware is added to the initramfs or built into the kernel. Those remain possible later options, but they add image/build complexity and extra firmware redistribution surface.

It trims broad desktop/peripheral and non-board support: display/GPU/media/sound/input, wireless/Bluetooth, virtualization, SATA/AHCI, non-board USB/I2C/SPI/MMC/NVMEM/PHY leaves, old USB-storage subdrivers, unrelated NIC vendors, legacy TCP/crypto/netfilter features, uncommon IPv4/IPv6 routing, NetLabel, extra virtual networking modes, legacy partition parsers, unused filesystems/block storage, USB gadget/OTG helpers, zram/zswap/hugepage/dm-integrity extras, and debug/test/proc-debug facilities.

`scripts/merge-config.sh` fails if a requested config symbol is not honored after `olddefconfig`; `scripts/verify-r2s-config.sh` checks the R2S-critical options before compile.

## Layout

```
nanopi-r2s-kernel-arch/
├── config/                 # config fragments and generated merge output
├── packaging/
├── scripts/
└── .github/workflows/
```

## CI

- `build-kernel.yml` builds, signs, and publishes GitHub Pages/Releases.
- `check-kernel.yml` checks ALARM for updates and can trigger a build.

## License

Kernel and driver patches: GPL-2.0-only. Devicetree changes follow the
upstream file license, GPL-2.0+ OR MIT. Packaging scripts: GPL-2.0-or-later.

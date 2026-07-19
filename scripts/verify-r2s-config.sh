#!/usr/bin/env bash
# Fail fast if merged config misses NanoPi R2S critical options.
set -euo pipefail

CFG="${1:?path to .config required}"

[ -f "$CFG" ] || {
    echo "Error: config file not found: $CFG" >&2
    exit 1
}

require_value() {
    local expected="$1" sym
    shift
    for sym in "$@"; do
        grep -Eq "^${sym}=(${expected})$" "$CFG" || {
            echo "Error: expected ${sym}=${expected}" >&2
            return 1
        }
    done
}

require_value y \
    CONFIG_STMMAC_ETH \
    CONFIG_STMMAC_PLATFORM \
    CONFIG_DWMAC_ROCKCHIP \
    CONFIG_DWMAC_GENERIC \
    CONFIG_REALTEK_PHY \
    CONFIG_WIREGUARD \
    CONFIG_NF_TABLES \
    CONFIG_NF_CONNTRACK \
    CONFIG_NF_NAT \
    CONFIG_BRIDGE \
    CONFIG_VLAN_8021Q

require_value y \
    CONFIG_COMPAT \
    CONFIG_KALLSYMS \
    CONFIG_IKCONFIG_PROC \
    CONFIG_INOTIFY_USER \
    CONFIG_FANOTIFY

require_value y \
    CONFIG_USB_DWC2 \
    CONFIG_USB_DWC2_HOST \
    CONFIG_USB_DWC3 \
    CONFIG_USB_DWC3_HOST \
    CONFIG_USB_XHCI_HCD \
    CONFIG_USB_XHCI_PLATFORM \
    CONFIG_USB_EHCI_HCD \
    CONFIG_USB_EHCI_HCD_PLATFORM \
    CONFIG_USB_OHCI_HCD \
    CONFIG_USB_OHCI_HCD_PLATFORM

require_value y \
    CONFIG_I2C_RK3X \
    CONFIG_MMC \
    CONFIG_MMC_BLOCK \
    CONFIG_MMC_DW \
    CONFIG_MMC_DW_PLTFM \
    CONFIG_MMC_DW_ROCKCHIP \
    CONFIG_PHY_ROCKCHIP_INNO_USB2 \
    CONFIG_PHY_ROCKCHIP_EMMC \
    CONFIG_MFD_RK8XX \
    CONFIG_MFD_RK8XX_I2C \
    CONFIG_REGULATOR_RK808 \
    CONFIG_COMMON_CLK_RK808 \
    CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL

require_value y \
    CONFIG_SCSI \
    CONFIG_BLK_DEV_SD \
    CONFIG_USB_STORAGE \
    CONFIG_USB_UAS \
    CONFIG_EXT4_FS \
    CONFIG_IPV6 \
    CONFIG_NLS \
    CONFIG_NLS_UTF8 \
    CONFIG_MSDOS_PARTITION \
    CONFIG_EFI_PARTITION \
    CONFIG_LEDS_GPIO \
    CONFIG_LEDS_TRIGGER_DEFAULT_ON \
    CONFIG_LEDS_TRIGGER_NETDEV \
    CONFIG_SECURITY_LANDLOCK

require_value y \
    CONFIG_TCP_CONG_CUBIC \
    CONFIG_CRYPTO_AES \
    CONFIG_CRYPTO_XTS \
    CONFIG_CRYPTO_CHACHA20

require_value m \
    CONFIG_USB_RTL8152 \
    CONFIG_TCP_CONG_BBR \
    CONFIG_CRYPTO_DEV_ROCKCHIP \
    CONFIG_DW_WATCHDOG \
    CONFIG_TUN \
    CONFIG_VETH \
    CONFIG_MACVLAN \
    CONFIG_IPVLAN

require_value 'y|m' \
    CONFIG_BLK_DEV_DM \
    CONFIG_DM_CRYPT \
    CONFIG_IFB \
    CONFIG_NET_SCH_CAKE \
    CONFIG_NET_SCH_FQ_CODEL \
    CONFIG_NET_SCH_INGRESS \
    CONFIG_NET_CLS_U32 \
    CONFIG_NET_CLS_BPF \
    CONFIG_NET_CLS_FLOWER \
    CONFIG_NET_CLS_MATCHALL \
    CONFIG_NET_ACT_MIRRED \
    CONFIG_NET_ACT_POLICE

echo "R2S config checks passed: $CFG"

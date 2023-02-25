#!/bin/bash
clear

## Prepare
# GCC CFlags
sed -i 's/Os/O2 -Wl,--gc-sections/g' include/target.mk
wget -qO - https://github.com/openwrt/openwrt/commit/8249a8c.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/66fa343.patch | patch -p1
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a
# Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/mmc.bootscript
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/nanopi-r2s.bootscript
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/nanopi-r4s.bootscript
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg
# Victoria's Secret
rm -rf ./scripts/download.pl
rm -rf ./include/download.mk
cp -rf ../immortalwrt/scripts/download.pl ./scripts/download.pl
cp -rf ../immortalwrt/include/download.mk ./include/download.mk
sed -i '/unshift/d' scripts/download.pl
sed -i '/mirror02/d' scripts/download.pl
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
sed -i 's/default NODEJS_ICU_SMALL/default NODEJS_ICU_NONE/g' feeds/packages/lang/node/Makefile

## Important Patches
# Backport MG-LRU to linux kernel 5.10
cp -rf ../PATCH/backport/MG-LRU/* ./target/linux/generic/pending-5.10/
# ARM64: Add CPU model name in proc cpuinfo
wget -P target/linux/generic/hack-5.10/ https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/hack-5.10/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# Patches for SSL
rm -rf ./package/libs/mbedtls
cp -rf ../immortalwrt/package/libs/mbedtls ./package/libs/mbedtls
rm -rf ./package/libs/openssl
cp -rf ../immortalwrt_21/package/libs/openssl ./package/libs/openssl
# Fix fstools
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
# Patch kernel to fix fullcone conflict
pushd target/linux/generic/hack-5.10
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.10/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch firewall to enable fullcone
rm -rf ./package/network/config/firewall4
cp -rf ../immortalwrt/package/network/config/firewall4  ./package/network/config/firewall4
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches/990-unconditionally-allow-ct-status-dnat.patch
rm -rf ./package/libs/libnftnl
cp -rf ../immortalwrt/package/libs/libnftnl ./package/libs/libnftnl
rm -rf ./package/network/utils/nftables
cp -rf ../immortalwrt/package/network/utils/nftables ./package/network/utils/nftables
mkdir -p package/network/config/firewall/patches
cp -rf ../immortalwrt_21/package/network/config/firewall/patches/100-fullconenat.patch ./package/network/config/firewall/patches/100-fullconenat.patch
wget -qO- https://github.com/msylgj/R2S-R4S-OpenWrt/raw/master/PATCHES/001-fix-firewall3-flock.patch | patch -p1
# Patch LuCI to add fullcone button
patch -p1 <../PATCH/firewall/luci-app-firewall_add_fullcone.patch
# FullCone modules
git clone --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone package/new/nft-fullcone
cp -rf ../PATCH/duplicate/fullconenat ./package/network/fullconenat
# Dnsmasq
rm -rf ./package/network/services/dnsmasq
cp -rf ../openwrt_ma/package/network/services/dnsmasq ./package/network/services/dnsmasq
cp -rf ../openwrt_luci_ma/modules/luci-mod-network/htdocs/luci-static/resources/view/network/dhcp.js ./feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/

## Change Rockchip target and Uboot
rm -rf ./target/linux/rockchip
cp -rf ../lede/target/linux/rockchip ./target/linux/rockchip
rm -rf ./target/linux/rockchip/Makefile
cp -rf ../openwrt_release/target/linux/rockchip/Makefile ./target/linux/rockchip/Makefile
rm -rf ./target/linux/rockchip/armv8/config-5.10
cp -rf ../openwrt_release/target/linux/rockchip/armv8/config-5.10 ./target/linux/rockchip/armv8/config-5.10
rm -rf ./target/linux/rockchip/patches-5.10/002-net-usb-r8152-add-LED-configuration-from-OF.patch
rm -rf ./target/linux/rockchip/patches-5.10/003-dt-bindings-net-add-RTL8152-binding-documentation.patch
cp -rf ../PATCH/rockchip-5.10/* ./target/linux/rockchip/patches-5.10/
rm -rf ./package/firmware/linux-firmware/intel.mk
cp -rf ../lede/package/firmware/linux-firmware/intel.mk ./package/firmware/linux-firmware/intel.mk
rm -rf ./package/firmware/linux-firmware/Makefile
cp -rf ../lede/package/firmware/linux-firmware/Makefile ./package/firmware/linux-firmware/Makefile
mkdir -p target/linux/rockchip/files-5.10
cp -rf ../PATCH/duplicate/files-5.10 ./target/linux/rockchip/
sed -i '/set_interface_core 20 "eth1"/a \\tethtool -K eth1 tso on sg on tx on' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
rm -rf ./package/boot/uboot-rockchip
cp -rf ../lede/package/boot/uboot-rockchip ./package/boot/uboot-rockchip
cp -rf ../lede/package/boot/arm-trusted-firmware-rockchip-vendor ./package/boot/arm-trusted-firmware-rockchip-vendor
rm -rf ./package/kernel/linux/modules/video.mk
cp -rf ../immortalwrt/package/kernel/linux/modules/video.mk ./package/kernel/linux/modules/video.mk

## Extra Packages
# AutoCore
cp -rf ../OpenWrt-Add/autocore ./package/new/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/new/autocore/files/generic/luci-mod-status-autocore.json
sed -i '/"$threads"/d' package/new/autocore/files/x86/autocore
rm -rf ./feeds/packages/utils/coremark
cp -rf ../immortalwrt_pkg/utils/coremark ./feeds/packages/utils/coremark
# Autoreboot
cp -rf ../immortalwrt_luci/applications/luci-app-autoreboot ./package/feeds/luci/luci-app-autoreboot
# Golang
rm -rf ./feeds/packages/lang/golang
cp -rf ../openwrt_pkg_ma/lang/golang ./feeds/packages/lang/golang
# MiniUPNP
rm -rf ./feeds/packages/net/miniupnpd
cp -rf ../openwrt_pkg_ma/net/miniupnpd ./feeds/packages/net/miniupnpd
pushd feeds/packages
wget -qO- https://github.com/openwrt/packages/commit/785bbcb.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/commit/d811cb4.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/commit/9a2da85.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/commit/71dc090.patch | patch -p1
popd
wget -P feeds/packages/net/miniupnpd/patches/ https://github.com/ptpt52/openwrt-packages/raw/master/net/miniupnpd/patches/201-change-default-chain-rule-to-accept.patch
wget -P feeds/packages/net/miniupnpd/patches/ https://github.com/ptpt52/openwrt-packages/raw/master/net/miniupnpd/patches/500-0004-miniupnpd-format-xml-to-make-some-app-happy.patch
wget -P feeds/packages/net/miniupnpd/patches/ https://github.com/ptpt52/openwrt-packages/raw/master/net/miniupnpd/patches/500-0005-miniupnpd-stun-ignore-external-port-changed.patch
wget -P feeds/packages/net/miniupnpd/patches/ https://github.com/ptpt52/openwrt-packages/raw/master/net/miniupnpd/patches/500-0006-miniupnpd-fix-stun-POSTROUTING-filter-for-openwrt.patch
rm -rf ./feeds/luci/applications/luci-app-upnp
cp -rf ../openwrt_luci_ma/applications/luci-app-upnp ./feeds/luci/applications/luci-app-upnp
pushd feeds/luci
wget -qO- https://github.com/openwrt/luci/commit/0b5fb915.patch | patch -p1
popd
# NIC drivers update
git clone https://github.com/sbwml/package_kernel_r8125 package/new/r8125
cp -rf ../immortalwrt/package/kernel/r8152 ./package/new/r8152
git clone -b master --depth 1 https://github.com/BROBIRD/openwrt-r8168.git package/new/r8168
patch -p1 <../PATCH/r8168/r8168-fix_LAN_led-for_r4s-from_TL.patch
cp -rf ../PATCH/backport/igc ./target/linux/x86/files-5.10
# Ram-free
cp -rf ../immortalwrt_luci/applications/luci-app-ramfree ./package/feeds/luci/luci-app-ramfree

## Ending
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/script/fuck package/base-files/files/usr/bin/fuck
# Conntrack_Max
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# Remove config
rm -rf .config
cat ../SEED/extra.cfg >> ./target/linux/generic/config-5.10

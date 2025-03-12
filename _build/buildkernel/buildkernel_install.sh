###############

silent() { "$@" >/dev/null 2>&1; }

echo "Installing Dependencies"
silent apt-get install -y curl sudo mc
echo "Installed Dependencies"

silent apt-get -y install build-essential bc kmod cpio flex libncurses5-dev libelf-dev libssl-dev dwarves bison
silent apt-get -y install python3

cat > /root/start.sh << 'EOL'
cd /root

echo "Compiling"
wget --no-check-certificate https://snapshot.debian.org/archive/debian/20231007T024024Z/pool/main/l/linux/linux-source-5.10_5.10.178-3_all.deb -O mypackage.deb
wget --no-check-certificate https://snapshot.debian.org/archive/debian/20231007T024024Z/pool/main/l/linux/linux-config-5.10_5.10.178-3_amd64.deb -O mypackagecfg.deb
ar x mypackage.deb data.tar.gz
ar x mypackagecfg.deb data.tar.xz
mkdir -p mypackage
tar -C mypackage -xzf data.tar.gz
tar -C mypackage -xJf data.tar.xz
tar -C mypackage/usr/src -xJf  mypackage/usr/src/linux-source-5.10.tar.xz
xz -dck mypackage/usr/src/linux-config-5.10/config.amd64_none_amd64.xz > mypackage/usr/src/linux-source-5.10/config.amd64_none_amd64
sed \
-e "s/CONFIG_VIRTIO=m/CONFIG_VIRTIO=y/g" \
-e "s/CONFIG_VIRTIO_PCI=m/CONFIG_VIRTIO_PCI=y/g" \
-e "s/CONFIG_NET_9P=m/CONFIG_NET_9P=y/g" \
-e "s/CONFIG_NET_9P_VIRTIO=m/CONFIG_NET_9P_VIRTIO=y/g" \
-e "s/CONFIG_9P_FS=m/CONFIG_9P_FS=y/g" \
-i mypackage/usr/src/linux-source-5.10/config.amd64_none_amd64
sed \
-e '$a\CONFIG_BUILD_SALT="5.10.0-22-amd64"' \
-e '$a\# CONFIG_MODULE_SIG_ALL is not set' \
-e '$a\CONFIG_MODULE_SIG_KEY=""' \
-e '$a\CONFIG_SYSTEM_TRUSTED_KEYS=""' \
-i mypackage/usr/src/linux-source-5.10/config.amd64_none_amd64

cd mypackage/usr/src/linux-source-5.10
make mrproper
cp config.amd64_none_amd64 .config
make -j`nproc` bzImage
cp arch/x86/boot/bzImage vmlinuz
echo "Compiled"
EOL
chmod +x /root/start.sh


echo "Cleaning up"
silent apt-get -y autoremove
silent apt-get -y autoclean
echo "Cleaned"

##############

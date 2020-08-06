#!/bin/bash
set -e

apt-get update
apt-get install -y libelf-dev

git clone --depth=1 https://github.com/buildroot/buildroot
export KCONFIG_ALLCONFIG=$HOME/work/k8s/k8s/boot2kube/build.config
cd buildroot

gnum=$(sed -n '/ROOTFS_ISO9660_CMD/=' fs/iso9660/iso9660.mk)
sed -i ''$gnum' i \techo "Boot2Kube $(date "+%Y%m%d")" > $(ROOTFS_ISO9660_TMP_TARGET_DIR)/version' fs/iso9660/iso9660.mk

make -s -j"$(nproc)" allnoconfig
make -s -j"$(nproc)"

apt-get install -y python-matplotlib python-numpy
make graph-build
cp output/graphs/build.hist-build.pdf /dev/shm/boot2kube-build.hist-build.pdf

d=$(date "+%Y%m%d")
cp output/images/rootfs.iso9660 /dev/shm/boot2kube.iso

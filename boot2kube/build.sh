#!/bin/bash
set -ex

apt-get update
apt-get install -y libelf-dev

export KCONFIG_ALLCONFIG=$(pwd)/boot2kube/build.config
# git clone --depth=1 https://github.com/buildroot/buildroot
RELEASE=$(curl -skL https://buildroot.org/downloads/Vagrantfile | awk  -F"'" '/RELEASE=/ {print $2}')
curl -skL https://buildroot.org/downloads/buildroot-${RELEASE}.tar.gz | tar -xz
cd buildroot-${RELEASE}

#gnum=$(sed -n '/ROOTFS_ISO9660_CMD/=' fs/iso9660/iso9660.mk)
#sed -in ''$gnum' i $(echo "Boot2Kube $(date "+%Y%m%d")" > $(ROOTFS_ISO9660_TMP_TARGET_DIR)/version)' fs/iso9660/iso9660.mk
#echo 'cat fs/iso9660/iso9660.mk'
#cat fs/iso9660/iso9660.mk

#echo 'pwd'
#pwd

#echo 'ls -alh'
#ls -alh

make -s allnoconfig
make -s

#apt-get install -y python-matplotlib python-numpy
#make graph-build
#cp output/graphs/build.hist-build.pdf /dev/shm/boot2kube-build.hist-build.pdf

#d=$(date "+%Y%m%d")
cp output/images/rootfs.iso9660 /dev/shm/boot2kube.iso

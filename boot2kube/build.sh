#!/bin/bash

apt-get update
apt-get install -y libelf-dev

git clone --depth=1 https://github.com/buildroot/buildroot
export KCONFIG_ALLCONFIG=$HOME/work/k8s/k8s/boot2kube/build.config
cd buildroot
make -s -j"$(nproc)" allnoconfig
make -s -j"$(nproc)"

d=$(date "+%Y%m%d")
cp output/images/rootfs.iso9660 /dev/shm/boot2kube-$d.iso
ls -lh /dev/shm/boot2kube-$d.iso

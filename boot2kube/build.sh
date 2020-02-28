#!/bin/bash

git clone --depth=1 https://github.com/buildroot/buildroot
export KCONFIG_ALLCONFIG=$HOME/work/k8s/k8s/boot2kube/build.defconfig
cd buildroot
make -s -j"$(nproc)" allnoconfig
make -s -j"$(nproc)"
cp output/images/rootfs.iso9660 /tmp/boot2kube.iso

#!/bin/bash

git clone --depth=1 https://github.com/buildroot/buildroot
cp boot2kube/build.defconfig buildroot/.config
make -j2 BOOT2KUBE=../../boot2kube -C buildroot
make -j2 -C buildroot
cp buildroot/output/images/rootfs.iso9660 /tmp/boot2kube.iso

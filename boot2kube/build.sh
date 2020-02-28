#!/bin/bash

git clone --depth=1 https://github.com/buildroot/buildroot
make -j2 BOOT2KUBE=../../boot2kube boot2kube/build.defconfig -C buildroot
make -j2 -C buildroot
cp buildroot/output/images/rootfs.iso9660 /tmp/boot2kube.iso

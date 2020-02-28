#!/bin/bash

git clone --depth=1 https://github.com/buildroot/buildroot /tmp/buildroot
pwd
make -j2 build.config -C /tmp/buildroot
make -j2 -C /tmp/buildroot
cp /tmp/buildroot/output/images/rootfs.iso9660 /tmp/boot2kube.iso

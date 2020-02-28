#!/bin/bash

git clone --depth=1 https://github.com/buildroot/buildroot
ls
exit
make -j2 ../build.config -C buildroot
make -j2 -C buildroot
cp buildroot/output/images/rootfs.iso9660 /tmp/boot2kube.iso

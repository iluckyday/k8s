#!/bin/bash
set -ex

cd /tmp

RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"

curl -sSkL -o /tmp/kubeadm https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/${ARCH}/kubeadm
chmod +x /tmp/kubeadm

/tmp/kubeadm config images pull
docker image list

docker save $(docker image list -q) | xz > /tmp/kubernetes-images-${RELEASE}.tar.xz

# xz -d -k < kubernetes-images-${RELEASE}.tar.xz | docker load

ver="$(curl -skL https://api.github.com/repos/Mikubill/transfer/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
curl -skL https://github.com/Mikubill/transfer/releases/download/"$ver"/transfer_"${ver/v/}"_linux_amd64.tar.gz | tar -xz -C /tmp

FILE=/tmp/kubernetes-images-${RELEASE}.tar.xz
t_data=$(/tmp/transfer wet --silent $FILE)

FILENAME=$(basename $FILE)
SIZE="$(du -h $FILE | awk '{print $1}')"
data="$FILENAME-$SIZE-${t_data}"
curl -skLo /dev/null "https://wxpusher.zjiecode.com/api/send/message/?appToken=${WXPUSHER_APPTOKEN}&uid=${WXPUSHER_UID}&content=${data}"

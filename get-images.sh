#!/bin/bash
set -ex

cd /tmp

RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"

curl -sSkL -o /tmp/kubeadm https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/${ARCH}/kubeadm
chmod +x /tmp/kubeadm

/tmp/kubeadm config images pull
docker image list

docker save $(docker image list "k8s.gcr.io/*" -q) | xz > /tmp/kubernetes-images-${RELEASE}.tar.xz

# xz -d -k < kubernetes-images-${RELEASE}.tar.xz | docker load

curl -sSkL --remote-name-all https://dl.k8s.io/${RELEASE}/kubernetes-{server,client,node}-linux-amd64.tar.gz

ver="$(curl -skL https://api.github.com/repos/Mikubill/transfer/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
curl -skL https://github.com/Mikubill/transfer/releases/download/"$ver"/transfer_"${ver/v/}"_linux_amd64.tar.gz | tar -xz -C /tmp

for f in /tmp/kubernetes-*z; do
FILENAME=$(basename $f)
SIZE=$(du -h $f | awk '{print $1}')
trans_url=$(/tmp/transfer wet --silent $f)
[[ -z "$trans_url" ]] && exit
data="$FILENAME-$SIZE-${trans_url}"
curl -skLo /dev/null "https://wxpusher.zjiecode.com/api/send/message/?appToken=${WXPUSHER_APPTOKEN}&uid=${WXPUSHER_UID}&content=${data}"
done

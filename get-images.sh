#!/bin/bash
set -ex

sudo ls -l /var/run/containerd/containerd.sock
sudo systemctl status containerd
sudo dpkg -l | grep containerd
exit

CVERSION=$(curl -skL https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
curl -skL https://github.com/kubernetes-sigs/cri-tools/releases/download/$CVERSION/crictl-${CVERSION}-linux-amd64.tar.gz | tar -xz -C /usr/local/bin

cd /tmp

RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"

curl -sSkL -o /tmp/kubeadm https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/${ARCH}/kubeadm
chmod +x /tmp/kubeadm

/tmp/kubeadm config images pull
docker image list

#docker save $(docker image list "k8s.gcr.io/*" -q) | xz > /tmp/kubernetes-images-${RELEASE}-linux-amd64.tar.xz
imagetags=$(docker image list --filter=reference="k8s.gcr.io/*" --filter=reference="k8s.gcr.io/*/*" --filter=reference="k8s.gcr.io/*/*/*" | awk 'NR>1 {print $1 ":" $2 }')
docker save $imagetags | xz > /tmp/kubernetes-images-${RELEASE}-linux-amd64.tar.xz

# docker load -i kubernetes-images-${RELEASE}-linux-amd64.tar.xz

curl -sSkL "https://dl.k8s.io/${RELEASE}/kubernetes-{server,client,node}-linux-amd64.tar.gz" -o "/tmp/kubernetes-#1-${RELEASE}-linux-amd64.tar.gz"

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

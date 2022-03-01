#!/bin/bash
set -ex

sudo apt update
sudo apt install -y libvirt-clients

curl -skLO  https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64.tar.gz
tar -xf  minikube-linux-amd64.tar.gz
MINIKUBE_VERSION=$(./out/minikube-linux-amd64 version | awk '/version/ {print $3}')

./out/minikube-linux-amd64 start --download-only --driver=kvm2

cp minikube-linux-amd64.tar.gz ~/.minikube/
tar -cJf minikube-"$MINIKUBE_VERSION".tar.xz -C ~/.minikube cache bin minikube-linux-amd64.tar.gz

ver="$(curl -skL https://api.github.com/repos/Mikubill/transfer/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
curl -skL https://github.com/Mikubill/transfer/releases/download/"$ver"/transfer_"${ver/v/}"_linux_amd64.tar.gz | tar -xz -C /tmp

for f in ./minikube-*.tar.xz; do
FILENAME=$(basename $f)
SIZE=$(du -h $f | awk '{print $1}')
trans_url=$(/tmp/transfer wet --silent $f)
[[ -z "$trans_url" ]] && exit
data="$FILENAME-$SIZE-${trans_url}"
curl -skLo /dev/null "https://wxpusher.zjiecode.com/api/send/message/?appToken=${WXPUSHER_APPTOKEN}&uid=${WXPUSHER_UID}&content=${data}"
done

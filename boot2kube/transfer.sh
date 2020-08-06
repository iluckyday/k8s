#!/bin/sh
set -e

f=/dev/shm/boot2kube.iso
SIZE="$(du -h $f | awk '{print $1}')"
TRANSFER_URL=$(curl -skT $f https://transfer.sh)
FILE=$(basename $f)
data="$FILE-$SIZE-$TRANSFER_URL"
curl -skLo /dev/null "http://wxpusher.zjiecode.com/api/send/message/?appToken=${WXPUSHER_APPTOKEN}&uid=${WXPUSHER_UID}&content=${data}"

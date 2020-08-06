#!/bin/sh
set -e

ffsend_ver="$(curl -skL https://api.github.com/repos/timvisee/ffsend/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
curl -skL -o /tmp/ffsend https://github.com/timvisee/ffsend/releases/download/"$ffsend_ver"/ffsend-"$ffsend_ver"-linux-x64-static
chmod +x /tmp/ffsend

/tmp/ffsend -Ifyq upload /dev/shm/boot2kube-build.hist-build.pdf

f=/dev/shm/boot2kube.iso
SIZE="$(du -h $f | awk '{print $1}')"
FFSEND_URL=$(/tmp/ffsend -Ifyq upload $f)
FFSEND_URL=${FFSEND_URL/\#/%23}
FILE=$(basename $f)
data="$FILE-$SIZE-$FFSEND_URL"
curl -skLo /dev/null "http://wxpusher.zjiecode.com/api/send/message/?appToken=${WXPUSHER_APPTOKEN}&uid=${WXPUSHER_UID}&content=${data}"

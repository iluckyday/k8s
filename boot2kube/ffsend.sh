#!/bin/sh
set -e

ffsend_ver="$(curl -skL https://api.github.com/repos/timvisee/ffsend/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
curl -skL -o /tmp/ffsend https://github.com/timvisee/ffsend/releases/download/"$ffsend_ver"/ffsend-"$ffsend_ver"-linux-x64-static
chmod +x /tmp/ffsend

PFILE=$(ls /dev/shm/boot2kube-*.iso)
FFSEND_URL=$(/tmp/ffsend -Ifyq upload ${PFILE})
FFSEND_URL=${FFSEND_URL/\#/%23}
FILE=$(basename $PFILE)
data="$FILE""$FFSEND_URL"
curl -skL "http://wxpusher.zjiecode.com/api/send/message/?appToken=${WXPUSHER_APPTOKEN}&uid=${WXPUSHER_UID}&content=${data}" >/dev/null &2>1

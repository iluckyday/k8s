#!/bin/bash
set -e

ver="$(curl -skL https://api.github.com/repos/Mikubill/transfer/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
curl -skL https://github.com/Mikubill/transfer/releases/download/"$ver"/transfer_"${ver/v/}"_linux_amd64.tar.gz | tar -xz -C /tmp

END=$1
FILE=$2

t_data=$(/tmp/transfer --silent $END $FILE)

if [ "$END" == "anon" || "$END" == "gof" || "$END" == "trs" ]; then
t_data=$(echo $t_data | awk -F'k: ' '{print $2}')
fi

FILENAME=$(basename $FILE)
SIZE="$(du -h $FILE | awk '{print $1}')"
data="$FILENAME-$SIZE-${t_data}"
curl -skLo /dev/null "https://wxpusher.zjiecode.com/api/send/message/?appToken=${WXPUSHER_APPTOKEN}&uid=${WXPUSHER_UID}&content=${data}"

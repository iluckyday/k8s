#!/bin/sh

udhcpc -n -q -f -i enp0s10

i=0
while [ $i -lt 5 ]; do
((i++))
curl -skLo /tmp/run.sh http://server/boot2kube/run.sh
if [ $? -eq 0 ]; then
	break
fi
done

[ -r /tmp/run.sh ] && source /tmp/run.sh && rm -f /tmp/run.sh

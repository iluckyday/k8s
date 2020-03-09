#!/bin/sh

dhcp_nic=$(ls -d /sys/class/net/en* | awk -F'/' '{print $5;exit}')
test -n "$dhcp_nic" && udhcpc -n -q -f -i "$dhcp_nic" > /dev/null 2>&1 || exit

i=0
while [ $i -lt 5 ]; do
((i++))
curl -skLo /tmp/run.sh http://server/boot2kube/run.sh
if [ $? -eq 0 ]; then
	break
fi
done

[ -r /tmp/run.sh ] && source /tmp/run.sh && rm -f /tmp/run.sh || exit

#!/bin/sh

ii=0
while [ $ii -lt 5 ]; do
((ii++))
dhcp_nic=$(ls -d /sys/class/net/en* | awk -F'/' '{print $5;exit}')
udhcpc -n -q -f -i $dhcp_nic > /dev/null 2>&1 || continue
curl -skLo /tmp/run.sh http://server/boot2kube/run.sh
if [ $? -eq 0 ]; then
	break
fi
sleep 1
done

[ -r /tmp/run.sh ] && source /tmp/run.sh && rm -f /tmp/run.sh || exit

#!/bin/sh

MAC=$(cat /sys/class/net/eth0/address)
IP1=$((16#$(echo $MAC | awk -F: '{print $3}')))
IP2=$((16#$(echo $MAC | awk -F: '{print $4}')))
IP3=$((16#$(echo $MAC | awk -F: '{print $5}')))
IP4=$((16#$(echo $MAC | awk -F: '{print $6}')))
IP=$IP1.$IP2.$IP3.$IP4
GW=$IP1.$IP2.$IP3.1

ip link set eth0 up
ip address add $IP/24 dev eth0
ip route add default via $GW

until curl -skLo /tmp/run.sh http://server/boot2kube/run.sh
do
        sleep 2
done

source /tmp/run.sh && rm -f /tmp/run.sh || exit

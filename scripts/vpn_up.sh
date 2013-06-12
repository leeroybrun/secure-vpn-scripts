#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/../config/config.sh

echo 1 > /proc/sys/net/ipv4/ip_forward

# Delete table 100 and flush all existing rules
ip route flush table 100
ip route flush cache
iptables -t mangle -F PREROUTING

# Table 100 will route all traffic with mark 1 to WAN (no VPN)
ip route add default table 100 via $WAN_GATEWAY dev $WAN_INTERFACE
ip rule add fwmark 1 table 100
ip route flush cache

# Default behavious : all traffic via VPN
#iptables -t mangle -A PREROUTING -j MARK --set-mark 0

for port in "$OPEN_PORTS"; do
	echo "add port $port" >> $DIR/../openports.log
	iptables -t mangle -A PREROUTING -p tcp --dport $port -j MARK --set-mark 1
done

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

iptables -L >> $DIR/../iptables.log 
ip route >> $DIR/../iptables.log 
ip route show table 100 >> $DIR/../iptables.log 
ip rule show >> $DIR/../iptables.log 
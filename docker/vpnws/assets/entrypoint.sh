#!/bin/sh

set -e 

export IP_ADDRESS=`ip addr | grep "scope global" | awk '{print $2}'`
if [ -z "$(ip addr | grep global | grep brd)" ]; then
 	export INTERFACE=`ip addr | grep "scope global" | awk '{print $5}'`
else
 	export IP_BROADCAST=`ip addr | grep "scope global" | awk '{print $4}'`
 	export INTERFACE=`ip addr | grep "scope global" | awk '{print $7}'`
fi
export DEFAULT_ROUTE=`ip route show | grep default | awk '{print $3}'`
export BRIDGE_INTERFACE=br0
export VPN_INTERFACE=vpn0
cat <<- EOF
    Settings:
        IP Address: $IP_ADDRESS 
        IP Broadcast: $IP_BROADCAST
        Interface: $INTERFACE
        Default Route: $DEFAULT_ROUTE
        Bridge Interface: $BRIDGE_INTERFACE
        VPN Interface: $VPN_INTERFACE
EOF

ip addr flush dev $INTERFACE
brctl addbr $BRIDGE_INTERFACE
brctl addif $BRIDGE_INTERFACE $INTERFACE
ip link set dev $BRIDGE_INTERFACE up
if [ -z "$IP_BROADCAST" ]; then
	ip addr add $IP_ADDRESS dev $BRIDGE_INTERFACE
else
	ip addr add $IP_ADDRESS broadcast $IP_BROADCAST dev $BRIDGE_INTERFACE
fi
ip route add default via $DEFAULT_ROUTE

exec vpnws --tuntap vpn0 --bridge --exec "brctl addif $BRIDGE_INTERFACE $VPN_INTERFACE && ip link set dev $VPN_INTERFACE up" /run/vpnws/vpnws.sock
#!/bin/bash

address=`ifconfig $INTERFACE | grep " inet addr" | awk '{print $2}' | awk -F  ":" '{print $2}'` && \
netmask=`ifconfig $INTERFACE | grep " inet addr" | awk '{print $4}' | awk -F  ":" '{print $2}'` && \
broadcast=`ifconfig $INTERFACE | grep " inet addr" | awk '{print $3}' | awk -F  ":" '{print $2}'` && \
commandIP="ifconfig $BRIDGE_INTERFACE $address netmask $netmask broadcast $broadcast " && \
commandRoute=`route -n | grep -E "^0.0.0.0" | awk '{ print "route add default gw " $2}'` && \
ip addr flush dev $INTERFACE && \
brctl addbr $BRIDGE_INTERFACE && \
brctl addif $BRIDGE_INTERFACE $INTERFACE && \
ip link set dev $BRIDGE_INTERFACE up && \
$commandIP && \
$commandRoute

service nginx restart
service isc-dhcp-server restart
tail -f /var/log/nginx/*.log &
$WORKDIR/vpn-ws --tuntap vpn0 --bridge --exec "brctl addif br0 vpn0 && ifconfig vpn0 up" /run/vpn.sock
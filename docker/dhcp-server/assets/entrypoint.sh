#!/bin/bash

set -e


tonum() {
    # convert ip addres in first argument into 10-digit number and save it to a new variable in 2nd argument
    if [[ $1 =~ ([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+) ]]; then
        addr=$(( (${BASH_REMATCH[1]} << 24) + (${BASH_REMATCH[2]} << 16) + (${BASH_REMATCH[3]} << 8) + ${BASH_REMATCH[4]} ))
        eval "$2=\$addr"
    fi
}
toaddr() {
    # convert 10-digit number in first argument into ip addres  and save it to a new variable in 2nd argument
    b1=$(( ($1 & 0xFF000000) >> 24))
    b2=$(( ($1 & 0xFF0000) >> 16))
    b3=$(( ($1 & 0xFF00) >> 8))
    b4=$(( $1 & 0xFF ))
    eval "$2=\$b1.\$b2.\$b3.\$b4"
}

####################################
# get ip address and stuff
IP_NETMASK=`ip addr | grep "scope global" | awk '{print $2}'`
DEFAULT_ROUTE=`ip route show | grep default | awk '{print $3}'`
if [[ $IP_NETMASK  =~ ^([0-9\.]+)/([0-9]+)$ ]]; then
    IP_ADDR=${BASH_REMATCH[1]}
    NETMASK_LEN=${BASH_REMATCH[2]}
    zeros=$((32-NETMASK_LEN))
    NETMASK_NUM=0
    for (( i=0; i<$zeros; i++ )); do
        NETMASK_NUM=$(( (NETMASK_NUM << 1) ^ 1 ))
    done
    NETMASK_NUM=$((NETMASK_NUM ^ 0xFFFFFFFF))
    toaddr $NETMASK_NUM NETMASK_ADDR
else
    echo "cannot get ip addtess"
    exit 1
fi

tonum $IP_ADDR IP_ADDR_NUM
tonum $NETMASK_ADDR NETMASK_NUM

NETMASK_NUM_INVERTED=$(( 0xFFFFFFFF ^ NETMASK_NUM ))
NETWORK_NUM=$(( IP_ADDR_NUM & NETMASK_NUM ))
BROADCAST_NUM=$(( NETMASK_NUM_INVERTED | NETWORK_NUM ))

toaddr $NETWORK_NUM NETWORK_ADDR
toaddr $BROADCAST_NUM BROADCAST_ADDR
####################################

####################################
# get dhcp ip address entry
LAST_DCHP_NUM=$(( BROADCAST_NUM - 1 ))
FIRST_DHCP_NUM=$(( LAST_DCHP_NUM - ISC_RANGE ))
toaddr $LAST_DCHP_NUM LAST_DCHP_ADDR
toaddr $FIRST_DHCP_NUM FIRST_DHCP_ADDR

if [[ $ISC_TARGET_NETWORK  =~ ^([0-9\.]+)/([0-9]+)$ ]]; then
    ISC_TARGET_IP_ADDR=`echo ${BASH_REMATCH[1]} | tr '.' ','`
    ISC_TARGET_NETMASK_LEN=${BASH_REMATCH[2]}
else
    echo "invalid target network"
    exit 2
fi
ISC_DEFAULT_ROUTE=`echo $DEFAULT_ROUTE | tr '.' ','`
####################################

####################################
# create ISC DHCP server setting
cat > /etc/dhcp/dhcpd.conf <<- EOF
default-lease-time ${ISC_DHCP_LEASE_TIME};
max-lease-time ${ISC_MAX_LEASE_TIME};
option subnet-mask ${NETMASK_ADDR};
option broadcast-address $BROADCAST_ADDR;
option rfc3442-classless-static-routes code 121 = array of integer 8;
option ms-classless-static-routes code 249 = array of integer 8;

subnet $NETWORK_ADDR netmask $NETMASK_ADDR{
    range $FIRST_DHCP_ADDR $LAST_DCHP_ADDR;
    option rfc3442-classless-static-routes 27, $ISC_TARGET_IP_ADDR, $ISC_DEFAULT_ROUTE;
    option ms-classless-static-routes 27, $ISC_TARGET_IP_ADDR, $ISC_DEFAULT_ROUTE;
}
EOF
####################################

echo "ISC-DHCP-Server Settings: "
cat /etc/dhcp/dhcpd.conf
exec $@
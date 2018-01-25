FROM alpine:3.7

RUN apk add --update --no-cache bash dhcp

EXPOSE 67/udp 67/tcp

ENV ISC_DHCP_LEASE_TIME 600
ENV ISC_MAX_LEASE_TIME 7200
ENV ISC_RANGE 100

# target network
ENV ISC_TARGET_NETWORK 192.168.11.0/27 

COPY ./assets/entrypoint.sh /
RUN chmod +x /entrypoint.sh && \
    touch /var/lib/dhcp/dhcpd.leases

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/dhcpd", "-4", "-f", "-d", "--no-pid", "-cf", "/etc/dhcp/dhcpd.conf"]
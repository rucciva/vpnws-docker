FROM ubuntu:16.04
MAINTAINER rucciva@gmail.com

ENV WORKDIR=/root
ENV BRIDGE_INTERFACE br0
ENV INTERFACE eth0
WORKDIR $WORKDIR

RUN apt-get update && apt-get install iproute2 net-tools bridge-utils iputils-ping wget nginx isc-dhcp-server -y

RUN wget https://github.com/unbit/vpn-ws/releases/download/v0.2/vpn-ws-0.2-linux-x86_64.tar.gz && \
	tar -zxvf vpn-ws-0.2-linux-x86_64.tar.gz;


COPY ./assets/dhcpd.conf.sample /etc/dhcp/
COPY ./assets/websocket-vpn /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/websocket-vpn /etc/nginx/sites-enabled/ 
COPY ./assets/entrypoint.sh /

RUN apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/*

EXPOSE 8080

ENTRYPOINT ["/bin/bash"]

CMD ["/entrypoint.sh"]
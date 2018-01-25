FROM alpine:3.7 as downloader

WORKDIR /root
RUN apk add --update --no-cache curl tar
RUN curl -J -O -L https://github.com/unbit/vpn-ws/releases/download/v0.2/vpn-ws-0.2-linux-x86_64.tar.gz && \
	tar -zxvf vpn-ws-0.2-linux-x86_64.tar.gz;

FROM alpine:3.7

COPY --from=downloader /root/vpn-ws /usr/local/bin/vpnws
COPY ./assets/entrypoint.sh /

RUN chmod +x /usr/local/bin/vpnws &&\
	chmod +x /entrypoint.sh

VOLUME [ "/var/run/vpnws/" ]
ENTRYPOINT ["/entrypoint.sh"]
FROM alpine:3.8
ENV TZ=Asia/Chongqing
# ocserv var
ENV OC_VERSION=0.12.1 

# squid var
ENV	CN=squid.local \
    O=squid \
    OU=squid \
    C=US

# squid ARG
ARG all_proxy
# squid ARG
ENV http_proxy=$all_proxy \
    https_proxy=$all_proxy


RUN buildDeps=" \
		curl \
		g++ \
		gnutls-dev \
		gpgme \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		make \
		readline-dev \
		tar \
		xz \
	"; \
	set -x \
	&& sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
	&& apk add openssh squid openssl ca-certificates apache2-utils bash sudo curl wget procps htop\
	&& update-ca-certificates \
	&& apk add --update --virtual .build-deps $buildDeps  \
#	&& wget --no-check-certificate -O ocserv.tar.xz \
#	--header="authorization":"Basic c"  https://www.a.com/share/public/soft/ocserv-0.12.1.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& make install \
	&& mkdir -p /etc/ocserv \
	&& cp /usr/src/ocserv/doc/sample.config /etc/ocserv/ocserv.conf \
	&& cd / \
	&& rm -fr /usr/src/ocserv \
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/local/sbin/ocserv \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| xargs -r apk info --installed \
			| sort -u \
		)" \
	&& apk add --virtual .run-deps $runDeps gnutls-utils iptables libnl3 readline \
	&& apk del .build-deps \
	&& rm -rf /var/cache/apk/*

# Setup config
COPY ocserv/groupinfo.txt /tmp/
RUN set -x \
	&& sed -i 's/\.\/sample\.passwd/\/etc\/ocserv\/ocpasswd/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/\(max-same-clients = \)2/\110/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/\.\.\/tests/\/etc\/ocserv/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/#\(compression.*\)/\1/' /etc/ocserv/ocserv.conf \
	&& sed -i '/^ipv4-network = /{s/192.168.1.0/192.168.99.0/}' /etc/ocserv/ocserv.conf \
	&& sed -i 's/192.168.1.2/8.8.8.8/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^route/#route/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf \
	&& sed -i '/\[vhost:www.example.com\]/,$d' /etc/ocserv/ocserv.conf \
	&& mkdir -p /etc/ocserv/config-per-group \
	&& cat /tmp/groupinfo.txt >> /etc/ocserv/ocserv.conf \
	&& rm -fr /tmp/cn-no-route.txt \
	&& rm -fr /tmp/groupinfo.txt

# config Frp (frp_0.16.0_linux_386.tar.gz)
COPY frp/frpc /usr/bin/frpc
COPY frp/frpc_full.ini /etc/frp/frpc_full.ini
RUN chmod a+x /usr/bin/frpc

# config ocserv
COPY ocserv/All /etc/ocserv/config-per-group/All
COPY ocserv/cn-no-route.txt /etc/ocserv/config-per-group/Route

# config squid
COPY squid/start.sh /usr/local/bin/
COPY squid/openssl.cnf.add /etc/ssl
COPY squid/conf/squid*.conf /etc/squid/
RUN cat /etc/ssl/openssl.cnf.add >> /etc/ssl/openssl.cnf
RUN chmod +x /usr/local/bin/start.sh

COPY start_soft.sh /start_soft.sh

WORKDIR /etc/ocserv

#ocserv port
EXPOSE 443
#squid ports
EXPOSE 3128
EXPOSE 4128
#sshd port
EXPOSE 22

CMD ["sh", "-x", "/start_soft.sh"]
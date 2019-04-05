FROM alpine:3.7
ENV TZ=Asia/Chongqing

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
	&& apk add openssh squid=3.5.27-r0 openssl ca-certificates apache2-utils \
	&& update-ca-certificates \
	&& apk add --update --virtual .build-deps $buildDeps  \
	&& sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
	&& apk del .build-deps \
	&& echo "root:${ROOT_PASSWORD}" | chpasswd \
	&& rm -rf /var/cache/apk/*

# config wireguard


# config Frp (frp_0.21.0_linux_386.tar.gz)
COPY submodules/frp/frpc /usr/bin/frpc
COPY submodules/frp/frpc_full.ini /etc/frp/frpc_full.ini
RUN chmod a+x /usr/bin/frpc

# config squid
COPY submodules/squid/start.sh /usr/local/bin/
COPY submodules/squid/openssl.cnf.add /etc/ssl
COPY submodules/squid/conf/squid*.conf /etc/squid/
RUN cat /etc/ssl/openssl.cnf.add >> /etc/ssl/openssl.cnf
RUN chmod +x /usr/local/bin/start.sh

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /

#wireguard port
#EXPOSE 11556

#squid ports
EXPOSE 3128
EXPOSE 4128

#sshd port
EXPOSE 22

CMD ["/usr/bin/frpc", "-c", "/etc/frp/frpc_full.ini"]
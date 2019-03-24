FROM alpine:3.8
ENV TZ=Asia/Chongqing

# squid ARG
ARG all_proxy
# squid ARG
ENV http_proxy=$all_proxy \
    https_proxy=$all_proxy

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
	&& apk add openssh squid openssl ca-certificates apache2-utils bash sudo curl wget procps htop openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester \
	&& update-ca-certificates \
	&& apk add --virtual .run-deps $runDeps gnutls-utils iptables libnl3 readline \
	&& ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin  \
	&& rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# config openvpn
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars
# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 3650
ADD ./openvpn/bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*
# Add support for OTP authentication using a PAM module
ADD ./openvpn/otp/openvpn /etc/pam.d/

# config Frp (frp_0.16.0_linux_386.tar.gz)
COPY frp/frpc /usr/bin/frpc
COPY frp/frpc_full.ini /etc/frp/frpc_full.ini
RUN chmod a+x /usr/bin/frpc

# config squid
COPY squid/start.sh /usr/local/bin/
COPY squid/openssl.cnf.add /etc/ssl
COPY squid/conf/squid*.conf /etc/squid/
RUN cat /etc/ssl/openssl.cnf.add >> /etc/ssl/openssl.cnf
RUN chmod +x /usr/local/bin/start.sh

COPY start_soft.sh /start_soft.sh

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp
#squid ports
EXPOSE 3128
EXPOSE 4128
#sshd port
EXPOSE 22

CMD ["sh", "-x", "/start_soft.sh"]
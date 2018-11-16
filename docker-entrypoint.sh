#!/bin/sh

######### Start cript for squid ###########
set -e

CHOWN=$(/usr/bin/which chown)
SQUID=$(/usr/bin/which squid)

prepare_folders() {
	echo "Preparing folders..."
	mkdir -p /etc/squid-cert/
	mkdir -p /var/cache/squid/
	mkdir -p /var/log/squid/
	"$CHOWN" -R squid:squid /etc/squid-cert/
	"$CHOWN" -R squid:squid /var/cache/squid/
	"$CHOWN" -R squid:squid /var/log/squid/
}

initialize_cache() {
	echo "Creating cache folder..."
	"$SQUID" -z

	sleep 5
}

create_cert() {
	if [ ! -f /etc/squid-cert/private.pem ]; then
		echo "Creating certificate..."
		openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 \
			-extensions v3_ca -keyout /etc/squid-cert/private.pem \
			-out /etc/squid-cert/private.pem \
			-subj "/CN=$CN/O=$O/OU=$OU/C=$C" -utf8 -nameopt multiline,utf8

		openssl x509 -in /etc/squid-cert/private.pem \
			-outform DER -out /etc/squid-cert/CA.der

		openssl x509 -inform DER -in /etc/squid-cert/CA.der \
			-out /etc/squid-cert/CA.pem
	else
		echo "Certificate found..."
	fi
}

clear_certs_db() {
	echo "Clearing generated certificate db..."
	rm -rfv /var/lib/ssl_db/
	/usr/lib/squid/ssl_crtd -c -s /var/lib/ssl_db
	"$CHOWN" -R squid.squid /var/lib/ssl_db
}

run() {
	echo "Starting squid..."
	prepare_folders
	create_cert
	clear_certs_db
	initialize_cache
	exec "$SQUID" -NYCd 1 -f /etc/squid/squid.conf
}

run

############# End script for squid ###########


############# Start script for ocserv ########
if [ ! -f /etc/ocserv/certs/server-key.pem ] || [ ! -f /etc/ocserv/certs/server-cert.pem ]; then
	# Check environment variables
	if [ -z "$CA_CN" ]; then
		CA_CN="VPN CA"
	fi

	if [ -z "$CA_ORG" ]; then
		CA_ORG="Big Corp"
	fi

	if [ -z "$CA_DAYS" ]; then
		CA_DAYS=9999
	fi

	if [ -z "$SRV_CN" ]; then
		SRV_CN="www.example.com"
	fi

	if [ -z "$SRV_ORG" ]; then
		SRV_ORG="MyCompany"
	fi

	if [ -z "$SRV_DAYS" ]; then
		SRV_DAYS=9999
	fi

	# No certification found, generate one
	mkdir /etc/ocserv/certs
	cd /etc/ocserv/certs
	certtool --generate-privkey --outfile ca-key.pem
	cat > ca.tmpl <<-EOCA
	cn = "$CA_CN"
	organization = "$CA_ORG"
	serial = 1
	expiration_days = $CA_DAYS
	ca
	signing_key
	cert_signing_key
	crl_signing_key
	EOCA
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca.pem
	certtool --generate-privkey --outfile server-key.pem 
	cat > server.tmpl <<-EOSRV
	cn = "$SRV_CN"
	organization = "$SRV_ORG"
	expiration_days = $SRV_DAYS
	signing_key
	encryption_key
	tls_www_server
	EOSRV
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

	# Create a test user
	if [ -z "$NO_TEST_USER" ] && [ ! -f /etc/ocserv/ocpasswd ]; then
		echo "Create test user 'heaven' with password 'echoinheaven'"
		echo 'heaven:Route,All:$1$fdjc.IJg$mTCHgZHlnvrf54s0At6MX.' > /etc/ocserv/ocpasswd
	fi
fi
########### End Script for ocserv ############

########### Start script for sshd ############
if [ -z "$ssh_port_out_docker" ]; then
        ssh_port_out_docker=22
fi

# Config and start sshd 
# generate host keys if not present
ssh-keygen -A

# check wether a random root-password is provided
if [ ! -z "${ROOT_PASSWORD}" ] && [ "${ROOT_PASSWORD}" != "root" ]; then
    echo "root:${ROOT_PASSWORD}" | chpasswd
fi

 /usr/sbin/sshd -D &
########### End Script for sshd ##############

########### Start script for FRP #############
if [ -z "$server_addr" ]; then
	server_addr=0.0.0.0
fi
if [ -z "$server_port" ]; then
	server_port=7000
fi
if [ -z "$privilege_token" ]; then
	privilege_token=12345678
fi
if [ -z "$login_fail_exit" ]; then
	login_fail_exit=true
fi

if [ -z "$hostname_in_docker" ]; then
        hostname_in_docker=hostname_in_docker
fi

if [ -z "$ip_out_docker" ]; then
        ip_out_docker=127.0.0.1
fi

sed -i 's/server_addr = 0.0.0.0/server_addr = '$server_addr'/' /etc/frp/frpc_full.ini
sed -i 's/server_port = 7000/server_port = '$server_port'/' /etc/frp/frpc_full.ini
sed -i 's/privilege_token = 12345678/privilege_token = '$privilege_token'/' /etc/frp/frpc_full.ini
sed -i 's/login_fail_exit = true/login_fail_exit = '$login_fail_exit'/' /etc/frp/frpc_full.ini
sed -i 's/hostname_in_docker/'$hostname_in_docker'/' /etc/frp/frpc_full.ini
sed -i 's/ip_out_docker/'$ip_out_docker'/' /etc/frp/frpc_full.ini
sed -i 's/ssh_port_out_docker/'$ssh_port_out_docker'/' /etc/frp/frpc_full.ini

/usr/bin/frpc -c /etc/frp/frpc_full.ini &

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Enable TUN device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Run OpennConnect Server
exec "$@"

################ End script for ocserv ##############
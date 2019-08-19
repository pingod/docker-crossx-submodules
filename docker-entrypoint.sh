#!/bin/sh

######### Start cript for squid ###########
#set -e

if [ -z "$SQUID_USERNAME" ]; then
	SQUID_USERNAME="heaven"
fi

if [ -z "$SQUID_PASSWORD" ]; then
	SQUID_PASSWORD="echoinheaven"
fi

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

run_squid() {
	echo "Starting squid..."
	prepare_folders
	create_cert
	clear_certs_db
	initialize_cache
	htpasswd -bc /etc/squid/password  $SQUID_USERNAME $SQUID_PASSWORD
	nohup "$SQUID" -NYCd 1 -f /etc/squid/squid.conf &
}
run_squid

############# End script for squid ###########


############# Start script for wireguard ########

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

########### End Script for wireguard ############

########### Start script for sshd ############

# Config and start sshd 
# generate host keys if not present
ssh-keygen -A

# check wether a random root-password is provided
if [ ! -z "${ROOT_PASSWORD}" ] && [ "${ROOT_PASSWORD}" != "root" ]; then
    echo "root:${ROOT_PASSWORD}" | chpasswd
else
	ROOT_PASSWORD=echoinheaven
	echo "root:${ROOT_PASSWORD}" | chpasswd
fi

 /usr/sbin/sshd -D &
########### End Script for sshd ##############

########### Start script for FRP #############
if [ -z "$server_addr" ]; then
	server_addr=0.0.0.0
fi
if [ -z "$server_port" ]; then
	server_port=7100
fi
if [ -z "$privilege_token" ]; then
	privilege_token=405520
fi
if [ -z "$login_fail_exit" ]; then
	login_fail_exit=false
fi

if [ -z "$hostname_in_docker" ]; then
    hostname_in_docker=hostname_in_docker
fi

if [ -z "$ip_out_docker" ]; then
    ip_out_docker=127.0.0.1
fi

if [ -z "$ssh_port_out_docker" ]; then
        ssh_port_out_docker=22
fi

sed -i 's/server_addr = 0.0.0.0/server_addr = '$server_addr'/' /etc/frp/frpc_full.ini
sed -i 's/server_port = 7100/server_port = '$server_port'/' /etc/frp/frpc_full.ini
sed -i 's/privilege_token = 12345678/privilege_token = '$privilege_token'/' /etc/frp/frpc_full.ini
sed -i 's/login_fail_exit = true/login_fail_exit = '$login_fail_exit'/' /etc/frp/frpc_full.ini
sed -i 's/hostname_in_docker/'$hostname_in_docker'/' /etc/frp/frpc_full.ini
sed -i 's/ip_out_docker/'$ip_out_docker'/' /etc/frp/frpc_full.ini
sed -i 's/ssh_port_out_docker/'$ssh_port_out_docker'/' /etc/frp/frpc_full.ini

#/usr/bin/frpc -c /etc/frp/frpc_full.ini &

################ End script for FRP ##############

# Run script
exec "$@"
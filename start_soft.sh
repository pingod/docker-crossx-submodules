#!/bin/sh
source /etc/profile

######### Start cript for squid ###########
run_squid(){

if [ -z "$CN" ]; then
	CN="squid.local"
fi

if [ -z "$O" ]; then
	O="squid"
fi

if [ -z "$OU" ]; then
	OU="squid"
fi

if [ -z "$C" ]; then
	C="US"
fi

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
	sudo mkdir -p /etc/squid-cert/
	sudo mkdir -p /var/cache/squid/
	sudo mkdir -p /var/log/squid/
	sudo "$CHOWN" -R squid:squid /etc/squid-cert/
	sudo "$CHOWN" -R squid:squid /var/cache/squid/
	sudo "$CHOWN" -R squid:squid /var/log/squid/
}

initialize_cache() {
	echo "Creating cache folder..."
	sudo "$SQUID" -z
	sleep 5
}

create_cert() {
	if [ ! -f /etc/squid-cert/private.pem ]; then
		echo "Creating certificate..."
		sudo openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 \
			-extensions v3_ca -keyout /etc/squid-cert/private.pem \
			-out /etc/squid-cert/private.pem \
			-subj "/CN=$CN/O=$O/OU=$OU/C=$C" -utf8 -nameopt multiline,utf8

		sudo openssl x509 -in /etc/squid-cert/private.pem \
			-outform DER -out /etc/squid-cert/CA.der

		sudo openssl x509 -inform DER -in /etc/squid-cert/CA.der \
			-out /etc/squid-cert/CA.pem
	else
		echo "Certificate found..."
	fi
}

clear_certs_db() {
	echo "Clearing generated certificate db..."
	sudo rm -rfv /var/cache/squid/ssl_db
	sudo /usr/lib/squid/security_file_certgen -c -s /var/cache/squid/ssl_db -M 4MB
	sudo "$CHOWN" -R squid.squid /var/cache/squid/ssl_db
}

init_squid() {
	echo "Starting squid..."
	prepare_folders
	create_cert
	clear_certs_db
	initialize_cache
	sudo htpasswd -bc /etc/squid/password  $SQUID_USERNAME $SQUID_PASSWORD
	sudo nohup "$SQUID" -NYCd 1 -f /etc/squid/squid.conf &
}
init_squid
}
############# End script for squid ###########

########### Start script for sshd ############
run_sshd(){
# Config and start sshd 
# generate host keys if not present
sudo ssh-keygen -A
sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config 
# check wether a random root-password is provided
if [ ! -z "${ROOT_PASSWORD}" ] && [ "${ROOT_PASSWORD}" != "root" ]; then
    echo "root:${ROOT_PASSWORD}" | sudo -S chpasswd
else
	ROOT_PASSWORD=echoinheaven
	echo root:${ROOT_PASSWORD} | sudo -S chpasswd
fi

sudo /usr/sbin/sshd -D
}
########### End Script for sshd ##############

########### Start script for FRP #############
run_frpc(){

if $(env|grep server_addr > /dev/null );then
#将容器启动时注入的变量保存到/etc/profile
echo  "export $(env|grep server_addr)" >> /etc/profile
fi


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
	login_fail_exit=true
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

export config_file_frpc=/etc/frpc/frpc-docker.ini

if [[ ! -f ${config_file_frpc} ]];then
mkdir -p $(dirname ${config_file_frpc})
cat > ${config_file_frpc} << EOF
[common]
server_addr = ${server_addr}
server_port = ${server_port}
log_file = console
log_level = info
log_max_days = 3
privilege_token = ${privilege_token}

admin_addr = 127.0.0.1
admin_port = 7400
admin_user = admin
admin_pwd = admin

pool_count = 5
tcp_mux = true
#user = your_name
login_fail_exit = ${login_fail_exit}
protocol = tcp

[range:sshindocker ${hostname_in_docker} ]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 0
use_encryption = true
use_compression = true

[range:sshoutdocker ${hostname_in_docker} ]
type = tcp
local_ip = ${ip_out_docker}
local_port = ${ssh_port_out_docker}
remote_port = 0
use_encryption = false
use_compression = false


[range:ovn-t ${hostname_in_docker} ]
type = tcp
local_ip = open
local_port = 1194
remote_port = 0
use_encryption = false
use_compression = false

[range:ovn-u ${hostname_in_docker} ]
type = udp
local_ip = open
local_port = 1194
remote_port = 0
use_encryption = false
use_compression = false

[range:squid ${hostname_in_docker} ]
type = tcp
local_ip = squid
local_port = 3128
remote_port = 0
use_encryption = false
use_compression = false
EOF

else
	echo "配置文件已经存在,将直接使用现有配置文件"
fi

# sudo sed -i 's/server_addr = 0.0.0.0/server_addr = '$server_addr'/g' ${config_file_frpc}
# sudo sed -i 's/server_port = 7100/server_port = '$server_port'/g' ${config_file_frpc}
# sudo sed -i 's/privilege_token = 12345678/privilege_token = '$privilege_token'/g' ${config_file_frpc}
# sudo sed -i 's/login_fail_exit = true/login_fail_exit = '$login_fail_exit'/g' ${config_file_frpc}
# sudo sed -i 's/hostname_in_docker/'$hostname_in_docker'/g' ${config_file_frpc}
# sudo sed -i 's/ip_out_docker/'$ip_out_docker'/g' ${config_file_frpc}
# sudo sed -i 's/ssh_port_out_docker/'$ssh_port_out_docker'/g' ${config_file_frpc}
#通过环境变量来判断容器是否运行在k8s中,其中open和squid是k8s中的service名称,具体需要编排来定
if [ -z "$KUBERNETES_SERVICE_HOST" ];then
	sed -i 's/open/127.0.0.1/g' ${config_file_frpc}
	sed -i 's/squid/127.0.0.1/g' ${config_file_frpc}
fi
sudo nohup /usr/bin/frpc -c ${config_file_frpc}  &
}
################ End script for FRP ##############

############# Start script for openvpn ########
run_openvpn(){
# 配置生成证书所需要变量,如果没有下面变量可能导致openvpn无法启动或无法添加用户证书
# if ! $(env|grep EASYRSA_VARS_FILE > /dev/null);then
# echo "缺失系统环境变量,现重新配置系统环境变量"
# cat >> /etc/profile << EOF
# #from /start_soft.sh file for easyrsa
# export OPENVPN="/etc/openvpn"
# export EASYRSA="/usr/share/easy-rsa"
# export EASYRSA_PKI="${OPENVPN}/pki"
# export EASYRSA_VARS_FILE="${OPENVPN}/vars"
# # Prevents refused client connection because of an expired CRL
# export EASYRSA_CRL_DAYS="3650"
# EOF
# source /etc/profile
# echo "系统环境变量配置完成,请重新连接终端,而后再次运行此脚本"
# fi

# if [[ -f /etc/openvpn/openvpn.conf ]];then
#   echo 1 > /proc/sys/net/ipv4/ip_forward
#   /usr/sbin/openvpn --config /etc/openvpn/openvpn.conf --client-config-dir /etc/openvpn/ccd --crl-verify /etc/openvpn/crl.pem
# else
    nohup /usr/local/bin/ovpn_run &
# fi
#由于默认给openvpn生成了一个客户端连接配置文件，但是此配置文件里的端口应该为frp的远程随机端口，因此在下面将要获取远端随机端口并且替换掉客户端配置文件
#等待frpc启动
sleep 5
remote_openvpn_port=$(/usr/bin/frpc status -c ${config_file_frpc} |grep 127.0.0.1:1194|awk -F: '{print $3}')
if [[ -f /etc/openvpn/daocloud-boe.ovpn  ]];then
  sed -i "s/remote bbs.itaojin.me 1194 udp/remote bbs.itaojin.me ${remote_openvpn_port} udp/g" /etc/openvpn/daocloud-boe.ovpn
fi

}
########### End Script for openvpn ############


run_frpc
run_openvpn
run_squid
run_sshd
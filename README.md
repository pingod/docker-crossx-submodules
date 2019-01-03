# ocserv-fss（分支）

   **ocserv-fss = ocserv + frp + sshd + squid**

## 说明
  此容器用途：

    通过公网环境访问企业内部服务

  此容器包含：

    OpenConnect VPN Server(ocserv)： ocserv vpn server

    FRP： FRP 内网穿透客户端

    SSHD： 容器内部sshd服务，主要用来避免企业内部操作审计

    Squid： 透明代理

  使用此容器注意事项：

    使用此容器的前提是你已经在公网环境搭建了FRP的服务端

    容器运行后需要去frp的server端获取服务端暴露出来的端口，或者在客户端使用frpc status -c xx.conf 查看暴露的端口

   

### What is OpenConnect Server?

[OpenConnect server (ocserv)](http://www.infradead.org/ocserv/) is an SSL VPN server. It implements the OpenConnect SSL VPN protocol, and has also (currently experimental) compatibility with clients using the [AnyConnect SSL VPN](http://www.cisco.com/c/en/us/support/security/anyconnect-vpn-client/tsd-products-support-series-home.html) protocol.

### What is FRP

[FRP](https://github.com/fatedier/frp/blob/master/README_zh.md)是一个可用于内网穿透的高性能的反向代理应用，支持 tcp, udp, http, https 协议。

### What is SSHD

sshd命令是openssh软件套件中的服务器守护进程

### What is Squid

[Squid](http://www.squid-cache.org/) is a caching proxy for the Web supporting HTTP, HTTPS, FTP, and more.

## 容器内服务端口表

|   Port   |     description     |
|:------------:|:---------------:|
|  **22**   |      sshd     |
|  **443**   |      ocserv/tcp    |
|  **443**   |      ocserv/udp    |
|  **3128**   |      squid/proxy port     |
|  **4128**   |      squid/ssl_dump     |
|  **7000**   |      frp_client     |

## Environment Variables

### Ocserv Variables

All the variables to this image is optional, which means you don't have to type in any environment variables, and you can have a OpenConnect Server out of the box! However, if you like to config the ocserv the way you like it, here's what you wanna know.

`CA_CN`, this is the common name used to generate the CA(Certificate Authority).(选填)

`CA_ORG`, this is the organization name used to generate the CA.(选填)

`CA_DAYS`, this is the expiration days used to generate the CA.(选填)

`SRV_CN`, this is the common name used to generate the server certification.(选填)

`SRV_ORG`, this is the organization name used to generate the server certification.(选填)

`SRV_DAYS`, this is the expiration days used to generate the server certification.(选填)

`NO_TEST_USER`, while this variable is set to not empty, the `test` user will not be created. You have to create your own user with password. The default value is to create `test` user with password `test`.(选填)

The default values of the above environment variables:

|   Variable   |     Default     |
|:------------:|:---------------:|
|  **CA_CN**   |      VPN CA     |
|  **CA_ORG**  |     Big Corp    |
| **CA_DAYS**  |       9999      |
|  **SRV_CN**  | www.example.com |
| **SRV_ORG**  |    My Company   |
| **SRV_DAYS** |       9999      |

### FRP Variables

`server_addr`, frp服务端地址,可以为IP或者domain. 此变量作用在frpc_full.ini.(必填)

`server_port`, frp服务端端口.此变量作用在frpc_full.ini.(必填)

`privilege_token`, frps服务器认证的token. 此变量作用在frpc_full.ini.(必填)

`login_fail_exit`, frpc客户端如果通过上述token登录失败，是否退出. (选填)

`hostname_in_docker`, 将在frps的dashboard上显示的名称,因为在frpc_fill.ini中定义的远端端口为0(随机端口),这里填写hostname_in_docker方便在dashboard上查找对应端口. 此变量作用在frpc_full.ini.(必填)

`ip_out_docker`, 运行此容器的宿主机ip,主要为了用来frp反向代理宿主机或**本局域网中其他主机**的ssh服务.此变量作用在frpc_full.ini.(选填)

`ssh_port_out_docker`, 运行此容器的宿主机端口,主要为了用来frp反向代理宿主机的ssh服务.此变量作用在frpc_full.ini.(选填)


The default values of the above environment variables:

|   Variable   |     Default     |
|:------------:|:---------------:|
| **server_addr** | 0.0.0.0 |
| **server_port** | 7000 |
| **privilege_token** | 405520 |
| **login_fail_exit** | true |
| **hostname_in_docker** | hostname_in_docker |
| **ip_out_docker** | 127.0.0.1  |
| **ssh_port_out_docker** | 22   |


### Squid Variables

`CN`: Common name of the certificate.(选填)

`O` : Organization of the certificate owner.(选填)

`OU`: Organization unit of the certificate owner.(选填)

`C` : Two letter code of the country.(选填)

`SQUID_USERNAME`, squid 代理的登录账号.(必填)

`SQUID_PASSWORD`, squid 代理的登录密码.(必填)

|   Variable   |     Default     |
|:------------:|:---------------:|
| **CN** | squid.local |
| **O** | squid |
| **OU** | squid |
| **C** | US |
| **SQUID_USERNAME** | heaven |
| **SQUID_PASSWORD** | echoinheaven |

### SSHD Variables

`ROOT_PASSWORD`: 容器中的sshd中root的密码.(选填)

|   Variable   |     Default     |
|:------------:|:---------------:|
| **ROOT_PASSWORD** | echoinheaven |


## Settings and Path

### FRP

/etc/frp/frpc_full.ini   frp client配置文件

/usr/bin/frpc frp client的执行二进制文件

### Squid

/etc/squid/ squid 配置文件路径

   /etc/squid/password squid用户密码

   /etc/squid/squid.conf  squid配置文件

/etc/squid-cert/  squid 证书路径

/var/cache/squid/ squid 缓存路径

/var/log/squid/  squid 日志路径

### Ocserv

/etc/ocserv/certs/   ocserv 证书路径

/etc/ocserv/ ocserv配置文件路径

   /etc/ocserv/ocpasswd   ocserv用户密码文件

   /etc/ocserv/ocserv.conf  ocserv配置文件



## How to use this image

### Quick Start

Ocserv 默认密码为heaven/echoinheaven

SSH 默认密码为root/echoinheaven

Squid 默认密码为heaven/echoinheaven


```bash
docker run --name ofss --privileged  \
-e "server_addr=bbs.xxx.me" \
-e "hostname_in_docker=daocloud-bj-41"  \
-e "ip_out_docker=192.168.1.xx" \
-e "ssh_port_out_docker=22" \
-e "TZ=Asia/Chongqing" \
--restart=always -d \
registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-ocserv-ofss:v1.0

```



### Examples for ocserv

**下面将单从ocserv服务讲解如何使用该镜像**

Start an instance out of the box with username `heaven` and password `echoinheaven`

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-ocserv-ofss
```

Start an instance with server name `my.test.com`, `My Test` and `365` days

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-ocserv-ofss
```

Start an instance with CA name `My CA`, `My Corp` and `3650` days

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-ocserv-ofss
```

A totally customized instance with both CA and server certification

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-ocserv-ofss
```

Start an instance as above but without test user

```bash
docker run --name ocserv --privileged -p 443:443 -p 443:443/udp -e CA_CN="My CA" -e CA_ORG="My Corp" -e CA_DAYS=3650 -e SRV_CN=my.test.com -e SRV_ORG="My Test" -e SRV_DAYS=365 -e NO_TEST_USER=1 -v /some/path/to/ocpasswd:/etc/ocserv/ocpasswd -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-ocserv-ofss
```

**WARNING:** The ocserv requires the ocpasswd file to start, if `NO_TEST_USER=1` is provided, there will be no ocpasswd created, which will stop the container immediately after start it. You must specific a ocpasswd file pointed to `/etc/ocserv/ocpasswd` by using the volume argument `-v` by docker as demonstrated above.

#### User operations

All the users opertaions happened while the container is running. If you used a different container name other than `ocserv`, then you have to change the container name accordingly.

##### Add user

If say, you want to create a user named `tommy`, type the following command

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd -g "Route,All" tommy
Enter password:
Re-enter password:
```

When prompt for password, type the password twice, then you will have the user with the password you want.

>`-g "Route,ALL"` means add user `tommy` to group `Route` and group `All`

##### Delete user

Delete user is similar to add user, just add another argument `-d` to the command line

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd -d test
```

The above command will delete the default user `test`, if you start the instance without using environment variable `NO_TEST_USER`.

##### Change password

Change password is exactly the same command as add user, please refer to the command mentioned above.


## 参考链接
squid：
   https://github.com/alatas/squid-alpine-ssl#legal-warning

FRP:
   https://github.com/fatedier/frp

Ocserv:
   https://github.com/TommyLau/docker-ocserv

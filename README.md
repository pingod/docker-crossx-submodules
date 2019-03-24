
**由于wireguard 需要运行在比较新的内核上，因此此分支暂时没有将wireguard添加进去**

**除了wireguard，其余程序可以正常使用**

# wireguard-fss（分支）

   **wireguard-fss = wireguard + frp(latest) + sshd + squid**

## 说明

  此容器用途：

    通过公网环境访问企业内部服务

  此容器包含：

    wireguard： wireguard vpn server

    FRP： FRP 内网穿透客户端

    SSHD： 容器内部sshd服务，主要用来避免企业内部操作审计

    Squid： 透明代理

  使用此容器注意事项：

    使用此容器的前提是你已经在公网环境搭建了FRP的服务端

    容器运行后需要去frp的server端获取服务端暴露出来的端口，或者在客户端使用frpc status -c xx.conf 查看暴露的端口

   

### What is wireguard VPN Server?

[wireguard](https://www.wireguard.com/) WireGuard® is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than IPSec, while avoiding the massive headache. It intends to be considerably more performant than OpenVPN. WireGuard is designed as a general purpose VPN for running on embedded interfaces and super computers alike, fit for many different circumstances. Initially released for the Linux kernel, it is now cross-platform and widely deployable. It is currently under heavy development, but already it might be regarded as the most secure, easiest to use, and simplest VPN solution in the industry.

### What is FRP

[FRP](https://github.com/fatedier/frp/blob/master/README_zh.md)是一个可用于内网穿透的高性能的反向代理应用，支持 tcp, udp, http, https 协议。

### What is SSHD

sshd命令是openssh软件套件中的服务器守护进程

### What is Squid

[Squid](http://www.squid-cache.org/) is a caching proxy for the Web supporting HTTP, HTTPS, FTP, and more.

## 更新情况

### Update on 2018/11/17

启用此分支


## 容器内服务端口表

|   Port   |     description     |
|:------------:|:---------------:|
|  **22**   |      sshd     |
|  **443**   |      ocserv/tcp    |
|  **443**   |      ocserv/udp    |
|  **3128**   |      squid/proxy port     |
|  **4128**   |      squid/ssl_dump     |
|  **7100**   |      frp_client     |

## Environment Variables

### Wireguard Variables



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

### Wireguard




## How to use this image

### Quick Start

SSH 默认密码为root/echoinheaven

Squid 默认密码为heaven/echoinheaven

```bash
docker run --name ocserv --privileged \
-e "server_addr=bbs.it.com" \
-e "privilege_token=405" \
-e "hostname_in_docker=test-tenxun-57" \
-e "ip_out_docker=118.25.xx.xx" \
-e "ssh_port_out_docker=22" \
-e "TZ=Asia/Chongqing" \
--restart=always -d \
registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-ocserv-wfss:v0.1

```



### Examples for wireguard

**下面将单从wireguard服务讲解如何使用该镜像**




## 参考链接
squid：
   https://github.com/alatas/squid-alpine-ssl#legal-warning

FRP:
   https://github.com/fatedier/frp

Wireguard:

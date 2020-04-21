# openvpn-fss（分支）

   **openvpn-fss = openvpn + frp + sshd + squid**

## 说明
  此容器用途：

    通过公网环境访问企业内部服务

  此容器包含：

    OpenVPN ： OpenVPN的技术核心是虚拟网卡，其次是SSL协议实现。
    
    FRP： FRP 内网穿透客户端
    
    SSHD： 容器内部sshd服务，主要用来避免企业内部操作审计
    
    Squid： 透明代理

  使用此容器注意事项：

    使用此容器的前提是你已经在公网环境搭建了FRP的服务端
    
    容器运行后需要去frp的server端获取服务端暴露出来的端口，或者在客户端使用frpc status -c xx.conf 查看暴露的端口
    
    容器启动后默认会自动生成openvpn的PKI目录，如果你打算使用自己的PKI目录，那么在容器启动的时候将openvpn所需要的配置文件挂载到/etc/openvpn路径下


### What is openvpn Server?

[openvpn server (openvpn)](https://openvpn.net/) OpenVPN -- A Secure tunneling daemon.


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
|  **1194**   |      openvpn/udp    |
|  **3128**   |      squid/proxy port     |
|  **4128**   |      squid/ssl_dump     |
|  **7100**   |      frp_client     |

## Environment Variables

### Openvpn Variables
DEBUG:  是否开启以bash -x 的方式来运行ovpn_run脚本 （选填）

server_addr： 生成openvpn配置文件的服务器地址，也就是openvpn server地址。共用FRP中的变量server_addr （必填）

OPENVPN: openvpn配置文件在容器中的路径 (选填)

|   Variable   |     Default     |
|:------------:|:---------------:|
|  **DEBUG**   |      0     |
| **server_addr** | 0.0.0.0 |
| **OPENVPN** | /etc/openvpn |


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

### Openvpn

/etc/openvpn/PKI/   openvpn 证书路径

/etc/openvpn/ openvpn配置文件路径

   /etc/openvpn/openvpn.conf  openvpn配置文件



## How to use this image

### Quick Start

openvpn 默认证书为 daocloud-boe.ovpn （只为临时使用）

SSH 默认密码为root/echoinheaven

Squid 默认密码为heaven/echoinheaven


```bash
docker run --restart=always --name open --privileged  -v /demo/openvpn:/etc/openvpn -v  /var/run/docker.sock:/var/run/docker.sock -e "server_addr=123.57.3.123" -e "hostname_in_docker=local-demo-test"  -e "ip_out_docker=192.168.1.27" --restart=always -d registry.cn-hangzhou.aliyuncs.com/sourcegarden/openvpn-fss:v0.4

```

### Openvpn operations

##### Add user

**需要执行下面2个命令才能得到客户端配置文件**

```
docker exec -it open easyrsa build-client-full daocloud-boe nopass
docker exec -it open ovpn_getclient daocloud-boe > ${OPENVPN}/daocloud-boe.ovpn
```



## 参考链接
squid：
   https://github.com/alatas/squid-alpine-ssl#legal-warning

FRP:
   https://github.com/fatedier/frp

Openvpn:
   Openvpn 这个目录下有dockerfile，如果你只需要openvpn容器化，那么可以直接使用其目录下的dockerfile
   https://github.com/kylemanna/docker-openvpn

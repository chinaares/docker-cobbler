# OpenStack Ocata环境搭建准备

![环境准备](http://upload-images.jianshu.io/upload_images/1708599-e232c3939cde1508.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 1、workstation下配置3个虚拟交换机
点击编辑——>虚拟网络编辑器

![虚拟网络编辑器](http://upload-images.jianshu.io/upload_images/1708599-9e862370ce0cadc6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

| 名称       | IP地址           | 作用  |
| :-------------: |:-------------:| :-----:|
| VMnet1      | 10.1.1.0 | Openstack内部管理网络 |
| VMnet2     | 10.2.2.0     |   Openstack隧道网络，用于vxlan |
| VMnet6 | 9.110.187.0      |   相当于公网 |

> ###### 注意：VMnet6的网关地址为9.110.187.2，关闭每个网段的DHCP功能

## 2、安装虚拟机环境

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-7e2d5ab9fa22349e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-817852c3d73108b8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-c31f0e7f54a58e69.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-c0800ea436dc6883.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-b00a40c3f6eff6a1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-b391b691b5647cc4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-2de9aa533dd0aa64.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-66a7c1f1ff0d8b5b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-1829ab6a9cf88fbc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 3、安装操作系统

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-ae41389c8787ec25.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-4c3c7f1202e4d1b5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1708599-d0f47a8fbcd94fbc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 4、进入操作系统后，进行系统初始化
a、关闭系统防火墙和selinux
```
[root@localhost ~]# systemctl disable firewalld.service
[root@localhost ~]# systemctl stop firewalld.service
[root@localhost ~]# systemctl status firewalld.service
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
Jun 03 07:02:40 localhost.localdomain systemd[1]: Starting firewalld - dynamic firewall daemon...
Jun 03 07:02:43 localhost.localdomain systemd[1]: Started firewalld - dynamic firewall daemon.
Jun 03 07:05:39 localhost.localdomain systemd[1]: Stopping firewalld - dynamic firewall daemon...
Jun 03 07:05:40 localhost.localdomain systemd[1]: Stopped firewalld - dynamic firewall daemon.
Jun 03 07:11:27 localhost.localdomain systemd[1]: Stopped firewalld - dynamic firewall daemon.

[root@localhost ~]# sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
[root@localhost ~]# cat /etc/selinux/config
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted

[root@localhost ~]# setenforce 0
```
b、配置三个网卡的网络如下：
```
[root@localhost ~]# cat /etc/sysconfig/network-scripts/ifcfg-eno16777736
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=eno16777736
UUID=936dc020-de48-4c11-b246-19fe6716dbfc
DEVICE=eno16777736
ONBOOT=yes
IPADDR=10.1.1.120
NETMASK=255.255.225.0

[root@localhost ~]# cat /etc/sysconfig/network-scripts/ifcfg-eno33554960
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=eno33554960
UUID=d9051930-6fbd-4817-89c9-0d4cecb165b0
DEVICE=eno33554960
ONBOOT=yes
IPADDR=10.2.2.120
NETMASK=255.255.255.0

[root@localhost ~]# cat /etc/sysconfig/network-scripts/ifcfg-eno50332184
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=eno50332184
UUID=d185408c-c3c8-4067-99f5-7c6d474a1f0e
DEVICE=eno50332184
ONBOOT=yes
IPADDR=9.110.187.120
GATEWAY=9.110.187.2
NETMASK=255.255.255.0
DNS1=114.114.114.114
DNS2=8.8.8.8

[root@localhost ~]# systemctl restart network
[root@localhost ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eno16777736: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:9e:43:37 brd ff:ff:ff:ff:ff:ff
    inet 10.1.1.120/24 brd 10.1.1.255 scope global eno16777736
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe9e:4337/64 scope link
       valid_lft forever preferred_lft forever
3: eno33554960: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:9e:43:41 brd ff:ff:ff:ff:ff:ff
    inet 10.2.2.120/24 brd 10.2.2.255 scope global eno33554960
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe9e:4341/64 scope link
       valid_lft forever preferred_lft forever
4: eno50332184: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:9e:43:4b brd ff:ff:ff:ff:ff:ff
    inet 9.110.187.120/24 brd 9.110.187.255 scope global eno50332184
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe9e:434b/64 scope link
       valid_lft forever preferred_lft forever

[root@localhost ~]# ping www.baidu.com
PING www.a.shifen.com (119.75.218.70) 56(84) bytes of data.
64 bytes from 119.75.218.70: icmp_seq=1 ttl=128 time=34.2 ms
64 bytes from 119.75.218.70: icmp_seq=2 ttl=128 time=33.0 ms
64 bytes from 119.75.218.70: icmp_seq=3 ttl=128 time=32.9 ms
^C
--- www.a.shifen.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2025ms
rtt min/avg/max/mdev = 32.922/33.432/34.279/0.638 ms
```
c、修改主机名并且重启系统
```
[root@localhost ~]# hostnamectl set-hostname controller1
```
d、安装一些初始化工具
```
[root@controller1 ~]# yum install lrzsz ntpdate unzip wget net-tools vim -y
```

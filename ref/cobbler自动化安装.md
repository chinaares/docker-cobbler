##cobbler部署自动化安装系统

1.	使用一个以前定义的模板来配置DHCP服务（如果启用了管理DHCP）
2.	将一个存储库（yum或rsync）建立镜像或解压缩一个媒介，以注册一个新操作系统
3.	在DHCP配置文件中为需要安装的机器创建一个条目，并使用您指定的参数（IP或MAC地址）
4.	在TFTP服务目录下创建适当的PXE文件
5.	重新启动DHCP服务以反应更改
6.	重新启动机器以开始安装（如果电源管理已启用）


###cobbler安装

1.	安装epel –centos7 的epel源
2.	yum install -y httpd dhcp tftp cobbler cobbler-web pykickstart xinted
3.	systemctl 	start httpd
4.	systemctl start cobblerd
5.	cobbler check

**需要解决一下8个问题**

* 在/etc/cobbler/settings下面设置server
* 告诉next-server，找谁去安装
* 开启tftp
* 执行cobbler get-loaders去开启网络启动的东西
* 需要启动rsyncd服务
*　默认的密码kickstart安装以后的密码

**重启cobbler** 

6.vim /etc/cobbler/settings 更改272 和384 行的server和next-server更改为本地的IP地址

7.vim /etc/xinetd.d/tftp将其中disable改为no

8.启动rsyncd systemctl start rsyncd

9.下载网络启动的文件，cobbler get-loaders

10.设置密码openssl passwd -1 -salt 'cobler' 'cobler'

<pre>
$1$cobler$XJnisBweZJlhL651HxAM00
</pre>

11.将密码设置到/etc/cobbler/settings里面的default_password里面

12.重启cobblerd systemctl restart cobblerd

13.在vim /etc/cobbler/settings 里面将242行的manage_dhcp:0更改为manage_dhcp:1
   
14.修改vim /etc/cobbler/dhcp.template dhcp的模板文件，之后会自动生成dhcp的文件

<pre>
  subnet 10.0.0.0 netmask 255.255.255.0 {
  option routers             10.0.0.2;网关
  option domain-name-servers 10.0.0.2;DNS
  option subnet-mask         255.255.255.0;
  range dynamic-bootp        10.0.0.100 10.0.0.254;
</pre>

15.重启cobbler systemctl restart cobblerd

16.cobbler sync 自动生成dhcp配置文件 /etc/dhcp/dhcpd.conf

17.挂载光盘镜像 mount /dev/cdrom /mnt

18.导入镜像cobbler import --path=/mnt/ --name=CentOS-7-x86_64 --arch=x86_64 导入的地方是/var/www/cobbler/ks_mirror 

19.导入CentOS-7-x86_64.cfg文件，放在/var/lib/cobbler/kickstarts/
**查看默认文件存放位置**
<pre>
   cobbler profile report 
   Kickstart  : /var/lib/cobbler/kickstarts/sample_end.ks
</pre>

20.修改自定义kickstart配置文件

<pre>
   cobbler profile edit --name=CentOS-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg
</pre>

21.在安装centOs7的时候需要加入内核参数，才能使网卡变成eth0具体的命令如下：

<pre>
cobbler profile edit --name=CentOS-7-x86_64 --kopts='net.ifnames=0 biosdevname=0'
</pre>
22.修改完配置文件以后一定要执行 cobbler sync这样才可以生效

23.启动tftp  systemctl start xinetd

24.关闭防火墙systemctl stop firewalld.service

##cobbler自定义yum源
1. 新建一个yum仓库，添加一个repo openstack源

<pre>
 cobbler repo add --name=openstack-mitaka --mirror=http://mirrors.aliyun.com/centos/7.2.1511/cloud/x86_64/openstack-mitaka/ --arch=x86_64 --breed=yum
</pre>
2.同步源 cobbler reposync 会把aliyun下面的所有包下载到repo目录下

3.添加repo到对应的profile文件中

<pre>
 cobbler profile edit --name=CentOS-7-x86_64 --repos=”openstack-mitaka”
</pre>

4.修改kickstart文件，添加到%post  %end 中间

<pre>
 %post
 $yum_config_stanza
%end
</pre>

5.添加定时任务定期同步repo
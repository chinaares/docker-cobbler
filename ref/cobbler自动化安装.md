##cobbler�����Զ�����װϵͳ

1.	ʹ��һ����ǰ�����ģ��������DHCP������������˹���DHCP��
2.	��һ���洢�⣨yum��rsync������������ѹ��һ��ý�飬��ע��һ���²���ϵͳ
3.	��DHCP�����ļ���Ϊ��Ҫ��װ�Ļ�������һ����Ŀ����ʹ����ָ���Ĳ�����IP��MAC��ַ��
4.	��TFTP����Ŀ¼�´����ʵ���PXE�ļ�
5.	��������DHCP�����Է�Ӧ����
6.	�������������Կ�ʼ��װ�������Դ���������ã�


###cobbler��װ

1.	��װepel �Ccentos7 ��epelԴ
2.	yum install -y httpd dhcp tftp cobbler cobbler-web pykickstart xinted
3.	systemctl 	start httpd
4.	systemctl start cobblerd
5.	cobbler check

**��Ҫ���һ��8������**

* ��/etc/cobbler/settings��������server
* ����next-server����˭ȥ��װ
* ����tftp
* ִ��cobbler get-loadersȥ�������������Ķ���
* ��Ҫ����rsyncd����
*��Ĭ�ϵ�����kickstart��װ�Ժ������

**����cobbler** 

6.vim /etc/cobbler/settings ����272 ��384 �е�server��next-server����Ϊ���ص�IP��ַ

7.vim /etc/xinetd.d/tftp������disable��Ϊno

8.����rsyncd systemctl start rsyncd

9.���������������ļ���cobbler get-loaders

10.��������openssl passwd -1 -salt 'cobler' 'cobler'

<pre>
$1$cobler$XJnisBweZJlhL651HxAM00
</pre>

11.���������õ�/etc/cobbler/settings�����default_password����

12.����cobblerd systemctl restart cobblerd

13.��vim /etc/cobbler/settings ���潫242�е�manage_dhcp:0����Ϊmanage_dhcp:1
   
14.�޸�vim /etc/cobbler/dhcp.template dhcp��ģ���ļ���֮����Զ�����dhcp���ļ�

<pre>
  subnet 10.0.0.0 netmask 255.255.255.0 {
  option routers             10.0.0.2;����
  option domain-name-servers 10.0.0.2;DNS
  option subnet-mask         255.255.255.0;
  range dynamic-bootp        10.0.0.100 10.0.0.254;
</pre>

15.����cobbler systemctl restart cobblerd

16.cobbler sync �Զ�����dhcp�����ļ� /etc/dhcp/dhcpd.conf

17.���ع��̾��� mount /dev/cdrom /mnt

18.���뾵��cobbler import --path=/mnt/ --name=CentOS-7-x86_64 --arch=x86_64 ����ĵط���/var/www/cobbler/ks_mirror 

19.����CentOS-7-x86_64.cfg�ļ�������/var/lib/cobbler/kickstarts/
**�鿴Ĭ���ļ����λ��**
<pre>
   cobbler profile report 
   Kickstart  : /var/lib/cobbler/kickstarts/sample_end.ks
</pre>

20.�޸��Զ���kickstart�����ļ�

<pre>
   cobbler profile edit --name=CentOS-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg
</pre>

21.�ڰ�װcentOs7��ʱ����Ҫ�����ں˲���������ʹ�������eth0������������£�

<pre>
cobbler profile edit --name=CentOS-7-x86_64 --kopts='net.ifnames=0 biosdevname=0'
</pre>
22.�޸��������ļ��Ժ�һ��Ҫִ�� cobbler sync�����ſ�����Ч

23.����tftp  systemctl start xinetd

24.�رշ���ǽsystemctl stop firewalld.service

##cobbler�Զ���yumԴ
1. �½�һ��yum�ֿ⣬���һ��repo openstackԴ

<pre>
 cobbler repo add --name=openstack-mitaka --mirror=http://mirrors.aliyun.com/centos/7.2.1511/cloud/x86_64/openstack-mitaka/ --arch=x86_64 --breed=yum
</pre>
2.ͬ��Դ cobbler reposync ���aliyun��������а����ص�repoĿ¼��

3.���repo����Ӧ��profile�ļ���

<pre>
 cobbler profile edit --name=CentOS-7-x86_64 --repos=��openstack-mitaka��
</pre>

4.�޸�kickstart�ļ�����ӵ�%post  %end �м�

<pre>
 %post
 $yum_config_stanza
%end
</pre>

5.��Ӷ�ʱ������ͬ��repo
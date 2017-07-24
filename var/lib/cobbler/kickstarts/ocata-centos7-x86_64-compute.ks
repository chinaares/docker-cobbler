# kickstart template for Fedora 8 and later.
# (includes %end blocks)
# do not use with earlier distros

#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
# System bootloader configuration
bootloader --location=mbr
# Partition clearing information
clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
firewall --disable
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
$SNIPPET('network_config')
# Reboot after installation
reboot

#Root password
rootpw --iscrypted $default_password_crypted
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone Asia/Shanghai
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr
# Allow anaconda to partition the system as needed
autopart

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages
$SNIPPET('func_install_if_enabled')
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# Enable lan centos source
mkdir /etc/yum.repos.d/.bakup
mv /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/.bakup/
cat <<'EOF' > /etc/yum.repos.d/Centos-7-lan.repo
[centos7]
name=CentOS-$releasever - Media
baseurl=http://192.161.14.180/CENTOS7/dvd/centos
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[epel7]
name=CentOS-$releasever - Media
baseurl=http://192.161.14.24/mirrors/epel/7/x86_64
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
yum clean all
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# prepare for openstack installation
cat <<'EOF' >> /etc/hosts
10.0.0.51 controller1 controller1.local
10.0.0.55 compute1 compute1.local
10.0.0.56 compute2 compute2.local
10.0.0.59 network1 network1.local
10.0.0.60 cinder1 cinder1.local
EOF
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0
# ntp config
yum install -y ntp
sed -i 's/#restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap/#restrict 10.0.0.0 mask 255.255.255.0 nomodify no trap/g' /etc/ntp.conf
sed -i 's/\.centos\.pool\.ntp\.org/\.cn\.pool\.ntp\.org/g' /etc/ntp.conf
sed -i 's/server .\.cn\.pool\.ntp\.org iburst/#&/g' /etc/ntp.conf
sed -i '25i\server 10.0.0.51 iburst' /etc/ntp.conf
systemctl enable ntpd.service
systemctl start ntpd.service

#yum update -y
#yum install -y wget crudini net-tools vim ntpdate bash-completion
#yum install -y openstack-packstack

####################################################################################################
#
#       Compute节点部署
#
####################################################################################################
一、安装相关依赖包
yum install -y openstack-selinux python-openstackclient yum-plugin-priorities openstack-nova-compute openstack-utils ntpdate

1. 配置nova.conf
cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
>/etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip 10.0.0.55
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:123456@controller1
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller1:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller1:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller1:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password 123456
openstack-config --set /etc/nova/nova.conf placement auth_uri http://controller1:5000
openstack-config --set /etc/nova/nova.conf placement auth_url http://controller1:35357
openstack-config --set /etc/nova/nova.conf placement memcached_servers controller1:11211
openstack-config --set /etc/nova/nova.conf placement auth_type password 
openstack-config --set /etc/nova/nova.conf placement project_domain_name default
openstack-config --set /etc/nova/nova.conf placement user_domain_name default
openstack-config --set /etc/nova/nova.conf placement project_name service
openstack-config --set /etc/nova/nova.conf placement username nova
openstack-config --set /etc/nova/nova.conf placement password 123456
openstack-config --set /etc/nova/nova.conf placement os_region_name RegionOne
openstack-config --set /etc/nova/nova.conf vnc enabled True
openstack-config --set /etc/nova/nova.conf vnc keymap en-us
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address 10.0.0.55
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://192.161.17.51:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf glance api_servers http://controller1:9292
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
openstack-config --set /etc/nova/nova.conf libvirt virt_type qemu

2. 设置libvirtd.service 和openstack-nova-compute.service开机启动
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service openstack-nova-compute.service
systemctl status libvirtd.service openstack-nova-compute.service

3. 到controller上执行验证
source /root/admin-openrc
openstack compute service list

# Start final steps
$SNIPPET('kickstart_done')
# End final steps
%end

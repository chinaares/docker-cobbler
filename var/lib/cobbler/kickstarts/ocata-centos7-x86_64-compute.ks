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
NIC=eth0
IP=`LANG=C ip addr show dev $NIC | grep 'inet '| grep $NIC$  |  awk '/inet /{ print $2 }' | awk -F '/' '{ print $1 }'`
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $IP
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
openstack-config --set /etc/nova/nova.conf placement auth_url http://controller1:35357/v3
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
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $IP
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://controller1:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf glance api_servers http://controller1:9292
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

#确定您的计算节点是否支持虚拟机的硬件加速。
egrep -c '(vmx|svm)' /proc/cpuinfo
#如果这个命令返回了 1 或更大的值，那么你的计算节点支持硬件虚拟化且不需要额外的配置。
#如果这个命令返回了 0 值，那么你的计算节点不支持硬件虚拟化。你必须配置 libvirt 来使用 QEMU 去代替 KVM
openstack-config --set /etc/nova/nova.conf libvirt virt_type qemu

2. 设置libvirtd.service 和openstack-nova-compute.service开机启动
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service openstack-nova-compute.service
systemctl status libvirtd.service openstack-nova-compute.service

3. 到controller上执行验证
source /root/admin-openrc
openstack compute service list
openstack catalog list
openstack image list
nova-status upgrade check


####################################################################################################
#
#       Compute节点部署neutron
#
####################################################################################################
# 安装neutron相关软件
yum install -y openstack-neutron-linuxbridge ebtables ipset

# 配置neutron配置文件/etc/neutron/neutron.conf （配置服务组件）
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
>/etc/neutron/neutron.conf
#openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
#openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:123456@controller1
#openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
#openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller1:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller1:35357 
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller1:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password 123456
#openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:123456@controller1/neutron
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
#openstack-config --set /etc/neutron/neutron.conf nova auth_url http://controller1:35357
#openstack-config --set /etc/neutron/neutron.conf nova auth_type password
#openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
#openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
#openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
#openstack-config --set /etc/neutron/neutron.conf nova project_name service
#openstack-config --set /etc/neutron/neutron.conf nova username nova
#openstack-config --set /etc/neutron/neutron.conf nova password 123456

# 配置网络选项 - 选择与您之前在控制节点上选择的相同的网络选项(这里为：自服务网络)
# 8、配置/etc/neutron/plugins/ml2/ml2_conf.ini （配置 Modular Layer 2 (ML2) 插件）
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan 
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population 
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security 
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan 
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 path_mtu 1500
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000 
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True

# 9、配置/etc/neutron/plugins/ml2/linuxbridge_agent.ini （配置Linuxbridge代理）
NIC=eth1
IP=`LANG=C ip addr show dev $NIC | grep 'inet '| grep $NIC$  |  awk '/inet /{ print $2 }' | awk -F '/' '{ print $1 }'`
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini DEFAULT debug false
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$NIC
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $IP
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population True 
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini agent prevent_arp_spoofing True
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True 
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

# 注意: eno16777736(修改后为eth1)是连接外网的网卡，一般这里写的网卡名都是能访问外网的，如果不是外网网卡，那么VM就会与外界网络隔离。
# local_ip 定义的是隧道网络，vxLan下 vm-linuxbridge->vxlan ------tun-----vxlan->linuxbridge-vm


# 配置计算服务来使用网络服务：重新配置/etc/nova/nova.conf，配置这步的目的是让compute节点能使用上neutron网络
openstack-config --set /etc/nova/nova.conf neutron url http://controller1:9696 
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller1:35357 
openstack-config --set /etc/nova/nova.conf neutron auth_type password 
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default 
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default 
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service 
openstack-config --set /etc/nova/nova.conf neutron username neutron 
openstack-config --set /etc/nova/nova.conf neutron password 123456
#openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True 
#openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret 123456

# 重启计算服务：
systemctl restart openstack-nova-compute.service

# 启动Linuxbridge代理并配置它开机自启动：
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service



# Start final steps
$SNIPPET('kickstart_done')
# End final steps
%end

FROM centos:7

MAINTAINER thijs.schnitger@container-solutions.com

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN yum -y install epel-release
RUN yum -y install cobbler cobbler-web dhcp bind syslinux pykickstart fence-agents xinetd initscripts which wget file net-tools debmirror

RUN systemctl enable cobblerd httpd dhcpd rsyncd xinetd

# enable tftp
RUN sed -i -e 's/\(^.*disable.*=\) yes/\1 no/' /etc/xinetd.d/tftp
RUN sed -i 's/#ServerName www.example.com:80/ServerName 127.0.0.1:80/' /etc/httpd/conf/httpd.conf

# settings debmirror
RUN sed -i -e 's|@dists=.*|#@dists=|'  /etc/debmirror.conf
RUN sed -i -e 's|@arches=.*|#@arches=|'  /etc/debmirror.conf

# create rsync file
RUN touch /etc/xinetd.d/rsync

EXPOSE 69
EXPOSE 80
EXPOSE 443
EXPOSE 25151

CMD ["/sbin/init"]

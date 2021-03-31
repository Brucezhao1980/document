#!/bin/bash
cat << EOF
+---------------------------------------+
|   your system is CentOS 7 x86_64      |
|      start optimizing.......          |
+---------------------------------------
EOF

#添加公网DNS地址
cat >> /etc/resolv.conf << EOF
nameserver 114.114.114.114
EOF
#Yum源更换为国内阿里源
yum install wget telnet -y
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

#yum重新建立缓存
yum clean all
yum makecache


#安装gcc基础库以及sysstat工具
yum -y install gcc gcc-c++ vim-enhanced unzip sysstat vim lrzsz net-tools
#配置NTP
yum install chrony -y
systemctl enable chronyd.service
systemctl start chronyd.service

#配置文件ulimit数值
ulimit -SHn 65534
echo "ulimit -SHN 65534" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*           soft     nofile     65534
*           hard     nofile     65534
EOF

#内核参数优化
cat >> /etc/sysctl.conf << EOF
vm.overcommit_memory = 1
net.ipv4.ip_local_port_range = 1024 65536
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_abort_on_overflow = 0
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.ipv4.netfilter.ip_conntrack_max = 2097152
net.nf_conntrack_max = 655360
net.netfilter.nf_conntrack_tcp_timeout_established = 1200
EOF
/sbin/sysctl -p
#禁用control-alt-delete组合键以防止误操作
sed -i 's@ca::ctrlaltdel:/sbin/shutdown -t3 -r now@#ca::ctrlaltdel:/sbin/shutdown -t3 -r now@' /etc/inittab
#关闭selinux
sed -i 's@SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
#关闭防火墙
systemctl disable firewalld.service 
systemctl stop firewalld.service
#禁止空密码登录
sed -i 's@#PermitEmptyPasswords no@PermitEmptyPasswords no@' /etc/ssh/sshd_config
#禁止SSH反向解析
sed  -i 's/^#UseDNS no/UseDNS no/g; s/^#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
systemctl restart sshd
#禁用IPV6地址
#echo "install ipv6 /bin/true" > /etc/modprobe.d/disable-ipv6.conf
#每当系统需要加载IPV6模块时，强制执行/bin/true来代替实际加载的模块
#echo "IPV6INIT=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
#禁用基于IPV6网络，使之不会触发启动
#chkconfig ip6tables off
#vim 基础语法优化
cat >> /root/.vimrc << EOF
set ruler
set nohlsearch
set shiftwidth=2
set tabstop=4
set expandtab
set cindent
set autoindent
set mouse=v
syntax on 
EOF
#精简开机自启动服务，安装最小化服务的机器初始可以只保留crond|network|rsyslog|sshd这4个服务
for i in `chkconfig --list|grep 3:on|awk '{print $1}'`;do chkconfig --level 3 $i off;done
for CURSRV in crond rsyslog sshd network;do chkconfig --level 3 $CURSRV on;done

#重启服务器
#reboot

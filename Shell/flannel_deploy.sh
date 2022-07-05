#!/bin/bash
cd /data/soft/ && unzip -o flannel.zip
echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf && sysctl -p
iptables -P FORWARD ACCEPT && iptables-save
fun_product() {
    cd flannel/flannel/ && unzip -o etcd.zip && unzip -o pro_ssl.zip && unzip -o flanneld.zip
    \cp -r flanneld/flannel /data/soft
    ln -s /data/soft/flannel/mk-docker-opts.sh /usr/bin/mk-docker-opts.sh
    ln -s /data/soft/flannel/flanneld /usr/bin/flanneld
    \cp -r ssl/ssl /data
    \cp etcd-v3.3.11-linux-amd64/etcd-v3.3.11-linux-amd64 /data/soft
    \cp flanneld.service /lib/systemd/system/flanneld.service
    if [ ! -d "/etc/flannel" ]; then
    mkdir /etc/flannel
    fi
    \cp pro_flanneld.conf /etc/flannel/flanneld.conf
    cd /data/soft/etcd-v3.3.11-linux-amd64
    ./etcdctl --ca-file=/data/ssl/etcd-ca.pem --cert-file=/data/ssl/etcd-client.pem --key-file=/data/ssl/etcd-client.key --endpoints="https://172.31.10.142:2379,https://172.31.11.57:2379,https://172.31.12.149:2379" set /coreos.com/network/config '{"Network":"172.30.0.0/16", "SubnetMin": "172.30.1.0", "SubnetMax": "172.30.254.0", "Backend":{"Type":"vxlan"}}'
}
fun_pre() {
    cd flannel/flannel/ && unzip -o etcd.zip && unzip -o pre_ssl.zip && unzip -o flanneld.zip
    \cp -r flanneld/flannel /data/soft
    ln -s /data/soft/flannel/mk-docker-opts.sh /usr/bin/mk-docker-opts.sh
    ln -s /data/soft/flannel/flanneld /usr/bin/flanneld
    \cp -r ssl/ssl /data
    \cp etcd-v3.3.11-linux-amd64/etcd-v3.3.11-linux-amd64 /data/soft
    \cp flanneld.service /lib/systemd/system/flanneld.service
    if [ ! -d "/etc/flannel" ]; then
    mkdir /etc/flannel
    fi
    \cp pre_flanneld.conf /etc/flannel/flanneld.conf
    cd /data/soft/etcd-v3.3.11-linux-amd64
    ./etcdctl  --ca-file=/data/ssl/etcd-ca.pem --cert-file=/data/ssl/etcd-client.pem --key-file=/data/ssl/etcd-client.key --endpoints="https://10.0.0.193:2379,https://10.0.0.213:2379,https://10.0.0.20:2379" set /coreos.com/network/config '{"Network":"172.20.0.0/16", "SubnetMin": "172.20.1.0", "SubnetMax": "172.20.254.0", "Backend":{"Type":"vxlan"}}'
}
case $1 in
  pre)
    fun_pre
     ;;
  product)
    fun_product
     ;;
esac
systemctl daemon-reload && systemctl restart flanneld && systemctl restart docker
echo flannel=`ifconfig  flannel.1 | head -n2 | grep inet | awk '{print $2}'`
echo docker=`ifconfig docker0 |head -n2|grep inet|awk '{print $2}'`
echo eth0=`ifconfig eth0 |head -n2 |grep inet |awk '{print $2}'`

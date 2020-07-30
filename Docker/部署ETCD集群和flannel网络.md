配置文件 etcd-ca.cnf

[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
keyUsage           = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints   = critical, CA:true

生成 key

openssl genrsa -out etcd-ca.key 4096

签发 ca

openssl req -x509 -new -nodes -key etcd-ca.key -days 1825 -out etcd-ca.pem \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=k8s/CN=etcd-ca" \
        -config etcd-ca.cnf -extensions v3_req

签发 etcd server 证书

etcd-server.cnf

[ req ]
req_extensions      = v3_req
distinguished_name  = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints    = CA:FALSE
extendedKeyUsage    = clientAuth, serverAuth
keyUsage            = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName      = @alt_names
[alt_names]
IP.1 = 172.31.114.7
IP.2 = 172.31.114.8
IP.3 = 172.31.114.9

IP.1 为客户端IP, 可以为多个, 如 IP.2 = xxx

openssl genrsa -out etcd-server.key 4096

生成证书签名请求

openssl req -new -key etcd-server.key -out etcd-server.csr \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=k8s/CN=etcd-server" \
        -config etcd-server.cnf

签发证书

openssl x509 -req -in etcd-server.csr -CA etcd-ca.pem \
        -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-server.pem -days 1825 \
        -extfile etcd-server.cnf -extensions v3_req

配置文件 

etcd-peer.cnf

[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
extendedKeyUsage   = clientAuth, serverAuth
keyUsage           = critical, digitalSignature, keyEncipherment
subjectAltName     = @alt_names

[alt_names]
IP.1 = 172.31.114.7
IP.2 = 172.31.114.8
IP.3 = 172.31.114.9

生成key

openssl genrsa -out etcd-peer.key 4096

openssl req -new -key etcd-peer.key -out etcd-peer.csr \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=k8s/CN=etcd-peer" \
        -config etcd-peer.cnf

签发证书

openssl x509 -req -in etcd-peer.csr \
        -CA etcd-ca.pem -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-peer.pem -days 1825 \
        -extfile etcd-peer.cnf -extensions v3_req
配置文件
etcd-client.cnf

[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
extendedKeyUsage   = clientAuth
keyUsage           = critical, digitalSignature, keyEncipherment

生成key

openssl genrsa -out etcd-client.key 4096

openssl req -new -key etcd-client.key -out etcd-client.csr \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=system:masters/CN=etcd-client" \
        -config etcd-client.cnf

openssl x509 -req -in etcd-client.csr \
        -CA etcd-ca.pem -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-client.pem -days 1825 \
        -extfile etcd-client.cnf -extensions v3_req

在各节点依次执行 yum install -y etcd 进行安装

yum install -y etcd

修改配置文件 /etc/etcd/etcd.conf

[member]
ETCD_NAME=etcd1
ETCD_DATA_DIR="/var/lib/etcd/etcd"
ETCD_LISTEN_PEER_URLS="https://172.31.114.7:2380"
ETCD_LISTEN_CLIENT_URLS="https://172.31.114.7:2379"
[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://172.31.114.7:2380"
ETCD_INITIAL_CLUSTER="etcd1=https://172.31.114.7:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_ADVERTISE_CLIENT_URLS="https://172.31.114.7:2379"
[security]
ETCD_CERT_FILE="/opt/ssl/etcd-server.pem"
ETCD_KEY_FILE="/opt/ssl/etcd-server.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/opt/ssl/etcd-ca.pem"
ETCD_AUTO_TLS="true"
ETCD_PEER_CERT_FILE="/opt/ssl/etcd-peer.pem"
ETCD_PEER_KEY_FILE="/opt/ssl/etcd-peer.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/opt/ssl/etcd-ca.pem"
ETCD_PEER_AUTO_TLS="true"

证书路径请根据证书实际目录对照修改
etcd1 ETCD_INITIAL_CLUSTER_STATE 设置为 new, 其余改为 existing
ETCD_DATA_DIR 指定数据存放路径，在生产环境集群推荐使用高性能SSD


添加 etcd2到集群：

ETCDCTL_API=3 etcdctl --endpoints=https://172.31.114.7:2379 \
                      --cacert=/opt/ssl/etcd-ca.pem \
                      --cert=/opt/ssl/etcd-client.pem \
                      --key=/opt/ssl/etcd-client.key \
                      member add etcd2 --peer-urls=https://172.31.114.8:2380
                      
                      
etcd2

[member]
ETCD_NAME=etcd2
ETCD_DATA_DIR="/var/lib/etcd/etcd"
ETCD_LISTEN_PEER_URLS="https://172.31.114.8:2380"
ETCD_LISTEN_CLIENT_URLS="https://172.31.114.8:2379"
[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://172.31.114.8:2380"
ETCD_INITIAL_CLUSTER="etcd1=https://172.31.114.7:2380,etcd2=https://172.31.114.8:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
ETCD_ADVERTISE_CLIENT_URLS="https://172.31.114.8:2379"
[security]
ETCD_CERT_FILE="/opt/ssl/etcd-server.pem"
ETCD_KEY_FILE="/opt/ssl/etcd-server.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/opt/ssl/etcd-ca.pem"
ETCD_AUTO_TLS="true"
ETCD_PEER_CERT_FILE="/opt/ssl/etcd-peer.pem"
ETCD_PEER_KEY_FILE="/opt/ssl/etcd-peer.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/opt/ssl/etcd-ca.pem"
ETCD_PEER_AUTO_TLS="true"

etcd3

[member]
ETCD_NAME=etcd3
ETCD_DATA_DIR="/var/lib/etcd/etcd"
ETCD_LISTEN_PEER_URLS="https://172.31.114.9:2380"
ETCD_LISTEN_CLIENT_URLS="https://172.31.114.9:2379"
[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://172.31.114.9:2380"
ETCD_INITIAL_CLUSTER="etcd1=https://172.31.114.7:2380,etcd3=https://172.31.114.9:2380,etcd2=https://172.31.114.8:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
ETCD_ADVERTISE_CLIENT_URLS="https://172.31.114.9:2379"
[security]
ETCD_CERT_FILE="/opt/ssl/etcd-server.pem"
ETCD_KEY_FILE="/opt/ssl/etcd-server.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/opt/ssl/etcd-ca.pem"
ETCD_AUTO_TLS="true"
ETCD_PEER_CERT_FILE="/opt/ssl/etcd-peer.pem"
ETCD_PEER_KEY_FILE="/opt/ssl/etcd-peer.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/opt/ssl/etcd-ca.pem"
ETCD_PEER_AUTO_TLS="true"



修改文件

/usr/lib/systemd/system/etcd.service

[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
User=etcd

ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd \
    --name=\"${ETCD_NAME}\" \
    --cert-file=\"${ETCD_CERT_FILE}\" \
    --key-file=\"${ETCD_KEY_FILE}\" \
    --peer-cert-file=\"${ETCD_PEER_CERT_FILE}\" \
    --peer-key-file=\"${ETCD_PEER_KEY_FILE}\" \
    --trusted-ca-file=\"${ETCD_TRUSTED_CA_FILE}\" \
    --peer-trusted-ca-file=\"${ETCD_PEER_TRUSTED_CA_FILE}\" \
    --initial-advertise-peer-urls=\"${ETCD_INITIAL_ADVERTISE_PEER_URLS}\" \
    --listen-peer-urls=\"${ETCD_LISTEN_PEER_URLS}\" \
    --listen-client-urls=\"${ETCD_LISTEN_CLIENT_URLS}\" \
    --advertise-client-urls=\"${ETCD_ADVERTISE_CLIENT_URLS}\" \
    --initial-cluster-token=\"${ETCD_INITIAL_CLUSTER_TOKEN}\" \
    --initial-cluster=\"${ETCD_INITIAL_CLUSTER}\" \
    --initial-cluster-state=\"${ETCD_INITIAL_CLUSTER_STATE}\" \
    --data-dir=\"${ETCD_DATA_DIR}\""

Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target



systemctl daemon-reload

systemctl start etcd  #启动etcd

systemctl enable etcd

查看状态

ETCDCTL_API=3 etcdctl --endpoints=https://172.31.114.7:2379 --cacert=/opt/ssl/etcd-ca.pem --cert=/opt/ssl/etcd-client.pem --key=/opt/ssl/etcd-client.key   member list

##############################################################
                       flannel配置
##############################################################

yum install flannel -y # 安装flannel网络

echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf && sysctl -p       # 开启路由转发

先建个软连：

ln -s /usr/libexec/flannel/mk-docker-opts.sh /usr/bin/mk-docker-opts.sh

etcdctl  --ca-file=/opt/ssl/etcd-ca.pem --cert-file=/opt/ssl/etcd-client.pem --key-file=/opt/ssl/etcd-client.key --endpoints="https://172.31.114.7:2379,https://172.31.114.8:2379,https://172.31.114.9:2379" set /coreos.com/network/config '{"Network":"172.10.0.0/16", "SubnetMin": "172.10.1.0", "SubnetMax": "172.10.254.0", "Backend":{"Type":"vxlan"}}'

cat /lib/systemd/system/flanneld.service 
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
User=root
Type=notify
LimitNOFILE=65536
EnvironmentFile=/etc/flannel/flanneld.conf
ExecStart=/usr/bin/flanneld -etcd-cafile=/opt/ssl/etcd-ca.pem \
-etcd-certfile=/opt/ssl/etcd-client.pem \
-etcd-keyfile=/opt/ssl/etcd-client.key \
-etcd-endpoints=${FLANNEL_ETCD_ENDPOINTS} \
-etcd-prefix=${FLANNEL_ETCD_PREFIX} $FLANNEL_OPTIONS

ExecStartPost=/usr/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure

[Install]
WantedBy=multi-user.target
#####################################################################################

cat /etc/flannel/flanneld.conf 
# Flanneld configuration options

# etcd url location. Point this to the server where etcd runs
#FLANNEL_ETCD_ENDPOINTS="-etcd-endpoints=http://0.0.0.0:2379"
# etcd集群配置
FLANNEL_ETCD_ENDPOINTS="https://172.31.114.7:2379,https://172.31.114.8:2379,https://172.31.114.9:2379"
# etcd config key. This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_PREFIX="/coreos.com/network"

# Any additional options that you want to pass
FLANNEL_OPTIONS="-iface=eth0"

######################################################################################
     在命令行排错，/usr/bin/flanneld -etcd-cafile=/opt/ssl/etcd-ca.pem -etcd-certfile=/opt/ssl/etcd-client.pem -etcd-keyfile=/opt/ssl/etcd-client.key -etcd-endpoints="https://192.168.190.128:2379,https://192.168.190.129:2379,https://192.168.190.130:2379" -etcd-prefix="/coreos.com/network"
######################################################################################

配置Docker

修改docker启动参数

  1 root@docker01:~# vim /lib/systemd/system/docker.service
  2 #……
  3 EnvironmentFile=/run/flannel/docker		#添加flannel转换后的docker能识别的配置文件
  4 ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_NETWORK_OPTIONS






































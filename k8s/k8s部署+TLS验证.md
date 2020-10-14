# **参考**  [Statemood]( https://github.com/Statemood/documents/tree/master/kubernetes)





# 概览

- 通过二进制文件安装 Kubernetes 1.10 及以上版本
- 本文档指导如何安装一个具有3 Master、2 Worker的高可用集群，在升级下方硬件配置后，可以应用于生成环境

## 1. 组件

- etcd
- calico
- flannel
- docker
- kube-apiserver
- kube-controller-manager
- kube-scheduler
- kube-proxy
- kubelet
- metrics-server
- dashboard
- coredns
- ingress
- prometheus

# 环境

## 1. OS

#### 版本

CentOS 7.2 minimal x86_64 或以上版本

#### 磁盘分区

确保根分区 `/` 或独立挂载的 `/var/log` 具有20GB以上的可用空间。

## 2. 资源配置

| 节点         | IP            | 配置                    | 备注 |
| ------------ | ------------- | ----------------------- | ---- |
| k8s-master-1 | 192.168.1.174 | 4 CPU, 8G MEM, 30G DISK | -    |
| k8s-master-2 | 192.168.1.175 | 4 CPU, 8G MEM, 30G DISK | -    |
| k8s-master-3 | 192.168.1.177 | 4 CPU, 8G MEM, 30G DISK | -    |

- 本配置为不分角色的混合部署，在同一节点上部署
  - etcd
  - master
  - worker
- 推荐在生产环境中
  - 使用更高配置
  - 独立部署 Etcd 并使用高性能SSD (PCIe)
  - 独立部署 Master, 根据集群规模和Pod数量，至少4C8G，建议8C16G起
  - 对集群进行性能和破坏性测试

## 2. 网络

### Calico

- 如使用 Calico网络，请忽略任何与 Flannel 相关操作
- BGP (default)  （现有云环境基本不支持自建BGP网络）
- IPIP

### Flannel

- vxlan

### Subnet

#### Service Network

IP 网段：10.0.0.0/12

IP 数量：1,048,576

#### Pod Network

IP 网段：10.64.0.0/10

IP 数量：4,194,304

## 3. Docker

Docker-CE 18.03 或更高版本

## 4. kubernetes

以下版本均已经过测试

- 1.15.x
- 1.16.x
- 1.17.x
- 1.18.0
- 1.19.0

# Kubernetes 数据持久化

## 前言

**[What is Persistent Volumes ?](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)**

一般情况下，较多是利用并通过 Kubernetes 的特性运行无状态服务，但在实际情况下，还是会有不少的有状态服务( *[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)* ) 也需要在Kubernetes 上运行，如 Prometheus、Grafana、MySQL、Harbor等等，故此需要针对这些服务提供数据持久化。

结合大部分业务场景，比较常见的存储供应商主要有公有云、硬件存储、SDS等等。这里主要介绍 [使用Ceph进行数据持久化](#use ceph rbd for storage class) 。

但在一些时候，可能无法提供Ceph RBD等更适用于Kubernetes的分布式文件系统供数据持久化，因此在一些小型环境、不太重要的服务上也可以使用 NFS。

更多NFS相关信息，请参阅 [使用NFS进行数据持久化](https://github.com/Statemood/documents/blob/master/kubernetes/uses/500.use-nfs-for-storage-class.md) 。



# 系统配置

- [调整内核参数](#调整内核参数（在所有节点执行）)
- [禁用 SWAP Firewalld 和 Selinux](#禁用swap（在所有节点执行）)

# 安装 Kubernetes

## 前期准备

- [签发证书](#签发证书)
- [安装 Etcd 集群](#安装 etcd 集群)
- [安装Kubernetes二进制程序](#安装Kubernetes二进制程序)
- [添加用户](#添加用户（在所有节点执行）)
- [为 kubectl 生成 kubeconfig](#生成 kubectl 的 kubeconfig 文件  每个节点都要执行。)
- [安装 Docker-CE](#安装 docker-ce repo)
- [安装依赖](#安装依赖项)

## 安装集群服务

- [安装 kube-apiserver](#安装kube-apiserver)
- [安装 kube-controller-manager](#安装kube-controller-manager)
- [安装 kube-scheduler](#安装kube-scheduler)
- [配置 apiserver 高可用](#Configuration HA kube-apiserver（可选）) (*可选*)
- [安装 kubelet](#安装kubelet)
- [安装 kube-proxy](#安装kube-proxy)

注意：**在Worker节点上**仅需安装 *kubelet & kube-proxy* 2个服务。

- [添加一个新节点](#添加一个新的 worker 节点)

## 部署基础组件  (非k8s安装参考其他链接)

- [Calico](#Calico(与flannel任选一种部署)) *or* [Flannel](#安装flannel) (*二选一*)     [非k8s安装Flannel](http://47.104.111.178/snapex/microservices/wikis/ETCD%E9%9B%86%E7%BE%A4%E5%92%8Cflannel%E7%BD%91%E7%BB%9C)   
- [CoreDNS](#deploy coredns)                                 [非k8s安装](http://47.104.111.178/snapex/microservices/wikis/CoreDns%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE)
- [Node Local DNS](#deploy node local dns)
- [Metrics Server](#https://github.com/kubernetes-sigs/metrics-server)
- [Kubernetes Dashboard](#deploy kubernetes dashboard)
- [Ingress Controller](#deploy ingress controller)

## 部署附加组件

- [Prometheus](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/403.deploy-prometheus.md)        [非k8s部署](http://47.104.111.178/snapex/microservices/wikis/Prometheus+grafana)
- [NPD](https://github.com/kubernetes/node-problem-detector)

# 使用案例

## 存储

- [使用 Ceph RBD 进行数据持久化](#use ceph rbd for storage class)

## 日志

- 使用ELK或者EFK处理日志（提高性能可增加redis或kafka，建议kafka）
- [ELK部署](http://47.104.111.178/snapex/microservices/wikis/ELK%E9%83%A8%E7%BD%B2)



# 禁用swap（在所有节点执行）



如系统已配置并启用了 swap，可按照如下方式禁用

执行 swapoff -a

```
swapoff -a
```

在 /etc/fstab 中移除 swap 相关行

**禁用selinux**

setenforce 0

sed -i 's@SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config

**禁用防火墙**

systemctl disable firewalld.service 

systemctl stop firewalld.service



# 添加用户（在所有节点执行）

```
Add Group & User kube

groupadd -g 200 kube && useradd -g 200 kube -u 200 -d / -s /sbin/nologin -M
```

**用户 kube 需要在所有节点上添加，包括 Master 节点。**

做ssh-key互信 

ssh-keygen -t rsa （一路回车）

ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.1.175

ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.1.177

其他2台也要按照上面的操作。

#  调整内核参数（在所有节点执行）



## 调整内核参数

*在所有节点执行*

按如下配置修改 /etc/sysctl.conf，并执行 `sysctl -p` 生效

```
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).
  
kernel.sysrq                        = 0
kernel.core_uses_pid                = 1
kernel.msgmnb                       = 65536
kernel.msgmax                       = 65536
kernel.shmmax                       = 68719476736
kernel.shmall                       = 4294967296
  
fs.file-max                         = 1000000

vm.max_map_count                    = 500000
  
net.core.netdev_max_backlog         = 32768
net.core.somaxconn                  = 32768
net.core.wmem_default               = 8388608
net.core.rmem_default               = 8388608
net.core.wmem_max                   = 16777216
net.core.rmem_max                   = 16777216
  
net.ipv4.ip_forward                 = 1
net.ipv4.tcp_max_tw_buckets         = 300000
net.ipv4.tcp_mem                    = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans            = 3276800
net.ipv4.tcp_keepalive_time         = 1200
net.ipv4.tcp_keepalive_intvl        = 30
net.ipv4.tcp_keepalive_probes       = 3
net.ipv4.ip_local_port_range        = 1024 65535
net.ipv4.conf.lo.arp_announce       = 2
net.ipv4.conf.all.arp_announce      = 2
```



# Kubernetes TLS 证书签发指导文档

## 概览

需要签发如下证书

1. ca
2. kube-apiserver
3. kube-controller-manager
4. kube-scheduler
5. kube-proxy
6. kubectl
7. metrics-server
8. proxy-client
9. calico *or* flannel

通常情况下，请根据实际场景需求选择 Calico 或 Flannel 其中的一种。

## 签发证书

### CA

创建 /etc/ssl/k8s 目录并进入(也可以是其它目录)

```
mkdir -p /etc/ssl/k8s && cd /etc/ssl/k8s
```

ca.cnf

```
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]

[ v3_req ]
keyUsage = critical, cRLSign, keyCertSign, digitalSignature, keyEncipherment
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:2
```

#### 生成 CA Key

```
openssl genrsa -out ca.key 4096
```

#### 签发CA

```
openssl req -x509 -new -nodes -key ca.key -days 1095 -out ca.pem -subj \
        "/CN=kubernetes/OU=System/C=CN/ST=Beijing/L=Beijing/O=k8s" \
        -config ca.cnf -extensions v3_req
```

- 有效期 **1095** (d) = 3 years
- 注意 -subj 参数中仅 'C=CN' 与 'Beijing' 可以修改，**其它保持原样**，否则集群会遇到权限异常问题

### kube-apiserver

#### apiserver.cnf

```
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
IP.1 = 10.0.0.1
IP.2 = 172.31.114.6
IP.3 = 192.168.1.174
IP.4 = 192.168.1.175
IP.5 = 192.168.1.177
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
```

- IP.2 为 HA VIP
- IP.3 为 API Server 1
- IP.4 为 API Server 2
- IP.5 为 API Server 3

如果需要, 可以加上其它IP, 如额外的API Server

#### 生成 key

```
openssl genrsa -out apiserver.key 4096
```

#### 生成证书签名请求

```
openssl req -new -key apiserver.key -out apiserver.csr -subj \
        "/CN=kubernetes/OU=System/C=CN/ST=Beijing/L=Beijing/O=k8s" \
        -config apiserver.cnf
```

- CN、OU、O 字段为认证时使用, 请勿修改
- 注意 -subj 参数中仅 'C'、'ST' 与 'L' 可以修改，**其它保持原样**，否则集群会遇到权限异常问题

#### 签发证书

```
openssl x509 -req -in apiserver.csr \
        -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out apiserver.pem -days 1095 \
        -extfile apiserver.cnf -extensions v3_req
```

### kube-apiserver-kubelet-client

kube-apiserver-kubelet-client.cnf

```
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
keyUsage           = critical, digitalSignature, keyEncipherment
extendedKeyUsage   = clientAuth
```

#### 生成key

```
openssl genrsa -out kube-apiserver-kubelet-client.key 4096
```

#### 生成证书签名请求

```
openssl req -new -key kube-apiserver-kubelet-client.key -out kube-apiserver-kubelet-client.csr \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=system:masters/CN=kube-apiserver-kubelet-client" \
        -config kube-apiserver-kubelet-client.cnf
```

#### 签发证书

```
openssl x509 -req -in kube-apiserver-kubelet-client.csr \
        -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out kube-apiserver-kubelet-client.pem -days 1825 \
        -extfile kube-apiserver-kubelet-client.cnf -extensions v3_req
```

### kube-controller-manager

kube-controller-manager.cnf

```
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
keyUsage           = critical, digitalSignature, keyEncipherment
extendedKeyUsage   = clientAuth
subjectAltName     = @alt_names
[alt_names]
IP.1 = 127.0.0.1
IP.2 = 192.168.1.174
IP.3 = 192.168.1.175
IP.4 = 192.168.1.177
```

#### 生成Key

```
openssl genrsa -out kube-controller-manager.key 4096
```

#### 生成证书签名请求

```
openssl req -new -key kube-controller-manager.key \
        -out kube-controller-manager.csr \
        -subj "/CN=system:kube-controller-manager/OU=System/C=CN/ST=Beijing/L=Beijing/O=system:kube-controller-manager" \
        -config kube-controller-manager.cnf
```

#### 签发证书

```
openssl x509 -req -in kube-controller-manager.csr \
        -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out kube-controller-manager.pem -days 1825 \
        -extfile kube-controller-manager.cnf -extensions v3_req
```

### kube-scheduler

kube-scheduler.cnf

```
cp kube-controller-manager.cnf kube-scheduler.cnf
```

- 复用 kube-controller-manager.cnf 文件即可

#### 生成Key

```
openssl genrsa -out kube-scheduler.key 4096
```

#### 生成证书签名请求

```
openssl req -new -key kube-scheduler.key \
        -out kube-scheduler.csr \
        -subj "/CN=system:kube-scheduler/OU=System/C=CN/ST=Beijing/L=Beijing/O=system:kube-scheduler" \
        -config kube-scheduler.cnf
```

#### 签发证书

```
openssl x509 -req -in kube-scheduler.csr \
        -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out kube-scheduler.pem -days 1825 \
        -extfile kube-scheduler.cnf -extensions v3_req
```

- **CN**和**O**均为 `system:kube-scheduler`，Kubernetes 内置的 ClusterRoleBindings `system:kube-scheduler` 赋予kube-scheduler所需权限

### kubectl

#### admin.cnf

```
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
extendedKeyUsage   = clientAuth
keyUsage = critical, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 192.168.1.174
```

#### 生成 key

```
openssl genrsa -out admin.key 4096
```

#### 生成证书签名请求

```
openssl req -new -key admin.key -out admin.csr -subj \
        "/CN=admin/OU=System/C=CN/ST=Beijing/L=Beijing/O=system:masters" \
        -config admin.cnf
```

#### 签发证书

```
openssl x509 -req -in admin.csr -CA ca.pem \
        -CAkey ca.key -CAcreateserial -out admin.pem \
        -days 1095 -extfile admin.cnf -extensions v3_req
```

### kube-proxy

kube-proxy.cnf

```
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
keyUsage           = critical, digitalSignature, keyEncipherment
extendedKeyUsage   = clientAuth
```

#### 生成 key

```
openssl genrsa -out kube-proxy.key 4096
```

#### 生成证书签名请求

```
openssl req -new -key kube-proxy.key -out kube-proxy.csr -subj \
      "/CN=system:kube-proxy/OU=System/C=CN/ST=Beijing/L=Beijing/O=k8s" \
      -config kube-proxy.cnf
```

#### 签发证书

```
openssl x509 -req -in kube-proxy.csr \
        -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out kube-proxy.pem -days 1095 \
        -extfile kube-proxy.cnf -extensions v3_req
```

### metrics-server

proxy-client.cnf

```
cp kube-controller-manager.cnf proxy-client.cnf
```

复用 kube-controller-manager.cnf 文件即可

#### 生成 Key

```
openssl genrsa -out proxy-client.key 4096
```

#### 生成证书签名请求

```
openssl req -new -key proxy-client.key -out proxy-client.csr \
        -subj "/CN=aggregator/OU=System/C=CN/ST=Beijing/L=Beijing/O=k8s" \
        -config proxy-client.cnf
```

CN名称需要配置在 **apiserver** 的 `--requestheader-allowed-names` 参数中，否则后续访问 metrics 时会提示权限不足

#### 签发证书

```
openssl x509 -req -in proxy-client.csr \
        -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out proxy-client.pem -days 1825 \
        -extfile proxy-client.cnf -extensions v3_req
```

### 分发证书

**在本文档示例中，每个节点上证书都保存在 */etc/kubernetes/ssl* 目录中。**

**请复制以下证书至 /etc/kubernetes/ssl。**

#### Master

##### ca

- ca.key
- ca.pem

CA 证书用于自签发 Kubernetes 集群所用证书。

##### etcd-client

- etcd-client.key
- etcd-client.pem

*请注意这里的 etcd-client 证书来签发自 etcd-ca。*

etcd-client 证书主要用于 kube-apiserver 与 etcd server 通信使用，同时CNI组件如 Calico 也会使用。

##### kube-apiserver

- kube-apiserver.key
- kube-apiserver.pem

##### kube-controller-manager

- kube-controller-manager.key
- kube-controller-manager.pem

##### kube-scheduler

- kube-scheduler.key
- kube-scheduler.pem

##### kubectl

- admin.key
- admin.pem

*仅安装了 kubectl 的节点才需要 admin 证书*

##### kube-proxy

- kube-proxy.key
- kube-proxy.pem

##### proxy-client

- proxy-client.key
- proxy-client.pem

#### Worker

##### kube-proxy

- kube-proxy.key
- kube-proxy.pem

##### kubelet

*kubelet 证书会在 kubelet CSR 获得批准后自动签发*



# 安装 Etcd 集群



配置文件 etcd-ca.cnf

```
[ req ]

req_extensions   = v3_req

distinguished_name = req_distinguished_name



[req_distinguished_name]



[ v3_req ]

keyUsage      = critical, keyCertSign, digitalSignature, keyEncipherment

basicConstraints  = critical, CA:true
```

生成 key

```
openssl genrsa -out etcd-ca.key 4096
```



签发 ca



```
openssl req -x509 -new -nodes -key etcd-ca.key -days 1825 -out etcd-ca.pem \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=k8s/CN=etcd-ca" \
 -config etcd-ca.cnf -extensions v3_req
```



签发 etcd server 证书



etcd-server.cnf

```
[ req ]

req_extensions   = v3_req

distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]

basicConstraints  = CA:FALSE

extendedKeyUsage  = clientAuth, serverAuth

keyUsage      = nonRepudiation, digitalSignature, keyEncipherment

subjectAltName   = @alt_names

[alt_names]

IP.1 = 192.168.1.174

IP.2 = 192.168.1.175

IP.3 = 192.168.1.177
```



IP.1 为客户端IP, 可以为多个, 如 IP.2 = xxx



```
openssl genrsa -out etcd-server.key 4096
```



生成证书签名请求

```
openssl req -new -key etcd-server.key -out etcd-server.csr \
-subj "/C=CN/ST=Beijing/L=Beijing/O=k8s/CN=etcd-server" \
-config etcd-server.cnf
```



签发证书

```
openssl x509 -req -in etcd-server.csr -CA etcd-ca.pem \
-CAkey etcd-ca.key -CAcreateserial \
-out etcd-server.pem -days 1825 \
-extfile etcd-server.cnf -extensions v3_req
```

配置文件 etcd-peer.cnf

 etcd-peer.cnf

```
[ req ]

req_extensions   = v3_req

distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]

extendedKeyUsage  = clientAuth, serverAuth

keyUsage      = critical, digitalSignature, keyEncipherment

subjectAltName   = @alt_names



[alt_names]

IP.1 = 192.168.1.174

IP.2 = 192.168.1.175

IP.3 = 192.168.1.177
```

生成key

```
openssl genrsa -out etcd-peer.key 4096
```



```
openssl req -new -key etcd-peer.key -out etcd-peer.csr \
-subj "/C=CN/ST=Beijing/L=Beijing/O=k8s/CN=etcd-peer" \
-config etcd-peer.cnf
```



签发证书

```
openssl x509 -req -in etcd-peer.csr \
-CA etcd-ca.pem -CAkey etcd-ca.key -CAcreateserial \
-out etcd-peer.pem -days 1825 \
-extfile etcd-peer.cnf -extensions v3_req
```

配置文件 etcd-client.cnf

etcd-client.cnf

```
[ req ]

req_extensions   = v3_req

distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]

extendedKeyUsage  = clientAuth

keyUsage      = critical, digitalSignature, keyEncipherment
```

生成key

```
openssl genrsa -out etcd-client.key 4096
```

```
openssl req -new -key etcd-client.key -out etcd-client.csr \
-subj "/C=CN/ST=Beijing/L=Beijing/O=system:masters/CN=etcd-client" \
-config etcd-client.cnf
```

```
openssl x509 -req -in etcd-client.csr \
-CA etcd-ca.pem -CAkey etcd-ca.key -CAcreateserial \
-out etcd-client.pem -days 1825 \
-extfile etcd-client.cnf -extensions v3_req
```

在各节点依次执行 yum install -y etcd 进行安装



yum install -y etcd



修改配置文件 /etc/etcd/etcd.conf



```
[member]

ETCD_NAME=etcd1

ETCD_DATA_DIR="/var/lib/etcd/etcd"

ETCD_LISTEN_PEER_URLS="https://192.168.1.174:2380"

ETCD_LISTEN_CLIENT_URLS="https://192.168.1.174:2379"

[cluster]

ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.1.174:2380"

ETCD_INITIAL_CLUSTER="etcd1=https://192.168.1.174:2380"

ETCD_INITIAL_CLUSTER_STATE="new"

ETCD_ADVERTISE_CLIENT_URLS="https://192.168.1.174:2379"

[security]

ETCD_CERT_FILE="/etc/etcd/ssl/etcd-server.pem"

ETCD_KEY_FILE="/etc/etcd/ssl/etcd-server.key"

ETCD_CLIENT_CERT_AUTH="true"

ETCD_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-ca.pem"

ETCD_AUTO_TLS="true"

ETCD_PEER_CERT_FILE="/etc/etcd/ssl/etcd-peer.pem"

ETCD_PEER_KEY_FILE="/etc/etcd/ssl/etcd-peer.key"

ETCD_PEER_CLIENT_CERT_AUTH="true"

ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-ca.pem"

ETCD_PEER_AUTO_TLS="true"


```

证书路径请根据证书实际目录对照修改

etcd1 ETCD_INITIAL_CLUSTER_STATE 设置为 new, 其余改为 existing

ETCD_DATA_DIR 指定数据存放路径，在生产环境集群推荐使用高性能SSD

### 3. 修改文件 /usr/lib/systemd/system/etcd.service

/usr/lib/systemd/system/etcd.service

```
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
```

##### 依次修改3个节点的 /etc/etcd/etc.conf 和 /usr/lib/systemd/system/etcd.service 文件

```
systemctl daemon-reload

systemctl start etcd 

systemctl enable etcd
```

**etcd2**

修改 /etc/etcd/etcd.conf

```
[member]

ETCD_NAME=etcd2

ETCD_DATA_DIR="/var/lib/etcd/etcd"

ETCD_LISTEN_PEER_URLS="https://192.168.1.175:2380"

ETCD_LISTEN_CLIENT_URLS="https://192.168.1.175:2379"

[cluster]

ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.1.175:2380"

ETCD_INITIAL_CLUSTER="etcd1=https://192.168.1.174:2380,etcd2=https://192.168.1.175:2380"

ETCD_INITIAL_CLUSTER_STATE="existing"

ETCD_ADVERTISE_CLIENT_URLS="https://192.168.1.175:2379"

[security]

ETCD_CERT_FILE="/etc/etcd/ssl/etcd-server.pem"

ETCD_KEY_FILE="/etc/etcd/ssl/etcd-server.key"

ETCD_CLIENT_CERT_AUTH="true"

ETCD_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-ca.pem"

ETCD_AUTO_TLS="true"

ETCD_PEER_CERT_FILE="/etc/etcd/ssl/etcd-peer.pem"

ETCD_PEER_KEY_FILE="/etc/etcd/ssl/etcd-peer.key"

ETCD_PEER_CLIENT_CERT_AUTH="true"

ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-ca.pem"

ETCD_PEER_AUTO_TLS="true"
```



添加 etcd2到集群：

```
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.1.174:2379 \
--cacert=/etc/etcd/ssl/etcd-ca.pem \
--cert=/etc/etcd/ssl/etcd-client.pem \
--key=/etc/etcd/ssl/etcd-client.key \
member add etcd2 --peer-urls=https://192.168.1.175:2380
```

根据提示修改配置文件，修改服务，然后启动。

**etcd3**

```
[member]

ETCD_NAME=etcd3

ETCD_DATA_DIR="/var/lib/etcd/etcd"

ETCD_LISTEN_PEER_URLS="https://192.168.1.177:2380"

ETCD_LISTEN_CLIENT_URLS="https://192.168.1.177:2379"

[cluster]

ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.1.177:2380"

ETCD_INITIAL_CLUSTER="etcd1=https://192.168.1.174:2380,etcd3=https://192.168.1.177:2380,etcd2=https://192.168.1.175:2380"

ETCD_INITIAL_CLUSTER_STATE="existing"

ETCD_ADVERTISE_CLIENT_URLS="https://192.168.1.177:2379"

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


```



查看状态

ETCDCTL_API=3 etcdctl --endpoints=https://192.168.1.174:2379 --cacert=/opt/ssl/etcd-ca.pem --cert=/opt/ssl/etcd-client.pem --key=/opt/ssl/etcd-client.key  member list

拷贝证书到新建目录

mkdir -p /etc/etcd/ssl && cp -rf /opt/ssl/* /etc/etcd/ssl/



# 安装Kubernetes二进制程序

```


wget https://storage.googleapis.com/kubernetes-release/release/v1.19.0/kubernetes-server-linux-amd64.tar.gz

tar zxf kubernetes-server-linux-amd64.tar.gz

安装程序

cd kubernetes/server/bin

cp -rf apiextensions-apiserver kube-apiserver kube-controller-manager kube-scheduler kube-proxy kubelet /usr/bin
```



复制到 /usr/bin 目录下

**在 Worker 节点上，仅需安装 kubelet 和 kube-proxy 两个服务**

kubectl

kubectl 是用来操作集群的客户端命令行工具，需要为其配置集群连接信息。



kubectl 需要在第一台 master 上部署，以便完成集群的初始配置



```
cp kubectl /usr/bin && chmod 755 /usr/bin/kube* /usr/bin/apiextensions-apiserver
```

# 生成 kubectl 的 kubeconfig 文件  每个节点都要执行。

设置集群参数

```
kubectl config set-cluster kubernetes --certificate-authority=/etc/kubernetes/ssl/ca.pem --server=https://192.168.1.174:6443
```

设置客户端认证参数

```
kubectl config set-credentials admin --client-certificate=/etc/kubernetes/ssl/admin.pem \
--client-key=/etc/kubernetes/ssl/admin.key
```

设置上下文参数

```
kubectl config set-context kubernetes --cluster=kubernetes --user=admin
```

设置默认上下文

```
kubectl config use-context kubernetes
```

kubelet.pem 证书的OU字段值为 system:masters，kube-apiserver预定义的RoleBinding cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该Role授予了调用kube-apiserver相关API的权限



生成的kubeconfig被保存到 ~/.kube/config 文件





# 安装 Docker-CE Repo

curl https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo

更改为清华镜像源

sed -i 's#download.docker.com#mirrors.tuna.tsinghua.edu.cn/docker-ce#g'  /etc/yum.repos.d/docker-ce.repo

安装 Docker-CE

yum install -y docker-ce

配置

修改 Docker 目录(/var/lib/docker)

可选步骤



如默认 /var/lib 目录容量较小时，需要进行修改



本例中将 docker 目录由 /var/lib/docker 改为 /data/docker



操作如下



创建目录



mkdir -p -m 700 /data/docker/overlay2



修改 docker 配置 (vim /etc/docker/daemon.json)



```
{

  "exec-opts": ["native.cgroupdriver=systemd"],            

  "data-root": "/data/docker",

  "storage-driver": "overlay2",

  "storage-opts":["overlay2.override_kernel_check=true"],

  "selinux-enabled": false,

  "log-driver": "json-file",

  "log-opts": {

    "max-size": "500m",

    "max-file": "3"

  },

  "registry-mirrors": [

    "https://docker.mirrors.ustc.edu.cn/"

  ],

  "oom-score-adjust": -1000,

  "default-ulimits": {

    "nofile": {

      "Name": "nofile",

      "Hard": 655360,

      "Soft": 655360

    }

  }

}
```



cgroup配置为systemd，否则kubelet配置文件需要改动跟docker一致 cgroupDriver: systemd  比如 cgroupDriver: cgroupfs  否则会服务会报错。



启动 Docker，生成目录



```
systemctl start docker
```



# 安装依赖项

```
yum install -y libnetfilter_conntrack-devel libnetfilter_conntrack conntrack-tools ipvsadm ipset nmap-ncat bash-completion nscd chrony  
```





# 安装kube-apiserver

### 修改配置文件 /etc/kubernetes/apiserver           

```
###
# kubernetes system config
#
# The following values are used to configure the kube-apiserver
#

KUBE_API_ARGS="\
      --allow-privileged=true      \
      --secure-port=6443           \
      --bind-address=192.168.1.174   \
      --etcd-cafile=/etc/etcd/ssl/etcd-ca.pem                        \
      --etcd-certfile=/etc/etcd/ssl/etcd-client.pem                  \
      --etcd-keyfile=/etc/etcd/ssl/etcd-client.key                   \
      --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem              \
      --tls-private-key-file=/etc/kubernetes/ssl/apiserver.key       \
      --client-ca-file=/etc/kubernetes/ssl/ca.pem                    \
      --requestheader-client-ca-file=/etc/kubernetes/ssl/ca.pem      \
      --proxy-client-cert-file=/etc/kubernetes/ssl/proxy-client.pem  \
      --proxy-client-key-file=/etc/kubernetes/ssl/proxy-client.key   \
      --service-account-key-file=/etc/kubernetes/ssl/ca.key          \
      --kubelet-certificate-authority=/etc/kubernetes/ssl/ca.pem     \
      --kubelet-client-certificate=/etc/kubernetes/ssl/kube-apiserver-kubelet-client.pem \
      --kubelet-client-key=/etc/kubernetes/ssl/kube-apiserver-kubelet-client.key         \
      --authorization-mode=RBAC,Node   \
      --kubelet-https=true             \
      --anonymous-auth=false           \
      --apiserver-count=3              \
      --audit-log-maxage=30            \
      --audit-log-maxbackup=7          \
      --audit-log-maxsize=100          \
      --event-ttl=1h                   \
      --logtostderr=true               \
      --enable-bootstrap-token-auth    \
      --max-requests-inflight=3000     \
      --delete-collection-workers=3    \
      --service-cluster-ip-range=10.0.0.0/12       \
      --service-node-port-range=30000-35000        \
      --default-not-ready-toleration-seconds=10    \
      --default-unreachable-toleration-seconds=10  \
      --requestheader-allowed-names=aggregator     \
      --requestheader-extra-headers-prefix=X-Remote-Extra- \
      --requestheader-group-headers=X-Remote-Group         \
      --requestheader-username-headers=X-Remote-User       \
      --enable-aggregator-routing=true \
      --max-requests-inflight=3000     \
      --etcd-servers=https://192.168.1.174:2379,https://192.168.1.175:2379,https://192.168.1.177:2379 \
      --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota,NodeRestriction"
```

- `--insecure-port=0` 关闭非安全的8080端口, 此参数即将弃用
- `--bind-address=` 要监听的本机IP，此IP应该在证书签发时指定的IP列表内
- 如果使用了kubelet TLS Boostrap机制，则不能再指定`--kubelet-certificate-authority`、`--kubelet-client-certificate`和`--kubelet-client-key`选项，否则后续kube-apiserver校验kubelet证书时出现 *x509: certificate signed by unknown authority* 错误
- `--admission-control` 值必须包含ServiceAccount
- `--service-cluster-ip-range`指定Service Cluster IP地址段，该地址段不能路由可达
- `--service-node-port-range` 指定 NodePort 的端口范围
- 缺省情况下kubernetes对象保存在etcd /registry路径下，可以通过`--etcd-prefix`参数进行调整

### 配置systemd unit

/etc/systemd/system/kube-apiserver.service

```
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target
After=etcd.service

[Service]
EnvironmentFile=-/etc/kubernetes/apiserver
User=kube
ExecStart=/usr/bin/kube-apiserver $KUBE_API_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### Start & Enable kube-apiserver

```
systemctl daemon-reload
systemctl start  kube-apiserver
systemctl enable kube-apiserver
systemctl status kube-apiserver
```

### 授予 kube-apiserver 访问 kubelet API 权限

在执行 kubectl exec、run、logs 等命令时，apiserver 会将请求转发到 kubelet 的 https 端口。这里定义 RBAC 规则，授权 apiserver 使用的证书（apiserver.pem）用户名（CN：kuberntes）访问 kubelet API 的权限

```
kubectl create clusterrolebinding kube-apiserver:kubelet-apis \
               --clusterrole=system:kubelet-api-admin --user kubernetes
```

- --user指定的为apiserver.pem证书中CN指定的值



## 安装kube-controller-manager

### 生成 kube-controller-manager 的 kubeconfig 文件

#### 设置集群参数

```
kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/kubernetes/ssl/ca.pem \
        --server=https://192.168.1.174:6443 \
        --kubeconfig=kube-controller-manager.kubeconfig
```

#### 设置客户端认证参数

```
kubectl config set-credentials system:kube-controller-manager \
        --client-certificate=/etc/kubernetes/ssl/kube-controller-manager.pem \
        --client-key=/etc/kubernetes/ssl/kube-controller-manager.key \
        --kubeconfig=kube-controller-manager.kubeconfig
```

#### 设置上下文参数

```
kubectl config set-context system:kube-controller-manager \
        --cluster=kubernetes \
        --user=system:kube-controller-manager \
        --kubeconfig=kube-controller-manager.kubeconfig
```

#### 设置默认上下文

```
kubectl config use-context system:kube-controller-manager \
        --kubeconfig=kube-controller-manager.kubeconfig
```

### 修改配置文件 /etc/kubernetes/controller-manager

/etc/kubernetes/controller-manager

```
###
# The following values are used to configure the kubernetes controller-manager

# defaults from config and apiserver should be adequate

# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS="\
      --service-account-private-key-file=/etc/kubernetes/ssl/ca.key  \
      --requestheader-client-ca-file=/etc/kubernetes/ssl/ca.pem      \
      --cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem         \
      --cluster-signing-key-file=/etc/kubernetes/ssl/ca.key          \
      --root-ca-file=/etc/kubernetes/ssl/ca.pem     \
      --service-cluster-ip-range=10.0.0.0/12        \
      --cluster-cidr=10.64.0.0/10                   \
      --allocate-node-cidrs=true                    \
      --cluster-name=kubernetes                     \
      --leader-elect=true                           \
      --secure-port=10257                           \
      --logtostderr=true                            \
      --v=4                                         \
      --node-monitor-period=2s                      \
      --node-monitor-grace-period=16s               \
      --pod-eviction-timeout=30s                    \
      --use-service-account-credentials=true        \
      --controllers=*,bootstrapsigner,tokencleaner  \
      --horizontal-pod-autoscaler-sync-period=10s   \
      --feature-gates=RotateKubeletServerCertificate=true                             \
      --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig                 \
      --authentication-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig  \
      --authorization-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig"
```

- --cluster-cidr指定Cluster中Pod的CIDR范围，该网段在各Node间必须路由可达(flannel保证)
- --service-cluster-ip-range参数指定Cluster中Service的CIDR范围，该网络在各 Node间必须路由不可达，必须和kube-apiserver中的参数一致
- --cluster-signing-* 指定的证书和私钥文件用来签名为TLS BootStrap创建的证书和私钥
- --root-ca-file用来对kube-apiserver证书进行校验，指定该参数后，才会在Pod容器的ServiceAccount中放置该CA证书文件
- --leader-elect=true部署多台机器组成的master集群时选举产生一处于工作状态的 kube-controller-manager进程

### 配置systemd unit

/etc/systemd/system/kube-controller-manager.service

```
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=-/etc/kubernetes/controller-manager
User=kube
ExecStart=/usr/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### 配置 kubeconfig 文件的 ACL 权限

```
setfacl -m u:kube:r /etc/kubernetes/kube-controller-manager.kubeconfig
```

### Start & Enable kube-controller-manager

```
systemctl daemon-reload
systemctl start  kube-controller-manager
systemctl enable kube-controller-manager
systemctl status kube-controller-manager
```



## 安装kube-scheduler

### 生成 kube-scheduler 的 kubeconfig 文件

#### 设置集群参数

```
kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/kubernetes/ssl/ca.pem \
        --server=https://192.168.1.174:6443 \
        --kubeconfig=kube-scheduler.kubeconfig
```

#### 设置客户端认证参数

```
kubectl config set-credentials system:kube-scheduler \
        --client-certificate=/etc/kubernetes/ssl/kube-scheduler.pem \
        --client-key=/etc/kubernetes/ssl/kube-scheduler.key \
        --kubeconfig=kube-scheduler.kubeconfig
```

#### 设置上下文参数

```
kubectl config set-context system:kube-scheduler \
        --cluster=kubernetes \
        --user=system:kube-scheduler \
        --kubeconfig=kube-scheduler.kubeconfig
```

#### 设置默认上下文

```
kubectl config use-context system:kube-scheduler \
        --kubeconfig=kube-scheduler.kubeconfig
```

### 修改配置文件 /etc/kubernetes/scheduler

/etc/kubernetes/scheduler

```
###
# kubernetes scheduler config

# default config should be adequate

# Add your own!
KUBE_SCHEDULER_ARGS="\
      --address=127.0.0.1 \
      --leader-elect=true \
      --logtostderr=true \
      --v=4 \
      --kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \
      --authorization-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \
      --authentication-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig"
```

### 配置systemd unit

/etc/systemd/system/kube-scheduler.service

```
[Unit]
Description=Kubernetes Scheduler Plugin
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=-/etc/kubernetes/scheduler
User=kube
ExecStart=/usr/bin/kube-scheduler $KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### 配置 kubeconfig 文件的 ACL 权限

```
setfacl -m u:kube:r /etc/kubernetes/kube-scheduler.kubeconfig
```

### Start & Enable kube-scheduler

```
systemctl daemon-reload
systemctl start  kube-scheduler
systemctl enable kube-scheduler
systemctl status kube-scheduler
```

## 检查集群状态

```
kubectl get cs
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok                   
controller-manager   Healthy   ok                   
etcd-2               Healthy   {"health": "true"}   
etcd-1               Healthy   {"health": "true"}   
etcd-0               Healthy   {"health": "true"}  
```

*如 etcd、kube-apiserver、kube-controller-manager、kube-scheduler 全部运行正常，则会如上显示*



# Configuration HA kube-apiserver（可选）

使用 Nginx + Keepalived 提供4层代理，为Kubernetes集群提供 API Server 高可用。

**注意**

用作VIP的IP地址需在签发 apiserver 证书时添加至IP列表内。

## Nginx

### 安装

```
yum install -y nginx nginx-mod-stream
```

### 配置

#### nginx.conf

```
include /usr/share/nginx/modules/*.conf;
# Set L4 Proxy config
include conf.d/L4-Proxy/*.conf;

user nobody;
worker_processes 4;
worker_rlimit_nofile 65535;
events {
    use epoll;
    worker_connections 65535;
}
http {
    include mime.types;
    default_type application/octet-stream;
    log_format default '$remote_addr $remote_port $remote_user $time_iso8601 $status $body_bytes_sent '
                       '"$request" "$request_body" "$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 8 32k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 128k;
    sendfile on;
    keepalive_timeout 65;
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types text/plain application/x-javascript text/css application/xml text/vnd.wap.wml;
    gzip_vary on;
    open_file_cache max=32768 inactive=20s;
    open_file_cache_min_uses 1;
    open_file_cache_valid 30s;
    proxy_ignore_client_abort on;
    client_max_body_size 1G;
    client_body_buffer_size 256k;
    proxy_connect_timeout 30;
    proxy_send_timeout 30;
    proxy_read_timeout 60;
    proxy_buffer_size 256k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;
    proxy_temp_file_write_size 256k;
    proxy_http_version 1.1;

    include conf.d/*.conf;
}
```

#### conf.d/nginx-status.conf

```
server {
    listen 127.0.0.1:80;
    server_name localhost;

    location /nginx-status {
        stub_status     on;
        access_log      off;
    }
}
```

#### conf.d/L4-Proxy/k8s-apiservers.conf

```
stream {
    upstream k8s_apiserver {
        server 192.168.1.174:6443;
        server 192.168.1.175:6443;
        server 192.168.1.177:6443;
    }

    server {
        listen 6443;

        proxy_pass k8s_apiserver;
    }
}
```

更多Nginx配置请[参阅此处](https://github.com/Statemood/documents/tree/master/nginx)

### 启动

```
nginx
```

## Keepalived

### 安装

```
yum install -y keepalived
```

### 配置

#### /etc/keepalived/keepalived.conf

```
! Configuration File for keepalived
global_defs {
    router_id nginx-ha
}
vrrp_sync_group VG_1 {
    group {
        VI_1
    }
}
vrrp_script nginx_check {
    script "/usr/local/bin/check.sh"
    interval 3
    weight 2
}
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 18
    mcast_src_ip 192.168.20.21
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    track_script {
        nginx_check weight 0
    }
    virtual_ipaddress {
        192.168.20.18 dev eth0
    }
}
```

#### /usr/local/bin/check.sh

```
#! /bin/bash
http_url="localhost/nginx-status"
http_code=$(curl -sq -m 5 -o /dev/null $http_url -w %{http_code})

test $http_code = 200 && exit 0 || exit 1
```

#### Permission

```
chmod 755 /usr/local/bin/check.sh

chcon -u system_u -t bin_t /usr/local/bin/check.sh
```

### 打开6443端口

```
firewall-cmd --direct --permanent --add-rule ipv4 filter INPUT 0 --destination 224.0.0.18 --protocol vrrp -j ACCEPT
firewall-cmd --zone public --add-port 6443/tcp --permanent
firewall-cmd --reload
```

## 启动

```
systemctl start  keepalived
systemctl enable keepalived
systemctl status keepalived
```



## 安装kubelet

### Bootstrap Token Auth 和授予权限

kubelet 启动时查找 `--kubeletconfig` 参数对应的文件是否存在，如果不存在则使用 `--bootstrap-kubeconfig` 指定的 kubeconfig 文件向 kube-apiserver 发送证书签名请求 (CSR)。

kube-apiserver 收到 CSR 请求后，对其中的 Token 进行认证，认证通过后将请求的 user 设置为 system:bootstrap:，group 设置为 `system:bootstrappers`，这一过程称为 Bootstrap Token Auth。

默认情况下，这个 user 和 group 没有创建 CSR 的权限，kubelet 启动失败。

因此需要先创建一个 clusterrolebinding，将 group `system:bootstrappers` 和 clusterrole `system:node-bootstrapper` 进行绑定。

```
kubectl create clusterrolebinding kubelet-bootstrap \
        --clusterrole=system:node-bootstrapper \
        --group=system:bootstrappers
```

kubelet 启动后使用` --bootstrap-kubeconfig` 向 kube-apiserver 发送 CSR 请求，当这个 CSR 被 approve 后，kube-controller-manager 为 kubelet 创建 TLS 客户端证书、私钥和` --kubeletconfig` 文件。

*注意: kube-controller-manager 需要配置`--cluster-signing-cert-file` 和 `--cluster-signing-key-file` 参数，才会为 TLS Bootstrap 创建证书和私钥*。

### 生成 kubelet 的 bootstrapping kubeconfig 文件

#### 建立一个随机产生BOOTSTRAP_TOKEN, 并在集群内创建 Bootstrap Token Secret

*本步骤仅需执行一次，后续新增节点无需重复*

```
TOKEN_PUB=$(openssl rand -hex 3)
TOKEN_SECRET=$(openssl rand -hex 8)
BOOTSTRAP_TOKEN="${TOKEN_PUB}.${TOKEN_SECRET}"
kubectl -n kube-system create secret generic bootstrap-token-${TOKEN_PUB} \
      --type 'bootstrap.kubernetes.io/token' \
      --from-literal description="cluster bootstrap token" \
      --from-literal token-id=${TOKEN_PUB} \
      --from-literal token-secret=${TOKEN_SECRET} \
      --from-literal usage-bootstrap-authentication=true \
      --from-literal usage-bootstrap-signing=true
```

Token 必须满足 [a-z0-9]{6}.[a-z0-9]{16} 格式；以 . 分割，前面的部分被称作 Token ID, Token ID 并不是 “机密信息”，它可以暴露出去；相对的后面的部分称为 Token Secret, 它应该是保密的。

###### Token 启动引导过程

- 在集群内创建特定的 Bootstrap Token Secret ，该 Secret 将替代以前的 token.csv 内置用户声明文件
- 在集群内创建首次 TLS Bootstrap 申请证书的 ClusterRole、后续 renew Kubelet client/server 的 ClusterRole，以及其相关对应的 ClusterRoleBinding；并绑定到对应的组或用户
- 调整 Controller Manager 配置，以使其能自动签署相关证书和自动清理过期的 TLS Bootstrapping Token
- 生成特定的包含 TLS Bootstrapping Token 的 bootstrap.kubeconfig 以供 kubelet 启动时使用
- 调整 Kubelet 配置，使其首次启动加载 bootstrap.kubeconfig 并使用其中的 TLS Bootstrapping Token 完成首次证书申请 证书被 Controller Manager 签署，成功下发，Kubelet 自动重载完成引导流程
- 后续 Kubelet 自动 renew 相关证书
- 可选的: 集群搭建成功后立即清除 Bootstrap Token Secret ，或等待 Controller Manager 待其过期后删除，以防止被恶意利用

#### 设置集群参数

```
kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/kubernetes/ssl/ca.pem \
        --server=https://192.168.1.174:6443 \
        --kubeconfig=bootstrap.kubeconfig
```

#### 设置客户端认证参数

```
kubectl config set-credentials kubelet-bootstrap \
        --token=$BOOTSTRAP_TOKEN \
        --kubeconfig=bootstrap.kubeconfig
```

#### 生成默认上下文参数

```
kubectl config set-context default \
        --cluster=kubernetes \
        --user=kubelet-bootstrap \
        --kubeconfig=bootstrap.kubeconfig
```

#### 切换默认上下文

```
kubectl config use-context default \
        --kubeconfig=bootstrap.kubeconfig
```

- --embed-certs为true时表示将certificate-authority证书写入到生成的bootstrap.kubeconfig文件中
- 设置kubelet客户端认证参数时没有指定秘钥和证书，后续由kube-apiserver自动生成
- 生成的bootstrap.kubeconfig文件会在当前文件路径下
- 向 kubeconfig 写入的是 Token, bootstrap 结束后 kube-controller-manager 将为 kubelet 自动创建 client 和 server 证书

### 修改 kubelet 配置文件

从v1.10版本开始，部分kubelet参数需要在配置文件中配置，建议尽快替换

/etc/kubernetes/kubelet.yaml

```
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 0.0.0.0
cgroupDriver: systemd
cgroupsPerQOS: true
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
    cacheTTL: 2m0s
  x509:
    clientCAFile: "/etc/kubernetes/ssl/ca.pem"
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
readOnlyPort: 0
port: 10250
clusterDomain: "cluster.local"
clusterDNS:
- "10.0.0.2"
configMapAndSecretChangeDetectionStrategy: Watch
containerLogMaxFiles: 5
containerLogMaxSize: 10Mi
contentType: application/vnd.kubernetes.protobuf
cpuCFSQuota: true
cpuCFSQuotaPeriod: 100ms
cpuManagerPolicy: none
cpuManagerReconcilePeriod: 10s
enableControllerAttachDetach: true
enableDebuggingHandlers: true
enableContentionProfiling: true
serverTLSBootstrap: true
enforceNodeAllocatable:
- pods
eventBurst: 10
eventRecordQPS: 5
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
evictionPressureTransitionPeriod: 5m0s
failSwapOn: true
fileCheckFrequency: 20s
hairpinMode: promiscuous-bridge
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 20s
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
imageMinimumGCAge: 2m0s
iptablesDropBit: 15
iptablesMasqueradeBit: 14
kubeAPIBurst: 10
kubeAPIQPS: 5
makeIPTablesUtilChains: true
maxOpenFiles: 1000000
maxPods: 110
nodeLeaseDurationSeconds: 40
nodeStatusReportFrequency: 1m0s
nodeStatusUpdateFrequency: 10s
oomScoreAdj: -999
podPidsLimit: -1
registryBurst: 10
registryPullQPS: 5
resolvConf: /etc/resolv.conf
rotateCertificates: true
runtimeRequestTimeout: 2m0s
serializeImagePulls: true
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 4h0m0s
syncFrequency: 1m0s
topologyManagerPolicy: none
volumeStatsAggPeriod: 1m0s
```

/etc/kubernetes/kubelet

```
KUBELET_ARGS="\
      --hostname-override=k8s-1 \
      --config=/etc/kubernetes/kubelet.yaml \
      --pod-infra-container-image=rancher/pause-amd64:3.1 \
      --bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \
      --kubeconfig=/etc/kubernetes/kubelet.kubeconfig  \
      --cert-dir=/etc/kubernetes/ssl \
      --root-dir=/data/kubelet \
      --network-plugin=cni \
      --logtostderr=true \
      --v=4"
```

- kubelet 启动后使用 --bootstrap-kubeconfig 向 kube-apiserver 发送 CSR 请求，当这个CSR 被 approve 后，kube-controller-manager 为 kubelet 创建 TLS 客户端证书、私钥和 --kubeletconfig 文件

- kube-controller-manager 需要配置 --cluster-signing-cert-file 和 --cluster-signing-key-file 参数，才会为 TLS Bootstrap 创建证书和私钥

  

### 修改 kubelet 数据目录(/data/kubelet)

- 创建目录

  ```
  mkdir -p -m 700 /data/kubelet
  ```

- 修改目录用户

  ```
  chown kube:kube /data/kubelet
  ```


### 创建静态Pod目录

```
mkdir -p /etc/kubernetes/manifests 
```

### 配置 kubeconfig 文件的 ACL 权限

```
setfacl -m u:kube:r /etc/kubernetes/*.kubeconfig
```

### 配置systemd unit

/etc/systemd/system/kubelet.service

```
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/data/kubelet
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/usr/bin/kubelet $KUBELET_ARGS
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Start & Enable kubelet

```
systemctl daemon-reload
systemctl start  kubelet
systemctl enable kubelet
systemctl status kubelet
```

### 批准kubelet的TLS请求

#### 查看未授权的CSR请求

```
kubectl get csr
```

#### 自动 approve CSR 请求

创建三个 ClusterRoleBinding，分别用于自动 approve client、renew client、renew server 证书

自动批准 system:bootstrappers 组用户 TLS bootstrapping 首次申请证书的 CSR 请求

```
kubectl create clusterrolebinding auto-approve-csrs-for-group \
        --clusterrole=system:certificates.k8s.io:certificatesigningrequests:nodeclient \
        --group=system:bootstrappers
```

自动批准 system:nodes 组用户更新 kubelet 自身与 apiserver 通讯证书的 CSR 请求

```
kubectl create clusterrolebinding node-client-cert-renewal \
        --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeclient \
        --group=system:nodes
```

创建自动批准相关 CSR 请求的 ClusterRole

```
kubectl create clusterrole approve-node-server-renewal-csr --verb=create \
        --resource=certificatesigningrequests/selfnodeserver \
        --resource-name=certificates.k8s.io
```

自动批准 system:nodes 组用户更新 kubelet 10250 api 端口证书的 CSR 请求

```
kubectl create clusterrolebinding node-server-cert-renewal \
        --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeserver \
        --group=system:nodes
```

#### 查看 CSR

```
kubectl get csr
```

- Pending 的 CSR 用于创建 kubelet server 证书，需要手动 approve
- 基于安全性考虑，CSR approving controllers 不会自动 approve kubelet server 证书签名请求，需要手动 approve

#### Approve CSR

```
kubectl certificate approve csr-bx5q2
```

#### 确认 CSR 状态

```
kubectl get csr
```

- kube-controller-manager 已经为各个节点生成了kubelet公私钥和kubeconfig

#### 确认节点是否已加入集群

```
kubectl get no
```



journalctl -xefu kubelet  # 检查服务启动错误命令

cgroupDriver: systemd 需要跟docker一致 比如 cgroupDriver: cgroupfs  否则会服务会报错。

kubectl get csr |grep Pending |awk '{print $1}' |xargs kubectl certificate approve # 修改csr状态

kubectl delete csr xxx  # 删除csr





## 安装kube-proxy

### 生成kube-proxy的kubeconfig文件

#### 设置集群参数

```
kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/kubernetes/ssl/ca.pem \
        --server=https://192.168.1.174:6443 \
        --kubeconfig=kube-proxy.kubeconfig    
```

#### 设置客户端认证参数

```
kubectl config set-credentials kube-proxy \
        --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
        --client-key=/etc/kubernetes/ssl/kube-proxy.key \
        --kubeconfig=kube-proxy.kubeconfig
```

#### 生成上下文参数

```
kubectl config set-context default \
        --cluster=kubernetes \
        --user=kube-proxy \
        --kubeconfig=kube-proxy.kubeconfig
```

#### 切换默认上下文

```
kubectl config use-context default \
        --kubeconfig=kube-proxy.kubeconfig
```

- --embed-cert 都为 true，这会将certificate-authority、client-certificate和client-key指向的证书文件内容写入到生成的kube-proxy.kubeconfig文件中
- kube-proxy.pem证书中CN为system:kube-proxy，kube-apiserver预定义的 RoleBinding cluster-admin将User system:kube-proxy与Role system:node-proxier绑定，该Role授予了调用kube-apiserver Proxy相关API的权限

### 修改配置文件 /etc/kubernetes/proxy.yaml

*从v1.10版本开始，kube-proxy参数需要在配置文件中配置*

/etc/kubernetes/kube-proxy.yaml

```
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
bindAddress: 0.0.0.0
clientConnection:
  acceptContentTypes: ""
  burst: 10
  contentType: application/vnd.kubernetes.protobuf
  kubeconfig: /etc/kubernetes/kube-proxy.kubeconfig
  qps: 5
clusterCIDR: 10.80.0.0/12
configSyncPeriod: 15m0s
conntrack:
  maxPerCore: 32768
  min: 131072
  tcpCloseWaitTimeout: 1h0m0s
  tcpEstablishedTimeout: 24h0m0s
enableProfiling: false
healthzBindAddress: 0.0.0.0:10256
hostnameOverride: "192.168.1.174"
iptables:
  masqueradeAll: false
  masqueradeBit: 14
  minSyncPeriod: 0s
  syncPeriod: 30s
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 2s
  scheduler: wlc
  strictARP: false
  syncPeriod: 30s
metricsBindAddress: 127.0.0.1:10249
mode: ipvs
nodePortAddresses: null
oomScoreAdj: -999
portRange: ""
udpIdleTimeout: 250ms
winkernel:
  enableDSR: false
  networkName: ""
  sourceVip: ""#
```

- 注意替换 `hostnameOverride`

### 配置 kubeconfig 文件的 ACL 权限

```
setfacl -m u:kube:r /etc/kubernetes/*.kubeconfig
```

### 配置 systemd unit

/etc/systemd/system/kube-proxy.service

```
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target
Requires=network.service

[Service]
ExecStart=/usr/bin/kube-proxy --config=/etc/kubernetes/kube-proxy.yaml
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### Start & Enable kube-proxy

```
systemctl daemon-reload
systemctl start  kube-proxy
systemctl enable kube-proxy
systemctl status kube-proxy
```



# 添加一个新的 Worker 节点

## 前期准备

1. [系统配置](#系统配置)
2. [添加用户](#添加用户（在所有节点执行）)
3. [安装 Docker-CE](#安装 docker-ce repo)
4. [安装依赖](#安装依赖项)

## kubelet

1. 复制文件

   ```
   /etc/kubernetes/bootstrap.kubeconfig
   /etc/kubernetes/kubelet.kubeconfig
   /etc/kubernetes/kubelet.yaml
   /etc/kubernetes/kubelet
   /etc/kubernetes/ssl/ca.pem
   /usr/bin/kubelet
   /etc/systemd/system/kubelet.service
   ```

   *复制到文件对应位置*

2. **修改配置**

   文件 /etc/kubernetes/kubelet

   修改 `--hostname-override`

3. 启动服务

   ```
   systemctl daemon-reload
   systemctl start  kubelet
   systemctl enable kubelet
   systemctl status kubelet
   ```

​       kubectl get csr |grep Pending |awk '{print $1}' |xargs kubectl certificate approve # 修改csr状态

​       在其他节点测试连接API-server

​      **验证API-server访问**

```
 cd /etc/kubernetes/ssl
 
 curl -sk --cacert $PWD/ca.pem --cert $PWD/admin.pem --key $PWD/admin.key https://192.168.1.174:6443
```

​       如果验证可以访问api服务，还是不能加入集群。可以查看SSL目录的证书，是不是复制多了，可以 在ssl目录下执行

```
 rm -rf kubelet-*
```

```
 systemctl start  kubelet &&  systemctl status kubelet
```

## kube-proxy

1. 复制文件

   ```
   /etc/kubernetes/kube-proxy.kubeconfig
   /etc/kubernetes/kube-proxy.yaml
   /etc/kubernetes/ssl/kube-proxy.key
   /etc/kubernetes/ssl/kube-proxy.pem
   /usr/bin/kube-proxy
   /etc/systemd/system/kube-proxy.service
   ```

2. 修改配置

   文件 */etc/kubernetes/kube-proxy.yaml*

   修改 `hostnameOverride`

3. 启动服务

   ```
   systemctl daemon-reload
   systemctl start  kube-proxy
   systemctl enable kube-proxy
   systemctl status kube-proxy
   ```





## Calico(与flannel任选一种部署)

### Calico 简介

Calico组件：

- Felix：Calico agent，运行在每个node节点上，为容器设置网络信息、IP、路由规则、iptables规则等
- etcd：calico后端数据存储
- BIRD：BGP Client，负责把Felix在各个node节点上设置的路由信息广播到Calico网络（通过BGP协议）
- BGP Router Reflector：大规模集群的分级路由分发
- Calico：Calico命令行管理工具

### Calico 配置

下载calico yaml

```
curl -O https://docs.projectcalico.org/v3.12/manifests/calico-etcd.yaml
```

修改yaml,以下配置项修改为对应pod地址段

```
typha_service_name: "calico-typha”
```

在`CALICO_IPV4POOL_CIDR`配置下添加一行`IP_AUTODETECTION_METHOD`配置

```
            - name: CALICO_IPV4POOL_CIDR
              value: "10.64.0.0/10"
            - name: IP_AUTODETECTION_METHOD
              value: "interface=ens160"
            - name: CALICO_IPV4POOL_IPIP
              value: "off"
```

将以下配置删除注释，并添加前面etcd-client证书（etcd配置了TLS安全认证，则需要指定相应的ca、cert、key等文件）

```
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: calico-etcd-secrets
  namespace: kube-system
data:
  etcd-key: (cat etcd-client.key | base64 -w 0) #将输出结果填写在这里
  etcd-cert: (cat etcd-client.pem | base64 -w 0) #将输出结果填写在这里
  etcd-ca: (cat etcd-ca.pem | base64 -w 0) #将输出结果填写在这里
```

修改configmap

```
kind: ConfigMap
apiVersion: v1
metadata:
  name: calico-config
  namespace: kube-system
data:
  etcd_endpoints: "https://192.168.20.31:2379,https://192.168.20.32:2379,https://192.168.20.33:2379"
  etcd_ca: /calico-secrets/etcd-ca"
  etcd_cert: /calico-secrets/etcd-cert"
  etcd_key: /calico-secrets/etcd-key"
```

ConfigMap部分主要参数：

- etcd_endpoints：Calico使用etcd来保存网络拓扑和状态，该参数指定etcd的地址，可以使用K8S Master所用的etcd，也可以另外搭建。
- calico_backend：Calico的后端，默认为bird。
- cni_network_config：符合CNI规范的网络配置，其中type=calico表示，Kubelet从 CNI_PATH(默认为/opt/cni/bin)找名为calico的可执行文件，用于容器IP地址的分配。

通过DaemonSet部署的calico-node服务Pod里包含两个容器：

- calico-node：calico服务程序，用于设置Pod的网络资源，保证pod的网络与各Node互联互通，它还需要以HostNetwork模式运行，直接使用宿主机网络。
- install-cni：在各Node上安装CNI二进制文件到/opt/cni/bin目录下，并安装相应的网络配置文件到/etc/cni/net.d目录下。

calico-node服务的主要参数：

- CALICO_IPV4POOL_CIDR： Calico IPAM的IP地址池，Pod的IP地址将从该池中进行分配。
- CALICO_IPV4POOL_IPIP：是否启用IPIP模式，启用IPIP模式时，Calico将在node上创建一个tunl0的虚拟隧道。
- FELIX_LOGSEVERITYSCREEN： 日志级别。
- FELIX_IPV6SUPPORT ： 是否启用IPV6。

 IP Pool可以使用两种模式：BGP或IPIP。使用IPIP模式时，设置 CALICO_IPV4POOL_IPIP="always"，不使用IPIP模式时，设置为"off"，此时将使用BGP模式。

```
IPIP是一种将各Node的路由之间做一个tunnel，再把两个网络连接起来的模式，启用IPIP模式时，Calico将在各Node上创建一个名为"tunl0"的虚拟网络接口。
```

将以下镜像修改为自己的镜像仓库

```
image: calico/cni:v3.9.1
image: calico/pod2daemon-flexvol:v3.9.1
image: calico/node:v3.9.1
image: calico/kube-controllers:v3.9.1
kubectl apply -f calico-etcd.yaml
```

主机上会生成了一个tun10的接口

```
# ip route
172.54.2.192/26 via 172.16.90.205 dev tunl0 proto bird onlink
blackhole 172.63.185.0/26 proto bird
# ip route
blackhole 172.54.2.192/26 proto bird
172.63.185.0/26 via 172.16.90.204 dev tunl0 proto bird onlink
```

- 如果设置CALICO_IPV4POOL_IPIP="off" ，即不使用IPIP模式，则Calico将不会创建tunl0网络接口，路由规则直接使用物理机网卡作为路由器转发。



## 安装Flannel



Flannel支持的后端：

- VXLAN：使用内核中的VXLAN封装数据包。
- host-gw：使用host-gw通过远程机器IP创建到子网的IP路由。
- UDP：如果网络和内核阻止使用VXLAN或host-gw，请仅使用UDP进行调试。
- ALIVPC：在阿里云VPC路由表中创建IP路由，这减轻了Flannel单独创建接口的需要。阿里云VPC将每个路由表的条目限制为50。
- AWS VPC：在AWS VPC路由表中创建IP路由。由于AWS了解IP，因此可以将ELB设置为直接路由到该容器。AWS将每个路由表的条目限制为50。
- GCE：GCE不使用封装，而是操纵IP路由以实现最高性能。因此，不会创建单独的Flannel 接口。GCE限制每个项目的路由为100。
- IPIP：使用内核IPIP封装数据包。IPIP类隧道是最简单的。它具有最低的开销，但只能封装IPv4单播流量，因此您将无法设置OSPF，RIP或任何其他基于组播的协议。



```
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

```
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-amd64
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-arm64
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-arm
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-ppc64le
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-s390x
```



 为镜像打tag，保持和yaml文件一样。



```
docker tag registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-amd64 quay.io/coreos/flannel:v0.12.0-amd64
docker tag registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-arm64 quay.io/coreos/flannel:v0.12.0-arm64
docker tag registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-arm quay.io/coreos/flannel:v0.12.0-arm
docker tag registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-ppc64le quay.io/coreos/flannel:v0.12.0-ppc64le
docker tag registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-s390x quay.io/coreos/flannel:v0.12.0-s390x
```

加载flannel

```
kubectl apply -f /opt/kube-flannel.yml

删除应用

kubectl delete -f /opt/kube-flannel.yml
```



如出现无法跨节点通信，请执行以下命令

```
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -L -n
```

查看pod状态

```
kubectl get pod --all-namespaces -o wide

kubectl get no
```

检查/opt/cni/bin目录下，发现没有文件，

于是执行

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum clean all
yum install kubernetes-cni -y
```

# Deploy CoreDNS

- [使用 CoreDNS 进行服务发现](https://kubernetes.io/zh/docs/tasks/administer-cluster/coredns/)
- [CoreDNS 资源需求计算公式](https://github.com/coredns/deployment/blob/master/kubernetes/Scaling_CoreDNS.md)

镜像仓库：https://hub.docker.com/r/coredns/coredns/tags

最新镜像：coredns/coredns

## 部署流程

#### 下载文件

```
curl -LO https://github.com/coredns/deployment/raw/master/kubernetes/deploy.sh
curl -LO https://github.com/coredns/deployment/raw/master/kubernetes/coredns.yaml.sed
```

*可修改文件 `coredns.yaml.sed` 中 `image` 为最新版本镜像*

#### 部署服务

```
sh ./deploy.sh | kubectl apply -f -
```

#### 查看服务

查看Pod状态

```
kubectl get po -o wide -n kube-system
```

查看Service信息

```
kubectl get svc -n kube-system
```

- *CoreDNS 的 Service 名称为 `kube-dns`*

#### 配置kubelet

确认文件 */etc/kubernetes/kubelet.yaml* 是否包含以下内容，*172.55.0.2* 即为当前CoreDNS Service IP

```
clusterDomain: "cluster.local"
clusterDNS:
- "172.55.0.2"
```

*如修改了 kubelet.yaml 文件，则应重启 kubelet 以便应用更新*

#### 验证服务

启动一个新的或进入已有Pod中，使用 `ping`、 `nslookup`、`dig` 等命令进行测试。

## 配置说明

*常用配置如下, 更多信息请参阅 [CoreDNS ConfigMap 选项](https://kubernetes.io/zh/docs/tasks/administer-cluster/dns-custom-nameservers/)*

- `loadbalance`：提供基于DNS的负载均衡功能。
- `loop`：检测在DNS解析过程中出现的简单循环问题。
- `cache`：提供前端缓存功能。
- `health`：对endpoint进行健康检查。
- `kubernetes`：从kubernetes中读取zone数据。
- `etcd`：从etcd读取zone数据，可以用于自定义域名记录。
- `file`：从RFC1035格式文件中读取zone数据。
- `hosts`：使用/etc/hosts文件或其他文件读取zone数据，可以用于定义域名记录。
- `auto`：从磁盘中自动加载区域文件。
- `reload`：定时自动重新加载Corefile配置。
- `forward`：转发域名查询到上游DNS服务器。
- `proxy`：转发特定的域名查询到多个其他DNS服务器，同时提供到多个DNS服务器的负载均衡功能。
- `prometheus`：为Prometheus提供采集性能指标数据的URL。
- `pprof`：在URL路径/debug/pprof下提供运行时的性能数据。
- `log`：对DNS查询进行日志记录。
- `errors`：对错误信息进行日志记录。



# Deploy Node Local DNS

See [Nodelocal DNS Cache](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns/nodelocaldns).

# Deploy Kubernetes Dashboard

For more details, see [Kubernetes Dashboard](https://github.com/kubernetes/dashboard).



# Deploy Ingress Controller

## 1. Ingress 是什么？

- Ingress 是一个封装了的Nginx, 基于 Openresty。
- 通常情况下，service和pod的IP仅可在集群内部访问。集群外部的请求需要通过负载均衡转发到service在Node上暴露的NodePort上，然后再由kube-proxy将其转发给相关的Pod。
- 而Ingress就是为进入集群的请求提供路由规则的集合。
- Ingress可以给service提供集群外部访问的URL、负载均衡、SSL终止、HTTP路由等。为了配置这些Ingress规则，集群管理员需要部署一个Ingress controller，它监听Ingress和service的变化，并根据规则配置负载均衡并提供访问入口。

## 2. Ingress 安装

### 2.1 获取 Yaml 文件

- 下载文件

  ```
  curl -LO https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
  ```

### 2.4 启动

- 创建 Controller

  ```
  kubectl create -f mandatory.yaml
  ```

- 创建 Service

  - ingress-controller-service.yaml

    ```
    apiVersion: v1
    kind: Service
    metadata:
      name: ingress-nginx
      namespace: ingress-nginx
    spec:
      type: NodePort
      ports:
      - name: http
        port: 80
        targetPort: 80
        nodePort: 30080
        protocol: TCP
      - name: https
        port: 443
        targetPort: 443
        nodePort: 30443
        protocol: TCP
      selector:
        app: ingress-nginx
    ```

### 2.5 查看状态

```
kubectl get po -o wide -n ingress-nginx
```

## 3. 高可用

### 3.1 Keepalived

- VIP 192.168.50.60

### 3.2 Nginx L4 Proxy

#### 3.2.1 安装 Nginx

- 使用 yum 安装

  ```
  yum install -y nginx
  ```

#### 3.2.2 配置 Nginx

- 修改 Nginx 配置文件 */etc/nginx/nginx.conf*

  请注意 Nginx 配置文件路径可能处于自己的安装目录下

  ```
  user nginx;
  worker_processes auto;
  error_log /var/log/nginx/error.log;
  
  pid /run/nginx.pid;
  
  include /usr/share/nginx/modules/*.conf;
  
  events {
      worker_connections 1024;
  }
  
  stream {
      upstream http_80 {
          server 192.168.50.60:30080;
      }
      upstream https_443 {
          server 192.168.50.60:30443;
      }
      server {
          listen 80;
          proxy_pass http_80;
      }
      server {
          listen 443;
          proxy_pass https_443;
      }
  }
  http {
      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
  
      access_log /var/log/nginx/access.log  main;
      
      sendfile            on;
      tcp_nopush          on;
      tcp_nodelay         on;
      keepalive_timeout   65;
      types_hash_max_size 2048;
      include             /etc/nginx/mime.types;
      default_type        application/octet-stream;
      include /etc/nginx/conf.d/*.conf;
  }
  ```

#### 3.2.3 测试 Nginx 配置文件是否正确

- 使用 nginx 命令

  ```
  nginx -t
  ```

- 如正常一般会显示类似如下信息:

  ```
  nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
  nginx: configuration file /etc/nginx/nginx.conf test is successful
  ```

- 如有异常则按提示行及指令进行检查

### 4. 创建项目域名配置

- 文件 demo-php.yaml

  ```
  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    name: demo-php
    namespace: project
  spec:
    rules:
    - host: h.linge.io
      http:
        paths:
        - backend:
            serviceName: demo-php
            servicePort: 8080
  ```

- 创建

  ```
  kubectl create -f demo-php.yaml
  ```

- 访问

  - 直接访问域名 http://h.linge.io/ 即可



## Use Ceph RBD for Storage Class

[什么是 Storage Class?](https://kubernetes.io/zh/docs/concepts/storage/storage-classes/)

Ceph

- [Intro to Ceph](https://docs.ceph.com/docs/master/start/intro/)
- [Ceph RBD (*Ceph's RADOS Block Devices*)](https://docs.ceph.com/docs/master/rbd/)
- [Ceph RDB (*for storage class*)](https://kubernetes.io/zh/docs/concepts/storage/storage-classes/#ceph-rbd)



## 前言

随着越来越多的应用迁移到 Kubernetes 中运行之后，一些有状态应用就需要稳定可靠的分布式网络存储提供数据持久化，这里主要介绍如何通过基于 Ceph RBD 的 Storage Class 进行数据持久化。

## 环境

#### 前置条件

- 首先有一个部署好的 Ceph 集群；
- 其次有一个部署好的 Kubernetes 集群。

## 接入步骤

为 Kubernetes 配置基于 Ceph RBD 的 Stroage Class 需要分为两个步骤进行。

### Step 1. Ceph

*以下步骤在 Ceph 集群节点上执行*

#### Key client.admin

获取 client.admin key

```
ceph auth get-key client.admin | base64
```

#### Key client.kube

创建一个用户 kube, 权限： mon = r, osd pool kube = rwx

```
ceph auth add client.kube mon 'allow r' osd 'allow rwx pool=kube'
```

获取 client.kebe key

```
ceph auth get-key client.kube | base64
```

### Step 2. Kubernetes

*以下步骤在具有 kubectl 的节点上操作*

主要有三个步骤：

- 创建 Storage Class
- 创建 Ceph Admin Secret
- 创建 Ceph Secret

#### 配置并创建 Storage Class

修改编排文件 storage-class.yaml

```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: data
provisioner: kubernetes.io/rbd
parameters:
  monitors: 192.168.1.100:6789,192.168.1.101:6789,192.168.1.102:6789
  pool: data
  adminId: admin
  adminSecretNamespace: kube-system
  adminSecretName: ceph-admin-secret
  userId: kube
  userSecretNamespace: kube-system
  userSecretName: ceph-secret
  imageFormat: "2"
  imageFeatures: layering
```

*以下字段配置，请根据自己场景修改*

- `monitors` 对应的Ceph 集群 Monitor 服务器 IP
- `pool` 对应 ceph rbd pool

更多信息请参阅[Ceph RDB (*for storage class*)](https://kubernetes.io/zh/docs/concepts/storage/storage-classes/#ceph-rbd)

创建 Storage Class

```
kubectl create -f storage-class.yaml
```

查看 Storage Class

```
kubectl get sc
```

#### 创建 ceph-admin-secret

secret-admin.yaml

```
apiVersion: v1
kind: Secret
metadata:
  name: ceph-admin-secret
  namespace: kube-system
type: "kubernetes.io/rbd"
data:
  # ceph auth get-key client.admin | base64
  key: QVFCSzNlUmR1aEFmQmhBQS9LUWlxOERwR2FTbWNLeUxyczNZeHc9PQ==
```

`key` 填入 *client.admin* 的 key, 获取 Key 方式见上方操作。

*ceph-admin-secret 仅创建在 Namespace kube-system 中*

创建 Ceph Admin Secret

```
kubectl create -f ceph-admin-secret.yaml
```

#### 创建 ceph-secret

```
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
  namespace: kube-system
type: "kubernetes.io/rbd"
data:
  # ceph auth add client.kube mon 'allow r' osd 'allow rwx pool=kube'
  # ceph auth get-key client.kube | base64
  key: QVFCWEdveGUwS0dWQWhBQW4wMWZ6U3BpYVp2dkxPR3B3bncrcEE9PQ==
```

`key` 填入 *client.kube* 的 key, 获取 Key 方式见上方操作。

*ceph-secret 创建在所有需要使用此 Storage Class 的 Namespace 中*

创建 Ceph Secret

```
kubectl create -f ceph-secret.yaml
```

### Demo

本段通过接入两个不同类型的服务，来演示 *Deployment* 和 *StatefulSet* 下如何使用 Storage Class 进行数据持久化。

#### Deployment

部署一个 Redis 服务

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: data-redis-myredis
  annotations:
    volume.beta.kubernetes.io/storage-class: data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Service

metadata:
  name: myredis

spec:
  ports:
  - port: 6379
  selector:
    app: myredis
---
apiVersion: apps/v1
kind: Deployment

metadata:
  name: myredis

spec:
  replicas: 1
  selector:
    matchLabels:
      app: myredis
  template:
    metadata:
      labels:
        app: myredis
    spec:
      containers:
      - name: redis
        image: statemood/redis:5.0.7
        imagePullPolicy: Always
        ports:
        - containerPort: 6379
        resources:
          requests:
            cpu: 300m
            memory: 1Gi
          limits:
            cpu: 300m
            memory: 1Gi
        livenessProbe:
          tcpSocket:
            port: 6379
          initialDelaySeconds: 10
          timeoutSeconds: 3
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: 6379
          initialDelaySeconds: 10
          timeoutSeconds: 3
          periodSeconds: 10
        volumeMounts:
        - name: data
          mountPath: /var/lib/redis
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: data-redis-myredis
```

#### StatefulSet

部署 Zookeeper 集群

```
apiVersion: v1
kind: Service
metadata:
  name: zk-svc
  labels:
    app: zk-svc
spec:
  ports:
  - port: 2888
    name: server
  - port: 3888
    name: leader-election
  clusterIP: None
  selector:
    app: zk
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: zk-cm
data:
  jvm.heap: "1000"
  tick: "2000"
  init: "10"
  sync: "5"
  client.cnxns: "300"
  snap.retain: "7"
  purge.interval: "24"
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: zk-pdb
spec:
  selector:
    matchLabels:
      app: zk
  minAvailable: 2
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zk
spec:
  serviceName: zk-svc
  replicas: 3
  selector:
    matchLabels:
      app: zk
  template:
    metadata:
      labels:
        app: zk
    spec:
      initContainers:
      - name: init-dir
        image: statemood/alpine:3.11
        command:
        - /bin/sh
        - -c
        - mkdir -p /data/zk && chown -v 567. /data/zk
        volumeMounts:
        - name: data
          mountPath: /data
      containers:
      - name: zk
        imagePullPolicy: Always
        image: statemood/zookeeper:3.6.0
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        ports:
        - containerPort: 2181
          name: client
        - containerPort: 2888
          name: server
        - containerPort: 3888
          name: leader-election
        - containerPort: 8080
          name: admin
        env:
        - name : ZK_REPLICAS
          value: "3"
        - name:  ZK_4LW_COMMANDS_WHITELIST
          value: "ruok, cons, stat, mntr"
        - name : ZK_SERVER_HEAP
          valueFrom:
            configMapKeyRef:
                name: zk-cm
                key: jvm.heap
        - name : ZK_TICK_TIME
          valueFrom:
            configMapKeyRef:
                name: zk-cm
                key: tick
        - name : ZK_INIT_LIMIT
          valueFrom:
            configMapKeyRef:
                name: zk-cm
                key: init
        - name : ZK_SYNC_LIMIT
          valueFrom:
            configMapKeyRef:
                name: zk-cm
                key: sync
        - name : ZK_MAX_CLIENT_CNXNS
          valueFrom:
            configMapKeyRef:
                name: zk-cm
                key: client.cnxns
        - name: ZK_SNAP_RETAIN_COUNT
          valueFrom:
            configMapKeyRef:
                name: zk-cm
                key: snap.retain
        - name: ZK_PURGE_INTERVAL
          valueFrom:
            configMapKeyRef:
                name: zk-cm
                key: purge.interval
        - name: ZK_LOG_DIR
          value: "/tmp"
        - name: ZK_CLIENT_PORT
          value: "2181"
        - name: ZK_SERVER_PORT
          value: "2888"
        - name: ZK_ELECTION_PORT
          value: "3888"
        readinessProbe:
          exec:
            command:
            - "zkOk.sh"
          initialDelaySeconds: 10
          timeoutSeconds: 5
        livenessProbe:
          exec:
            command:
            - "zkOk.sh"
          initialDelaySeconds: 10
          timeoutSeconds: 5
        volumeMounts:
        - name: data
          mountPath: /data
        securityContext:
          runAsUser: 567
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      storageClassName: data
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```






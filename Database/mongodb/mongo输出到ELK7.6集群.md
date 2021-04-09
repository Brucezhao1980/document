**mongo输出到ELK7.6集群**



**由于ELK7.6版本配置变更。多点集群配置如下：**

es01：

```
cluster.name: my-cluster
node.name: ${HOSTNAME}
path.data: /opt/elk/elasticsearch/data
path.logs: /opt/elk/elasticsearch/logs
bootstrap.memory_lock: false
network.host: 172.31.114.7
http.port: 9200
transport.tcp.port: 9300
discovery.seed_hosts: ["172.31.114.7", "172.31.114.8", "172.31.114.9"]
cluster.initial_master_nodes: ["172.31.114.7", "172.31.114.8", "172.31.114.9"]
http.cors.enabled: true
http.cors.allow-origin: "*"
```

es02：

```
cluster.name: my-cluster
node.name: ${HOSTNAME}
path.data: /opt/elk/elasticsearch/data
path.logs: /opt/elk/elasticsearch/logs
bootstrap.memory_lock: false
network.host: 172.31.114.8
http.port: 9200
transport.tcp.port: 9300
discovery.seed_hosts: ["172.31.114.7", "172.31.114.8", "172.31.114.9"]
cluster.initial_master_nodes: ["172.31.114.7", "172.31.114.8", "172.31.114.9"]
http.cors.enabled: true
http.cors.allow-origin: "*"
```

es03：

```
cluster.name: my-cluster
node.name: ${HOSTNAME}
path.data: /opt/elk/elasticsearch/data
path.logs: /opt/elk/elasticsearch/logs
bootstrap.memory_lock: false
network.host: 172.31.114.9
http.port: 9200
transport.tcp.port: 9300
#network.publish_host: 172.31.114.7
discovery.seed_hosts: ["172.31.114.7", "172.31.114.8", "172.31.114.9"]
cluster.initial_master_nodes: ["172.31.114.7", "172.31.114.8", "172.31.114.9"]
http.cors.enabled: true
http.cors.allow-origin: "*"
```

kibana配置忽略

安装logstash插件

```
./logstash-plugin install logstash-input-mongodb
./logstash-plugin install logstash-ouput-mongodb
```

**logstash配置如下：**

```
input {

   mongodb {
        uri => 'mongodb://autotest:auto******@172.31.114.7:27017/autotest'  #带用户名密码的URL
        placeholder_db_dir => '/opt/logstash'    #本地路径（必须是目录） ** 不同集合的路径必须不同 **
        placeholder_db_name => 'autotest'    #库名
        collection => 'SnapUser'    #集合
        }
}
filter {

        mutate {
            rename => ["_id", "uid"]
        }
       mutate {
            convert => ["userName","string"]  #更改userName字段的类型为string
        }

   
   date {
      match => ["accessTime", "yyyy-MM-dd HH:mm:ss.SSS"]
      target => "@timestamp"
    }
}
output {
       file {
            path => "/var/log/mongons.log"
        }
        stdout {
           codec => json_lines
        }
        elasticsearch {
            hosts => ["172.31.114.9:9200"]
            index => "mongodb_%{+YYYY.MM.dd}"
        }
}
```



mongo和mongo-express使用docker-compose部署。

docker-compose.yml

```
version: '3'
services:
  mongo-db:
    image: mongo:latest
    container_name: mongo-db
    restart: always
    ports:
      - 27017:27017
    environment:
      TZ: Asia/Shanghai
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: admin123
    volumes:
      - /opt/mongo/db:/data/db
      - /etc/localtime:/etc/localtime
    logging:
      driver: "json-file"
      options:
        max-size: "200k"
        max-file: "10"

  mongo-express:
    image: mongo-express:latest
    container_name: mongo-express
    restart: always
    links:
      - mongo-db:mongodb
    depends_on:
      - mongo-db
    ports:
      - 27018:8081
    environment:
      ME_CONFIG_OPTIONS_EDITORTHEME: 3024-night
      ME_CONFIG_MONGODB_SERVER: mongodb
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: admin123
      ME_CONFIG_BASICAUTH_USERNAME: admin
      ME_CONFIG_BASICAUTH_PASSWORD: admin123
```



后续测试mongo分布式部署和配置。





**升级 logstash_input_mongodb版本**

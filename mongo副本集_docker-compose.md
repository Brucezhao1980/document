生成mongo认证KEY

```
mkdir $HOME/.mongoReplSet/keyfile

openssl rand -base64 745 > $HOME/.mongoReplSet/keyfile/mongoReplSet-keyfile

chmod 600 $HOME/.mongoReplSet/keyfile/mongoReplSet-keyfile

chown 999 $HOME/.mongoReplSet/keyfile/mongoReplSet-keyfile   ## 这步要给权限。

mkdir -p /opt/mongo/db1

mkdir -p /opt/mongo/db2

mkdir -p /opt/mongo/db3

chown 999 -R /opt/mongo/

docker-compose.yml 内容：

version: '3.1'
services:
  mongo1:
    image: mongo
    hostname: mongo1
    container_name: mongo1
    restart: always
    ports:

      - 27017:27017
        volumes:
            - /opt/mongo/db1:/data/db
                  - /etc/localtime:/etc/localtime
                  - /root/.mongoReplSet/keyfile:/data/keyfile
                environment:
                        MONGO_INITDB_ROOT_USERNAME: root
                        MONGO_INITDB_ROOT_PASSWORD: root123
                command: mongod --auth --keyFile /data/keyfile/mongoReplSet-keyfile --bind_ip_all --replSet rs0

  mongo2:
    image: mongo
    hostname: mongo2
    container_name: mongo2
    restart: always
    ports:
      - 27018:27017
        volumes:
            - /opt/mongo/db2:/data/db
                  - /etc/localtime:/etc/localtime
                  - /root/.mongoReplSet/keyfile:/data/keyfile
                environment:
                        MONGO_INITDB_ROOT_USERNAME: root
                        MONGO_INITDB_ROOT_PASSWORD: root123
                command: mongod --auth --keyFile /data/keyfile/mongoReplSet-keyfile --bind_ip_all --replSet rs0

  mongo3:
    image: mongo
    hostname: mongo3
    container_name: mongo3
    restart: always
    ports:
      - 27019:27017
        volumes:
            - /root/.mongoReplSet/keyfile:/data/keyfile
                  - /opt/mongo/db3:/data/db
                  - /etc/localtime:/etc/localtime
                environment:
                        MONGO_INITDB_ROOT_USERNAME: root
                        MONGO_INITDB_ROOT_PASSWORD: root123
                command: mongod --auth --keyFile /data/keyfile/mongoReplSet-keyfile --bind_ip_all --replSet rs0

  mongo-express:
    image: mongo-express:latest
    container_name: mongo-express
    restart: always

depends_on:
  - mongo1
ports:
  - 27020:8081
environment:
    ME_CONFIG_OPTIONS_EDITORTHEME: 3024-night
    ME_CONFIG_MONGODB_SERVER: mongo1
    ME_CONFIG_MONGODB_ADMINUSERNAME: root
    ME_CONFIG_MONGODB_ADMINPASSWORD: root123
    ME_CONFIG_BASICAUTH_USERNAME: root
    ME_CONFIG_BASICAUTH_PASSWORD: root123


注意：

docker-compose -f local-mongo.yml up -d 启动


注意：

启动之后按以下流程进行:

docker exec -it mongo1 /bin/bash
进入 docker 以后, mongo -u <用户名> -p <密码>
rs 初始化

rs.initiate(
  {
    _id : 'rs0',
    members: [
      { _id : 0, host : "mongo1:27017" },
      { _id : 1, host : "mongo2:27017" },
      { _id : 2, host : "mongo3:27017" }
    ]
  }
)

最后通过 rs.status() 查看状态即可。
```

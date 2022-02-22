#!/bin/bash
set -e

cd /data/soft
# 停所有服务
docker-compose  stop cfd operation account gateway versatile follow community reconciliation


pid=`ps -ef |grep -w 'wallet'|grep -v grep|awk '{print $2}'`

for i in $pid
do
  echo "Kill the wallet process [ $i ]"
  kill -9 $i
done


# 停止MQ和hazelcast
cd /data/soft/hazelcast-3.12.12/bin && sh stop.sh
cd /data/soft/hazelcast-3.12.12-cfd/bin && sh stop.sh
echo "shut hazelcast doen"

ssh ec2-user@172.*.*.142 "sh /data/soft/stop.sh"

sleep 5

ssh ec2-user@172.*.*.57 "sh /data/soft/stop.sh"
sleep 5
echo "shut rocketmq done"


# 执行sql语句清库

mysql -ucfd_admin -p'***********' -h 172.**.247 -e "source /opt/V6.0.0__init_moonxbt.sql"

# 执行sql语句初始化

mysql -uwallet_admin -p'**************' -h 172.**.247 -e "source /opt/V6.0.0__init_wallet.sql"

# # 导入mongo数据

# 启动MQ和hazelcast
cd /data/soft/hazelcast-3.12.12/bin && nohup ./start.sh & >/dev/null 2>&1
cd /data/soft/hazelcast-3.12.12-cfd/bin && nohup ./start.sh & >/dev/null 2>&1
echo "start hazelcast doen"

ssh ec2-user@172.**.142 "sh /data/soft/start.sh"
ssh ec2-user@172.**.57 "sh /data/soft/start.sh"
sleep 5
echo "start rocketmq done"
cd /data/soft

docker-compose start account

cd /data/wallet/ && sh start_new.sh

sleep 60 


curl http://localhost:6888/trigger
# 执行curl程序直到返回值
#curl_1="curl http://localhost:6888/status"
#$curl_1
sleep 1
while true
do
curl_1=`curl http://localhost:6888/status`

if [ "$curl_1" == "true" ]; then
        cd /data/soft/ && docker-compose start cfd operation gateway versatile follow community reconciliation
        break
else
        $curl_1
        sleep 1
        echo "OOOO"
fi
done

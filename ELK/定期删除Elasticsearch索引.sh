#!/bin/bash

DATA=`date -d "30 day ago" +%Y.%m.%d`
app=(logstash-access-nginx approval-api approval-approval approval-boss docker-1.44 horizon-bms horizon-boss horizon-cacs horizon-card-bigdata-cleaning \
horizon-cass horizon-fq horizon-hbms horizon-hmos horizon-ibms horizon-octs horizon-octsjob horizon-report itdbp-bigdata-api itdbp-bigdata-facade \
itdbp-bigdata-web prov-tucs-preservice prov-tucs-prov-tucs-contr)
   for i in ${app[*]}
     do
	INDEX=`curl --connect-timeout 5 -m 10 -u admin:admin -k 'https://172.168.1.202:9200/_cat/indices/*' |awk '{print $3}' |grep $i-$DATA`
	echo $INDEX
	curl -u admin:admin -XDELETE -k "https://172.168.1.202:9200/$INDEX"

      done

##################
删除索引并且合并分片
##################

#!/bin/bash
day=`date -d "3 day ago" +%Y.%m.%d`
DATA=`date -d "30 day ago" +%Y.%m.%d`
curl  -XDELETE -k "http://127.0.0.1:9200/*-${DATA}"
sleep 3  # 合并分片
curl -XPOST http://127.0.0.1:9200/*-${day}/_forcemerge?max_num_segments=1

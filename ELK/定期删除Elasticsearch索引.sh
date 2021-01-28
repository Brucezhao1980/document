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

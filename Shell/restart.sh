#!/bin/bash

filebeat=`ps aux|grep filebeat | grep -v 'grep elasticsearch' | awk '{print $2}' |head -1`
kill -9 $filebeat
sleep 10

nohup ./filebeat -c filebeat.yml >/dev/null 2>&1 &

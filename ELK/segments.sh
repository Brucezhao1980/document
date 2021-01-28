#!/bin/bash
day=`date -d "3  days ago"  "+%Y.%m.%d"`
curl -XPOST http://127.0.0.1:9200/*-${day}/_forcemerge?max_num_segments=1

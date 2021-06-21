#!/bin/bash
# $1 $2 $3 对应的是年月日，开始时间和结束时间

grep -r "$1" error.log | sed  -n '/'$2'/,/'$3'/p' |grep limiting | awk '{print $14}' | uniq -c | sort -hr >456.log

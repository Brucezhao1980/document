**日志 compress.sh**
```
#!/bin/bash
cd /data/logs/kline/
day=`date +"%Y-%m-%d" -d "-1day"`
file="kline-bpsp."$day.*.log
echo $file
zip -r $day.zip $file && rm -rf $file

```

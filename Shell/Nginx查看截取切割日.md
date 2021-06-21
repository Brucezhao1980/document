Nginx查看截取切割日

切割日志
查找7月17日访问log导出到17.log文件中：

cat gelin_web_access.log | egrep "17/Jul/2017" | sed  -n '/00:00:00/,/23:59:59/p' > /tmp/17.log
查看访问量前10的IP
awk '{print $1}' 17.log | sort | uniq -c | sort -nr | head -n 10 
查看访问前10的URL
awk '{print $11}' gelin_web_access.log | sort | uniq -c | sort -nr | head -n 10
查询访问最频繁的URL
awk '{print $7}' gelin_web_access.log | sort | uniq -c | sort -n -k 1 -r | more
查询访问最频繁的IP
awk '{print $1}' gelin_web_access.log | sort | uniq -c | sort -n -k 1 -r | more
根据访问IP统计UV
awk '{print $1}' gelin_web_access.log | sort | uniq -c | wc -l
统计访问URL统计PV
awk '{print $7}' gelin_web_access.log | wc -l
根据时间段统计查看日志
cat gelin_web_access.log | sed -n '/17\/Jul\/2017:12/,/17\/Jul\/2017:13/p' | more


生产限制访问IP过滤

grep -r "2020/11/04" error.log | sed  -n '/13:40/,/15:30/p' |grep limiting | awk '{print $14}' | uniq -c | sort -hr >456.log
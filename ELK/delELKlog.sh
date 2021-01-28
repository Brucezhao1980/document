#!/bin/bash
source /etc/profile
date=`date -d '1 month ago' +%Y.%m.%d`
curl -XDELETE 'http://localhost:9200/'service-$date*''
curl -XDELETE 'http://localhost:9200/'trans-$date*''
curl -XDELETE 'http://localhost:9200/'app-$date*''
curl -XDELETE 'http://localhost:9200/'dsf-$date*''


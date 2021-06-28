#!/bin/bash
#先删除4行，在添加4行。
sed -i '/multiline:/,+4d' filebeat.yml                     
sed -i '/node/a\  multiline: \n    pattern: '\''^[0-9]{4}-[0-9]{2}-[0-9]{2}'\''\n    negate: true\n    match: after\n    max_lines: 500' filebeat.yml

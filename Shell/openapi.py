import os
import sys
#定义镜像名称
#imagename = 'registry.cn-beijing.aliyuncs.com/djm/appdemo1:latest'
#cmd_pull = 'docker pull {}'.format(imagename)
registry_url = 'docker login -u igament -p CoTRrPuAiIy1WeJ9 registry.cn-hongkong.aliyuncs.com'
cmd_down = 'cd /data/soft && docker-compose -f docker-compose.yml down --rmi all'
cmd_up = 'cd /data/soft && docker-compose -f docker-compose.yml up -d'


os.system(registry_url)
os.system(cmd_down)
os.system(cmd_up)

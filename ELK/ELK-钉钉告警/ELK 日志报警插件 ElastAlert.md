python
python模块修复


yum install python3
yum install python3-devel
pip3 install --upgrade --force-reinstall setuptools
pip3 install  elasticsearch-dsl  
pip3 install elastalert
pip install elasticsearch==7.6.0
pip3 install "setuptools>=11.3"
pip3 install -r requirements.txt
python setup.py install


elastalert-test-rule rules/network.yaml

测试报错

Timezone offset does not match system offset: 0 != -28000. Please, check your config files
查看时区并修改成
more /etc/sysconfig/clock
ZONE="Asia/Shanghai"


python3 -m elastalert.elastalert --verbose --rule rules/network.yaml


/bin/python /usr/local/python3/bin/elastalert --config /data/elk/elastalert/config.yaml --rule /data/elk/elastalert/example_rules/applog.yaml

nohup /usr/local/python3/bin/elastalert --config /data/elk/elastalert/config.yaml --rule /data/elk/elastalert/example_rules/applog.yaml &

python -m elastalert.elastalert --verbose --rule /root/elastalert/example_rules/applog.yaml


以服务启动elastalert
mkdir /etc/elastalert
cp config.yaml.example /etc/elastalert/config.yaml

# 创建规则目录
mkdir /etc/elastalert/rules
cp /root/elastalert/example_rules/example_frequency.yaml /etc/elastalert/rules/
cp /root/elastalert/example_rules/example_frequency.yaml /etc/elastalert/rules/rule.yaml

# 修改配置文件
vim /etc/elastalert/config.yaml
    rules_folder: /etc/elastalert/rules

# 创建elastalert服务文件
vim /etc/systemd/system/elastalert.service

elastalert.service文件内容：



[Unit]
Description=elastalert
After=elastalert.service
[Service]
Type=simple
User=root
Group=root
Restart=on-failure
PIDFile=/usr/local/elastalert.pid
WorkingDirectory=/etc/elastalert
ExecStart=/usr/bin/python -m elastalert.elastalert --config /etc/elastalert/config.yaml --rule /etc/elastalert/rules/rule.yaml
ExecStop=/bin/kill -s QUIT $MAINPID
ExecReload=/bin/kill -s HUP $MAINPID
[Install]
WantedBy=multi-user.target



systemctl daemon-reload                    
systemctl start elastalert



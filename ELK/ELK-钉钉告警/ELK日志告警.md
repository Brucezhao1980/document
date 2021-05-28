**python模块修复版本升级**

```
yum install python3

yum install python3-devel



pip install --upgrade --force-reinstall setuptools

pip install elasticsearch-dsl 

pip install elastalert

pip install "setuptools>=11.3"

\#pip install -r requirements.txt

\#python setup.py install

pip uninstall jira

pip install jira



jira>=2.0.0



测试报错

Timezone offset does not match system offset: 0 != -28000. Please, check your config files

查看时区并修改成

more /etc/sysconfig/clock

ZONE="Asia/Shanghai"
```





**以服务启动elastalert**

```
mkdir /etc/elastalert

cp config.yaml.example /etc/elastalert/config.yaml


```

**# 创建规则目录**

```
mkdir /etc/elastalert/rules

cp /root/elastalert/example_rules/example_frequency.yaml /etc/elastalert/rules/

cp /root/elastalert/example_rules/example_frequency.yaml /etc/elastalert/rules/rule.yaml



elastalert目录下有config.yaml  钉钉插件目录 elastalert_modules  自定义规则目录rules


```

启动监控

```
/usr/bin/python -m elastalert.elastalert --verbose --config /etc/elastalert/config.yaml --rule /etc/elastalert/rules/rule.yaml
```



下载钉钉

```
git clone https://github.com/xuyaoqiang/elastalert-dingtalk-plugin.git
```



复制插件到elastalert中

```
cp -r elastalert-dingtalk-plugin/elastalert_modules/ /etc/elastalert/
```



**# 修改配置文件**

vim /etc/elastalert/config.yaml

```
  	rules_folder: /etc/elastalert/rules
```

**# 创建elastalert服务文件**

vim /etc/systemd/system/alert-cfd.service

**cfd.service文件内容：**

```
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

ExecStart=/usr/bin/python -m elastalert.elastalert --verbose --config /etc/elastalert/config.yaml --rule /etc/elastalert/rules/cfd.yaml

ExecStop=/bin/kill -s QUIT $MAINPID

ExecReload=/bin/kill -s HUP $MAINPID

[Install]

WantedBy=multi-user.target
```



**生产配置如下：**

**account**



```
es_host: 127.0.0.1

es_port: 9200



name: 【account日志报警】

type: any

index: account-*

filter:

- query:

  query_string:

   query: "message: postProcess AND message: failed AND message: (!JWTToken)" 

include: ["message", "@timestamp", "loglevel"]  # 只发送包含这些字段的信息

filter:

- query:

  query_string:

   query: "message: failed AND message: (!JWTToken)" 



alert:

 - "elastalert_modules.dingtalk_alert.DingTalkAlerter"

dingtalk_webhook: https://oapi.dingtalk.com/robot/send?access_token=efbdbc83****************************38dd5b8937a8c69506058d8a3c643c5b

dingtalk_msgtype: "text"
```

**versatile**

```
es_host: 127.0.0.1

es_port: 9200

name: 【versatile日志报警】

type: any

index: versatile-*

filter:

- query_string:

  query: "message: (TradeCompetitionEventListener.resolveMessage AND failed) OR message: (ConfigEventListener.resolveMessage AND failed) OR message: (onMessage AND failed)"
include: ["message", "@timestamp", "loglevel"]  # 只发送包含这些字段的信息
alert:

 - "elastalert_modules.dingtalk_alert.DingTalkAlerter"

dingtalk_webhook: https://oapi.dingtalk.com/robot/send?access_token=efbdbc83****************************38dd5b8937a8c69506058d8a3c643c5b

dingtalk_msgtype: "text"
```

**cfd**

```
es_host: 127.0.0.1

es_port: 9200

name: 【cfd日志报警】

type: any

\#type: frequency

index: cfd-*



filter:

- query_string:

  query: "message: (process AND failed) OR message: (postProcess AND failed) OR message: (order AND status AND illegal) OR message: (checkAndPendingToPlaceOrders AND failed) OR message: (addTxQueueAndRemoveTxMapSafely AND failed) OR message: (batchCheckAddTxQueueAndRemoveTxMap AND failed) OR message: (pendingToPlaceOrder AND failed) OR message: (checkAddAndRemoveTxMap AND failed) OR message: (closeSimuOrder AND failed) OR message: (settleOverNightOrders AND notOverNight AND failed) OR message: (settleOverNightOrders AND overNight AND failed) OR message: (checkAndSettleOrders AND failed) OR message: (cannot AND get AND product)" 

include: ["message", "@timestamp", "loglevel"]  # 只发送包含这些字段的信息


alert:

 - "elastalert_modules.dingtalk_alert.DingTalkAlerter"

dingtalk_webhook: https://oapi.dingtalk.com/robot/send?access_token=8cc160d1dbda303902af77603caec523eeb82e0ea008c07839e 

dingtalk_msgtype: "text"
```


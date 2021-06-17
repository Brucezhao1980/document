使用 Fai2Ban

$ sudo yum install -y  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

$ sudo yum install fail2ban

配置 Fai2Ban
Fail2Ban安装包中含有一个名为jail.conf的默认配置文件。 升级Fail2Ban时，该文件将被覆盖。因此，如果有定制化的配置，需要在升级前做好备份。

另一种推荐的方法是将jail.conf文件复制到一个名为jail.local的文件中。 我们将定制的的配置更改存入jail.local中。这个文件在升级过程中将保持不变。 Fail2Ban启动时会自动读取这jail.conf与jail.local这两个配置文件。

操作方法：sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

现在，我们使用编辑器中打开文件jail.local。我使用的是vim。

操作方法：sudo vim /etc/fail2ban/jail.local

“ignoreip”- 永远不会被禁止的IP地址白名单。他们拥有永久的“摆脱监狱”卡。本地主机的IP地址  （0.0.1）是在列表中默认情况下，其IPv6相当于（::1）。如果确认永远不应禁止的其它IP地址，请将它们添加到此列表中，并在每个IP地址之间留一个空格
“bantime”- 禁止IP地址的持续时间（“ m”代表分钟）。如果键入的值不带“ m”或“ h”（代表小时），则将其视为秒。值 -1将永久禁止IP地址。要非常小心，不要将自己的计算机给关了起来，这是非常有可能发生的低级错误。
“findtime” – 尝试失败的连接次数过多会导致IP地址被禁止的时间。
“maxretry”- “尝试失败次数过多”的数值。

解释一下这几个设置项的具体作用，如果来自同一IP地址的maxretry连接在该findtime时间段内尝试了失败的连接，则在的持续时间内将其禁止bantime。唯一的例外是ignoreip列表中的IP地址。

Fail2Ban将满足条件的IP地址放入“jail”（监狱）一段时间。Fai2Blan支持许多不同的“监狱”，每个“监狱”代表适用于单个连接类型的具体设置。可以对各种连接类型进行不同的设置。或者，可以使得Fail2Ban仅监视一组选定的连接类型。

[DEFAULT]部分的名称正如英文单词的含义，这个部分是缺省的设置。现在，让我们再去看一下SSH”监狱”的设置。

Jails可让我们将连接类型移入和移出Fail2Ban的监视。如果默认设置不匹配要应用于监狱，您可以设置特定值bantime，findtime和maxretry。

向下滚动到第241行，我们看到[sshd] 的部分。

我们要在这个部分设置SSH连接监狱的值。要将这个监狱包括在监视和禁止中，我们要加入以下几行：

enabled = truemaxretry = 3

好了，sshd 的部分就配置好了。

启用 Fail2Ban
到目前为止，我们已经安装Fail2Ban并进行了配置。现在，我们必须使它能够作为自动启动服务运行。然后，我们需要对其进行测试以确保其可以正常工作。要使得系统开机后自动运行Fail2Ban服务，我们使用systemctl命令：

sudo systemctl enable fail2ban

我们还要来启动服务：

sudo systemctl start fail2ban

我们也可以使用来检查服务的状态systemctl：

sudo systemctl status fail2ban.service 我看到了这样的结果，表明Fail2Ban 已经正常的运行起来。

让我们看看是否  Fail2Ban 自身检查的情况：

sudo fail2ban-client status

这反映了我们刚刚进行的设置。我们启用了一个名为[sshd]的“监狱”。如果在这条命令中包含“监狱”的名称，我们还可以获得更多的信息：

sudo fail2ban-client status sshd

**如何配置服务**

Fail2Ban 带有一组预定义的过滤器，用于各种服务，如 ssh、apache、nginx、squid、named、mysql、nagios 等。 我们不希望对配置文件进行任何更改，只需在服务区域中添加 enabled = true这一行就可以启用任何服务。 禁用服务时将 true 改为 false 即可。

# SSH servers
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
enabled： 确定服务是打开还是关闭。
port：指明特定的服务。 如果使用默认端口，则服务名称可以放在这里。 如果使用非传统端口，则应该是端口号。
logpath：提供服务日志的位置
backend：指定用于获取文件修改的后端。

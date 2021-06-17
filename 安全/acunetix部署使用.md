# 漏洞扫描软件AWVS的介绍和使用



Acunetix Web Vulnerability Scanner（AWVS）是用于测试和管理Web应用程序安全性的平台，能够自动扫描互联网或者本地局域网中是否存在漏洞，并报告漏洞。

### **1. AWVS简介**

Acunetix Web Vulnerability Scanner（AWVS）可以扫描任何通过Web浏览器访问和遵循HTTP/HTTPS规则的Web站点。适用于任何中小型和大型企业的内联网、外延网和面向客户、雇员、厂商和其它人员的Web网站。

AWVS可以通过检查SQL注入攻击漏洞、XSS跨站脚本攻击漏洞等漏洞来审核Web应用程序的安全性。

### **1.1 AWVS功能及特点**

- 自动的客户端脚本分析器，允许对Ajax和Web2.0应用程序进行安全性测试
- 业内最先进且深入的SQL注入和跨站脚本测试
- 高级渗透测试工具，例如HTPP Editor和HTTP Fuzzer
- 可视化宏记录器帮助您轻松测试web表格和受密码保护的区域
- 支持含有CAPTHCA的页面，单个开始指令和Two Factor（双因素）验证机制
- 丰富的报告功能，包括VISA PCI依从性报告
- 高速的多线程扫描器轻松检索成千上万的页面
- 智能爬行程序检测web服务器类型和应用程序语言
- Acunetix检索并分析网站，包括flash内容，SOAP和AJAX
- 端口扫描web服务器并对在服务器上运行的网络服务执行安全检查
- 可到处网站漏洞文件

### **1.2 AWVS工作原理**

- 扫描整个网络，通过跟踪站点上的所有链接和robots.txt来实现扫描，扫描后AWVS就会映射出站点的结构并显示每个文件的细节信息。
- 在上述的发现阶段或者扫描过程之后，AWVS就会自动地对所发现的每一个页面发动一系列的漏洞攻击，这实质上是模拟一个黑客的攻击过程（用自定义的脚本去探测是否有漏洞） 。WVS分析每一个页面中需要输入数据的地方，进而尝试3所有的输入组合。这是一个自动扫描阶段 。
- 在它发现漏洞之后，AWVS就会在“Alerts Node(警告节点)”中报告这些漏洞，每一个警告都包含着漏洞信息和如何修补漏洞的建议。
- 在一次扫描完成之后，它会将结果保存为文件以备日后分析以及与以前的扫描相比较，使用报告工具，就可以创建一个专业的报告来总结这次扫描。

### **2. AWVS安装**

（1）在官网下载awvs安装包，此软件为付费软件试用期14天。目前版本已经迭代到Acunetix WVS13版本

（2）点击安装包执行安装，勾选使用协议，执行下一步

![img](https://pic2.zhimg.com/80/v2-670fbc0c7485624464cc3aae9661924d_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-8f568e635be55ddccb5efe33392ac687_720w.jpg)

（3）填写邮件、密码并执行下一步，这里的邮件及密码会用于以后使用软件的时候进行登录验证

![img](https://pic2.zhimg.com/80/v2-6f756785d82ccce82595690c01e03f09_720w.jpg)

（4）这一步填写端口号，默认为3443，可以根据自己需求进行修改；询问是否在桌面添加快捷方式，一般选择是，选择后执行下一步

![img](https://pic2.zhimg.com/80/v2-90310acb038d17d73e9012e765fd2ff1_720w.jpg)

（5）勾选创建桌面快捷方式，执行下一步完成安装

![img](https://pic1.zhimg.com/80/v2-c7b1f3b098c3c86b6ebde69b2a7d8be4_720w.jpg)

### **3. AWVS的使用**

### **3.1 AWVS页面简介**

主菜单功能介绍：主菜单共有5个模块，分别为Dashboard、Targets、Vulnerabilities、Scans和Reports。

- Dashboard：仪表盘，显示扫描过的网站的漏洞信息
- Targets：目标网站，需要被扫描的网站
- Vulnerabilities：漏洞，显示所有被扫描出来的网站漏洞
- Scans：扫描目标站点，从Target里面选择目标站点进行扫描
- Reports：漏洞扫描完成后生成的报告

设置菜单功能介绍：设置菜单共有8个模块，分别为Users、Scan Types、Network Scanner、Issue Trackers、Email Settings、Engines、Excluded Hours、Proxy Settings

- Users：用户，添加网站的使用者、新增用户身份验证、用户登录会话和锁定设置
- Scan Types：扫描类型，可根据需要勾选完全扫描、高风险漏洞、跨站点脚本漏洞、SQL 注入漏洞、弱密码、仅爬网、恶意软件扫描
- Network Scanner：网络扫描仪，配置网络信息包括地址、用户名、密码、端口、协议
- Issue Trackers：问题跟踪器，可配置问题跟踪平台如github、gitlab、JIRA等
- Email Settings：邮件设置，配置邮件发送信息
- Engines：引擎，引擎安装删除禁用设置
- Excluded Hours：扫描时间设置，可设置空闲时间扫描
- Proxy Settings：代理设置，设置代理服务器信息

![img](https://pic2.zhimg.com/80/v2-2cd8d1ff7caa98ca77c70c734b0b2b29_720w.jpg)

### **3.2 使用AWVS扫描网站**

- 添加网址，点击Save

![img](https://pic1.zhimg.com/80/v2-e75c32eaaf38e463eef73fbfff881aac_720w.jpg)

- 进入扫描设置页面，根据项目需求，配置信息，点击scan开始扫描

![img](https://pic1.zhimg.com/80/v2-c502cd3dd22a190174c9719f8a31ad0c_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-c21693b3827d446d5ff668fea13ec0ff_720w.jpg)

![img](https://pic1.zhimg.com/80/v2-cf4f8cb9a6aea46de098a2b54ad56f90_720w.jpg)

![img](https://pic2.zhimg.com/80/v2-cef8a97c067bb77955cc72c0720d6535_720w.jpg)

- 设置扫描选项，一般选择全扫，也可以根据你的需求设置扫描类型，设置完成后执行扫描

![img](https://pic3.zhimg.com/80/v2-c95cf94e98117c46b32e8cc7eeaea3ea_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-4c125a7bd8ffff4ba6c2e7e7521d8fd3_720w.jpg)

- 执行扫描后，自动跳转到仪表板，可以查看扫描过程中发现的漏洞情况

![img](https://pic2.zhimg.com/80/v2-912f664c4a972328e1a5d279c55cb055_720w.jpg)

- 点击Vulnerabilities进入漏洞列表页面，这里可以导出扫描报告 AWVS将漏洞分为四级并用红黄蓝绿表示紧急程度，其中红色表示高等、黄色表示中等、蓝色表示低等、绿色表示信息类

![img](https://pic1.zhimg.com/80/v2-6cb87ff037a1ba3bdfb553b703c13ebc_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-33854305daa0d298ff4f0db68378d79b_720w.jpg)

![img](https://pic2.zhimg.com/80/v2-7aa90e49148b58e33e94f0f2523f2409_720w.jpg)

- 点击选择一个漏洞，点击进入可以看到AWVS给出的详细描述 AWVS给出了漏洞详细描述信息，包括：Vulnerability description（漏洞描述）、Attack Details（攻击详细信息）、HTTP Request （http请求）、HTTP Response （http响应）、The impact of this vulnerability（此漏洞的影响）、How to fix this vulnerability（如何修复此漏洞）、Classificationa（分类）、Detailed Information（详细信息）、Web References web（引用）

![img](https://pic4.zhimg.com/80/v2-92f1f26db58a896acfe95c96865814d7_720w.jpg)

![img](https://pic3.zhimg.com/80/v2-5ad52b25ce50d2373694f8b91be23062_720w.jpg)

Classification漏洞分类解释

CWE：CommonWeakness Enumeration，是社区开发的常见软件和硬件安全漏洞列表。它是一种通用语言，是安全工具的量尺，并且是弱点识别，缓解和预防工作的基准。 比如下图中CWE-89表示的是 这个bug是CWE列表中第89号常见弱点：

![img](https://pic2.zhimg.com/80/v2-6dc39d287cdce1b3224aa9bd18f38b29_720w.jpg)

CVSS： Common Vulnerability Scoring System，即“通用漏洞评分系统”，是一个“行业公开标准，其被设计用来评测漏洞的严重程度，并帮助确定所需反应的紧急度和重要度”。

CVSS评分系统中规定：漏洞的最终得分最大为10，最小为0。得分7-10分的漏洞通常被认为比较严重，得分在4-6.9分之间的是中级漏洞，0-3.9分的则是低级漏洞。其中，7~10分的漏洞都是必须要修复的。

下图展示的是CVSS计算指标：

![img](https://pic2.zhimg.com/80/v2-ce1aa700325a6bf84a8b54b7c425ab05_720w.jpg)

- 站点结构Site Structure查看每个模块的漏洞情况，便于及时定位问题

![img](https://pic2.zhimg.com/80/v2-7fced500038864e1d373f327bbce64e9_720w.jpg)

### **3.3 AWVS导出报告**

- 在Scans页面选择报告类型，点击导出

![img](https://pic4.zhimg.com/80/v2-518d504ca4557a94de899a1a155b65a3_720w.jpg)

- 在Reports页面可选择要下载的报告格式类型，包括pdf和html AWVS在扫描结束后还可以根据不同要求不同阅读方式，可生成不同类型的报告和细则，然后点击导出报告图标即可导出此次安全扫描报告。

![img](https://pic3.zhimg.com/80/v2-bf964add861877b3337cba0be34575d2_720w.jpg)

![img](https://pic3.zhimg.com/80/v2-1b8a78edf58c700647124bfda8a9722e_720w.jpg)

### **4. 验证漏洞的真实性**

根据针对公司多个项目的扫描，得到了几种常见的漏洞情况，以下是这几种漏洞的验证方法：

### **4.1 SQL盲注/SQL注入**

验证方法：利用sqlmap，GET、POST方式可以直接sqlmap -u "url"，cookie SQL注入新建txt文档把请求包大数据复制粘贴到里面，再利用sqlmap -r "xxx.txt"，查寻是否存在注入点。

sqlmap使用教程可参考：

[https://www.acunetix.com/vulnerability-scanner/](https://link.zhihu.com/?target=https%3A//www.acunetix.com/vulnerability-scanner/)

### **4.2 CSRF跨站伪造请求攻击**

CSRF，利用已登录的用户身份，以用户的名义发送恶意请求，完成非法操作。

举例说明：用户如果浏览并信任了存在CSRF漏洞的网站A，浏览器产生了相应的cookie，用户在没有退出该网站的情况下，访问了危险网站B 。危险网站B要求访问网站A，发出一个请求。浏览器带着用户的cookie信息访问了网站A，因为网站A不知道是用户自身发出的请求还是危险网站B发出的请求，所以就会处理危险网站B的请求，这样就完成了模拟用户操作的目的。

验证方法：

- 同个浏览器打开两个页面，一个页面权限失效后，另一个页面是否可操作成功，如果仍然能操作成功即存在风险。
- 使用工具发送请求，在http请求头中不加入referer字段，检验返回消息的应答，应该重新定位到错误界面或者登录界面。

### **4.3 HTTP缓慢拒绝服务攻击**

HTTP缓慢拒绝服务攻击是指以极低的速度往服务器发送HTTP请求。由于Web Server对于并发的连接数都有一定的上限，因此若是恶意地占用住这些连接不释放，那么Web Server的所有连接都将被恶意连接占用，从而无法接受新的请求，导致拒绝服务。要保持住这个连接，RSnake构造了一个畸形的HTTP请求，准确地说，是一个不完整的HTTP请求。

验证方法可参考：

[https://www.acunetix.com/vulnerability-scanner/](https://link.zhihu.com/?target=https%3A//www.acunetix.com/vulnerability-scanner/)

### **4.4 源代码泄露**

攻击者可以通过分析源代码来收集敏感信息（数据库连接字符串、应用程序逻辑）。此信息可用于进行进一步攻击。

验证方法：

在url后加/.svn/all-wcprops或者使用工具SvnExploit测试

例如：

![img](https://pic1.zhimg.com/80/v2-7e0755bc48b0f4c66e2bd727360a1540_720w.jpg)

![img](https://pic1.zhimg.com/80/v2-9a06080905206fd66d012bebdf6eaa20_720w.jpg)

### **4.5 文件信息泄露**

开发人员很容易上传一些敏感信息如：邮箱信息、SVN信息、内部账号及密码、数据库连接信息、服务器配置信息，导致文件信息泄露。

验证方法可参考：

[https://www.acunetix.com/vulnerability-scanner/](https://link.zhihu.com/?target=https%3A//www.acunetix.com/vulnerability-scanner/)

### **5. 总结**

AWVS给出的扫描结果并不代表完全真实可靠，还需要依靠人工再次验证判断。在AWVS扫描结果基础上，根据不同的严重级别进行排序、手工+工具验证的方式对漏洞验证可靠性，排除误报的情况，并尽可能找出漏报的情况，把本次扫描结果汇总，对以上已验证存在的安全漏洞排列优先级、漏洞威胁程度，并提出每个漏洞的修复建议。总的来说我们可以借助这个工具来进行扫描分析，但不能完全依赖于这个工具。
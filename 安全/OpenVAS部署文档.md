OpenVAS部署文档

先部署docker

docker search gvm

docker pull securecompliance/gvm //将镜像pull到本地

**运行GVM 11镜像**

docker run -d -p 8080:9392 --name gvm securecompliance/gvm



浏览器打开GVM的控制台界面： https://IP:8080/login

用户名/口令：admin/admin



**更新NVT**

重启GVM容器即可更新NVT特征库，无需单独运行命令。

**设置****admin（管理员）****口令**

在运行镜像时，通过修改环境变量PASSWORD来指定admin口令：

docker run -d -p 8080:9392 -e PASSWORD="password" --name gvm securecompliance/gvm



**使用数据卷**

在运行镜像时，将宿主机的/gvm-data目录映射到容器的/data目录：

mkdir /gvm-data //宿主机创建本地目录，容器中的目录无需手工创建

docker run -d -p 8080:9392 -v /gvm-data:/data --name gvm securecompliance/gvm




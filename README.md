# document
CentOS 7安装python3

yum install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make -y

#运行这个命令添加epel扩展源
yum -y install epel-release

#安装pip
yum install python-pip -y

用pip装wget
pip install wget

wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tar.xz

#解压
xz -d Python-3.6.4.tar.xz && tar -xf Python-3.6.4.tar

#进入解压后的目录，依次执行下面命令进行手动编译
./configure prefix=/usr/local/python3
make && make install

#将原来的链接备份
mv /usr/bin/python /usr/bin/python.bak

#添加python3的软链接
ln -s /usr/local/python3/bin/python3.6 /usr/bin/python

#测试是否安装成功了
python -V

更改yum配置，因为其要用到python2才能执行，否则会导致yum不能正常使用

sed -i 's/\#\!\/usr\/bin\/python/\#\!\/usr\/bin\/python2/g' /usr/bin/yum

sed -i 's/\#\!\/usr\/bin\/python/\#\!\/usr\/bin\/python2/g' /usr/libexec/urlgrabber-ext-down

加上pip的修改 mv /usr/bin/pip /usr/bin/pip.bak     ln -s /usr/local/python3/bin/pip3 /usr/bin/pip      pip -V

还需要把python3的bin添加到环境变量中。 

echo 'export PATH=$PATH:/usr/local/python3/bin' >>/etc/profile

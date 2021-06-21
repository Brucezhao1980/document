import paramiko
import os

test_fail = 'result.fail'
if os.path.exists(test_fail):
    os.remove(test_fail)

test_ok = 'result.ok'
if os.path.exists(test_ok):
    os.remove(test_ok)

pass_file = open('passwd', 'r')
for line in pass_file:  # 打开文件并读取数据
    inform = line.split()
    ipaddr = inform[0]
    username = inform[1]
    old_pass = inform[2]
    new_pass = inform[3]
    port = 22
    try:
        ssh = paramiko.SSHClient()
        ssh.load_system_host_keys()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=ipaddr, username=username, password=old_pass, timeout=5)  # 连接到服务器
        ssh.exec_command('echo "%s"|passwd --stdin root' % new_pass)  # 修改服务器密码
        ret_ok = open('result.ok', 'a+')  # // 输出结果
        ret_ok.write(ipaddr + " is OK\n")
        ret_ok.close()
        ssh.close()
    except Exception as e:
        ret_fail = open('result.fail', 'a+')  # // 输出结果
        ret_fail.write(ipaddr + " is failed\n")
        ret_fail.close()
pass_file.close()

dmesg命令

dmesg -Tx |grep oom-killer  #显示时间戳和级别过滤

显示和内存、硬盘、USB、TTY相关的信息
dmesg | grep -i memory
dmesg | grep -i dma
dmesg | grep -i usb
dmesg | grep -i tty

dmesg | grep -E "memory|dma|usb|tty"


输出守护进程的信息：

dmesg --facility=daemon

只输出特定级别的信息

dmesg --level=err,warn


# mariadb_install
mariadb自动安装脚本

mariadb_install.sh

my_test.cnf

mariadb-10.3.18-linux-x86_64.tar.gz

三个文件放在同一个目录下，例如/root/soft/

1）安装并启动mysql进程（主和从库都执行） 

#/bin/bash mariadb_install.sh

2）配置主从复制（从库执行）

#/bin/bash mariadb_install.sh repl

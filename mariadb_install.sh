# MariaDB自动安装脚本
#!/bin/bash

echo "正在安装MySQL软件......."

useradd mysql
useradd nagios

sleep 2
mariadb_version=mariadb-10.3.18-linux-x86_64.tar.gz
mariadb_version_dir=mariadb-10.3.18-linux-x86_64

###############################################
if [ "$1" = "repl" ]
then
while true
do
	read -t 30 -p "输入你的主库IP:  " master_ip
	read -t 30 -p "输入你的主库端口号:  " master_port
	if [[ -z $master_ip || -z $master_port ]]
	then
		continue
	else
		echo ""
		echo "主库IP是： $master_ip"
		echo "主库端口号是： $master_port"
		break 
	fi
done

/usr/local/mysql/bin/mysql -h127.0.0.1 -u"admin" -p"hechunyang" -P"$master_port" -e "CHANGE MASTER TO MASTER_HOST='$master_ip',MASTER_USER='repl',MASTER_PASSWORD='sysrepl',MASTER_PORT=$master_port,master_use_gtid = current_pos;START SLAVE;"

	echo "MySQL主从复制同步已经初始化完毕。"
	exit 0
fi
################################################


ps aux | grep 'mysql' | grep -v 'grep' | grep -v 'bash'
if [ $? -eq 0 ]
then
	echo "MySQL进程已经启动，无需二次安装。"
	exit 0
fi

if [ ! -d /usr/local/${mariadb_version_dir} ]
then
	tar zxvf ${mariadb_version} -C /usr/local/
	ln -s /usr/local/${mariadb_version_dir} /usr/local/mysql
	chown -R mysql.mysql /usr/local/mysql/
	chown -R mysql.mysql /usr/local/mysql
else
	ln -s /usr/local/${mariadb_version_dir} /usr/local/mysql
	chown -R mysql.mysql /usr/local/mysql/
	chown -R mysql.mysql /usr/local/mysql
fi 

while true
do
	read -t 30 -p "输入你的数据库名:  " dbname
	read -t 30 -p "输入你的数据库端口号:  " dbport
	read -t 30 -p "输入MySQL serverId:  " serverId
	read -t 30 -p "输入innodb_buffer_pool_size大小，单位G:  " innodb_bp_size
	if [[ -z $dbname || -z $dbport || -z $serverId || -z $innodb_bp_size ]]
	then
		continue
	else
		echo "数据库名字是： $dbname"
		echo "数据库端口是： $dbport"
		echo "MySQL serverId： $serverId"
		echo "BP大小是： $innodb_bp_size GB"
		break 
	fi
done

sed "s/test/$dbname/g;s/3312/$dbport/;s/17712/$serverId/;/innodb_buffer_pool_size/s/1/$innodb_bp_size/" my_test.cnf > /etc/my_$dbname.cnf

DATA_DIR=/data/mysql/$dbname
[ ! -d $DATA_DIR ] && mkdir -p $DATA_DIR/{data,binlog,relaylog,tmp,slowlog,log};chown -R mysql.mysql /data/mysql/


if [ `ls -A $DATA_DIR/data/ | wc -w` -eq 0 ]
then
	cd /usr/local/mysql
	scripts/mysql_install_db --defaults-file=/etc/my_$dbname.cnf --user=mysql
	sleep 2
	/usr/local/mysql/bin/mysqld_safe --defaults-file=/etc/my_$dbname.cnf --numa-interleave --flush-caches --log-slow-slave-statements --user=mysql &
fi

sleep 10
ps aux | grep 'mysql' | grep -v 'grep' | grep -v 'bash'
if [ $? -eq 0 ]
then
        echo "MySQL安装完毕。"
else
	echo "MySQL安装失败。"
fi

###创建同步账号和管理员账号
/usr/local/mysql/bin/mysql -S /tmp/mysql_$dbname.sock -e "GRANT REPLICATION SLAVE,REPLICATION CLIENT ON *.* TO 'repl'@'%' IDENTIFIED BY 'sysrepl';GRANT ALL on *.* to 'admin'@'%' identified by 'hechunyang' WITH GRANT OPTION;RESET MASTER;"

sed -i -r "s/(PATH=)/\1\/usr\/local\/mysql\/bin:/" /root/.bash_profile
source /root/.bash_profile

echo "MySQL账号初始化完毕。"



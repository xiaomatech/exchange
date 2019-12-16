#!/usr/bin/env bash
server_ip=`/sbin/ifconfig  | grep 'inet'| grep -v '127.0.0.1' |head -n1 |tr -s ' '|cut -d ' ' -f3 | cut -d: -f2`
hostname=`hostname -f`

data_dir=/data/zookeeper
myid=1

server_1=$1
server_2=$2
server_3=$3

if [ -z $server_1 ];then
    echo 'useage: ./install_zk.sh server_hostname1 server_hostname2 server_hostname3'
    exit 1
fi

if [ -z $server_2 ];then
    echo 'server_2 empty'
    exit 1
fi

if [ -z $server_3 ];then
    echo 'server_3 empty'
    exit 1
fi

if [ $server_1 == $hostname ];then
myid=1
fi
if [ $server_2 == $hostname ];then
myid=2
fi
if [ $server_3 == $hostname ];then
myid=3
fi

mkdir -p $data_dir
echo $myid > $data_dir/myid
useradd zookeeper -u 1042 -s /sbin/nologin

mkdir -p /etc/zookeeper /var/log/zookeeper /var/run/zookeeper
chown -R zookeeper:zookeeper /etc/zookeeper /var/log/zookeeper /var/run/zookeeper


yum install -y java-1.8.0-openjdk-devel java-11-openjdk-devel

wget http://yum.meizu.mz/hadoop/zookeeper-3.4.10.tar.gz -O /tmp/zookeeper-3.4.10.tar.gz
tar -zxf /tmp/zookeeper-3.4.10.tar.gz -C /opt
rm -rf /tmp/zookeeper-3.4.10.tar.gz
ln -s /opt/zookeeper-3.4.10 /opt/zookeeper
rm -rf /opt/zookeeper/conf && ln -s /etc/zookeeper /opt/zookeeper/conf
chown -R zookeeper:zookeeper /opt/zookeeper*

echo -ne '''
log4j.rootLogger=INFO, CONSOLE, ROLLINGFILE
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=INFO
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} - %-5p [%t:%C{1}@%L] - %m%n
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=DEBUG
log4j.appender.ROLLINGFILE.File=/var/log/zookeeper/zookeeper.log
log4j.appender.ROLLINGFILE.MaxFileSize=10MB
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} - %-5p [%t:%C{1}@%L] - %m%n
log4j.appender.TRACEFILE=org.apache.log4j.FileAppender
log4j.appender.TRACEFILE.Threshold=TRACE
log4j.appender.TRACEFILE.File=zookeeper_trace.log
log4j.appender.TRACEFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.TRACEFILE.layout.ConversionPattern=%d{ISO8601} - %-5p [%t:%C{1}@%L][%x] - %m%n
'''>/etc/zookeeper/log4j.properties

echo -ne '''
export JAVA_HOME=/usr/java/default
export ZOOKEEPER_HOME=/opt/zookeeper
export ZOO_LOG_DIR=/var/log/zookeeper
export ZOOPIDFILE=/var/run/zookeeper/zookeeper_server.pid
export SERVER_JVMFLAGS=-Xmx1024m
export JAVA=$JAVA_HOME/bin/java
export CLASSPATH=$CLASSPATH:/usr/share/zookeeper/*
export ZOOCFGDIR=/etc/zookeeper
export ZOOCFG=zoo.cfg
'''>/etc/zookeeper/zookeeper-env.sh

echo -ne '''
clientPort=2181
initLimit=10
autopurge.purgeInterval=24
syncLimit=5
tickTime=3000
dataDir=/data/zookeeper
autopurge.snapRetainCount=30
server.1='$server_1':2888:3888
server.2='$server_2':2888:3888
server.3='$server_3':2888:3888
'''>/etc/zookeeper/zoo.cfg

echo -ne '\n\n\n'
echo 'please echo '$server_1 $server_2 $server_3 ' to /etc/hosts'

echo -ne '\n\n\n'
echo 'then start zookeeper '

echo -ne '\n\n\n'
echo 'source /etc/zookeeper/zookeeper-env.sh && /opt/zookeeper/bin/zkServer.sh start'


echo -ne '\n\n\n'


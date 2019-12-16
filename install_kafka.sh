#!/usr/bin/env bash
server_ip=`/sbin/ifconfig  | grep 'inet'| grep -v '127.0.0.1' |head -n1 |tr -s ' '|cut -d ' ' -f3 | cut -d: -f2`

data_dirs='/data01/kafka,/data02/kafka,/data03/kafka,/data04/kafka,/data05/kafka,/data06/kafka,/data07/kafka,/data08/kafka,/data09/kafka,/data10/kafka,/data11/kafka,/data12/kafka'
zk_url=$1


datadirs=${data_dirs//,/ }
mkdir -p $datadirs

if [ -z $zk_url ];then
    echo 'useage: ./install_kafka.sh 1.1.1.1 2.2.2.2 3.3.3.3'
    exit 1
fi
useradd kafka -u 1019 -s /sbin/nologin

mkdir -p /etc/kafka /var/log/kafka /var/run/kafka
chown -R kafka:kafka /etc/kafka /var/log/kafka /var/run/kafka

yum install -y java-1.8.0-openjdk-devel java-11-openjdk-devel

wget http://mirrors.aliyun.com/apache/kafka/2.0.0/kafka_2.11-2.0.0.tgz -O /tmp/kafka_2.11-2.0.0.tgz
tar -zxf /tmp/kafka_2.11-2.0.0.tgz -C /opt
rm -rf /tmp/kafka_2.11-2.0.0.tgz
ln -s /opt/kafka_2.11-2.0.0 /opt/kafka
rm -rf /opt/kafka/config && ln -s /etc/kafka /opt/kafka/config
chown -R kafka:kafka /opt/kafka*

echo -ne '''
kafka.logs.dir=logs

log4j.rootLogger=INFO, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=[%d] %p %m (%c)%n
log4j.appender.kafkaAppender=org.apache.log4j.DailyRollingFileAppender
log4j.appender.kafkaAppender.DatePattern='.'yyyy-MM-dd-HH
log4j.appender.kafkaAppender.File=${kafka.logs.dir}/server.log
log4j.appender.kafkaAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.kafkaAppender.layout.ConversionPattern=[%d] %p %m (%c)%n
log4j.appender.kafkaAppender.MaxFileSize = 256MB
log4j.appender.kafkaAppender.MaxBackupIndex = 20
log4j.appender.stateChangeAppender=org.apache.log4j.DailyRollingFileAppender
log4j.appender.stateChangeAppender.DatePattern='.'yyyy-MM-dd-HH
log4j.appender.stateChangeAppender.File=${kafka.logs.dir}/state-change.log
log4j.appender.stateChangeAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.stateChangeAppender.layout.ConversionPattern=[%d] %p %m (%c)%n
log4j.appender.requestAppender=org.apache.log4j.DailyRollingFileAppender
log4j.appender.requestAppender.DatePattern='.'yyyy-MM-dd-HH
log4j.appender.requestAppender.File=${kafka.logs.dir}/kafka-request.log
log4j.appender.requestAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.requestAppender.layout.ConversionPattern=[%d] %p %m (%c)%n
log4j.appender.cleanerAppender=org.apache.log4j.DailyRollingFileAppender
log4j.appender.cleanerAppender.DatePattern='.'yyyy-MM-dd-HH
log4j.appender.cleanerAppender.File=${kafka.logs.dir}/log-cleaner.log
log4j.appender.cleanerAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.cleanerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n
log4j.appender.controllerAppender=org.apache.log4j.DailyRollingFileAppender
log4j.appender.controllerAppender.DatePattern='.'yyyy-MM-dd-HH
log4j.appender.controllerAppender.File=${kafka.logs.dir}/controller.log
log4j.appender.controllerAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.controllerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n
log4j.appender.controllerAppender.MaxFileSize = 256MB
log4j.appender.controllerAppender.MaxBackupIndex = 20
log4j.logger.kafka=INFO, kafkaAppender
log4j.logger.kafka.network.RequestChannel$=WARN, requestAppender
log4j.additivity.kafka.network.RequestChannel$=false
log4j.logger.kafka.request.logger=WARN, requestAppender
log4j.additivity.kafka.request.logger=false
log4j.logger.kafka.controller=TRACE, controllerAppender
log4j.additivity.kafka.controller=false
log4j.logger.kafka.log.LogCleaner=INFO, cleanerAppender
log4j.additivity.kafka.log.LogCleaner=false
log4j.logger.state.change.logger=TRACE, stateChangeAppender
log4j.additivity.state.change.logger=false
'''>/etc/kafka/log4j.properties

echo -ne '''
log4j.rootLogger=WARN, stderr

log4j.appender.stderr=org.apache.log4j.ConsoleAppender
log4j.appender.stderr.layout=org.apache.log4j.PatternLayout
log4j.appender.stderr.layout.ConversionPattern=[%d] %p %m (%c)%n
log4j.appender.stderr.Target=System.err
'''>/etc/kafka/tools-log4j.properties


echo -ne '''
#!/bin/bash
export JAVA_HOME=/usr/java/default
export PATH=$PATH:$JAVA_HOME/bin
export PID_DIR=/var/run/kafka
export LOG_DIR=/var/log/kafka
'''>/etc/kafka/kafka-env.sh

echo -ne '''auto.create.topics.enable=true
auto.leader.rebalance.enable=true
compression.type=producer
controlled.shutdown.enable=true
controlled.shutdown.max.retries=3
controlled.shutdown.retry.backoff.ms=5000
controller.message.queue.size=10
controller.socket.timeout.ms=30000
default.replication.factor=1
delete.topic.enable=false
fetch.purgatory.purge.interval.requests=10000
host.name='$server_ip'
leader.imbalance.check.interval.seconds=300
leader.imbalance.per.broker.percentage=10
listeners=PLAINTEXT://'$server_ip':6667
log.cleaner.enable=true
log.cleanup.interval.mins=10
log.dirs='$data_dirs'
log.index.interval.bytes=4096
log.index.size.max.bytes=10485760
log.retention.bytes=-1
log.retention.hours=168
log.roll.hours=168
log.segment.bytes=1073741824
message.max.bytes=1000000
min.insync.replicas=1
num.io.threads=8
num.network.threads=3
num.partitions=32
num.recovery.threads.per.data.dir=1
num.replica.fetchers=1
offset.metadata.max.bytes=4096
offsets.commit.required.acks=-1
offsets.commit.timeout.ms=5000
offsets.load.buffer.size=5242880
offsets.retention.check.interval.ms=600000
offsets.retention.minutes=86400000
offsets.topic.compression.codec=0
offsets.topic.num.partitions=50
offsets.topic.replication.factor=3
offsets.topic.segment.bytes=104857600
port=6667
producer.purgatory.purge.interval.requests=10000
queued.max.requests=500
replica.fetch.max.bytes=1048576
replica.fetch.min.bytes=1
replica.fetch.wait.max.ms=500
replica.high.watermark.checkpoint.interval.ms=5000
replica.lag.max.messages=4000
replica.lag.time.max.ms=10000
replica.socket.receive.buffer.bytes=65536
replica.socket.timeout.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
zookeeper.connect='$zk_url'
zookeeper.connection.timeout.ms=25000
zookeeper.session.timeout.ms=30000
zookeeper.sync.time.ms=2000
'''> /etc/kafka/server.properties




source /etc/kafka/kafka-env.sh

/opt/kafka/bin/kafka-server-start.sh -daemon /etc/kafka/server.properties

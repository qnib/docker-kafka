#!/bin/bash

TOPICS=$(/opt/kafka/bin/kafka-topics.sh --zookeeper leader.zookeeper.service.consul:2181 --list|xargs)
EC=$?
if [ $EC -ne 0 ];then
    echo "/opt/kafka/bin/kafka-topics.sh returns EC:'${EC}'"
    return ${EC}
fi
if [ "X${TOPICS}" == "X" ];then
	/opt/kafka/bin/kafka-topics.sh --zookeeper leader.zookeeper.service.consul:2181 --topic syslog --create --partitions 1 --replication-factor 1
fi

TOPICS=$(/opt/kafka/bin/kafka-topics.sh --zookeeper leader.zookeeper.service.consul:2181 --list|xargs)
EC=$?
if [ $EC -ne 0 ];then
    echo "/opt/kafka/bin/kafka-topics.sh returns EC:'${EC}'"
    return ${EC}
else
    echo "$(echo ${TOPICS}|wc -w) Kafka Topics: $(echo ${TOPICS}|sed -e 's/ /,/g')"
fi

#!/bin/bash

function get_brokerid {
  BROKER_ID=$(consul-cli kv read kafka/brokerid/$(hostname))
  if [ -z ${BROKER_ID} ];then
    ## Aquire lock
    SESSION=$(consul-cli kv lock brokerid --behavior=delete)
    LATEST=$(consul-cli kv read kafka/brokerid/LAST)
    if [ -z ${LATEST} ];then
      BROKER_ID=0
    else
      BROKER_ID=$(echo "${LATEST}+1" |bc)
    fi
    consul-cli kv write kafka/brokerid/$(hostname) ${BROKER_ID}
    consul-cli kv write kafka/brokerid/LAST ${BROKER_ID}
    consul-cli kv unlock brokerid --session="${SESSION}"
  fi
  echo ${BROKER_ID}
}

sleep 5

if [ "X${ZK_DC}" != "X" ];then
    sed -i'' -E "s#service \"zookeeper(@\w+)?\"#service \"zookeeper@${ZK_DC}\"#" /etc/consul-templates/kafka.server.properties.ctmpl
fi
if [ "X${KAFKA_HOST}" == "X" ];then
    export KAFKA_HOST=$(curl -s -XGET "172.17.42.1:8500/v1/catalog/service/zookeeper?dc=dc1&tag=${ZOOKEEPER_ENV_MYID}"|jq ".[0].Node"|sed -e 's/"//g')
fi
if [ "${KAFKA_HOST}" == "null" ];then
    export KAFKA_HOST=$(hostname -f)
fi

## Get the BROKER_ID
export BROKER_ID=get_brokerid()
consul-template -consul localhost:8500 -once -template "/etc/consul-templates/kafka.server.properties.ctmpl:/opt/kafka/config/server.properties"

JMXD="-Dcom.sun.management.jmxremote"
export KAFKA_JMX_OPTS="${JMXD}.authenticate=false ${JMXD}.ssl=false ${JMXD}.port=54299"

/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties

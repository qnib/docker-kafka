#!/bin/bash

sleep 5

export KAFKA_HOST=$(hostname -f)

## Get the BROKER_ID
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
export BROKER_ID=${BROKER_ID}
if [ -n ${KAFKA_GRAPHITE_METRICS_GROUP} ];then
    export KAFKA_GRAPHITE_METRICS_GROUP=$(/opt/qnib/kafka/bin/show_group.sh)
fi
consul-template -consul localhost:8500 -once -template "/etc/consul-templates/kafka.server.properties.ctmpl:/opt/kafka/config/server.properties"

JMXD="-Dcom.sun.management.jmxremote"
export KAFKA_JMX_OPTS="${JMXD}.authenticate=false ${JMXD}.ssl=false ${JMXD}.port=54299"

/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties

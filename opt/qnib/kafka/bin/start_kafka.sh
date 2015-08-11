#!/bin/bash

sleep 5

consul-template -consul localhost:8500 -once -template "/etc/consul-templates/kafka.server.properties.ctmpl:/opt/kafka/config/server.properties"

/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties

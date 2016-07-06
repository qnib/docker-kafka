### Docker Image
FROM qnib/jmxtrans8

ENV KAFKA_VER=0.10.0.0 \
    KAFKA_PORT=9092 \
    API_VER=2.11
RUN curl -fLs http://apache.mirrors.pair.com/kafka/${KAFKA_VER}/kafka_${API_VER}-${KAFKA_VER}.tgz | tar xzf - -C /opt \
 && mv /opt/kafka_${API_VER}-${KAFKA_VER} /opt/kafka/ \
 && dnf install -y jq
ADD etc/supervisord.d/*.ini /etc/supervisord.d/
ADD opt/kafka/config/server.properties /opt/kafka/config/
ADD opt/qnib/kafka/bin/check_kafka.sh \
    opt/qnib/kafka/bin/show_group.sh \
    opt/qnib/kafka/bin/create_topics.sh \
    opt/qnib/kafka/bin/show_topics.py \
    opt/qnib/kafka/bin/show_group.sh \
    opt/qnib/kafka/bin/start.sh \
    /opt/qnib/kafka/bin/
ADD etc/consul.d/kafka.json /etc/consul.d/
ADD etc/consul-templates/kafka.server.properties.ctmpl /etc/consul-templates/
RUN echo "/opt/kafka/bin/kafka-console-consumer.sh --zookeeper zookeeper.service.consul:2181 --topic syslog" >> /root/.bash_history && \
    echo "/opt/kafka/bin/kafka-topics.sh --zookeeper zookeeper.service.consul:2181 --replication-factor 3 --partitions 1 --create --topic ring0" >> /root/.bash_history && \
    echo "/opt/kafka/bin/kafka-run-class.sh kafka.admin.TopicCommand --zookeeper zookeeper.service.consul:2181 --topic ring0 --describe" >> /root/.bash_history && \
    echo "/opt/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic ring0" >> /root/.bash_history && \
    echo "/opt/kafka/bin/kafka-topics.sh --zookeeper zookeeper.service.consul:2181 --describe --topic \$(/opt/kafka/bin/kafka-topics.sh --zookeeper zookeeper.service.consul:2181 --list|xargs|sed -e 's/ /,/g')" >> /root/.bash_history


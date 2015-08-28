### Docker Image
FROM qnib/java7

ENV KAFKA_VER 0.8.2.1 
ENV API_VER 2.11
RUN curl -fLs http://apache.mirrors.pair.com/kafka/${KAFKA_VER}/kafka_${API_VER}-${KAFKA_VER}.tgz | tar xzf - -C /opt && mv /opt/kafka_${API_VER}-${KAFKA_VER} /opt/kafka/
RUN yum install -y jq
ADD etc/supervisord.d/*.ini /etc/supervisord.d/
ADD opt/kafka/config/server.properties /opt/kafka/config/
ADD opt/qnib/kafka/bin/*.sh /opt/qnib/kafka/bin/
ADD etc/consul.d/kafka.json /etc/consul.d/
ADD etc/consul-templates/kafka.server.properties.ctmpl /etc/consul-templates/
RUN echo "/opt/kafka/bin/kafka-console-consumer.sh --zookeeper leader.zookeeper.service.consul:2181 --topic syslog" >> /root/.bash_history

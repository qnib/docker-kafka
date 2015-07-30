### Docker Image
FROM qnib/zookeeper

ENV KAFKA_VER 0.8.2.1 
ENV API_VER 2.11
RUN curl -fLs http://apache.mirrors.pair.com/kafka/${KAFKA_VER}/kafka_${API_VER}-${KAFKA_VER}.tgz | tar xzf - -C /opt && mv /opt/kafka_${API_VER}-${KAFKA_VER} /opt/kafka/
ADD etc/supervisord.d/kafka.ini /etc/supervisord.d/
ADD opt/kafka/config/server.properties /opt/kafka/config/
ADD opt/qnib/kafka/bin/check_kafka.sh /opt/qnib/kafka/bin/
ADD etc/consul.d/check_kafka.json /etc/consul.d/

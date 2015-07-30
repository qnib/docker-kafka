# docker-kafka
[![](https://badge.imagelayers.io/qnib/kafka:latest.svg)](https://imagelayers.io/?images=qnib/kafka:latest 'Details')

## Hello World

Fire up the stack and start an consumer.
```
$ docker-compose up -d
Creating dockerkafka_consul_1...
Creating dockerkafka_kafka_1...
$ docker exec -ti dockerkafka_kafka_1 bash
[root@kafka /]# /opt/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic syslog
```
Within a sceond terminal we now start a producer and start submitting messages.
```
$ docker exec -ti dockerkafka_kafka_1 bash
[root@kafka /]# /opt/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic syslog
[2015-07-30 15:54:53,682] WARN Property topic is not valid (kafka.utils.VerifiableProperties)
Test
Hello World
```
Et voila, the consumer prints the very same messages... :)
```
[root@kafka /]# /opt/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic syslog
Test
Hello World
```
### Syslog
Rsyslog is forwarding it's messages as well, therefore you could just submit a log via `logger`.
```
[root@kafka /]# logger Test123
[root@kafka /]#  /opt/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic syslog --from-begin
*snip*
2015-07-30T17:52:22.716437+02:00 kafka logger: Test123
```

## Kafka syslog-ng

The `syslog-ng-kafka` plugin does not work for me currently. syslog-ng segfaults when kafka is enabled. :(
```
[root@kafka /]# cat /etc/syslog-ng/syslog-ng.conf
@version:3.4

# syslog-ng configuration file.
#
# This should behave pretty much like the original syslog on RedHat. But
# it could be configured a lot smarter.
#
# See syslog-ng(8) and syslog-ng.conf(5) for more information.
#
# Note: it also sources additional configuration files (*.conf)
#       located in /etc/syslog-ng/conf.d/

options {
    flush_lines (0);
    time_reopen (10);
    log_fifo_size (1000);
    chain_hostnames (off);
    use_dns (no);
    use_fqdn (no);
    create_dirs (no);
    keep_hostname (yes);
    stats_freq(0);
};

source s_sys {
    file ("/proc/kmsg" program_override("kernel") flags(kernel));
    unix-dgram ("/dev/log");
    internal();
    udp(ip(0.0.0.0) port(514));
    tcp(ip(0.0.0.0) port(514));
};

# Source additional configuration files (.conf extension only)
@include "/etc/syslog-ng/conf.d/*.conf"


# vim:ft=syslog-ng:ai:si:ts=4:sw=4:et:
```
The kafka config:
```
[root@kafka /]# cat /etc/syslog-ng/conf.d/kafka.conf
destination d_kafka {
  channel {
    rewrite {
      set("${HOST}"    value(".eventv1.host"));
      set("1"          value(".eventv1.@version"));
      set("${ISODATE}" value(".eventv1.@timestamp") condition("${.eventv1.@timestamp}" eq ""));
      set("${MESSAGE}" value(".eventv1.message")    condition("${.eventv1.message}" eq ""));
      set("${MSG}"     value(".eventv1.message")    condition("${.eventv1.message}" eq ""));
      set("generic"    value(".eventv1.type")       condition("${.eventv1.type}" eq ""));
    };
    destination {
      kafka(properties(metadata.broker.list("localhost:9092")
                       queue.buffering.max.ms("1"))
            topic("syslog")
            payload("$(format-json --key .eventv1.* --rekey .eventv1.* --shift 9)"));
    };
  };
};

log {
    source(s_sys);
    destination(d_kafka);
};
```
Give it a spin...
```
# syslog-ng --foreground
[2015-07-30T15:59:15.640661] WARNING: Configuration file format is too old, syslog-ng is running in compatibility mode Please update it to use the syslog-ng 3.6 format at your time of convinience, compatibility mode can operate less efficiently in some cases. To upgrade the configuration, please review the warnings about incompatible changes printed by syslog-ng, and once completed change the @version header at the top of the configuration file.;
Segmentation fault
```

The WARNING derives from the version statement of `syslog-ng.conf`, but maybe there is something wrong with it as well... 

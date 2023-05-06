# Broker Under the Hood

An optional exercise to shell into the broker container and see what the messages look like in the commit log.

First, let's search the broker container logs to find out where it created the topic partitions:

```
docker-compose logs broker | grep "Created log for partition"
```

Example output:

```
INFO Created log for partition person-0 in /var/lib/kafka/data/person-0 with properties {} (kafka.log.LogManager)
INFO Created log for partition greeting-0 in /var/lib/kafka/data/greeting-0 with properties {} (kafka.log.LogManager)
```

Shell into broker container to look at commit logs in more detail:

```
docker-compose exec broker bash
```

```bash
ls -l /var/lib/kafka/data/person-0
# -rw-r--r-- 1 appuser appuser 10485760 May  6 12:11 00000000000000000000.index
# -rw-r--r-- 1 appuser appuser      279 May  6 12:11 00000000000000000000.log
# -rw-r--r-- 1 appuser appuser 10485756 May  6 12:11 00000000000000000000.timeindex
# -rw-r--r-- 1 appuser appuser        0 May  6 12:11 leader-epoch-checkpoint
# -rw-r--r-- 1 appuser appuser       43 May  6 12:11 partition.metadata

# Notice the schema is embedded in the message
cat /var/lib/kafka/data/person-0/00000000000000000000.log
# �����]���]����������������Objavro.codenullavro.schema�{"type":"record","name":"person","fields":[{"name":"full_name","type":"string"},{"name":"age","type":"int"}]}u}}\�7���&J:��Jane Doe8u}}\�7���&J:��message_type

ls -l /var/lib/kafka/data/greeting-0
# -rw-r--r-- 1 appuser appuser 10485760 May  6 12:11 00000000000000000000.index
# -rw-r--r-- 1 appuser appuser       86 May  6 12:15 00000000000000000000.log
# -rw-r--r-- 1 appuser appuser 10485756 May  6 12:11 00000000000000000000.timeindex
# -rw-r--r-- 1 appuser appuser        0 May  6 12:11 leader-epoch-checkpoint
# -rw-r--r-- 1 appuser appuser       43 May  6 12:11 partition.metadata

# Notice schema not embedded in message.
# Can't see it from binary format, but only the schema ID is embedded, making the message more compact.
cat /var/lib/kafka/data/greeting-0/00000000000000000000.log
# J
# �u^����������������������0$hello, world
```


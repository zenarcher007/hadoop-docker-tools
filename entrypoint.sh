#!/bin/bash

set -e

export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin:$PIG_HOME/bin:$HIVE_HOME/bin:$SPARK_HOME/bin"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-$(dpkg --print-architecture)"



[ -z "$( ls -A '/srv/namenode' )" ] && "$HADOOP_HOME/bin/hdfs" namenode -format

mkdir -p /run/sshd
chmod 0755 /run/sshd
/usr/sbin/sshd

set -x
"$HADOOP_HOME/sbin/start-dfs.sh"
"$HADOOP_HOME/sbin/start-yarn.sh"
"$HADOOP_HOME/bin/mapred" --daemon start historyserver
"$SPARK_HOME/sbin/start-master.sh"
"$SPARK_HOME/sbin/start-worker.sh" "spark://localhost:7077"
"$HBASE_HOME/bin/start-hbase.sh"
set +x

"$HIVE_HOME/bin/init-hive-dfs.sh"
"$HIVE_HOME/bin/schematool" -info -dbType derby || "$HIVE_HOME/bin/schematool" -dbType derby -initSchema

# Cleanup function
cleanup() {
  set +e
  echo "Caught termination signal! Shutting down daemons..."
  set -x
  "$SPARK_HOME/sbin/stop-worker.sh"
  "$SPARK_HOME/sbin/stop-master.sh"
  "$HBASE_HOME/bin/hbase-daemon.sh" stop regionserver
  "$HBASE_HOME/bin/hbase-daemon.sh" stop master
  "$HADOOP_HOME/bin/mapred" --daemon stop historyserver
  "$HADOOP_HOME/sbin/stop-yarn.sh"
  "$HADOOP_HOME/sbin/stop-dfs.sh"
  pkill sshd
  set +x
}
trap cleanup EXIT


if [ $# -eq 0 ]; then
  /bin/bash
else
  exec "$@"
fi
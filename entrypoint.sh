#!/bin/bash

set -e

export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin:$PIG_HOME/bin:$HIVE_HOME/bin:$SPARK_HOME/bin"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"

[ -z "$( ls -A '/srv/namenode' )" ] && hadoop-2.8.1/bin/hdfs namenode -format

mkdir -p /run/sshd
chmod 0755 /run/sshd
/usr/sbin/sshd

"$HADOOP_HOME/sbin/start-dfs.sh"
"$HADOOP_HOME/sbin/start-yarn.sh"
"$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh" start historyserver
"$HBASE_HOME/bin/start-hbase.sh"
"$SPARK_HOME/sbin/start-master.sh"
"$SPARK_HOME/sbin/start-slave.sh" "spark://localhost:7077"

# Ensure Hive directories and correct permissions
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
"$HIVE_HOME/bin/schematool" -info -dbType derby || "$HIVE_HOME/bin/schematool" -dbType derby -initSchema

# Cleanup function
cleanup() {
  set +e
  echo "Caught termination signal! Shutting down daemons..."
  echo "### Stopping Spark..."
  "$SPARK_HOME/sbin/stop-slave.sh"
  "$SPARK_HOME/sbin/stop-master.sh"
  echo "### Stopping HBase..."
  "$HBASE_HOME/bin/hbase-daemon.sh" stop regionserver
  "$HBASE_HOME/bin/hbase-daemon.sh" stop master
  echo "### Stopping History Server..."
  "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh" stop historyserver
  echo "### Stopping YARN..."
  "$HADOOP_HOME/sbin/stop-yarn.sh"
  echo "### Stopping HDFS..."
  "$HADOOP_HOME/sbin/stop-dfs.sh"
  echo "### Stopping SSH..."
  pkill sshd
}
trap cleanup EXIT


if [ $# -eq 0 ]; then
  /bin/bash
else
  exec "$@"
fi
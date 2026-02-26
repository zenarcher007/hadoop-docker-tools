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

# Ensure Hive directories and correct permissions
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
"$HIVE_HOME/bin/schematool" -info -dbType derby || "$HIVE_HOME/bin/schematool" -dbType derby -initSchema

if [ $# -eq 0 ]; then
  /bin/bash
else
  exec "$@"
fi
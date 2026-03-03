FROM ubuntu:jammy

RUN apt update -y
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends ssh wget sudo tzdata ca-certificates

WORKDIR /root

RUN wget -q --show-progress --progress=bar:force https://downloads.apache.org/hadoop/common/stable/hadoop-3.4.3.tar.gz

# Install hadoop
RUN wget -q --show-progress --progress=bar:force -O- https://downloads.apache.org/hadoop/common/stable/hadoop-3.4.3.tar.gz | tar -xzf -

# Install Pig
RUN wget -q --show-progress --progress=bar:force -O- https://downloads.apache.org/pig/pig-0.18.0/pig-0.18.0.tar.gz | tar -xzf -

# Install pig libraries
ADD https://repo1.maven.org/maven2/org/apache/parquet/parquet-pig-bundle/1.12.3/parquet-pig-bundle-1.12.3.jar /root/pig-0.18.0/lib/
ADD https://repo1.maven.org/maven2/org/xerial/snappy/snappy-java/1.1.10.8/snappy-java-1.1.10.8.jar /root/pig-0.18.0/lib/
ADD https://repo1.maven.org/maven2/org/apache/thrift/libthrift/0.22.0/libthrift-0.22.0.jar /root/pig-0.18.0/lib/
ADD https://repo1.maven.org/maven2/org/apache/avro/avro/1.12.1/avro-1.12.1.jar /root/pig-0.18.0/lib/

# Install Hbase
RUN wget -q --show-progress --progress=bar:force -O- https://downloads.apache.org/hbase/stable/hbase-2.5.13-bin.tar.gz | tar -xzf -

# Install Hive
RUN wget -q --show-progress --progress=bar:force -O- https://downloads.apache.org/hive/hive-4.2.0/apache-hive-4.2.0-bin.tar.gz | tar -xzf -

# Install Spark
RUN wget -q --show-progress --progress=bar:force -O- https://downloads.apache.org/spark/spark-4.1.1/spark-4.1.1-bin-hadoop3.tgz | tar -xzf -

# Install additional packages. We must break up these openjdk installs to prevent a conflicting dependency tree
RUN apt update -y
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends openjdk-21-jdk

# Set environment variables
ENV SPARK_HOME="/root/spark-4.1.1-bin-hadoop3"
ENV HIVE_HOME="/root/apache-hive-4.2.0-bin"
ENV HADOOP_HOME="/root/hadoop-3.4.3"
ENV HBASE_HOME="/root/hbase-2.5.13"
ENV PIG_HOME="/root/pig-0.18.0"
ENV PIG_CLASSPATH="$PIG_HOME/lib"
ENV HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
ENV SPARK_MASTER_HOST="0.0.0.0"


# Configure self-ssh key for hadoop
RUN mkdir /root/.ssh && chmod 755 /root/.ssh && ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa && mv /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && echo "StrictHostKeyChecking no" >> /root/.ssh/config

RUN mkdir /srv/namenode /srv/datanode
COPY config/hadoop-env.sh "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
COPY config/hdfs-site.xml "$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
COPY config/yarn-site.xml "$HADOOP_HOME/etc/hadoop/yarn-site.xml"
COPY config/core-site.xml "$HADOOP_HOME/etc/hadoop/core-site.xml"
COPY config/hbase-site.xml "$HBASE_HOME/conf/hbase-site.xml"
COPY config/hbase-env.sh "$HBASE_HOME/conf/hbase-env.sh"
COPY config/hive-config.sh "$HIVE_HOME/bin/hive-config.sh"
COPY config/hive-env.sh "$HIVE_HOME/conf/hive-env.sh"
COPY config/hive-site.xml "$HIVE_HOME/conf/hive-site.xml"


COPY entrypoint.sh ./entrypoint.sh



ENTRYPOINT ["./entrypoint.sh"]

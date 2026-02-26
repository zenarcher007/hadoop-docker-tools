FROM ubuntu:jammy
ENV TZ='America/Chicago'
RUN apt update -y

RUN apt install -y ssh wget openjdk-8-jdk

WORKDIR /root

# Install hadoop
RUN wget -q --show-progress --progress=bar:force -O- https://archive.apache.org/dist/hadoop/core/hadoop-2.8.1/hadoop-2.8.1.tar.gz | tar -xzf -

# Install Pig
RUN wget -q --show-progress --progress=bar:force -O- https://archive.apache.org/dist/pig/pig-0.16.0/pig-0.16.0.tar.gz | tar -xzf -

# Install pig libraries
ADD https://repo1.maven.org/maven2/org/apache/parquet/parquet-pig-bundle/1.12.3/parquet-pig-bundle-1.12.3.jar /root/pig-0.16.0/lib/
ADD https://repo1.maven.org/maven2/org/xerial/snappy/snappy-java/1.1.10.8/snappy-java-1.1.10.8.jar /root/pig-0.16.0/lib/
ADD https://repo1.maven.org/maven2/org/apache/thrift/libthrift/0.22.0/libthrift-0.22.0.jar /root/pig-0.16.0/lib/
ADD https://repo1.maven.org/maven2/org/apache/avro/avro/1.12.1/avro-1.12.1.jar /root/pig-0.16.0/lib/

# Install Hbase
RUN wget -q --show-progress --progress=bar:force -O- https://archive.apache.org/dist/hbase/1.2.6/hbase-1.2.6-bin.tar.gz | tar -xzf -

# Install Hive
RUN wget -q --show-progress --progress=bar:force -O- https://archive.apache.org/dist/hive/hive-1.2.2/apache-hive-1.2.2-bin.tar.gz | tar -xzf -
COPY config/hive-config.sh /root/apache-hive-1.2.2-bin/bin/
COPY config/hive-env.sh /root/apache-hive-1.2.2-bin/conf/

# Install Spark
RUN wget -q --show-progress --progress=bar:force -O- https://archive.apache.org/dist/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz | tar -xzf -

# Set environment variables
ENV SPARK_HOME="/root/spark-2.2.0-bin-hadoop2.7"
ENV HIVE_HOME="/root/apache-hive-1.2.2-bin"
ENV HADOOP_HOME="/root/hadoop-2.8.1"
ENV HBASE_HOME="/root/hbase-1.2.6"
ENV PIG_HOME="/root/pig-0.16.0"
ENV PIG_CLASSPATH="/root/pig-0.16.0/lib"
ENV HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"


# Configure self-ssh key for hadoop
RUN mkdir /root/.ssh && chmod 755 /root/.ssh && ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa && mv /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && echo "StrictHostKeyChecking no" >> /root/.ssh/config

RUN mkdir /srv/namenode /srv/datanode
COPY config/hadoop-env.sh /root/hadoop-2.8.1/etc/hadoop/hadoop-env.sh
COPY config/hdfs-site.xml /root/hadoop-2.8.1/etc/hadoop/hdfs-site.xml
COPY config/yarn-site.xml /root/hadoop-2.8.1/etc/hadoop/yarn-site.xml
COPY config/hbase-site.xml /root/hbase-1.2.6/conf/hbase-site.xml
COPY config/core-site.xml /root/hadoop-2.8.1/etc/hadoop/core-site.xml

COPY entrypoint.sh ./entrypoint.sh



ENTRYPOINT ["./entrypoint.sh"]

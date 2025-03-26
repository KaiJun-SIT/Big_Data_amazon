#!/bin/bash

# Create HDFS directory structure
echo "Creating HDFS directory structure..."
docker exec -it namenode hdfs dfs -mkdir -p /user/hadoop
docker exec -it namenode hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/raw
docker exec -it namenode hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/results

# Set permissions
echo "Setting permissions..."
docker exec -it namenode hdfs dfs -chmod -R 777 /user/hadoop

# Configure Hadoop for better performance
echo "Optimizing Hadoop configuration..."
docker exec -it namenode bash -c "
  echo '<?xml version=\"1.0\"?>
  <configuration>
    <property>
      <name>mapreduce.map.memory.mb</name>
      <value>2048</value>
    </property>
    <property>
      <name>mapreduce.reduce.memory.mb</name>
      <value>4096</value>
    </property>
    <property>
      <name>mapreduce.map.java.opts</name>
      <value>-Xmx1638m</value>
    </property>
    <property>
      <name>mapreduce.reduce.java.opts</name>
      <value>-Xmx3276m</value>
    </property>
    <property>
      <name>mapreduce.job.maps</name>
      <value>8</value>
    </property>
    <property>
      <name>mapreduce.job.reduces</name>
      <value>4</value>
    </property>
    <property>
      <name>mapreduce.task.io.sort.mb</name>
      <value>512</value>
    </property>
    <property>
      <name>mapreduce.task.io.sort.factor</name>
      <value>100</value>
    </property>
  </configuration>' > /etc/hadoop/mapred-site.xml
"

docker exec -it namenode bash -c "
  echo '<?xml version=\"1.0\"?>
  <configuration>
    <property>
      <name>dfs.replication</name>
      <value>1</value>
    </property>
    <property>
      <name>dfs.blocksize</name>
      <value>134217728</value>
    </property>
    <property>
      <name>dfs.datanode.handler.count</name>
      <value>20</value>
    </property>
    <property>
      <name>dfs.namenode.handler.count</name>
      <value>50</value>
    </property>
  </configuration>' > /etc/hadoop/hdfs-site.xml
"

echo "Setup complete!"
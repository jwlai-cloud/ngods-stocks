#!/bin/bash

export JAVA_HOME="$(jrunscript -e 'java.lang.System.out.println(java.lang.System.getProperty("java.home"));')"
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/metastore
export TRINO_HOME=/opt/trino
export DAGSTER_HOME=/opt/dagster

export METASTORE_HADOOP_VERSION=3.2.0
export HADOOP_CLASSPATH=${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.375.jar:${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-${METASTORE_HADOOP_VERSION}.jar

export DAGSTER_DIR=/var/lib/ngods/dagster

# spark
mkdir -p /tmp/spark-events
start-master.sh -p 7077 --webui-port 8061
start-worker.sh spark://spark:7077 --webui-port 8062
start-history-server.sh
start-thriftserver.sh --hiveconf hive.server2.thrift.port 10000 --hiveconf hive.server2.authentication NOSASL

# metastore 
${HIVE_HOME}/bin/schematool -initSchema -dbType postgres
${HIVE_HOME}/bin/start-metastore &

# trino
${TRINO_HOME}/bin/launcher start

# dagster
cd ${DAGSTER_DIR} && dagit -h 0.0.0.0 -p 3070 &

# Entrypoint, for example notebook, pyspark or spark-sql
if [[ $# -gt 0 ]] ; then
    eval "$1"
fi
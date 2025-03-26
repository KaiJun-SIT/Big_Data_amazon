#!/bin/bash

# Script to execute commands on the Hadoop containers

function print_usage() {
  echo "Hadoop environment helper script"
  echo "Usage:"
  echo "  ./hadoop-env.sh hdfs [command]    Execute HDFS commands"
  echo "  ./hadoop-env.sh yarn [command]    Execute YARN commands"
  echo "  ./hadoop-env.sh mapred [command]  Execute MapReduce commands"
  echo "  ./hadoop-env.sh shell             Open a shell in the namenode container"
}

case "$1" in
  hdfs)
    shift
    docker exec -it namenode hdfs $@
    ;;
  yarn)
    shift
    docker exec -it resourcemanager yarn $@
    ;;
  mapred)
    shift
    docker exec -it resourcemanager mapred $@
    ;;
  shell)
    docker exec -it namenode bash
    ;;
  *)
    print_usage
    ;;
esac
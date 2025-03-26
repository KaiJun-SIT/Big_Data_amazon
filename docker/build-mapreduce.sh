#!/bin/bash

echo "Building MapReduce job..."

# Download required libraries
docker exec -it namenode bash -c "
  mkdir -p /tmp/lib
  cd /tmp/lib
  if [ ! -f json-simple-1.1.1.jar ]; then
    curl -L https://repo1.maven.org/maven2/com/googlecode/json-simple/json-simple/1.1.1/json-simple-1.1.1.jar -o json-simple-1.1.1.jar
  fi
"

# Compile inside namenode
docker exec -it namenode bash -c "
  mkdir -p /tmp/build
  cp /src/mapreduce/ReviewAnalysis.java /tmp/build/
  cd /tmp/build
  javac -cp \$(hadoop classpath):/tmp/lib/json-simple-1.1.1.jar ReviewAnalysis.java
  jar cvf ReviewAnalysis.jar *.class
  cp ReviewAnalysis.jar /src/mapreduce/
"

echo "Build complete. JAR file created at src/mapreduce/ReviewAnalysis.jar"
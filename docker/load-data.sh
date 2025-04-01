#!/bin/bash
# Script to load data into HDFS
# Create HDFS directory structure
echo "Creating HDFS directory structure..."
docker exec -it namenode bash -c 'hdfs dfs -mkdir -p /user/hadoop'
docker exec -it namenode bash -c 'hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/data'
docker exec -it namenode bash -c 'hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/filtered_data'
docker exec -it namenode bash -c 'hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/processed'
docker exec -it namenode bash -c 'hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/results'

SOURCE_FOLDER="data/filtered_data/"

# Load others_data from local data directory to HDFS
for file in "$SOURCE_FOLDER"*; do
    echo "Loading $file into HDFS..."

    # First, copy the file to the namenode container
    docker cp "$file" namenode:/data/filtered_data

    # Then, move it from the container to HDFS
    docker exec -it namenode bash -c 'hdfs dfs -put /data/filtered_data/$(basename "$file") /user/hadoop/amazon_reviews/data/'

    echo "$file loaded!"
done

# Verify data was loaded
echo "Verifying data..."
docker exec -it namenode bash -c 'hdfs dfs -ls -h /user/hadoop/amazon_reviews/data/'

echo "Data loading complete!"
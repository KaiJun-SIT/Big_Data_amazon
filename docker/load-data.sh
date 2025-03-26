#!/bin/bash

# Script to load data into HDFS

# Create HDFS directory structure
echo "Creating HDFS directory structure..."
docker exec -it namenode hdfs dfs -mkdir -p /user/hadoop
docker exec -it namenode hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/raw
docker exec -it namenode hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/others_raw
docker exec -it namenode hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/processed
docker exec -it namenode hdfs dfs -mkdir -p /user/hadoop/amazon_reviews/results

SOURCE_FOLDER="data/others_data/"

# Load others_data from local data directory to HDFS
for file in "$SOURCE_FOLDER"*; do
    echo "Loading $file into HDFS..."

    # First, copy the file to the namenode container
    docker cp "$file" namenode:/data/others_raw

    # Then, move it from the container to HDFS
    docker exec -it namenode hdfs dfs -put "/data/others_data/$(basename "$file")" /user/hadoop/amazon_reviews/others_raw/

    echo "$file loaded!"
done

# Verify data was loaded
echo "Verifying data..."
docker exec -it namenode hdfs dfs -ls -h /user/hadoop/amazon_reviews/others_raw/

echo "Data loading complete!"

------------------------------------------------------------------------------------------------------------------------------------------

SOURCE_FOLDER="data/raw_data/"

# Load raw_data from local data directory to HDFS
for file in "$SOURCE_FOLDER"*; do
    echo "Loading $file into HDFS..."

    # First, copy the file to the namenode container
    docker cp "$file" namenode:/data/raw_data

    # Then, move it from the container to HDFS
    docker exec -it namenode hdfs dfs -put "/data/raw_data/$(basename "$file")" /user/hadoop/amazon_reviews/raw/

    echo "$file loaded!"
done

# Verify data was loaded
echo "Verifying data..."
docker exec -it namenode hdfs dfs -ls -h /user/hadoop/amazon_reviews/raw/

echo "Data loading complete!"
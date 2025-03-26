#!/bin/bash

# Process multiple JSON files using Hadoop MapReduce

# Check if input directory is provided
if [ -z "$1" ]; then
  echo "Usage: ./process-files.sh <input_directory> [max_files]"
  exit 1
fi

INPUT_DIR="$1"
MAX_FILES="${2:-0}"  # Default to 0 (process all files)

# Configuration
HDFS_INPUT_DIR="/user/hadoop/amazon_reviews/raw"
HDFS_OUTPUT_DIR="/user/hadoop/amazon_reviews/results"
MAPREDUCE_JAR="/src/mapreduce/ReviewAnalysis.jar"
LOCAL_RESULTS_DIR="results/files"

# Create local results directory
mkdir -p "$LOCAL_RESULTS_DIR"

# Get all JSON files from input directory
JSON_FILES=($INPUT_DIR/output.json)

# Limit files if specified
if [ "$MAX_FILES" -gt 0 ] && [ ${#JSON_FILES[@]} -gt "$MAX_FILES" ]; then
  JSON_FILES=("${JSON_FILES[@]:0:$MAX_FILES}")
fi

# Process status tracking
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="results/processing_log.txt"
echo "Starting processing at $TIMESTAMP" > "$LOG_FILE"
echo "Total files to process: ${#JSON_FILES[@]}" >> "$LOG_FILE"

# Function to check HDFS space
function check_hdfs_space {
  docker exec -it namenode hdfs dfs -df -h /
}

# Process each JSON file
FILE_COUNT=0

for JSON_FILE in "${JSON_FILES[@]}"; do
  FILE_COUNT=$((FILE_COUNT + 1))
  FILE_NAME=$(basename "$JSON_FILE")
  BASE_NAME="${FILE_NAME%.*}"
  
  echo "Processing file $FILE_COUNT/${#JSON_FILES[@]}: $FILE_NAME"
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$TIMESTAMP: Starting file $FILE_COUNT/${#JSON_FILES[@]}: $FILE_NAME" >> "$LOG_FILE"
  
  # Step 1: Check HDFS space before uploading
  check_hdfs_space
  
  # Step 3: Run MapReduce job
  echo "Running MapReduce job..."
  docker exec -it namenode hadoop jar "$MAPREDUCE_JAR" ReviewAnalysis "$HDFS_INPUT_DIR/$FILE_NAME" "$HDFS_OUTPUT_DIR/$BASE_NAME"
  
  if [ $? -eq 0 ]; then
    # Step 4: Get list of output files
    OUTPUT_FILES=$(docker exec -it namenode hdfs dfs -ls "$HDFS_OUTPUT_DIR/$BASE_NAME" | awk '{print $8}' | grep "part-r-")
    
    # Download each output file
    for output_file in $OUTPUT_FILES; do
      filename=$(basename "$output_file")
      echo "Downloading $filename..."
      
      # Copy to temp location in container
      docker exec -it namenode sh -c "hdfs dfs -get $output_file /tmp/$filename"
      
      # Copy from container to local
      docker cp namenode:/tmp/$filename "$LOCAL_RESULTS_DIR/$filename"
      
      # Clean up temp file in container
      docker exec -it namenode rm "/tmp/$filename"
    done
    
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP: Completed file $FILE_NAME successfully" >> "$LOG_FILE"
  else
    echo "Job failed for file $FILE_NAME"
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP: FAILED file $FILE_NAME" >> "$LOG_FILE"
  fi
  
  # Step 5: Remove from HDFS to free space
  echo "Removing file from HDFS..."
  docker exec -it namenode hdfs dfs -rm "$HDFS_INPUT_DIR/$FILE_NAME"
  
  echo "File $FILE_COUNT/${#JSON_FILES[@]} complete"
  echo "-----------------------------------------"
done

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "All files processed at $TIMESTAMP" >> "$LOG_FILE"
echo "Processing complete! Results are in $LOCAL_RESULTS_DIR"
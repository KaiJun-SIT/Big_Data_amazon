#!/bin/bash

# Monitor processing progress

LOG_FILE="results/processing_log.txt"

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
  echo "Log file not found. Has processing started?"
  exit 1
fi

# Get processing statistics
TOTAL_FILES=$(grep "Total files to process:" "$LOG_FILE" | head -n 1 | sed 's/.*: //')
COMPLETED=$(grep -c "Completed file" "$LOG_FILE")
FAILED=$(grep -c "FAILED file" "$LOG_FILE")

# Calculate progress
if [[ "$TOTAL_FILES" =~ ^[0-9]+$ ]]; then
  PROGRESS_PCT=$((COMPLETED * 100 / TOTAL_FILES))
  
  echo "=== PROCESSING PROGRESS ==="
  echo "Total files: $TOTAL_FILES"
  echo "Completed: $COMPLETED ($PROGRESS_PCT%)"
  echo "Failed: $FAILED"
  echo "Remaining: $((TOTAL_FILES - COMPLETED - FAILED))"
else
  echo "Processing has started but total file count not found."
fi

# Check HDFS status
echo -e "\n=== HDFS STATUS ==="
docker exec -it namenode hdfs dfsadmin -report | grep -A 5 "Configured Capacity"

# Check container status
echo -e "\n=== CONTAINER STATUS ==="
docker stats --no-stream

# Show recent log entries
echo -e "\n=== RECENT LOG ENTRIES ==="
tail -n 10 "$LOG_FILE"
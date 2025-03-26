#!/bin/bash

# Aggregate results from all processed files

RESULTS_DIR="results/files"
OUTPUT_FILE="results/final_results.csv"

# Ensure output directory exists
mkdir -p "results"

# Check if we have any results
if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls -A $RESULTS_DIR)" ]; then
  echo "No results found in $RESULTS_DIR"
  exit 1
fi

echo "Aggregating results from files in $RESULTS_DIR"

# Find all part-r-00000 files
PARTS=$(find "$RESULTS_DIR" -name "part-r-00000" | sort)

if [ -z "$PARTS" ]; then
  echo "No result parts found"
  exit 1
fi

# Extract header from first file
HEAD_FILE=$(echo "$PARTS" | head -n 1)
if [ -f "$HEAD_FILE" ]; then
  head -n 1 "$HEAD_FILE" > "$OUTPUT_FILE"
else
  echo "Header file not found"
  exit 1
fi

# Append data from all files (skip header)
for PART in $PARTS; do
  tail -n +2 "$PART" >> "$OUTPUT_FILE"
done

# Count total lines
TOTAL_LINES=$(wc -l < "$OUTPUT_FILE")
echo "Aggregation complete. Final result has $TOTAL_LINES lines."
echo "Final results saved to: $OUTPUT_FILE"
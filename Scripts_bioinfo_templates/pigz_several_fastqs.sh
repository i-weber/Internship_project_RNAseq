#!/bin/bash

# Specify directory containing FASTQ files
DIRECTORY="/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/"

# Find all .fastq files in the specified directory and subdirectories. Write line by line, pipe each line with one file name into while loop that compresses it.
find "$DIRECTORY" -type f -name "*.fastq" | while read -r FILE; do
  echo "Compressing $FILE"
  pigz "$FILE"
done

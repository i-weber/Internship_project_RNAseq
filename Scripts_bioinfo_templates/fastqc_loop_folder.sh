#!/bin/bash

directory="/home/iweber/Documents/Datasets/Pre_eclampsia_mice/Pre_eclampsia_mice_fastq"

for file in "$directory"/*.fastq; do
	if [ -f "$file" ]; then
		fastqc "$file" --outdir /home/iweber/Documents/Datasets/Pre_eclampsia_mice/FastQC_results
	fi
done

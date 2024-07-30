!#/bin/bash

trimmomatic PE -phred33 *.fastq -baseout "output" LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:3

fastqc output_* --threads 8 --memory 40000 --outdir FastQC_results

multiqc FastQC_results/ --outdir MultiQC_results/

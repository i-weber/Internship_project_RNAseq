Welcome to my first NGS data analysis project! This is still a work in progress, in which I have invested around ==280 hours of hands-on time== up until now. You can see the interim results here: [https://i-weber.shinyapps.io/shiny_app_pre-eclampsia_results/](https://i-weber.shinyapps.io/shiny_app_pre-eclampsia_results/).

I analyzed the RNA sequencing data from this study: **[GSE167193](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE167193)** on GEO at NCBI. This study, from the <a href='https://sites.rutgers.edu/shuo-xiao/'>lab of Shuo Xiao at Rutgers University</a> , analyzed a potential connection between a pregnancy disorder known as pre-eclampsia and autism spectrum disorders. Pre-eclampsia is a common and dangerous increase in maternal blood pressure that can occur after the 20th week of pregnancy. One in 20 pregnant people are affected by pre-eclampsia, which has a severe negative impact on both the pregnant person and the fetus. There is no treatment known to date, except for the delivery of the placenta, and very little is known about the long-term consequences on the development of the child's brain.

The original study focused on gene expression and identified around 250 genes that are differentially expressed under the prenatal stress of pre-eclampsia. I chose to re-analyze the data using a different suite of alignment, mapping, and expression analysis tools (STAR, Salmon, and DESeq). Additionally, I wanted to focus on better understanding alternative pre-mRNA splicing. 

To do so, I started out by employing the [rnasplice](https://doi.org/10.5281/zenodo.8424632) Nextflow pipeline from [nf-core]( https://doi.org/10.1038/s41587-020-0439-x).
# Table of contents
- [1. Where to find specific files](#1.where-to-find-specific-files)
- [2. What is *not* included in the repository](#2.-what-is--not--included-in-the-repository)
- [3. Current to do list](#3.-current-to-do-list)
- [4. Sources](#4.-sources)

# 1. Where to find specific files

1. Description of how I progressed through the project: **"Knowledge_Progression_handling_RNA-seq_datasets"** 

This includes: 
- how I built my Linux virtual machine and how I transferred it from VirtualBox to VMWare Workstation Pro;
- how I performed the analyses in Linux (Ubuntu) using the Nextflow rnasplice pipeline from nf-core;
- how I checked the results of the pipeline

I included this description file in both PDF and in the Obsidian markdown format. The images these files reference are in the folder **Own project images**.

2.  Results directly from the rnasplice pipeline: **Pre-eclampsia_dataset_raw_and_processed -> Pre_eclampsia_mice_rnasplice_results**:  (copies of the output files from the different parts of the pipeline. Originals are on my virtual machine in the pipeline result folder.)

Of potential general interest:
- html report from MultiQC about the entirety of the pipeline, stored in **Pre-eclampsia_dataset_raw_and_processed -> Pre_eclampsia_mice_rnasplice_results -> multiqc**

3.  My analyses in R of the rnasplice pipeline results.: **Pre-eclampsia_dataset_raw_and_processed -> Pre_eclampsia_analyses**
This includes:
- the tabular results of my analyses, stored in **Pre-eclampsia_dataset_raw_and_processed -> Pre_eclampsia_analyses -> results**;
- the plots resulting from my analyses, stored in **Pre-eclampsia_dataset_raw_and_processed -> Pre_eclampsia_analyses -> plots**
- the code for the Shiny app (**app.R**), which is in **Pre-eclampsia_dataset_raw_and_processed -> Pre_eclampsia_analyses -> results -> Shiny_app_rnasplice_pre-eclampsia_final**

Any comments specific to each analysis or the app are within their respective scripts.

# 2. What is *not* included in the repository
I omitted some files due to the size restrictions of GitHub:
- original FastQ files, BAM and tsv files resulting from the analyses or interim steps
- RDS files that I used to save all of the variables in each of the scripts. These can be quickly re-generated the first time you run one of the scripts. I used them to be able to jump right back into each of the analyses on the quick.

# 3. Current to do list

1. Overview page
- [x] what is study about
- [x] what have I analyzed

2. General stats about the dataset
- [x] edit Excel file with output from MultiQC - separate in separate Sheets with easy-to-understand names & import in R for plotting
- [x] graphs made based on summary info from pipeline
- [x] extract html graphs from multiqc report for other tools
- [ ] import Salmon quant.sf files for each sample and do hierarchical cluster analysis
- [ ] include FastQC plots


3. Differentially expressed genes and transcripts (DESeq2 and DEXSeq DTU)
- [ ] show with how many data points each tool started and how this dropped based on different parameters, e.g. presence of NAs (interactive alluvial plots)
- [ ] PCA analysis DESeq2 and PCA analysis DEXSeq DTU (row 1)
- [ ] DESeq2: investigate - why does LFC shrinkage not do anything in my case?
- [x] interactive adjusted p-value/FDR distribution plots for DESEq2 and DEXSeq DTU (row 2)

- [x] side by side, volcano plots DESEq2 and DEXSeq DTU
- [ ] make sure volcano plots and p-value distribs have similar axis setups
- [ ] interactive MA plot DESeq (if LFC shrinkage succeeds -> MA plot after it!)
- [ ] interactive table - which of the DEGs from paper did I find in my DESeq2 analysis? 
- [ ] expression levels and significance I find for the genes they highlight in figure 2G

- [ ] extract all NCBI synonyms for gene names in original publication and add to respective rows in that table
- [ ] overlap genes I find with DESeq2 with genes found in publication
- [ ] conclusions from overlap in gene expression
- [ ] button to download overlap table my genes - publication genes

- [ ] transcripts analysis: what genes do they come from? Overlap with genes detected by DESeq2?
- [ ] download button - overlap table DESeq2 genes - DEXSeq DTU genes

- [ ] conclusions for gene- and transcript-level analysis


4. Exons that are alternatively spliced
- [ ] show with how many data points each tool started and how this dropped based on different parameters (interactive alluvial plots)
- [x] interactive adjusted p-value/FDR distribution plots for DEXSeq DEU, rMATS, edgeR, SUPPA
- [x] interactive volcano plots for DEXSeq DEU, rMATS, edgeR, SUPPA
- [x] UpSet plot in center showing overlaps between datasets. 
- [x] table genes shared between different datasets
- [ ] buttons that allow downloading of significant data for each plot
- [ ] Sashimi plots for genes that contain differentially spliced exons
- [ ] think and research: why could some of the tools find so few diff regulated exons? Esp edgeR, who finds so many exons in total in the annotations.
- [ ] 
- [ ] conclusions for exon-level analysis


# 4. Sources

- data: <a href='https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE167193'>GSE167193</a>
- source [publication of Liu et al., 2023](https://www.life-science-alliance.org/content/6/8/e202301957)

* Rnasplice pipeline   https://doi.org/10.5281/zenodo.8424632
* The nf-core framework   https://doi.org/10.1038/s41587-020-0439-x
* Software dependencies of rnasplice  https://github.com/nf-core/rnasplice/blob/master/CITATIONS.md

- DESeq2: Love, M.I., Huber, W., Anders, S. (2014) Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2. _Genome Biology_, **15**:550. [10.1186/s13059-014-0550-8](http://dx.doi.org/10.1186/s13059-014-0550-8)
- DEXSeq: Anders S, Reyes A, Huber W (2012). “Detecting differential usage of exons from RNA-seq data.” _Genome Research_, **22**, 4025. [doi:10.1101/gr.133744.111](https://doi.org/10.1101/gr.133744.111).
- DEXSeq: Reyes A, Anders S, Weatheritt R, Gibson T, Steinmetz L, Huber W (2013). “Drift and conservation of differential exon usage across tissues in primate species.” _PNAS_, **110**, -5. [doi:10.1073/pnas.1307202110](https://doi.org/10.1073/pnas.1307202110).

-  edgeR: Robinson, MD, McCarthy, DJ, Smyth, GK (2010). edgeR: a Bioconductor package for differential expression analysis of digital gene expression data. Bioinformatics 26, 139–140. https://doi.org/10.1093/biostatistics/kxm030
- edgeR: Robinson, MD, McCarthy, DJ, Smyth, GK (2010). edgeR: a Bioconductor package for differential expression analysis of digital gene expression data. Bioinformatics 26, 139–140. [https://doi.org/10.1093/bioinformatics/btp616](https://doi.org/10.1093/bioinformatics/btp616)
- edgeR: Chen Y, Chen L, Lun ATL, Baldoni PL, Smyth GK (2024). edgeR 4.0: powerful differential analysis of sequencing data with expanded functionality and improved support for small counts and larger datasets. bioRxiv doi: [10.1101/2024.01.21.576131](https://10.1101/2024.01.21.576131).

- rMATS: Shen S., Park JW., Lu ZX., Lin L., Henry MD., Wu YN., Zhou Q., Xing Y. rMATS: Robust and Flexible Detection of Differential Alternative Splicing from Replicate RNA-Seq Data. _PNAS_, 111(51):E5593-601. [doi: 10.1073/pnas.1419161111](http://dx.doi.org/10.1073/pnas.1419161111)  
- rMATS: Park JW., Tokheim C., Shen S., Xing Y. Identifying differential alternative splicing events from RNA sequencing data using RNASeq-MATS. _Methods in Molecular Biology: Deep Sequencing Data Analysis_, 2013;1038:171-179 [doi: 10.1007/978-1-62703-514-9_10](http://dx.doi.org/10.1007/978-1-62703-514-9_10)  
- rMATS: Shen S., Park JW., Huang J., Dittmar KA., Lu ZX., Zhou Q., Carstens RP., Xing Y. MATS: A Bayesian Framework for Flexible Detection of Differential Alternative Splicing from RNA-Seq Data. _Nucleic Acids Research_, 2012;40(8):e61 [doi: 10.1093/nar/gkr1291](http://dx.doi.org/10.1093/nar/gkr1291)

- SUPPA: - Trincado JL, Entizne JC, Hysenaj G, Singh B, Skalic M, Elliott DJ, Eyras E. [SUPPA2: fast, accurate, and uncertainty-aware differential splicing analysis across multiple conditions](https://www.ncbi.nlm.nih.gov/pubmed/29571299). Genome Biol. 2018 Mar 23;19(1):40.
- SUPPA: Alamancos GP, Pagès A, Trincado JL, Bellora N, Eyras E. [Leveraging transcript quantification for fast computation of alternative splicing profiles](https://www.ncbi.nlm.nih.gov/pubmed/26179515). RNA. 2015 Sep;21(9):1521-31.

# Aims

I want to see if I can replicate results published on the basis of a bulk RNA-seq dataset in terms of:
	- differential gene expression (DGE) analysis
	- GO term analysis on differentially expressed genes
	- Functional enrichment if possible
	- enrichment in disease-related genes or SNPs
	- gene network analysis

# Finding a suitable study
I searched for clinically relevant, loosely cerebral cortex development-related RNA-seq datasets with attached publication. I selected only datasets uploaded last year and whose publications don't do highly in-depth analyses, as I believe that me working on this data will bring the biggest contribution to expanding our knowledge horizon. As to why I selected datasets that were associated with a publication: this was for me to be able to cross-check the results of my analyses and make sure I am performing my analysis properly.

I found this study: **[GSE167193](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE167193)** on GEO at NCBI. This study analyzed a potential connection between a pregnancy disorder known as pre-eclampsia and autism spectrum disorders. Pre-eclampsia is a common and dangerous increase in maternal blood pressure that can occur after the 20th week of pregnancy. One in 20 pregnant people are affected by pre-eclampsia, which has a severe negative impact on both the pregnant person and the fetus. There is no treatment known to date, except for the delivery of the placenta, and very little is known about the long-term consequences on the development of the child's brain.

The authors used a pre-eclampsia mouse model in which the disorder was induced in pregnant mice by treating them with a compound called L-NAME. The mouse offspring from mothers that were exposed to L-NAME behaved in ways reminiscent of ASD and scored accordingly on several behavioral tests that are thought to assess metrics related to the condition.

To better understand the relationship between the two conditions, the authors sequenced RNAs from the cortices of mouse embryos at day E 17.5, two days before birth, from mother animals that had or did not have elevated blood pressure, and similarly from the hippocampi of adult offspring. The authors generated cDNA libraries from the cortical RNAs of control and experimental condition embryonic cortices using a kit for stranded mRNA detection. This means that the kit enriches for poly-A-tailed mRNAs and also captures information regarding which genomic DNA strand the mRNAs were transcribed from. This is an excellent fit for my purposes, as I am, for the time being, interested in coding transcripts. Then, the cDNA libraries were fragmented, and the fragments were sequenced on Illumina Hiseq X machines, a process that generated millions of paired-end 150 bp reads (21 million, to be a little more precise [link to post where I open the FastQC files]).

I focused my investigation on the embryonic cortex data, as this is a system I am more familiar with from my own research work.

![[2024-03-11_preeclampsia_SRAvalidation.png]]

I downloaded the datasets directly from the entry of this study on GEO in SRA format. As I found out, SRA is an NCBI-specific way to compress FastQ files. These are the ones with the raw reads from the sequencers and I learned that these are precisely what I will need for performing differential sequence analysis. The processing of the files to any other format, such as SAM or BAM, or anything else except for basic quality control, may introduce biases that affect subsequent data analyses.

# So what is RNA-seq anyway? And what's the deal with alternative splicing analysis?

> [!To read:]
> General info on RNA-Seq analysis https://academic.oup.com/bib/article/23/2/bbab563/6514404?login=false
> general info RNA-seq, inc long read (third-gen) https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10043755/
> 
> https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4712774/ tximport solves issues with artificially inflated gene counts derived from transcript isoforms. It essentially bundles the counts obtained by Salmon for individual transcripts into counts for the gene that those transcripts were transcribed from. For this, it needs a so-called tx2gene.tsv table that indicates the relationships between all of the possible transcripts from a genome and the genes from that genome.

# Downloading genomes
I knew the next step would be to map the reads to the source genome, and for that I, of course, needed the mouse genome.

I found [here](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/) that NCBI has two command line tools for Linux that ease the download of datasets. From within the NGS environment and in a new folder "Genomes", I used `curl` to get the installers as shown on the NCBI page, and then made the binaries executable as instructed.

I then proceeded to download the genomes that are relevant to me (mouse and human) using the option to find them by accession number. I got the accessions for the latest assemblies [here](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.40/) and [here](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001635.27/). To be on the safe side, I decided to use the more elaborately curated RefSeq assemblies, so the commands looked as follows:

`(NGS) iweber@iweber-VirtualBox:~/Documents/Genomes$ datasets download genome accession GCF_000001405.40 --filename genome_H_sapiens_GRCh38.zip`

...and got a big, fat load of nothing  xD, because the shell said it can't find the command "datasets". Instead of fumbling to find where the binaries associated with these two tools are, I decided to simply use conda to install them directly into this environment.

`conda create -n ncbi_datasets
`conda activate ncbi_datasets`
`conda install -c conda-forge ncbi-datasets-cli`
![[2024-05-07_conda_install_ncbi_dataset_success.png]]


# In the Windows Subsystem for Linux (WSL), getting the SRA Toolkit and SRR run files from the preeclampsia study

Using the documentation at NCBI, I found that one needs a suite of programs called SRA Toolkit in order to losslessly convert the SRA files into FastQ files. I installed the toolkit using the instructions on the GitHub page of the NCBI, https://github.com/ncbi/sra-tools/wiki/ . I decided to do so under Ubuntu running on the Windows Subsystem for Linux (WSL). I have read that, for optimal memory usage, it is preferable to create a virtual machine running a Linux distribution rather than the WSL. However, given that this was my first shot at analyzing a relatively small SRA dataset (~2.8 GB), I concluded that this is good enough for starters.

I downloaded the SRA toolkit as a .tar.gz archive for Ubuntu from one of the FTP servers of the NCBI:

```bash
wget --output-document sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
```

then extracted it in one of my Ubuntu folders with the tar utility (included in Ubuntu),

```bash
tar -vxzf sratoolkit.tar.gz
```

 and could afterwards access its tools over the command line.

As per the instructions of the GitHub page, I modified the PATH variable in my system. This essentially tells Ubuntu that there is a shortcut to the folders where SRA Toolkit has its binaries (bin directory) so that I can then easily access the individual tools and commands from the toolkit via the command line without needing to constantly change directories to that in which I extracted the SRA toolkit. 
 
```bash
export PATH=$PATH:$PWD/sratoolkit.3.1.0-ubuntu64/bin
```

This should tell the shell that, when looking for binaries (tools, programs, etc that are executable), it should also look in the respective folder of the SRA Toolkit.

To verify whether the binaries can be found by the shell, I used

```bash
fastq-dump --stdout -X 2 SRR390728
```

...which worked as expected with returning the path to the directory of binaries precisely until I restarted the terminal :) I then found out that "export" only does a temporary modification of the PATH environment variable, which isn't kept in the global namespace. So, after advice from Christoph, I found out I need to only add the exact same line, minus "export", into the .profiles file, which should save any customized variants of the PATH variable. And now I have the SRA Toolkit set up to work from any directory, and even after restarting the shell.

Additionally, I created a handy alias for changing the directory to where my datasets are stored by adding the following under "Some more aliases" in the .bashrc file:

```bash
alias mydatasets='cd /home/iweber/Datasets'
```

So now I can go straight to that folder with only typing "myd" and hitting tab.

I also undertook the Toolkit Configuration as directed by the GitHub page of SRA toolkit using `vdb-dump -i`.[[double check command]] One noteworthy difference to how the configuration window looks like for me vs the website is that I do not have, under Main, the frame with options regarding to Workspace name and Workspace location. 
***I wonder if this is a matter of working on WSL instead of a full Linux distro?***

However, in the tab Cache, I did set the location of the user-repository and process-local to be my Datasets folder, so that I may always find my files easily. I also created a subdirectory for my current study so that my data stays organized.

# WSL - Extracting FastQ files from the SRR archives

And now that the tools are set up, I went on to try and extract the FastQ files from my dataset in SRA format. In my Datasets directory, I used the fasterq-dump command together with my dataset as a command-line argument:

```bash
fasterq-dump SRR13761520
```

And waited. I was afraid nothing is happening and I just went into some infinite loop, but then I navigated in Windows to the Datasets folder in WSL and saw that a temporary directory had been created. Since the terminal also didn't show me a fresh command prompt, I assumed it was just working intensely in the background to convert the data. Also, my ventilators were going crazy. s, when I checked the Task Manager, I saw that nearly 60% of my memory was in use by a process called "Vmmem". Sure enough, a brief web search uncovered that this happens precisely when using WSL, and is the Windows process responsible for the virtual memory management[[Double check!]]. All of this was happening before switching my RAM chips from a total of 32 GB to a total of 128 GB :) Yes, I am aware that I will need to set up a few more things, such as hyper-threading, for the new RAM to work as effectively as possible, but I was reluctant to do this at first, as my first experience after getting my laptop had been it crashing and refusing to start Windows upon installing a VirtualBox virtual machine and tinkering with the virtualization settings).

I had read on the GitHub page of the SRA Toolkit that the extraction of FastQ files requires a RAM size up to as much as 10 times the size of the original SRA file, at least during the extraction process (scratch space - had run into issues with this with Photoshop before, which kept complaining that the scratch disks were full and it therefore couldn't save whatever new artsy monster file I had created). So I was expecting Task Manager to tell me that around 25 of my 32 GB of RAM (~78% of it) were in use by the Vmmem process. The process started out at around 50%. Half an hour of observation later, I realized that it kept increasing over time. I did see it go up to a max of 75.6% with a fairly steady increase over time, so I assume the Toolkit kept adding info to the scratch disks as the process progressed. Looking in the Resource Monitor of Windows, vmmem said it was using a Commit of 10,470,000 and a Working set of about the same size. I suspect Task Manager is not as accurate as the Resource Monitor ?

To check the progress of the unpacking, I peeked at the size of the temporary folder in the SRA folder of this study in Datasets. When I first looked at it, some 3-4 minutes after starting the extraction tool, it was at around 3.8 GB. Some 10 minutes after starting the extraction, it was at 6.5 GB.

At this point, I started wondering where exactly WSL was storing its files in a physical sense (I know, I know, should've done so sooner, etc). It being a subsystem of Windows, I strongly suspected it would also be on my Windows drive, which, unfortunately, is the smaller of my two SSDs, at 250 GB. And indeed, when checking the properties of my Windows drive, I realized that the free space on this drive was decreasing. Being fairly close to the size limit of the drive (~10 GB free), I was concerned that this might completely kill Windows if working on such a full drive or result in a corrupted, incomplete extraction of the FastQ files. So I started uninstalling any programs I saw were using a lot of space with their files and freed up some 10 more GB of RAM.

I also noticed that the Toolkit had also created another folder under Datasets called "sra", with a .sra.cache file of a only slightly larger size as the original SRA dataset (2,829,033 KB for the dataset and 2,829,054 KB for the .sra.cache file). This did not change in time.

It took around one hour for the extraction to finish, and I then got this:
![[2024-03-12_SRA_fasterq-dump_result.png]]

And bam! I had two FastQ files in my study directory, each at exactly 7,954,345 Kb, so 7.9 GB and a total of around 16 GB. All in all, that's around 5.7x larger than the original SRA file.

But why were there two files with the same accession number but with _____1_ or __2__ appended to the file name? The answer was fairly easy to find: these were reads from paired-end sequencing runs, as indicated on the NCBI website for this [dataset](https://trace.ncbi.nlm.nih.gov/Traces/index.html?view=run_browser&acc=SRR13761520&display=metadata) and the paper's methods. Sequencing both ends of the cDNA fragments resulting from the cortex RNAs allows for more precise alignment [source] and is thus more useful especially in detecting alternative splicing isoforms, which may be of interest to me later. 

I opened the two behemoth files by ~~torturing~~ convincing Notepad++ to do so, and, at first glance, they looked identical. 

After this step, I also realized I had severely underestimated exactly how many files I'd have to download and extract, and to what space requirements that would amount to :teary-smile:

So, the first thing I did was to...get a larger SSD for my OS. I initially had a 256 GB NVMe and switched to a 4 TB instead.

# Temporary fix for space issues: change location where WSL stores its files
But, for the time being: how could I change where Windows saves the files of the WSL? Thank goodness that I'm not yet at a level at which my questions haven't yet been asked by anybody on the Internet. I found this set of instructions by [NotTheDr01ds](https://superuser.com/users/1210833/notthedr01ds) on SuperUser: https://superuser.com/questions/1736576/change-the-storage-location-of-a-wsl2 I decided to execute them on the basis that they also create a backup image of Ubuntu on the WSL as I had it set up before, that the code was clearly commented and easy to understand in terms of what environment variables were being modified how, and that the user seemed to have taken extra time to spell out precautions and build in safety checks. This is what I ran:

![[2024-03-14_WSL_locchange_process.png]]

And it seems to have worked. Also, this was my first time seeing both Windows ***and*** Linux command lines mixed in the same window and, as the beginner that I am, it blew my mind. I realized that, basically, all I'm doing when starting the Ubuntu terminal  I can also do from PowerShell window, provided that I started the WSL within it.

With WSL open in the PowerShell terminal, I did several checks as to whether the new distro at the new location was working properly:
![[2024-03-14_WSL_locchange_check.png]]

I started WSL, then tested which distro was running using the code provided by [NotTheDr01ds](https://superuser.com/users/1210833/notthedr01ds). In addition to that, I checked whether I could still use an alias I had set in my .bashrc some time ago, which simply changes the working directory directly to one where I store files for the ABI course. I also listed the contents of the directory, just to be extra sure that they are what I know them to be and that my default user is still the owner and has all of the permissions, as I know this can be difficult to alter should I not be the owner any longer [[***source?***]] 

And I then de-registered my old distro from WSL.

A consequence that I hadn't anticipated is that now I cannot use the Ubuntu app from the store directly any longer, at least not without creating a completely new distro...but that's easily fixed by running Ubuntu from the Windows Terminal instead, which I've taken to doing.

Result: successfully changed location, freeing some space on my currently plighted OS drive. I will need to change it back once I exchange the OS drive to a larger one, but at least the datasets I have stored in WSL and all of my course materials are safe for now on the other SSD. 

***Considering to make regular .tar/VHD backups of the WSL on the second SSD just to be on the safe side***

I then wanted to get and extract all of the other SRA archives related to the E 17.5 cortices in this study. To do so, I wrote a Bash script containing the commands for fetching the remaining SRA archives (`prefetch` command of the SRA toolkit) and to unpack them (`fasterq-dump` command), set it to executable, and started it from the shell.

> [!NOTE]
> script?

I checked the progress on occasion via TeamViewer, and saw things moving along through the continual increase in the size of the export folder. As a side note, here I also saw that the WSL virtual machine was still using up almost half of my RAM during this operation, and I think this is due to the limitations that WSL has in terms of memory usage, at least when compared to a virtual machine, so I decided I must take the plunge and create one. (see linked post about VM)


# Quality control of FastQ files with the RNA-seq reads (still on WSL)
## Quality control of individual FastQ files
For the quality control of this small number of files, I used [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), which is an open-source tool that checks the reads in FastQ files for various quality parameters, such as sequence quality scores, GC content, sequence duplication levels, or the presence of sequences left behind by the oligonucleotide adapters used for the amplification and actual sequencing of the cDNA fragments. I was pleasantly surprised that opening the application from the Ubuntu command line resulted in a user-friendly GUI, with which I could select the sequences to be analyzed. After analyzing the two FastQ files resulting from the first sequencing run (SRR13761520_1 and SRR13761520_2), I got quite different results. Whereas the file ending in 2 passed the quality checks in all but one department ("Per base sequence content" gave a warning), the file ending in 1 had a few more issues. It failed the "Per base sequence content" testing and gave warnings for "Per sequence GC content" and "Sequence duplication levels". I suppose this difference results from one of the files representing one item from each pair of reads and the other file the sequence complementary to it [source?]. As these two reads stem from two separate sequencing reactions [source], it is normal that one set can have different sequencing quality, based on differences in the reaction setup, base composition, or technically-introduced biases that only happened for one of the two sequencing runs.

Nonetheless, I wanted to understand better what the parameters returned by FastQC are and what they mean for the usability of the data for further analyses. To better understand how this data was pre-processed, I foraged a bit in the Series Matrix file provided on the GEO page of the study, but the authors don't give a lot of details about the handling of the data, aside from `Reads filtering under criteria removing reads with 20% of the base quality lower than 13"`. Considering that FastQC did not indicate the presence of any known adapter sequences in the data and that the files were already clearly sorted by experimental condition and subject, (I hope) it's safe to assume that any necessary demultiplexing and adapter trimming has been performed by the authors of the study/the sequencing facility they worked with, plus applying this quality filter they mention in the Series Matrix file.

To centralize all analysis info for all of the FastQ files generated by FastQC, I settled on [MultiQC](https://academic.oup.com/bioinformatics/article/32/19/3047/2196507?login=false) . I envision myself working with single-cell RNA-seq datasets at a later time point, and MultiQC can, as the name suggests, run the analyses in parallel on many files, making it a lot more efficient in handling large numbers of datasets. MultiQC is a part of the bcbio-nextgen Python package, so I wanted to install it in my Python on the WSL Ubuntu as instructed by the package's GitHub [page](https://bcbio-nextgen.readthedocs.io/en/latest/contents/installation.html#automated). I thought this installed not only the package but also all dependencies (other modules) that are needed for it to run...but it didn't. It told me it was missing crucial data, such as the genome assemblies for mouse and human, which prevented it from running at all.

During the lengthy installation process, I kept getting a message for all packages "Solving environment: failed with initial frozen solve. Retrying with flexible solve.". Thanks to another kind internet [stranger](https://medium.com/floppy-disk-f/linux-ubuntu-how-to-fix-solving-environment-failed-with-initial-frozen-solve-27c53c6de32a), I found that this is a problem that stems from having a version of Python that's newer than what many of these packages are optimized to work with. [what version do i have on my WSL? what versions needed? conda search python, then conda install python=desired_version_number, and then restart Ubuntu and Py, and update bcbio-nextgen package, hoping that this will resolve dependency issues]. However, the installation of bcbio-nextgen was still running (also, still running after 3h with the WSL virtual machine using 85 GB RAM sounds unusual and a bit alarming). 

I realized that this may be due to WSL being less efficient in its memory usage than a full-fledged virtual machine [source?], so I proceeded to kill this process and install Oracle VirtualBox 7 and make an Ubuntu VM on it.

## MultiQC: General quality stats of the pre-eclampsia FastQ files


I saw that multiqc takes one full folder as input.  I could call `fastqc` from the command line individually for all of my FastQ files, but...why would I do something rather tedious to do for all of the 16 FastQ files? So I quickly wrote a small Bash script to automate the process:

```bash
#!/bin/bash

directory="/home/iweber/Documents/ABI_files_NGS/6484_fastq/"

for file in "$directory"/*.fastq; do
	if [ -f "$file" ]; then
		fastqc "$file" --outdir /home/iweber/Documents/ABI_files_NGS/FastQC_results
	fi

done
```

This simply cycles through all of the files with a .fastq ending in the indicated directory, stores the name of the file in the variable called file, and then calls fastqc to operate on the content of the file name variable ($file), while outputting the result into the FastQC_results folder.
I made it executable with `chmod` and then ran it, and:

![[2024-05-07_script_FastQC_success.png]]

It worked! Naturally, I then ran MultiQC to summarize all of the reports obtained with FastQC.

![[2024-05-07_MultiQC_res_pre-e_success.png]]

Let's have a more detailed look at the results.

![[2024-05-07_MultiQC_res_pre-e_general_stats.png]]
So far, so good. Each of the files contains around 21 million reads, with a GC content that's normal for the mouse ([source?]). The amount of sequences flagged as duplicates is around 30%, which is to be expected due to the amplification steps during the library preparation ([quote from Ioana Lemnian]).

The Phred scores are, on average, also good across the entire length of the reads., even though, as usual, the quality at the beginning, in the first 10 nucleotides or so from the 5' end, is a bit lower than in the rest of the sequence.
![[2024-05-07_MultiQC_res_pre-e_seq_quality.png]]

What looked a bit less rosy was the per base sequence content quantification. For all of the `_2` ending samples, FastQC gave a warning for the nucleotide composition, which should ideally be uniform across the read, with each base keeping its proportion percentage and giving a plot with four parallel lines. It's normal that the beginning of the read is a bit more noisy, up to 10 bases, and that's what we see here. Even for the samples ending in `_1` , that were flagged as "failed", the irregularities are restricted to this area. This looks like a good case for trimming these fragment start regions off in subsequent steps.
![[2024-05-07_MultiQC_res_pre-e_per-base-seq-content.png]]

The per sequence GC content looked mostly alright (the reads in 11 of the 16 FastQ files passed with no warning), but there were some where FastQC gave a warning, so I know to keep an eye out in case these files cause some strange, systematic error down the line. 

SRR13761520_1
SRR13761521_1
SRR13761521_2
SRR13761522_1
SRR13761523_1
![[Pasted image 20240507201249.png]]

The content of bases that could not be unequivocally identified during the sequencing was, fortunately, negligible.
![[2024-05-07_MultiQC_res_pre-e_per-base-N-content.png]]

Many of the FastQ files were found to contain reads from duplications. These usually result from the PCRs from the library preparation or even during sequencing itself, but the concentration of the second peak at 10x duplication suggests that these all stem from some 10-cycle-PCR. FastQC seems to flag any FastQ files where more than 8% of the reads are duplicates at the >10x mark but only those where the dupes surpass 11% of the read count for the 2x duplication mark [why?].

There were no warnings for overrepresented sequences, and FastQC did not find any of the usual sequences of adapters used in NGS kits in the FastQ files. This tells me that the files were processed before their further use, perhaps directly by the sequencing facility after demultiplexing [maybe ***bcl2fastq*** or ***BCL convert*** can also do this? Or maybe the authors just uploaded the already trimmed reads to GEO.] 

![[2024-05-07_MultiQC_res_pre-e_overrepresented-seqs.png]]

## Summary of initial quality warnings for the reads

> [!Warnings:]
> Datasets with warnings for GC content: 
> SRR13761520_1
> SRR13761521_1
> SRR13761521_2
> SRR13761522_1
> SRR13761523_1
> 
> Dupe warnings:
> SRR13761520_1
> SRR13761521_1
> SRR13761522_1
> SRR13761523_1
> SRR13761524_1
> SRR13761525_1
> SRR13761526_1
> SRR13761526_2
> SRR13761527_1
> SRR13761527_2


# Real solution for space issues: Making a VirtualBox virtual machine to run Ubuntu

Before taking the plunge to make a virtual machine, I made some very thorough backups of my system. I made a restore point, then also used File History and Backup and Restore to make images of my WinOS. Finally, I made a recovery USB in case I wouldn't be able to start the OS after making changes to the BIOS to enable virtualization. Maybe I wouldn't be this paranoid if tinkering with the virtualization options hadn't BSOD-ed my back-then three days old laptop right after setting it up out of the box for the very first time...so better safe than sorry.

Got an Ubuntu 22.04 image from the Canonical website, and installed it as VM with the name Ubuntu 22x64 using the Oracle VirtualBox. I allotted it 96 GB RAM, and 6 CPUs, to make sure it has all of the resources it might need to analyze large data sets.

I thought this worked at first, and then the issues started popping up like mushrooms after the rain: the GNOME terminal that comes with the distro didn't work, I couldn't update the Snap Store even though the update was recommended. I installed another terminal emulator called Guake and attempted to install the bcbio-nextgen tool bundle...and it got stuck with conda not being able to solve the environment (this issue seems to be known and caused due to R package dependencies that conda can't solve, or at least not quickly, see [link](https://github.com/bcbio/bcbio-nextgen/issues/2713)). After stopping that process, I tried updating Python, which almost completely broke the entirety of the Ubuntu installation: the VM stopped showing me the Ubuntu desktop at all and only did so for the TTY terminal, with which I was not able to refresh the installation of the GUI desktop.

(Side note: I also tried the terminal emulator Terminator, whose options I also enjoyed).

I removed the VM completely and reinstalled everything from scratch...only to find out that, suddenly, my user, created during the VM creation process, had no `sudo` privileges and I had no way of accessing the root to give it said privileges. Removed the entire VM again.

Reinstalled Ubuntu 22.04 on a VM with the name ubuntu22x64. Gave it my username iweber and my usual password for the purpose, and selected guest additions from the suggested iso. Let's see if I now have sudo rights for my user... Nope.

Found a forum entry here saying that the issue can be that this unattended installation option that the VM provides creates an user without `sudo` rights. Skipped this option during the creation of the new VM, leaving me to install Ubuntu manually after the creation of the VM.

Did so, selected the keyboard and then to erase disk and install Ubuntu.


After the installation and restart, noticed that the first DOS-like screen had some errors talking about a graphics device and issues with unsupported hyper-visor, but Ubuntu started nonetheless and I could log in with user IoWe (my user, with actual username iweber). ***LE: this keeps happening when the virtual machine powers up, but it still boots, and I am currently not seeing any other issues.***

And magic! I could even open the GNOME Terminal now!

I then let Software Updater update everything it said needed updating. It ran and I noticed it again giving some errors regarding Snaps...but then it finalized the update and said it needed to restart to apply all of the updates, so I let it do so.

After the restart, the terminal still works. I could also `whoami` myself AND `sudo whoami`, which, after providing my password, also let me set the user to root, so I now know I can install any software I may be needing down the line.

I went to the Anaconda website to find out how to download packages that I [previously found out ](https://docs.anaconda.com/free/anaconda/install/linux/)need to be installed for the Anaconda Navigator GUI (anaconda3) to work. The command I used in the terminal was:

```bash
sudo apt-get install libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
```
and it executed without me seeing any errors.

Tried to download the Anaconda Navigator installer [Anaconda3-2024.02-1-Linux-x86_64.sh](https://repo.anaconda.com/archive/Anaconda3-2024.02-1-Linux-x86_64.sh) as recommended by the Anaconda Navigator page by using

```bash
curl -O https://repo.anaconda.com/archive/Anaconda3-2024.02-1-Linux-x86_64.sh`
```
...and found out I first had to install the curl package (*cry-laugh* ), which I quickly did with

```bash
sudo apt install curl
```

I could then finally run the curl command above to get the Anaconda Navigator. What was displayed during the installation was this:

![[2024-04-03_VM_ubuntu_curl_get_anacondanav.png]]

The percentage reached 100 and I had a new command line available, so I knew it was installed. I checked, as per the rec of the Anaconda Navigator install page, whether the checksum is correct using `shasum -a 256 Anaconda3-2024.02-1-Linux-x86_64.sh` (curl always downloads in the working directory). This check returned the expected SHA-256 hash for this version, so I knew I was good to go actually using the installer. Used `bash Anaconda3-2024.02-1-Linux-x86_64.sh` to run the installer, and what I saw was:

![[2024-04-03_VM_ubuntu_install_anacondanav.png]]

I confirmed that I wanted to let conda configure my shell profile so that it can be automatically initialized by entering `yes`.
![[2024-04-03_VM_ubuntu_install_anacondanav_init.png]]

This seems to have worked. I closed and reopened my shell and checked if I can use the `conda` command to open the manager.

Success!
![[2024-04-03_VM_ubuntu_install_anacondanav_success.png]]


And now I finally had hope of being able to install the bcbio-nextgen package.

...but then I realized I still couldn't see the Anaconda Navigator as a GUI version at this point. I saved the state of my VM and restarted it...and quickly realized that this isn't a restore point like in Windows, but a genuinely frozen point in time with all open apps, so more like a hibernation in Windows. So I then truly restarted it from the VirtualBox menu.

I then researched and found that Anaconda Navigator does not show up as an app in the Ubuntu Apps, but can still be opened by running the following very simple command in the terminal:
`anaconda-navigator`

And yes, this opened the software! (after some warnings relating to GNOME and rescaling) I chose to update as recommended. However, I did not find the bcbio-nextgen package listed among the packages that could be installed, in spite of creating environments

I discovered that these issues may also be fixed if using mamba as a dependency solver instead of conda. I read the docs of how to install Mamba [here](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html). It seems I need to install Miniforge, which seems to be the most recent version, as opposed to using Mambaforge. I read that I must install Miniforge (Mamba) in the so-called base environment and that only it and conda, and no other packages whatsoever, may be installed in the base, because other packages could break both environment managers. 

I downloaded the Miniforge .sh binary and ran it in the terminal with `bash Miniforge3-Linux-x86_64.sh`.

It worked:

![[2024-04-03_VM_ubuntu_install_mamba_success.png]]

Followed installation instructions from the bcbio-nextgen page: https://bcbio-nextgen.readthedocs.io/en/latest/contents/installation.html#automated

First, installed Git from git-scm using `sudo apt-get install git`. Checked if I have tar installed by simply typing `tar` in my terminal, and yes, I do.

I then started the installation by calling python3 and, using it, the Py script that is supposed to install bcbio-nextgen. I used the options --nodata to do a minimal installation, without genomes etc, and --mamba to use mamba as a package manager. The command looked like:

```bash
python3 bcbio-nextgen-install.py /home/iweber/bcbio --tooldir=/home/iweber/bcbio/tools --nodata --mamba
```
I noticed it said it was installing mamba, and am not sure why - maybe because I am not installing bcbio within the mamba directory? But I thought that that amounts to installing in the base environment and is not recommended? Either way, the installation did not succeed. It also told me I was using a deprecated version of conda, so I updated it to the last version (24.3 at the time of writing this).

***LE: I think the Py installer script for bcbio-nextgen installs Miniconda and uses that to solve the environment/package dependencies, and that's why it pops up as deprecated, even though I just installed the most recent version of conda***

 ***Can I somehow force bcbio installer to use the properly installed anaconda3 instead of Miniconda as a solver? - maybe not a good idea. If installer calls for a particular version of conda, it may have a good reason in terms of package dependencies.***

After this, whenever I tried running the installation script again, it told me it cannot create the data directory required for the installation, a positional argument that needs to be given upon running the script. So I decided to run it with root privileges using

`sudo python3 bcbio-nextgen-install.py /bcbio-data --nodata --mamba`

in order to create a fully new data directory called bcbio-data, and, as before, to not download any genome data and to use mamba as an environment solver instead of conda. And now it seems like I'm stuck in the same solving environment step as has happened every time before when I tried it in the WSL:

![[2024-04-03_VM_ubuntu_bcbio-nextgen_stuck.png]]

I killed the process with `Ctrl+C`. I decided to create a separate conda environment called `bcbio-env` and, within it, to install one of the latest stable versions of Python to see if that helps matters. I had Python 3.10.12 and updated to 3.12.2.

Then, attempted the installation with root privileges in this environment with the same sudo command as before. Same problem with "`failed with intial frozen solve. Retrying with flexible solve.`" . 

After that, "`failed with repodata from current_repodata.json, will retry with next repodata source`"

Downgraded Python in my bcbio-env to python 3.9.0 and tried installing again with the sudo command. Also  "`failed with intial frozen solve. Retrying with flexible solve.`" . Killed process.

Upgraded Py to 3.12.2. Tried installing bcbio using pip3 ([pip is the Python package manager]). It said it worked, but, when calling `bcbio_nextgen.py --version`, it gave me an error message saying that the "six" package was not installed. I installed it manually with pip3 and tried calling the version of the package...and then got an error saying another package, toolz, was not installed. Did that as well, only to end up with another package error, this time for "yaml". However, when trying to install yaml via pip3, I got an error mesage that "no version could be found that satisfies requirements/no matching distribution found for yaml."

I ran `mamba clean -a` to remove all of these packages.

As the last strategy, I tried installing bcbio from bioconda as described on the [anaconda page](https://anaconda.org/bioconda/bcbio-nextgen):
`conda install bioconda::bcbio-nextgen`

And, suddenly, I could not only use `which bcbio-nextgen` to see where it is installed (/home/iweber/miniforge3/envs/bcbio-env/bin/bcbio_nextgen.py) but ***even got a version number*** when looking for it with `bcbio_nextgen.py --version`, namely version `1.2.9`...which, indeed, is the latest version. At this point, I could've cried of happiness. 

As life often goes, I realized only moments later that I can't actually download a new genome because the installation probably didn't create the correct folders for the data that bcbio-nextgen needs to run....

(Side note #2: another thing to remember is to start writing a logfile of everything I do in the terminal. For this, every time I start terminal, should run

`script logfile`

This automatically closes and creates that logfile when exiting terminal with Ctrl+D.

To get all packages currently installed in my conda environment:

`conda list --export > my_conda_packages.txt` [what was the point of this?]

I closed the VM at this point to come back to it another day...only to come back to not being able to open the Anaconda Navigator anymore from bash...

I added the path to the anaconda binaries folder to my PATH variable in the .profile file so that the bash knows to look here for executables as well, because I'd like to type less whenever I want to start the Anaconda Navigator: ` export PATH=$PATH:/home/iweber/anaconda3/bin`. This, however, did not solve the issue.

I went ahead and updated the installation with `bash Anaconda3-2024.02-1-Linux-x86_64.sh -u
and got yet another weird error message.

And...the same errors over and over again. I looked further into this pipeline and decided its maintenance is lagging too far behind, as, for many other bioinformatic projects, the main contributors have, in the meanwhile, moved on to other projects.

I have decided to, instead, use Nextflow and established NGS data analysis pipelines that work on it. 
### Fixing Win-Linux clipboard
In the meanwhile, I tried fixing my highly annoying copy-paste and drag-and-drop issues between my virtual machine and my Windows host. I first installed:

`sudo apt-install build-essential dkms linux-headers-generic`,

following [this answer](https://www.reddit.com/r/Ubuntu/comments/12knd2j/how_do_i_copy_and_paste_between_my_windows_host/) and the [page it refers to ](https://itsfoss.com/virtualbox-guest-additions-ubuntu/). I "mounted" the VA Guest Box addition disc image and ran the "autorun.sh" bash script it contains as a program (right click -> "Run as program"). After it asked for credentials, the terminal opened and I saw the expected screen. Restarted Ubuntu et voila! Copying and pasting now finally works. 

### Creating an inter-OS shared folder between Win and Linux

I had previously created a shared folder between my Windows host system and the Ubuntu virtual machine using the VM menu "Devices" -> "Shared folders" -> "Shared folders settings". Clicking the blue folder icon with a plus sign on it, I got such a window:
![[2024-05-06_VM_creating_shared_folder_win_ubu_success.png]]

The "Folder Path" field allowed me to select a folder in my host to use as the shared folder. For this purpose, I went to Windows and, on the partition of the SDD that I had allotted to the virtual machine, I created a folder called "Win_Ubuntu_shared". I could then access this from the VM menu displayed above, and selected to auto-mount it and make it permanent in order to have it automatically accessible whenever I run the VM. I also gave it a mount point name in order to find it more easily under Linux, and chose "/mnt-win-ubu-shared" for this name.

But I didn't see this folder in my Linux file explorer, not even after restarting the virtual machine. I followed the instructions given [here](https://askubuntu.com/questions/161759/how-to-access-a-shared-folder-in-virtualbox) and ran `sudo usermod -aG vboxsf $USER` in terminal, and then tried accessing folder via Other locations -> Computer, where I finally saw the "mnt-win-ubu-shared" folder (remember, this is the name I gave the folder when setting it up in the virtual machine in the VirtualBox menu "Devices"> "Shared folders"). ![[2024-05-06_VM_accessing_shared_folder_win_ubu.png]]


Got a message window asking me to also log in with my user credentials. ![[2024-05-06_VM_accessing_shared_folder_win_ubu_2.png]]

I did so, and I could finally see the contents of the shared folder! I immediately bookmarked this mnt-win-ubu-shared folder from the address bar of the explorer (three-dot menu) for easy access later.

![[2024-05-06_VM_accessing_shared_folder_win_ubu_success.png]]

I could now *finally* access the FastQ files I had previously generated on the WSL for further analyses!

## Making the inter-OS shared folder auto-mount without asking for my password every time
I had previously created a folder for the internship data that's shared between my Windows host OS and Linux , and I realized I wasn't using it as the sole folder for my data in Linux because, every time I wanted to access it, it asked me for my user password. That made me reluctant to use it especially in the context of an automated analysis pipeline, because I feared that Linux suddenly forgetting the password might interrupt the pipeline at inconvenient times, e.g. when I'm not at my laptop. Additionally, this complicated setting up a proper GitHub repo. So, to fix that, I asked ChatGPT.

I used `mount | grep mnt-win-ubu-shared` to check where the folder is located. It returned `Win_Ubuntu_shared on /mnt-win-ubu-shared type vboxsf (rw,nodev,relatime,iocharset=utf8,uid=0,gid=999,dmode=0770,fmode=0770,tag=VBoxAutomounter)`, so I now knew the address of my mounted folder.

I added my user to the permissions group for the virtual box folder (`vboxsf`) with `sudo usermod -aG vboxsf $USER`, then ran a `chown` command to change ownership of the folder:
`sudo chown -R $USER:vboxsf /mnt-win-ubu-shared/

Now, when checking the permissions, I saw:
![[2024-07-29_changing ownership of mounted folder.png]]

so I knew I now have read and write privileges for the directory for both myself and the virtual box group I am in. I copied and pasted some files into this folder from both Windows and Linux to make sure it works bidirectionally, as it should, and it does.

## Giving the inter-OS shared folder the correct permissions upon startup 

However, upon restarting the virtual machine, Ubuntu still asked me for my password (specifically, "Authentication is required to run gvfsd-admin daemon") when trying to open the inter-OS shared folder...ChatGPT said this is likely due to startup permissions not being set properly and suggested I edit a file called "fstab" with admin privileges and add the path to the inter-OS shared folder. "fstab" is a "file systems table" with information about files, folders, and mount points [other source to confirm?].  I added `Win_Ubuntu_shared /mnt-win-ubu-shared vboxsf uid=1000,gid=1000,dmode=0770,fmode=0770 0 0` at the end of the file. I tried it, restarted the system, and I still got asked for the password...

ChatGPT's next idea was to create a script that will be automatically run at system startup and will mount the inter-OS shared folder with the appropriate permissions from the get-go. I removed the line I previously added to the fstab file and proceeded to create the new startup file. I created the file directly with nano, `sudo nano /usr/local/bin/mount_shared_folder.sh`, and added to it 

```bash
#!/bin/bash
sudo mount -t vboxsf -o uid=1000,gid=1000,dmode=0770,fmode=0770 Win_Ubuntu_shared /mnt-win-ubu-shared
```

I made it executable with `sudo nano /etc/systemd/system/mount_shared_folder.service`, then created a service to run it at startup: `sudo nano /etc/systemd/system/mount_shared_folder.service`, with the contents 

```bash
[Unit]
Description=Mount VirtualBox Shared Folder
After=vboxadd.service
Requires=vboxadd.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mount_shared_folder.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
.
 Then, reloaded the Systemd and enabled the newly created service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable mount_shared_folder.service
```
, which returned 
```bash
Created symlink /etc/systemd/system/multi-user.target.wants/mount_shared_folder.service → /etc/systemd/system/mount_shared_folder.service.
```
And I restarted the service with `sudo systemctl start mount_shared_folder.service`, and then the virtual machine itself. And it still doesn't work without punching in my password. So I decided that, for the time being, if I only have to input the password once, at system startup, that's fine and unlikely enough to affect the pipeline that I'm willing to drop it and move onto something more productive.

I added aliases to my .bashrc file to more easily access the folder, if nothing else. I just pasted into it:
```bash
alias inter-OS='cd /mnt-win-ubu-shared'
alias inter-OS_data='cd /mnt-win-ubu-shared/Datasets/'
```

Additionally, I installed conda environment name autocompletion. I first tried installing the bash autocompletion just to be sure it works properly with `sudo apt-get install bash-completion
, but that ran into an error:
![[2024-07-29_bash_autocomplete_installation_error.png]]

The error seems to be related to the Nvidia and Cuda drivers...and I don't have the time to look further into this right now.

I simply proceeded with `conda install bash-completion` in the base environment. It seems to have completed error-free, and the autocompletion now works without errors.
## Updating installation for the SRA toolkit

I had initially worked on the WSL and created the VirtualBox virtual machine later, so of course the SRA toolkit was not working any longer. I created a dedicated conda environment for it called `ncbi_SRA`, and installed the package from Bioconda using `conda install sra-tools` and updated it with `conda update sra-tools`

# New environment, new life: creating dedicated bioinformatics environments using conda
Since I had all of the aforementioned issues with bcbio, I decided to abandon that approach, and, consequently, deleted the environment with conda, just to be on the safe side that I will have no issues later:

`conda env remove --name bcbio-env`

I then created a brand new, fresh environment called "NGS" in which to install the QC packages:
`conda env --create NGS`. Made a separate conda environment called "NGS" with `conda create --name NGS`

Using the shared folder between my Windows host and my Ubuntu virtual machine, I copied the FastQ  files I had previously generated with WSL into the virtual machine.

## Installing FastQC on my NGS conda environment within the Linux virtual machine
Perl and Java were already installed on my system (I suspect I installed them when installing conda and it creating its base environment), which is important because FastQC needs to run a small Perl script to find the binaries (executable files). The rest was as easy as 123: downloaded the archive, unzipped it, made the file called "fastqc" executable (chmod u+x) and ran it with ./fastqc.

Added path to the FastQC folder to my PATH environment variable so that I can now only type `fastqc` from any folder and Linux still finds the binaries of fastqc and can open it:

`sudo ln -s /home/iweber/Downloads/fastqc_v0.12.1/FastQC/fastqc /usr/local/bin/fastqc`

This worked! I can now call `fastqc` from the command line.

## Installing MultiQC on my NGS conda environment within the Linux virtual machine

Once more, this was extra simple from the command line:
``conda install bioconda::multiqc`` , after which I could call it from the command line.

After that, I wanted to see what options are available for multiqc, so I ran `multiqc --help`. I got quite a number of options:
![[2024-05-06_multiqc_help_options.png]]
![[2024-05-06_multiqc_help_options_2.png]]
![[2024-05-06_multiqc_help_options_3.png]]



# Creating a GitHub repository for the project

 In order to be able to more easily version my work on the project and to allow my internship supervisor to gain insight into what I was doing, I created a GitHub repo for the newly minted "official project folder" (the inter-OS shared folder I created before). Naturally, I should have started a repository much longer ago, but, as the saying goes, "The best time to plant a tree was 20 years ago. The next-best time is now". I started working on this project while my bioinformatics course was still ongoing and we hadn't talked about git yet - now's that next-best time to catch up on this.
## Making the repo under Linux

I first created an empty repo on GitHub and also a fine-grained access token for myself, giving myself all of the privileges necessary for using the repo. Then, from Ubuntu, I initialized a new git repo in the inter-OS shared folder with `git init` and pointed its head to the main branch:
`git symbolic-ref HEAD refs/heads/main`. 

I added the online repo with
`git remote add origin https://github.com/i-weber/Internship_project_RNAseq`.

I added all of the files in the folder to the current staging area with `git add .`, and that might have been a mistake, given that the FastQ files are pretty large in their uncompressed state - the whole folder is around 170 GB *insert clenched teeth smiley*. On the side, I then read one can use the `top` command _**in a new terminal window**_ to check resource usage in Linux, similar to Windows's task manager, and I saw that Git is using 70-80% of all resources of the virtual machine, so I gave it time. Next time, I will use  `git add . --verbose` to get a better feel of the progress it is making through the files and folders. Also, can use `iostat -x 1` to investigate disk usage (install beforehand with `sudo apt-get install sysstat`) or `htop`, which apparently is `top` on steroids (also needs prior installation with `sudo apt-get install htop`).

So far, clocking at half an hour run time for the `add` command...let's see how long it takes in total.

At the one hour mark, I decided it was time to stop messing around, so I killed the process and proceeded to add the FastQ files and genomic files to the .gitignore. I created it with nano and added to it:

```         
Adapters/
Genomes/
Nextflow/
Software/
Datasets/sra
Datasets/Pre_eclampsia_mice/Pre_eclampsia_mice_fastq/
```

to avoid some of the largest and recoverable files from the push and commit.

> [!For the future:]
> Note to self: add them without the slashes, I think git was looking for  "empty" name items in these folders and not finding them, without selecting everything *inside* of the folders.

I then tried to push the .gitignore only, and, after completing the command line sign in, immediately got an error because I had previously set GitHub to block commits that might publicize my email address. So I found out that, in order to avoid this issue, I can use a no-reply address that GitHub itself creates for all of its users as my default email. I ran `git config --global user.email "163516184+i-weber@users.noreply.github.com"` to do so, and deactivated the checkbox in my GitHub email setttings that supposedly protects one from publicizing their email in the commit metadata (I now know that this no-reply address will be used). And I could finally push the .gitignore file and see it on the website!

I then proceeded to add all other files with `git add . --verbose` at 16.48. It crashed around 17.05 because - and I should've thought of this! - I deleted a file from the folder at some point ***facepalm***. One more thing learned...and restarted the same command at 17.06. Annnd it worked!

I proceeded to commit the changes with `git commit -m "All files up to date"`, which returned

```bash
[main 3a13867] All files up to date
 131 files changed, 98102 insertions(+), 1 deletion(-)
```

It failed, with an error message saying: "Enumerating objects: 129, done. Counting objects: 100% (129/129), done. Delta compression using up to 6 threads Compressing objects: 100% (123/123), done. error: unable to rewind rpc post data - try increasing http.postBuffer error: unable to rewind rpc post data - try increasing http.postBuffer error: RPC failed; HTTP 400 curl 92 Recv failure: Connection reset by peer send-pack: unexpected disconnect while reading sideband packet Writing objects: 100% (127/127), 2.04 GiB | 2.85 MiB/s, done. Total 127 (delta 18), reused 1 (delta 0), pack-reused 0 (from 0) fatal: the remote end hung up unexpectedly Everything up-to-date"

I set the postBuffer to 200 MB using `git config --global http.postBuffer 209715200` , and re-started the commit command at 23:20. 

Aaand...it failed again. The message read just as above (I think - I lost the clipboard because I shut the virtual machine off too soon, apparently...).

My next approach was to try the Git Large File System extension (https://git-lfs.com). I used the command
``
```bash
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh sudo bash
```

to install the package, as directed by the website that git-lfs directed me towards, https://packagecloud.io/github/git-lfs/install. That didn't cut it, and neither did trying to install git by using `git lfs install`, as I suspect that will only work once lfs is actually on the system (it gives an error saying it doesn't recognize the command). So I downloaded the tar archive, changed the directory to the Downloads folder, and extracted it with tar (v = verbose, x = extract - otherwise, tar tries creating an archive, z = indicate that archive is in gzip format, f = name to use for the extracted file or folder)

	`tar -vxzf git-lfs-linux-amd64-v3.5.1.tar.gz`

I then navigated to the decompressed folder, made the install.sh script file inside of the folder executable with `chmod u+x install.sh`, then navigated to my inter-OS folder and ran the install.sh with sudo permissions (it told me I could not install it where I had downloaded it, the regular Downloads folder of Ubuntu, hence my choice to change to my folder). I tried now to use `git lfs install` and got the same message as before, `Updated Git hooks. Git LFS initialized.` It is now ready to use...but, in the end, does not seem so useful for my plans. I don't have individual files at the moment that are extremely large - I simply have folders with lots of relatively small files in them.

To see which files git is currently tracking, I used ` git ls-files`, `git ls-tree -d HEAD` (directories only) and `git ls-tree -r HEAD` (directories and files contained therein) to make sure I am now really only tracking the files that I want to track, and not the FastQ files or genome files.

![[2024-07-30_git_currently_tracked_dirs_files.png]]
It looks like I am indeed now avoiding the really large files. I added again everything with `git add .`, then checked the status. It said it has nothing to commit, confirmed when I still tried to commit with `git commit -m "Add remaining changes"` so I went on to push the changes with `git push origin main`. The runtime started at 13:30, this time the "Writing objects" buffer went up to 10%, as opposed to the 7% it used to go up to yesterday. But it crashed again, with the error

"Writing objects: 100% (140/140), 2.04 GiB | 1.08 MiB/s, done.
Total 140 (delta 26), reused 1 (delta 0), pack-reused 0
fatal: the remote end hung up unexpectedly
Everything up-to-date",

so I think I need to reduce the buffer size again. Did it with `git config --global http.postBuffer 157286400`, let's see if this is of any help...nope.

I went through all of the files and removed anything that is not absolutely critical. I then reset the git staging area, and also removed any of the cached versions of any files with `git rm -r --cached .` Then, I used `find . -type f` to find all files that could be added at that moment. I checked the sizes - nothing is above 100 MB at the moment, not even folders.

Tried again to add and push in small batches, e.g., in the Presentations folder, only some of the PNG images. It stopped at 96% in the writing process and would not progress. I increased the http buffer with `git config --global http.postBuffer 524288000` to 500 MB, but it then got stuck at 76% in the writing process.

This is when I gave up and decided to do a fresh start. I deleted the .git folder, everything in the online version of the repository, and all of the data inside the inter-OS shared folder, since I had it backed up in a different location anyway. I re-initialized a git repo inside of the same folder, added the remote repo I had previously created and which was basically empty at this point, and then started adding the files and folders piecemeal back into the inter-OS shared folder, adding them to the staging area, committing, and pushing after each smaller batch of files. Worked like a charm, took maybe 15 min and solved all of my problems. Presentations folder, at 33 MB, took from 21:36 to 21:37 - nothing like the full hour it took in the previous days and earlier today!

## Getting the repo to work under Windows as well

Since I later want to take the data that the analysis pipeline generates and work with it under Windows, where I have R fully set up and ready to rumble, I want to have access to the repo from this OS as well. Additionally, I read that Visual Studio Code allows for a very nice integration with GitHub, including an extension that shows when commits were made and how different branches of a project relate to one another (Git Graph). So I opened the repo in Visual Studio Code, installed the extension, and now can open it with Ctrl+Shift+P --> Git Graph: View Git Graph from the dropdown menu. Now I can very easily track the changes to the repo visually, and also have access to the repo from the Windows side - if I select the folder where the repo is in the Explorer part of VSC, I can perform all of the usual git commands from the terminal.

## Trying to use Git LFS to track FastQ and other large files

As I want to track changes to my FastQ files as well once I start trimming them and processing them, but also to other large files, such as bam files, that I will generate further in the process, I set up Git LFS to track such files.

I had previously installed git LFS on my VM, and I now went to my inter-OS folder and hit `git lfs install` to initialize it (yes, the naming is somewhat confusing). 

I then proceeded to track .fastq files by using `git lfs track "*.fastq"` and it returned `Tracking "*.fastq"`.  I checked which files are now tracked by git LFS using `git lfs ls-files`, and it returned...nothing xD.

![[2024-08-01_git_lfs_not_tracking_yet.png]]

I checked whether the .gitattributes file was correctly created, and it seems so - it is present in my repo and contains `*.fastq filter=lfs diff=lfs merge=lfs -text`, as it should.

I pasted my FastQ files into a raw data folder (Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/), together with the FastQC and MultiQC files that resulted from their analysis. I then created a .gitignore file to, for now, ignore the FastQs but still be able to stage, commit and push the new directory structure. After doing the usual git steps, I had an updated online repo including the FastQC and MultiQC files, but not the .fastq ones.

I removed the .fastq rule from the .gitignore file. When hitting `git status` now, the only files left unchanged were indeed the newly added FastQ ones.

I ran the `git lfs track "*.fastq"` command again, and got a message saying `"*.fastq" already supported`.

I next added the first FastQ file to the staging area, SRR13761520_1.fastq. I started at 12.07, and it took around 5 min to finish. It also took a moment to commit, but, when I tried pushing it to the repo, it failed, saying 

```bash
[f12181f07712304b1aed2f1876165f549942ad8144457878ca37fbe90356a731] Size must be less than or equal to 2147483648: [422] Size must be less than or equal to 2147483648
error: failed to push some refs to 'https://github.com/i-weber/Internship_project_RNAseq'
```
It sounds to me like git LFS is still not managing the FastQ files as it should. In the previous step, Git tried to push a file larger than 270 MB to the repo, which is clearly not what it should be doing, if git LFS were working. 

> [!What's happening here? There's some logical connection missing.]
> The solution may involve using [`git lfs migrate`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-migrate.adoc?utm_source=gitlfs_site&utm_medium=doc_man_migrate_link&utm_campaign=gitlfs) to force the objects that are now managed by git to be managed by git LFS instead. I used `git lfs ls-files --all` to understand if git lfs was already tracking anything

2:17 git status
2:19: It looks like the file that now appears to already be tracked by git lfs does not appear any longer under "untracked files".


Tried adding the pair of this FastQ file (the one ending in `_2`) to the staging area and committing. then running `git lfs ls-files --all` to see if git LFS takes over this file after the commit.

![[2024-08-01_git_lfs_success.png]]
And success! The files now don't show up in the regular git tracked files, but do show up as managed by git LFS! 

So, what have I learned? Git LFS needs a definition of what kinds of files to look for (the pattern specified in the .gitattributes file). It then keeps a lookout for them, and, when such files are added to the staging area, it picks up on them and creates so-called pointers (pointer files) to these files and the changes in them, which are recorded in the repository instead of the files themselves. A bit like a group of elite dogs getting a sniff at a fabric scrap from persons they should track, then alerting when those persons are nearby, staying with their snouts pointed towards them.

However, they still will not be pushed online. So, even with git LFS, the problem seems to be on the side of GitHub. 
![[2024-08-01_git_lfs_size_fail.png]]
ChatGPT says that GitHub has a maximal limit of 2 GB even for files managed by git LFS, and this seems to fit the number the push command returns (2147483648 bytes is 2.14 GB).

So I guess I have to add these files to .gitignore and be done with them...

I added `*.fastq` to my .gitignore file, then used `git rm --cached *.fastq` to remove any previously tracked fastq files. That took a few minutes in which git-lfs was using a hefty portion of my CPU (77%). It seems to have worked:

![[2024-08-01_git_rm_fastq_success.png]]

I checked the git status, just in case:
![[2024-08-01_git_status_after_rm.png]]

It looks like the next commit should delete these files from my staging area, without touching the files per se in my computer. Tried it out, and, indeed, I could still see my files in my file system using the file explorer and `ls -lat`.

I also removed `*.fastq` files from the git LFS tracking using `git lfs untrack "*.fastq"`. Got a message in return saying `Untracking "*.fastq"`, and saw that the .gitattributes file is now also empty again. 

> [!Important to know for the future:]
> 
> Apparently, [trying to push files from Windows to GitHub that are larger than 4 GB truncates them and causes them getting corrupted](https://github.com/git-lfs/git-lfs/issues/2434#issuecomment-436341992)!

# What is Nextflow?
![[2024-08-14_nextflow_general_principle.png]] from the [Nextflow training page](https://training.nextflow.io/basic_training/intro/#execution-abstraction)

a [domain-specific programming language,](https://en.wikipedia.org/wiki/Domain-specific_language) as opposed to C++, Python, etc, which are general-purpose programming languages

https://github.com/chlazaris/Nextflow_training/blob/main/nextflow_cheatsheet.md
https://github.com/danrlu/Nextflow_cheatsheet/blob/main/nextflow_cheatsheet.pdf

# Setting up Nextflow to run bioinformatic analysis pipelines
## Installing Nextflow and nf-core
First, installed Java:
```bash
	sudo apt install default-jre
```
I created a dedicated environment in which i will work with Nextflow, that I called as such, using 
```bash
conda create Nextflow
```

After activating it, I installed the actual Nextflow workflow manager with
`conda install -c bioconda nextflow`, and it worked like a charm. Then, to get access to the curated Nextflow pipelines for bioinformatic analyses, I installed nf-core in the same environment with `conda install nf-core`, which also completed without any overt errors.

I also activated shell completions for nf-core by adding the [recommended](https://nf-co.re/docs/nf-core-tools/installation#activate-shell-completions-for-nf-coretools) command to my .bashrc file:
```bash
eval "$(_NF_CORE_COMPLETE=bash_source nf-core)"
```
and restarted my shell.

And now I could easily list all of the curated pipelines available in nf-core:
![[2024-07-27_nf-core_list.png]]

The pipeline I am interested in is called `rnasplice` , and we'll get back to that in a moment.

## Containerization with Docker for nf-core/Nextflow?

What caught my eye when reading more about nf-core was the following:
![[2024-07-27_nf-core_containerization.png]]
![[2024-07-27_nf-core_containerization2.png]]

I started working with conda because everyone in the bioinformatic community swears by it, and so did the economics researchers that I had my very first Python course with. It has served me very well so far, but I do also know [quote Adi Dilita] that software developers prefer to work with Docker, Singularity, or Kubernetes to create containers so that their software can always be run, that is, at any time, on any machine. I read more about how Docker, Conda, and Nextflow relate to one another and found out that conda is used so widely in the bioinformatic/scientific community because it integrates seamlessly with Python and R and is a more lightweight solution for reproducibility. This is due to the fact that it manages only the dependencies specifically required by these programming languages. However, Docker containers also incorporate information about the OS and all of the apps and packages installed on it that are required to run a specific program/application. In essence, Docker containers mirror the environment that the developer of a particular software worked in in order to program that software/app etc _and_ isolate this mirror image within another user's OS. This increases the degree of reproducibility dramatically BUT is also more bulky, because a Docker container then stores all of this extra information related to the OS.

Since I want to try out Docker AND because it might be the less buggy option here, I decided to install it on my Linux virtual machine.

As per the instructions on the website, I first ran 

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```
 to install the required packages....and it doesn't work. What I get is:

```bash
Get:1 file:/var/cuda-repo-ubuntu2004-11-7-local  InRelease [1.575 B]
Get:1 file:/var/cuda-repo-ubuntu2004-11-7-local  InRelease [1.575 B]
Hit:2 http://de.archive.ubuntu.com/ubuntu jammy InRelease                                               
Hit:3 https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/ InRelease                              
Get:4 http://de.archive.ubuntu.com/ubuntu jammy-updates InRelease [128 kB]                              
Hit:5 https://packages.microsoft.com/repos/code stable InRelease                                        
Hit:6 http://de.archive.ubuntu.com/ubuntu jammy-backports InRelease                                     
Hit:7 https://ppa.launchpadcontent.net/c2d4u.team/c2d4u4.0+/ubuntu jammy InRelease                      
Get:8 http://security.ubuntu.com/ubuntu jammy-security InRelease [129 kB]                   
Hit:9 https://packagecloud.io/github/git-lfs/ubuntu jammy InRelease             
Fetched 257 kB in 2s (139 kB/s)
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
ca-certificates is already the newest version (20230311ubuntu0.22.04.1).
ca-certificates set to manually installed.
curl is already the newest version (7.81.0-1ubuntu1.16).
The following packages were automatically installed and are no longer required:
  libwpe-1.0-1 libwpebackend-fdo-1.0-1
Use 'sudo apt autoremove' to remove them.
0 upgraded, 0 newly installed, 0 to remove and 11 not upgraded.
8 not fully installed or removed.
After this operation, 0 B of additional disk space will be used.
Do you want to continue? [Y/n] y
Setting up nvidia-dkms-515 (515.65.01-0ubuntu1) ...
update-initramfs: deferring update (trigger activated)

A modprobe blacklist file has been created at /etc/modprobe.d to prevent Nouveau
from loading. This can be reverted by deleting the following file:
/etc/modprobe.d/nvidia-graphics-drivers.conf

A new initrd image has also been created. To revert, please regenerate your
initrd by running the following command after deleting the modprobe.d file:
`/usr/sbin/initramfs -u`

*****************************************************************************
*** Reboot your computer and verify that the NVIDIA graphics driver can   ***
*** be loaded.                                                            ***
*****************************************************************************

INFO:Enable nvidia
DEBUG:Parsing /usr/share/ubuntu-drivers-common/quirks/lenovo_thinkpad
DEBUG:Parsing /usr/share/ubuntu-drivers-common/quirks/put_your_quirks_here
DEBUG:Parsing /usr/share/ubuntu-drivers-common/quirks/dell_latitude
Removing old nvidia-515.65.01 DKMS files...
Deleting module nvidia-515.65.01 completely from the DKMS tree.
Loading new nvidia-515.65.01 DKMS files...
Building for 6.5.0-44-generic
Building for architecture x86_64
Building initial module for 6.5.0-44-generic
ERROR: Cannot create report: [Errno 17] File exists: '/var/crash/nvidia-dkms-515.0.crash'
Error! Bad return status for module build on kernel: 6.5.0-44-generic (x86_64)
Consult /var/lib/dkms/nvidia/515.65.01/build/make.log for more information.
dpkg: error processing package nvidia-dkms-515 (--configure):
 installed nvidia-dkms-515 package post-installation script subprocess returned error exit status 10
dpkg: dependency problems prevent configuration of cuda-drivers-515:
 cuda-drivers-515 depends on nvidia-dkms-515 (>= 515.65.01); however:
  Package nvidia-dkms-515 is not configured yet.

dpkg: error processing package cuda-drivers-515 (--configure):
 dependency problems - leaving unconfigured
dpkg: dependency problems prevent configuration of cuda-drivers:
 cuda-drivers depends on cuda-drivers-515 (= 515.65.01-1); however:
  Package cuda-drivers-515 is not configured yet.

dpkg: error processing package cuda-drivers (--configure):
 dependency problems - leaving unconfigured
dpkg: dependency problems prevent configuration of nvidia-driver-515:
 nvidia-driver-515 depends on nvidia-dkms-515 (= 515.65.01-0ubuntu1); however:
  Package nvidia-dkms-515 is not configured yet.

dpkg: error processing package nvidia-driver-515 (--configure):
 dependency problems - leaving unconfigured
dpkg: dependency problems prevent configuration of cuda-runtime-11-7:
 cuda-runtime-11-7 depends on cuda-drivers (>No apport report written because the error message indicates its a followup error from a previous failure.
                                              No apport report written because the error message indicates its a followup error from a previous failure.
                                               No apport report written because MaxReports is reached already
    No apport report written because MaxReports is reached already
                                                                  No apport report written because MaxReports is reached already
                       No apport report written because MaxReports is reached already
                                                                                     No apport report written because MaxReports is reached already
                                          = 515.65.01); however:
  Package cuda-drivers is not configured yet.

dpkg: error processing package cuda-runtime-11-7 (--configure):
 dependency problems - leaving unconfigured
dpkg: dependency problems prevent configuration of cuda-demo-suite-11-7:
 cuda-demo-suite-11-7 depends on cuda-runtime-11-7; however:
  Package cuda-runtime-11-7 is not configured yet.

dpkg: error processing package cuda-demo-suite-11-7 (--configure):
 dependency problems - leaving unconfigured
dpkg: dependency problems prevent configuration of cuda-11-7:
 cuda-11-7 depends on cuda-runtime-11-7 (>= 11.7.1); however:
  Package cuda-runtime-11-7 is not configured yet.
 cuda-11-7 depends on cuda-demo-suite-11-7 (>= 11.7.91); however:
  Package cuda-demo-suite-11-7 is not configured yet.

dpkg: error processing package cuda-11-7 (--configure):
 dependency problems - leaving unconfigured
dpkg: dependency problems prevent configuration of cuda:
 cuda depends on cuda-11-7 (>= 11.7.1); however:
  Package cuda-11-7 is not configured yet.

dpkg: error processing package cuda (--configure):
 dependency problems - leaving unconfigured
Processing triggers for initramfs-tools (0.140ubuntu13.4) ...
update-initramfs: Generating /boot/initrd.img-6.5.0-44-generic
Errors were encountered while processing:
 nvidia-dkms-515
 cuda-drivers-515
 cuda-drivers
 nvidia-driver-515
 cuda-runtime-11-7
 cuda-demo-suite-11-7
 cuda-11-7
 cuda
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

I went online to try and find what all of these issues with Nvidia and Cuda are about, and, sure enough, I found an [Nvidia page](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html) about it.

I went through the preliminary checks. Yes, I have an OS version that's supported, yes, I have a GPU that supports Cuda. I also have gcc installed and `uname -r` returned "6.5.0-44-generic".

I tried finding this mlnx_ofed driver to install, but it was not available anywhere on the NVIDIA pages. I downloaded the dedicated Linux 64-bit driver for my graphics card (RTX A4000) from the NVIDIA website (it's a bash script) and ran it with sudo, but I got an error saying
![[2024-07-31_nvidia_driver_installation_fail.png]]

Upon further reading, I saw that Ubuntu is a bit peculiar in the way in which it uses NVIDIA drivers and that, for some stability reasons, it has its own driver, based on the current driver's predecessor (number 535 instead of 550). But, after hitting OK on this error message, I got another one saying:

![[2024-07-31_nvidia_driver_installation_fail2.png]]

I hit "abort installation" and peeked at whether version 515 is indeed the one installed on my system using `ubuntu-drivers list`. Annnnd all I got was![[2024-07-31_nvidia_driver_installation_check.png]]

As far as I understand, the driver list is different from what a normal, non-virtual OS would have.


I tried upgrading the driver by running `sudo apt-get install nvidia-driver-515` ....annnnd got the exact same big stream of errors as above, which suggest rebooting computer and making sure NVIDIA graphics driver can be loaded. This seems to be a general issue with trying to run Cuda on a virtual machine, as, as far as my meagre understanding takes me, the virtual machine does not have direct access to the GPU through the host, especially not on VirtualBox virtual machines (apparently, VMWare is somewhat better, but that's not what I have).

I'm considering trying Singularity instead. Singularity is the containerization app often used on high-performance computing clusters (HPCs), and it makes things a little bit easier because it also does not require root access privileges. 

...apparently, Singularity has changed names and is now called Apptainer. I started following the [installation instructions ](https://github.com/apptainer/apptainer/blob/main/INSTALL.md) , and already the very first step for a setuid installation, `sudo apt install -y software-properties-common` immediately threw the same sequence of errors about NVIDIA and Cuda as above. So I decided the time has come to see if I can clean that up.

Before doing so, I backed up all of my conda environments into my GitHub repository. I created a new folder "Conda_environment_yamls", and pushed that to GitHub

I also created a snapshot of my virtual machine in its current state using VirtualBox, and saved my .vbox file in a safe location. Additionally, I saved the entire virtual machine folder in another location, and exported my virtual machine as an OVF/OVA file (in VirtualBox, File --> Export Appliance). Finally, I made a full clone of my virtual machine to test changing the drivers in, so that I can always just remove it and go back to my unchanged version, should major problems arise (did that also from VirtualBox from the machine options).

It seems like I got myself into another technical rabbithole here: apparently, the root of the problems is that VirtualBox cannot take the GPU available to my Windows host and pass it through to my virtual machine. This might just be what is causing all of the issues: given the errors the Docker installation throws, it probably needs to access the GPU itself, because it helps it speed up computation quite a lot (inasmuch as my NVIDIA RTX A4000 can do that - it's a good GPU,  not the top of the tops, but surely better than the virtualized version that VirtualBox creates). And because the Docker containers are so resource-intensive, this is likely why it won't work without it.

I can likely transfer my virtual machine from VirtualBox to another virtual machine software, VMware, but that will likely require some more tweaking as well. For the time being, I will try running the pipeline as is in Nextflow under Conda, and then see about anything else.

## Transferring entirety of virtual machine to VMware

I took a snapshot of my current VM (2024-08-01) using VirtualBox, and, in the same program, hit "Export appliance" for this very same machine from the File menu. Started around 18:40, reading about the pipeline in parallel. It's mightily slow - at 19.05, so 25 min later, it was at barely 2%, meaning this will probably take until Saturday...
18:40 - start
19:05 - 2 %    --> 1%/12.5 min
19:42 - 4 % --> 1%/18.5 min
21:00 - 7 % --> 3%/1h15, eq to 1%/25 min
...somehow, it seems to be slowing down quite a lot. Maybe because I opened more apps. Should be faster over night, when I'm not actively working on the laptop. 
21:42 - 10% --> 7%/42 min, eq to 1%/6 min

90% more to go. At best, this should take 6x90 min = 9 h. At worst, 25x90 min = 37.5 h ***insert clenched teeth smiley here*** Of course, I closed any app that might be eating any of my laptop's memory/processing power, but the virtual machine was only using 16-30% of my CPU to begin with, so maybe that's not the issue here. Maybe, as with many other things, VirtualBox is rather inefficient in its resource utilization...

At around 2 AM, it had finally finished creating the OVF file (the file format of the so-called virtual machine appliance I just created, which is an [universal format]([How To Convert Virtual Machines Between VirtualBox and VMware (howtogeek.com)](https://www.howtogeek.com/125640/how-to-convert-virtual-machines-between-virtualbox-and-vmware/)) and can be shared between different VM software).

After many loopholes, I finally downloaded VMware Workstation Pro, which, to my joy, is now available for free for personal use since May of this year.

During the installation of VMware Workstation Pro, I got a message saying 
![[2024-08-02_vmware_installation_hyper-v.png]]

I researched this further and found that, in my Windows Features, Hyper-V was actually switched off. However, since I had previously used WSL, I suspect this is not entirely true. I went on to fully switch it off in an elevated command prompt using

```windows
bcdedit /set hypervisorlaunchtype off
```

Seconds later, I realized it was stupid to not make a Windows restore point right before that, and I tried reverting the command using "on" instead of "off", but it just gave me an error message saying "The integer data is not valid as specified.  Run "bcdedit /?" for command line assistance. The parameter is incorrect.". I asked ChatGPT and found I was supposed to run
```Windows
bcdedit /set hypervisorlaunchtype auto
```

which, indeed, completed successfully. I swiftly created another restore point. Additionally, I updated my bootable Windows USB drive, which I had created some time back, to be able to easily boot the system in case I suddenly get a BSOD (this happened to me some years back, on the second day of owning this laptop, when I wanted to set up VirtualBox...better safe than sorry).

I also downloaded the VMware OVF Tool to make sure that the OVF I previously generated with VirtualBox is compatible with VMware Workstation Pro. I added its installation directory to my PATH variable under Windows, and could then access it from my command line in PowerShell.

I tried converting the old virtual machine OVA file to a VMware-compatible type using " ovftool ubuntu22x64.ova E:\VMware_ubuntu_VM " (into a new directory I created for the purpose), but got an error: "Opening OVA source: ubuntu22x64.ova Opening VMX target: E:\VMware_ubuntu_VM Error: OVF Package is not supported by target: - Line 25: Unsupported hardware family 'virtualbox-2.2'. Completed with errors " 

To convert this hardware family to one that's compatible with VMware Workstation Pro, ChatGPT suggested unpacking the OVA archive and directly editing the OVF file that contains the info. While 7zip was doing the unpacking, I did a [bit more reading online on the topic](How To Convert Virtual Machines Between VirtualBox and VMware (howtogeek.com)](https://www.howtogeek.com/125640/how-to-convert-virtual-machines-between-virtualbox-and-vmware/)). Because this website says it should be possible to open the VM as is in VMware, once it is installed, so I decided to postpone modifying anything in the OVF until I shut off Hyper-V for good with bcdedit, restart my PC, and attempt to install VMware.

7zip kept showing "Unexpected end of data" all the way through.

And then I restarted my PC. And got no BSOD, yay! *insert party smiley*

I re-ran the installer for VMware Workstation Pro, and didn't get that error relating to Hyper-V, which means it's now finally switched off and I don't need to worry any longer. I chose to skip adding the optional "Enhanced Keyboard Driver", as I did not find any overtly important reason to do so. The installation completed successfully and I could now finally open the software ***!yay!***

I followed the instructions from How To Geek to import the VM from VirtualBox into VMware. I got the error the website predicted:

![[2024-08-02_vmware_importing_vm_error.png]]

I hit "Retry" as instructed, which, as it says, makes the importing criteria less strict, and the actual import began. Annnnnnnd it worked!

![[2024-08-02_vmware_importing_success.png]]


I started the machine and *even conda was still working as expected in the terminal*. What was left to do was to install the VMware Guest Additions from the Linux ISO. For this, with the VM powered off, I went to its settings and added a CD/DVD, which I pointed to the VMware Linux ISO that should contain the additional tools for this Ubuntu virtual machine. The behavior was rather strange after that:

```bash
(base) iweber@iweber-VirtualBox:~$ vmware-toolbox-cmd -v
12.3.5.46049 (build-22544099)
(base) iweber@iweber-VirtualBox:~$ sudo vmware-uninstall-tools.pl
sudo: vmware-uninstall-tools.pl: command not found
(base) iweber@iweber-VirtualBox:~$ sudo mount /dev/cdrom /mnt
mount: /mnt: WARNING: source write-protected, mounted read-only.
```

Maybe I have a broken installation of the Toolbox, because the option to reinstall it is greyed out in the VM menu, and, while some part of it is installed, returning me some version number, somehow, the uninstallation command isn't. So I tried to remove the Toolbox in its entirety from the system, running these commands one by one:

```bash
sudo rm -rf /usr/lib/vmware-tools # completed with no errors
sudo rm -rf /etc/vmware-tools # completed with no errors
sudo rm -rf /usr/lib/vmware-tools/modules # same
sudo rm -rf /usr/bin/vmware* # same
```

I then re-mounted the ISO image with
```bash
sudo mount /dev/cdrom /mnt
```
, which told me that it's already mounted.

Then, I used tar to extract the archive from the ISO:

```bash
tar -zxvf /mnt/VMwareTools-*.tar.gz -C /tmp
```
, which generated an onslaught of files, but completed fine and gave me a new command prompt.

I changed to the extracted archive directory, made the installation script executable, and ran it. It didn't work, and I realized, based on the messages, that the problem was that the toolbox of VirtualBox was still present on the system:
![[2024-08-02_vmware_toolbox_issue.png]]

!!! I started this kernel driver installer, but I soon realized this was nonsense, and aborted it. I re-ran the rm operations above to purge any existing installed pieces of VMware Toolbox. Then, I proceeded to remove the open-vm-tools installation:

```bash
sudo apt-get remove --purge open-vm-tools
sudo apt-get autoremove
```

Or...at least I thought I would be doing so. Instead, I got that very same nice error message regarding Nvidia and Cuda that I struggled with on VirtualBox. I tried:

```bash
sudo dpkg --purge open-vm-tools
```

and at least this one seems to have worked (I got an active command prompt after this):
![[2024-08-02_vmware_toolbox_issue_removing_open-vm-tools.png]]

I ran a few more commands ChatGPT suggested to completely purge any pieces left from either Toolbox or open-vm-tools:
![[2024-08-02_vmware_toolbox_issue_removing_open-vm-tools_purging.png]]
It seems no piece were left anyway - the system said it failed to find the things that I was trying to delete. Also, my shared clipboard between my Windows host and my VM stopped working, as was to be expected.

I attempted to reinstall VMware tools, when I got an interesting message:
![[2024-08-02_vmware_toolbox_issue_reinstall_attempt_vmware_tools.png]]

I am postponing decisionmaking about this to tomorrow, I'll have to do a bit more research to confirm. This is the website it is sending me to:  https://knowledge.broadcom.com/external/article?legacyId=2073803 and it is last updated in February of this year, so seems fairly recent...

After some further research, I see that VMware indeed recommends open vm tools as the open source implementation of... VMware tools. They also recommend installing it as per the instructions of the OS producer.

After reading [this](https://linuxcapable.com/how-to-install-open-vm-tools-on-ubuntu-linux/) , I chose to go with the desktop version of open-vm-tools, as that offers extended capability for GUI-based systems, whereas, apparently, the simple open-vm-tools package is meant for bare-bones Linux servers.

I first checked what packages need updating before that with `sudo apt update` and listed the packages with `sudo apt list --upgradable`. I got this list, and decided to take a snapshot of the system before the update, just in case something destabilizes it: 

![[2024-08-05_installing_updates_after_snapshot.png]]

I hit ` sudo apt upgrade` to upgrade all of the packages listed above, and ran into the same issue with the NVIDIA and Cuda drivers not working. And when I tried the actual command to install open-vm-tools,

```bash
sudo apt install open-vm-tools-desktop
```

it happened again...

I had a look in the VMware graphics settings and found that I could change some options regarding 3d acceleration, which I know Nvidia is in charge of, so I switched that on. This is how the updated settings look like:
![[2024-08-05_VMware_modified_display_settings.png]]

After this, I tried switching the machine back on to see if this maybe allows the use of Nvidia and Cuda and lets me install open-vm-ware....nope. Process failed with same problem. 

Then, I also saw I have direct virtualization options under "Processors" in the virtual machine's settings. I changed those as follows:

![[2024-08-05_VMware_modified_virtualization_settings.png]]

Now, when peeking at the Windows task manager, I can actually see Vmware using the GPU!

But I still can't install anything, not even Ubuntu's very own tool , without the same error about nvidia and cuda popping up again.

I ran
```bash
sudo apt-get remove --purge '^nvidia-.*'
sudo apt-get remove --purge '^cuda-.*'
sudo apt-get remove --purge '^libcuda-.*'
sudo apt-get remove --purge '^libnvidia-.*'
sudo apt-get autoremove --purge
sudo apt-get clean
```
to clear any installation I might have left on the system for any nvidia and cuda-related packages, and start afresh. Confirmed no more packages left  with `lsmod | grep nvidia`, which didn't return anything, and then added the graphics drivers repository to my system with  

```bash
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-get update
```

I then went to [Ubuntu's official Nvidia driver page](https://ubuntu.com/server/docs/nvidia-drivers-installation) to see how they recommend installing these drivers from the command line interface (CLI)...no help there. All i got when checking for the recommended drivers for my machine with `sudo ubuntu-drivers install` is...drumroll...open-vm-tools *laugh-cry*

I suspect this won't do much, but, in sheer despair, I tried forcing the installation of an Nvidia driver with `sudo apt-get install nvidia-driver-535` and rebooted with `sudo reboot`. But running `nvidia-smi` to check the driver gave the same message as before the install, "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running."

I shut off the virtual machine and went scouting in my BIOS options to see if anything else relating to Intel VT needs switching on, but it does not look like it - "VT-d" is activated in my BIOS setup.

Again out of lack of better options, I tried installing the nvidia-cuda toolkit directly using `sudo apt install nvidia-cuda-toolkit`. Oddly enough, it downloaded all of the packages and completed successfully. I rebooted the machine and typed `nvidia-smi` to check if the GPU is recognized, but got the same error as above, saying it has failed because it couldn't communicate with the NVIDIA driver. 

I also tried installing the CUDA toolkit from https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_local , but I do suspect this won't do much if Nvidia can't communicate from my virtual machine with the Nvidia driver.

For the umpteenth time, I purged everything Nvidia related, and  installed the Nvidia driver version 550, apparently the latest recommended by Nvidia for Linux 64-bit systems like my VM (I currently have version 535 installed) - `sudo apt-get install nvidia-driver-550`. I also re-installed the CUDA toolkit according to the link above.

And, again, out of sheer desperation, I tried installing Docker as I had previously done on my old VirtualBox virtual machine with


```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```
and...it gave no errors?!??

I then ran, as indicated on the Docker website,

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

, which also completed without errors, and, finally:
```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

It...completed?!?? Miracles????

IT WORKED. It actually worked. The test command completed successfully:
![[2024-08-05_VMware_docker_install_success.png]]

So...now I have Docker on the system. Will perhaps also the pigz installation work now?

It did. Or a prior installation is now working (it looks rather like it tried to update it but didn't find any more recent version):
![[2024-08-05_VMware_pigz_install_success.png]]

I ***immediately*** started creating another snapshot of the machine, just in case anything else goes awry.

### Ensuring Docker can use GPU

ChatGPT had me test whether Docker can actually use my GPU, in case that's needed (and it likely will be, with the RNA-Seq pipelines) using `sudo docker run --rm --gpus all nvidia/cuda:11.5-base nvidia-smi`, which didn't work ("Unable to find image 'nvidia/cuda:11.5-base' locally docker: Error response from daemon: manifest for nvidia/cuda:11.5-base not found: manifest unknown: manifest unknown. See 'docker run --help'.") - not surprising, considering that `nvidia-smi` still shows the same error message saying "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running."

So it suggested installing the nvidia-docker2 package 

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update

sudo apt-get install -y nvidia-docker2

sudo systemctl restart docker
``` 

and then pulling a Docker image that's easily retrievable to test if the GPU is working:

```bash
sudo docker pull nvidia/cuda:11.0-base
sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```
Which...did not work. ChatGPT said the exact name of the docker container (its tag) might be at fault, and I then went on the official [GitLab repo of Nvidia with Docker containers to test different Cuda versions](https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/supported-tags.md) Here, I noticed that the Cuda toolkit version that I have (`nvcc -V` -> "Cuda compilation tools, release 11.5, V11.5.119") is not listed under "Ubuntu 22.04" but under earlier versions. I did install the toolkit as recommended on the [Cuda toolkit website](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_local) but, somehow, still installed version 11.5 instead of 12.6, which seems to be current recommended one. 

How did that happen? I did follow the instructions on the Cuda toolkit website to a T - I cycled back to previous commands, and I for sure ran the commands for version 12.6, the latest recommended one. I now ran, out of curiosity, "sudo apt-get -y install cuda-toolkit-12-6", and what I got back was 

```bash
[sudo] password for iweber: Reading package lists... Done Building dependency tree... Done Reading state information... Done 

***cuda-toolkit-12-6 is already the newest version (12.6.0-1)***.

The following packages were automatically installed and are no longer required: libatomic1:i386 libdrm-amdgpu1:i386 libdrm-intel1:i386 libdrm-nouveau2:i386 libdrm-radeon1:i386 libdrm2:i386 libedit2:i386 libelf1:i386 libexpat1:i386 libffi8:i386 libgl1:i386 libgl1-mesa-dri:i386 libglapi-mesa:i386 libglvnd0:i386 libglx-mesa0:i386 libglx0:i386 libicu70:i386 libllvm15:i386 libnvidia-egl-wayland1 libnvidia-egl-wayland1:i386 libpciaccess0:i386 libsensors5:i386 libstdc++6:i386 libwayland-client0:i386 libwayland-server0:i386 libx11-xcb1:i386 libxcb-dri2-0:i386 libxcb-dri3-0:i386 libxcb-glx0:i386 libxcb-present0:i386 libxcb-randr0:i386 libxcb-shm0:i386 libxcb-sync1:i386 libxcb-xfixes0:i386 libxfixes3:i386 libxml2:i386 libxshmfence1:i386 libxxf86vm1:i386 nvidia-firmware-550-550.107.02 Use 'sudo apt autoremove' to remove them. 0 upgraded, 0 newly installed, 0 to remove and 3 not upgraded.
```

Still, when I do the `nvcc -V` check, what I get is that I have `Cuda compilation tools, release 11.5, V11.5.119`. I wondered if it is possible that I have two versions on my system, both 12.6 and 11.5, and, if yes, how I would check that. ChatGPT had me run `ls /usr/local/` to see what Cuda folders and present there, and, lo and behold, it was three: cuda, cuda-12, and cuda-12.6. So it is indeed possible that they're all different versions. However, my system apparently can't access either of them directly, since they seem to not be in the PATH variable - running `echo $PATH | grep -o "/usr/local/cuda[^:]*/bin"` to find anything cuda-related in the PATH didn't return anything.

To add the latest version to the PATH variable, I edited my .bashrc file and added, through the console, the path to the folder of the latest Cuda version: 

```bash
sudo echo 'export PATH=/usr/local/cuda-12.6/bin${PATH:+:${PATH}}' >> ~/.bashrc
sudo echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
```
, then re-loaded my .bashrc with `source ~/.bashrc`.  Now, when running `echo $PATH | grep -o "/usr/local/cuda[^:]*/bin"`, I got back "/usr/local/cuda-12.6/bin" -> success in adding it to the PATH. When I now checked the version with `nvcc -V`, I finally saw 

![[2024-08-06_cuda_toolkit_version_change.png]]

I now tried pulling an existing Cuda Docker container from [their GitLab repository](https://gitlab.com/nvidia/container-images/cuda/-/blob/master/doc/supported-tags.md) using

```bash
sudo docker pull nvidia/cuda:12.5.1-base-ubuntu22.04
```
and saw that it worked:
![[2024-08-06_docker_download_cuda_image.png]]
(I didn't see a version for Cuda 12.6, so I chose a container running the latest available version, 12.5)

I next tried running the container to see if GPU usage actually works using

```bash
sudo docker run --rm --gpus all nvidia/cuda:12.5.1-base-ubuntu22.04 nvidia-smi
```
...and it didn't. I restarted the machine, thinking that maybe this will help certain settings load properly, and tried again. I also tried running it without the `nvidia-smi` part. Either way, I got the same error message: "docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error running hook #0: error running hook: exit status 1, stdout: , stderr: Auto-detected mode as 'legacy'
nvidia-container-cli: initialization error: nvml error: driver not loaded: unknown."

This is apparently a problem, again, with the Nvidia driver.  I could try pulling some other docker container to test this further, but I suspect it wouldn't change much if `nvidia-smi` doesn't show anything useful. And I could go on and on trying this out, but maybe I'm lucky again and maybe the pipeline works even without the GPU usage. So the next important step is to generate some small test data to run a pilot test with the pipeline (see [[#Pipeline pilot experiment *C. elegans* data from the course]] )

### Accessing shared folder from VMware virtual machine

I noticed that I could see my former inter-OS shared folder from the VMware virtual machine, but it appeared as empty, even though I set the path to it in the VM settings in VMware Workstation Pro. I unmounted this folder and then checked the [VMware website and ChatGPT](https://docs.vmware.com/en/VMware-Workstation-Pro/17/com.vmware.ws.using.doc/GUID-AB5C80FE-9B8A-4899-8186-3DB8201B1758.html) for how to mount the folder. I realized I need to first [check what Linux kernel version I have](https://linuxize.com/post/how-to-check-the-kernel-version-in-linux/), so I used

```bash
uname -srm
```
so I could confirm I have the `Linux 6.5.0-45-generic x86_64` kernel.

I created a new mount point with

```bash
sudo mkdir /mnt/mnt-win-ubu-shared
```

and then, to access my shared folder at this mount point, used:
```bash
sudo /usr/bin/vmhgfs-fuse .host:/ /mnt/mnt-win-ubu-shared -o subtype=vmhgfs-fuse,allow_other
```

I attempted to make the mounted folder not ask me for my password every time by adding this to `/etc/fstab` (sudo access):
```bash
.host:/ /mnt/mnt-win-ubu-shared fuse.vmhgfs-fuse defaults,allow_other 0 0
```

and then finally mounted
```bash
sudo mount -a
```

And restarted my system. I had to go to the mounting point /mnt/mnt-win-ubu-shared from the address bar of my file explorer (ctrl+L) but could then see the folder. I swiftly added it to my bookmarks in the left-hand-side panel.
![[2024-08-06_shared_folder_success.png]]

I also changed the alias in my .bashrc for the command needed to switch to this inter-OS shared folder:
![[2024-08-06_shared_folder_alias_bashrc.png]]

I reloaded the .bashrc with `source ~/.bashrc` and set the permissions on the folder for everyone (including my user) to be able to use it:

```bash
sudo chmod 755 /mnt/mnt-win-ubu-shared
```

### Checking that the git repository within the newly mounted inter-OS folder still works

I immediately hit `git status` to make sure my git repo still works, and what I got was an error saying "fatal: detected dubious ownership in repository at '/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared' To add an exception for this directory, call: git config --global --add safe.directory /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared". 

To hopefully resolve this, I ran:
```bash
git config --global --add safe.directory /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared
```

and then tested if it pops up as safe using `git config --global --get-all safe.directory` and its address does show up in the list.

Next, I tested if git is running as it should using `git status`, and it does - I immediately got an overview of untracked changes :) (I added the folders relating to my pilot pipeline run,  "Adapters", "Genomes" and "C elegans mapping exercise", to .gitignore because I don't care about tracking them. When I repeated the git status command, they did not show up any longer). Everything was updated as it should on GitHub :) 


# The rnasplice pipeline

`rnasplice` is a fairly new pipeline on the nf-core, published just a few months back. This is partially the reason for which I really badly want to run it in a container rather than just in conda: I suspect it probably can still throw a number of bugs when run on a system even remotely different than whatever the developers were using.

I pulled the pipeline from nf-core using

```bash
nextflow pull nf-core/rnasplice
```
![[2024-08-06_pipeline_pull_success.png]]


While I am trying to transfer the entirety of my virtual machine from VirtualBox to VMware (see section [[#Attempting to transfer entirety of virtual machine to VMware]] ), I read about the pipeline to better understand what the individual steps involve.

## Pipeline description for rnasplice


Calling the pipeline could be as easy as typing 

```bash
nextflow run nf-core/rnasplice \
--input samplesheet.csv \ 
--contrasts contrastsheet.csv \ 
--genome GRCh37 \ 
--outdir my/result/directory \ 
-profile docker
```

but what does it do, and what other parameters need to be set?

### Graphical overview
I tried creating an overview here that is somewhat easier to describe with words than the image on the website:

![[rnasplice_map.png]]

### Parts of the pipeline

Also described well at https://github.com/zifornd/rnasplice/blob/dev/docs/output.md

>***Part 1 of pipeline: preprocessing***
>>**cat fastq** 
>>	is something I would use if I had several fastq files per sample, coming from several runs of sequencing. This is usually done to increase sequencing depth, but the SRA archives I downloaded contained precisely two files per sample, containing the two parts of a pair of reads each.
>>
>>**FastQC**
>>_own addition_: **MultiQC** to summarize results
>>	I already performed these steps on the WSL, so will not need to do so again. I already know I need to trim 10 bases from the 5' end of the reads in order to solve any problems that the suboptimal per-base distribution of the four nucleotides may create.
>>
>>>**TrimGalore**! - [GitHub](https://github.com/FelixKrueger/TrimGalore) and [user guide](https://github.com/FelixKrueger/TrimGalore/blob/master/Docs/Trim_Galore_User_Guide.md)
>>>	- **COMMAND**: `trim_galore [options] <filename(s)>`
>>>	- [ will set `--cores 4` to make maximal use of all of my cores but following the indication on the website that says this is a sweet spot (I set 6 cores to be available to the VM)] *dropped this one as it isn't a TrimGalore option I can automatically set. I set the number of cores as a parameter for the pipeline in general*
>>>	- [will use the `--paired` option because I have paired reads as input] *dropped this one as it isn't a TrimGalore option I can automatically set. This is set for the pipeline in general based on the sample sheet*
>>>	- see above - need to trim 10 bases. I previously worked with Trimmomatic for this kind of operation, but TrimGalore also has the option `--clip_R1 10` and `--clip_R2 10`, which will remove these 10 bases from the 5' ends of all of the reads.
>>>	- Since it employes FastQC, TrimGalore does an automated check for low quality base calls and trims accordingly. I don't need to specify the Phred score cutoff for base call quality - it automatically sets it to the most modern version, --phred33.
>>>	- in my previous checks, FastQC did not detect any significant adapter contamination in the reads. If there are any adapters left, they will be of the Illumina type, since this is what kit was employed. However, I am a little reluctant to just use the --illumina parameter, as this trimming is extremely stringent and an overlap of even only 1 base between the end of the read and the adapter sequences will be removed, potentially losing useful information in the process. I will rather let TrimGalore automatically look for potential overlaps with adapter sequences and set `--stringency` to `5` to lose less information, since the risk of real adapter contamination seems extremely low AND I am anyway trimming the 5' ends because of the biased  base distribution
>>>	-  it also automatically filters the resulting sequences and, if a read is then shorter than 20 bp, it is automatically removed from the results.
>>>	- output: [***does it also create separate files for reads that could successfully be paired up from the two input FastQ files and those that could not?***]
>>>	
>>>	>>>	
>>>	
>>>>**FastQC**
>>>>- these two steps are done to check whether the trimming worked exactly as expected, so, in my case, I'd expect the new report generated by MultiQC to show me 140 bp reads with no more issues at the 5' ends.
>>>>- to run FastQC again on the results, use `--fastqc_args "--outdir /TrimGalore_output" ` (TrimGalore automatically creates the output directory if it doesn't exist)
>>>>-_own addition_: **MultiQC** to summarize results

> [!To do]
> >>>	
> >>>	I will then need to add a MultiQC step to summarize the results, but I can do that manually

>>>>>input files: fasta and gtf - see sections [[#Downloading genomes]] and [[#Initial creation of genome and transcriptome indices]]


[this certainly needs more research for accuracy!] also see https://github.com/zifornd/rnasplice/blob/dev/docs/output.md#star-and-salmon
The rest of the pipeline is divided in two branches. Each branch starts with one of two different algorithms, [STAR](https://pubmed.ncbi.nlm.nih.gov/23104886/) and [Salmon](https://salmon.readthedocs.io/en/latest/salmon.html), whose mechanics sound similar at first, but work quite differently. 

As explained [here ](https://www.biostars.org/p/180986/#180993)by Devon Ryan, an aligner like STAR genuinely looks at the base-to-base match of a read to a region in the target genome ("does this read from the sequencing rn align with this bit of the genome?") and also saves information on whether the read matches the genomic region as-is, from one end of the read to the other, or whether there are gaps or insertions ("does every one of the 150 bases in the read match 150 bases at the location where it's mapped in the genome? Or are, say, only bases 1-57 aligned, with an unmatching portion from bases 58-92, and then 93-150 match again?"). This means that it can later be used to accurately quantify which genes are expressed at what levels. Additionally, it is built so that it can easily identify reads that span exon-exon boundaries, thereby making it able to distinguish which of the different transcripts that can come from the same genomic locus the read could be derived from. This information is usually collected in a SAM file (human-readable) and then, for space reasons, converted into a BAM file (non-human-readable).

> [!TO DO:]
> Read more on how Salmon works - the Harvard Chan Bioinfo Core PDF has good visualizations.
> I found this excellent [RNA-seq analysis course ](https://github.com/hbctraining/Intro-to-rnaseq-hpc-salmon-flipped/blob/main/schedule/links-to-lessons.md)from the Harvard Chan Bioinformatics Core ( [Zenodo](https://doi.org/10.5281/zenodo.5833880)). In the [Salmon lesson](https://github.com/hbctraining/Intro-to-rnaseq-hpc-salmon-flipped/blob/main/lessons/08_quasi_alignment_salmon.md) , they explain how to set the parameters:

STAR is the gold standard of the old school of transcript abundance analysis when looking to map reads in a splice-aware manner. Salmon is the new star on the block because it can be used in two different ways: as a pseudo-aligner or as a real aligner. It truly shines as a pseudo-aligner, a mode in which it does not care about the exact fit of the read base-to-base, and does a quantification of "is this read likely to come from this transcript?" based on some more complex background mathematics. This is called pseudo-alignment, and is much faster than an actual base-to-base alignment, like STAR performs. In this mode, Salmon does not compare the reads to a reference genome but to a reference transcriptome, for which it needs a so-called index of the transcriptome. Often, such reference indices are readily available for download for well-studied organisms, such as the mouse (see[[#Salmon installation and mouse transcriptome index]] for how I downloaded it). 

Salmon also makes some adjustments for normalizing the read counts, e.g. to the length of the transcript, in order to produce accurate estimates of how abundantly different splice isoforms are expressed from a particular gene. It can take the BAM files generated by STAR in order to give these results, which we will obtain with STAR in the first part of the pipeline. [how does tximport play into this?]

Salmon can also operate on raw reads from scratch, as an aligner like STAR would, and I could theoretically let it start its branch of the pipeline from scratch, based on the raw reads, but I will anyway get the BAM files from the STAR branch, [so I could save some time on that.] ***does this really save time? pseudo-alignment is much faster - maybe it's better for accuracy, but not time***

The creators of the dataset/authors of the original study used Hisat2 instead of STAR to align the reads to the mm10 mouse genome, and HTSeq to obtain read counts aka expression levels for the genes. The rnasplice pipeline also runs HTSeq after the STAR step, and I am curious how the results will compare to the ones published in the paper.


> ***Part 2a of pipeline: read alignment and read count quantification starting with STAR***
>>**STAR**
>>	aligns the reads
>>	Parameters to consider:
>>	- **`--star_index`**: Provide the path to the STAR index built for your reference genome.
>>	- --genome: Specify the reference genome (e.g., GRCh38) (but only if using the AWS iGenomes, which seem to be very out of date [source: warning from nextflow pages])
>>	- **`--sjdb_overhang`**: Adjust based on your read length. A common choice is `read_length - 1`, or else it defaults to 100 bp. So I will use ***149***, because I am dealing with 150 bp reads.
>>	- `--save_unaligned true` if wanting to get insight into which reads *weren't* aligned - this will give me an idea of whether the alignment in general is working reliably
>>	- [Here](https://www.reneshbedre.com/blog/star-aligner.html), Renesh Bedre explains more of the other parameters that STAR can use, such as `--runThreadN`, which sets on how many cores the aligner should be run (I'll use 6, because that's how many I have)
>>	-  "if `--aligner star_salmon` is specified then all the downstream results will be placed in the `star_salmon/` directory." (https://github.com/zifornd/rnasplice/blob/dev/docs/output.md#alignment-post-processing )
>>	

>>>**samtools**
>>	- https://www.htslib.org/doc/
>>	- https://www.htslib.org/doc/samtools.html
>>	is a set of programs used, in this pipeline, to process the BAM files for further use. The mapped reads are sorted by coordinate and the BAM files are processed to generate mapping statistics.
>>
>>>> ***Part 3a of pipeline: splicing quantification with edgeR, DEXSeq***
>>>>> **rMATS** = splicing event quantification
>>>>> 	- activated by default in pipeline
>>>>> 	**`--rmats_threads`**: Set the number of threads to use for `rMATS` [is this really necessary?]
>>>>> 	
>>>
>>>
>>>>Then follow two branches that deal with finding differentially expressed exons in the data: 
>>>>
>>>>> **HTSEq** - part of the DEXSeq package
>>>>>> **DEXSeq** = differential exon usage
>>>>>> 	https://genome.cshlp.org/content/22/10/2008 
>>>>>> 	- R/Bioconductor package, always active in the pipeline due to the parameter `--dexseq_exon` set to true by default
>>>>>> 	- "Using the `--aggregation` parameter the pipeline will combine overlapping genes into a single aggregate gene. This approach can alternatively be skipped and any exons that overlap other exons from different genes will be skipped. Other important options to take note of are the `--alignment_quality` parameter which can be set by the user and defines the minimum alignment quality required for reads to be included (defined in 5th column of a given SAM file) (default: 10). Prior to quantification, DEXSeq provides an annotation preparation script which takes a GTF file as input and returns a GFF file. Users may instead wish to define their own GFF file and skip this annotation preparation skip by supplying it using the `--gff_dexseq` parameter."
>>>>>> 
>>>>> **featureCounts**
>>>>> 	- provides a quantification that edgeR requires
>>>>> 	- " is activated when the parameter `--edger_exon` is enabled. Please note that as this is aimed at differential exon usage feature type is set as `exon` and cannot be changed. Please take care to use a suitable attribute to categorize the featureCounts attribute type in your GTF using the option `--gtf_group_features` (default: `gene_id`)."
>>>>> 	- 
>>>>>>**edgeR** provides info on differential exon usage, based on featureCounts


Part 4 of the pipeline does some processing of the BAM files resulting from STAR in order to quantify splicing events and resulting transcript variants and make them easy to display in a genome browser. This last step is performed by [MISO, which creates so-called Sashimi plots with read densities across the exons and their junctions.][sure-sure?]

>>>>***Part 4 of pipeline: post-processing after STAR/samtools branch***
>>>>>**BEDtools** 
>>>>>>**bedGraphTobigWig**
>>>>>>	- https://github.com/zifornd/rnasplice/blob/dev/docs/output.md#bedtools-and-bedgraphtobigwig
>>>>>>	- the bigWig format is an even further compressed format than BAM, based on the BAM file generated by STAR. The bigWig file produced by the pipeline can be used in genome browsers such as the IGV genome browser to visualize the read mapping density across the genome
>>>>>>
>>>>>**MISO/Sashimi**
>>>>>	- MISO (Mixture of ISOforms) quantifies expression levels of different transcripts resulting from the alternative splicing of a pre-mRNA derived from one gene ([source](https://miso.readthedocs.io/en/fastmiso/index.html#what-is-miso)). It actually performs a Monte Carlo Markov chain estimation [source explaining this concept!]. 
>>>>>	- like SUPPA, it can also quantify either full transcript variants with all of their splicing particularities, or individual events, such as how frequently one particular exon is included in a type of sample. See [Katz et al](http://www.nature.com/nmeth/journal/v7/n12/full/nmeth.1528.html) for the source publication.
>>>>>	- MISO contains an utility called [sashimi_plot](https://miso.readthedocs.io/en/fastmiso/sashimi.html) (automatically active in the rnasplice pipeline), which creates easy-to-understand plots showing both read densities across certain sequences and also the counts of how often certain splice junctions are paired with each other. This gives information on how frequently parts of a pre-mRNA are included in transcripts or skipped and how the resulting transcripts are structured. Also see [Katz et al](http://biorxiv.org/content/early/2014/02/11/002576)
>>>>>	- the MISO/Sashimi part of the pipeline has two parameters with which users can specify exactly which genes to create the plots for, `miso_genes` for a list of individual identifiers, given as a 'string in single quotes',  and `miso_genes_file`, where one can give a list of identifiers stored in a file. I presume these options come in handy once the analysis is completed and I can look into the genes with the strongest alterations in splicing patterns in the pre-eclampsia mice in comparison to the control ones. See the [pipeline parameters page](https://nf-co.re/rnasplice/1.0.4/parameters#miso) and [this page for potential errors/bugs.](https://github.com/nf-core/rnasplice/issues/72#issuecomment-1643637616)



> ***Part 2b of pipeline: read pseudo-alignment and/or read count quantification per transcript using Salmon***
>**Salmon**
>	- generates read counts per transcript using the BAM files from STAR or an alignment it makes by itself
>> **tximport**
>> 	- https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4712774/ 
>> 	- https://bioconductor.org/packages/3.7/bioc/vignettes/tximport/inst/doc/tximport.html
>> 	- it imports the quantifications generated by Salmon from the data and prepares them for differential expression analysis between samples from different conditions
>> 	- check this on how to use it independent of the pipeline: https://divingintogeneticsandgenomics.com/post/downstream-of-bulk-rnaseq-read-in-salmon-output-using-tximport-and-then-deseq2/
>> 	- tximport also solves issues with artificially inflated gene counts due to transcript isoforms derived from the same gene
>> 
>>>> ***Part 3b of pipeline: actual splicing junction quantification***
>>>>> **DRIMSeq**
>>>>	- https://f1000research.com/articles/5-1356/v2
>>>>		- an R/Bioconductor package that quantifies changes between experimental conditions in the relative abundance of all of the possible transcript isoforms resulting from a genomic locus, and also monitors SNPs that can lead to such abundance changes (splicing quantitative trait loci, sQTLs)
>>>>		- it also [filters low-abundance transcripts](https://github.com/zifornd/rnasplice/blob/dev/docs/output.md) and some other categories before we use DEXSeq (see below)
>>>>
>>>>>> **DEXSeq** = in this case, used for differential transcript usage
>>>>>> 	- activated by default in the pipeline due to the parameter `--dexseq_dtu` being set to true ([[Knowledge_Progression_handling_RNA-seq_datasets#Config file for the rnasplice pipeline with absolutely all of the default parameters]])
>>>>>> 	- 
>>>>> **SUPPA** = differential event-based alternative splicing analysis
>>>>> 	https://github.com/comprna/SUPPA
>>>>> 	- can work in two different ways: detecting either
>>>>> 		- individual splicing events, e.g. inclusion or skipping of a particular exon, ( Skipping Exon = SE,  Alternative 5'/3' Splice Sites = A5/A3 (generated together with the option SS), Mutually Exclusive Exons = MX, Retained Intron = RI, Alternative First/Last Exons = AF/AL (generated together with the option FL),
>>>>> 		- or can quantify the abundance of different transcript variants, with their specific composition of exons or retained introns, alternative splice sites, etc.
>>>>> 	- both ways are activated by default in the pipeline ([[Knowledge_Progression_handling_RNA-seq_datasets#Config file for the rnasplice pipeline with absolutely all of the default parameters]])

### Config file for the rnasplice pipeline with absolutely all of the default parameters

Taken directly from https://github.com/nf-core/rnasplice/blob/1.0.4/nextflow.config

```Groovy
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/rnasplice Nextflow config file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Default config options for all compute environments
----------------------------------------------------------------------------------------
*/

// Global default params, used in configs
params {

    // Input options
    input                      = null
    contrasts                  = null
    source                     = 'fastq'

    // References
    genome                     = null
    transcript_fasta           = null
    gtf_extra_attributes       = 'gene_name'
    gtf_group_features         = 'gene_id'
    gencode                    = false
    save_reference             = false
    igenomes_base              = 's3://ngi-igenomes/igenomes/'
    igenomes_ignore            = false

    // Trimming
    clip_r1                    = null
    clip_r2                    = null
    three_prime_clip_r1        = null
    three_prime_clip_r2        = null
    trim_nextseq               = null
    save_trimmed               = false
    skip_trimming              = false
    skip_trimgalore_fastqc     = false
    min_trimmed_reads          = 10000

    // Alignment
    aligner                    = 'star_salmon'
    pseudo_aligner             = 'salmon'
    bam_csi_index              = false
    seq_center                 = null
    salmon_quant_libtype       = null
    star_ignore_sjdbgtf        = false
    skip_alignment             = false
    save_unaligned             = false
    save_align_intermeds       = false
    save_merged_fastq          = false

    // QC
    skip_bigwig                = true
    skip_fastqc                = false

    // rMATs
    rmats                      = true
    rmats_splice_diff_cutoff   = 0.0001
    rmats_paired_stats         = true
    rmats_read_len             = 40
    rmats_novel_splice_site    = false
    rmats_min_intron_len       = 50
    rmats_max_exon_len         = 500

    // DEXSeq DEU
    dexseq_exon                = true
    save_dexseq_annotation     = false
    gff_dexseq                 = null
    alignment_quality          = 10
    aggregation                = true
    save_dexseq_plot           = true
    n_dexseq_plot              = 10

    // edgeR DEU
    edger_exon                 = true
    save_edger_plot            = true
    n_edger_plot               = 10

    // DEXSeq DTU
    dexseq_dtu                 = true
    dtu_txi                    = 'dtuScaledTPM'

    // Miso
    sashimi_plot               = true
    miso_genes                 = 'ENSG00000004961, ENSG00000005302, ENSG00000147403'
    miso_genes_file            = null
    miso_read_len              = 75
    fig_width                  = 7
    fig_height                 = 7

    // DRIMSeq Filtering
    min_samps_feature_expr     =  2
    min_samps_feature_prop     =  2
    min_samps_gene_expr        =  4
    min_feature_expr           =  10
    min_feature_prop           =  0.1
    min_gene_expr              =  10

    // SUPPA options
    suppa                      = true
    suppa_per_local_event      = true
    suppa_per_isoform          = true
    suppa_tpm                  = null

    // SUPPA Generate events options
    generateevents_pool_genes  = true
    generateevents_event_type  = 'SE SS MX RI FL'
    generateevents_boundary    = 'S'
    generateevents_threshold   = 10
    generateevents_exon_length = 100
    psiperevent_total_filter   = 0

    // SUPPA Diffsplice options
    diffsplice_local_event     = true
    diffsplice_isoform         = true
    diffsplice_method          = 'empirical'
    diffsplice_area            = 1000
    diffsplice_lower_bound     = 0
    diffsplice_gene_correction = true
    diffsplice_paired          = true
    diffsplice_alpha           = 0.05
    diffsplice_median          = false
    diffsplice_tpm_threshold   = 0
    diffsplice_nan_threshold   = 0

    // SUPPA Cluster options
    clusterevents_local_event  = true
    clusterevents_isoform      = true
    clusterevents_sigthreshold = null
    clusterevents_dpsithreshold= 0.05
    clusterevents_eps          = 0.05
    clusterevents_metric       = 'euclidean'
    clusterevents_separation   = null
    clusterevents_min_pts      = 20
    clusterevents_method       = 'DBSCAN'

    // MultiQC options
    multiqc_config             = null
    multiqc_title              = null
    multiqc_logo               = null
    max_multiqc_email_size     = '25.MB'
    multiqc_methods_description = null

    // Boilerplate options
    outdir                     = null
    publish_dir_mode           = 'copy'
    email                      = null
    email_on_fail              = null
    plaintext_email            = false
    monochrome_logs            = false
    hook_url                   = null
    help                       = false
    version                    = false

    // Config options
    config_profile_name        = null
    config_profile_description = null
    custom_config_version      = 'master'
    custom_config_base         = "https://raw.githubusercontent.com/nf-core/configs/${params.custom_config_version}"
    config_profile_contact     = null
    config_profile_url         = null

    // Max resource options
    // Defaults only, expecting to be overwritten
    max_memory                 = '128.GB'
    max_cpus                   = 16
    max_time                   = '240.h'

    // Schema validation default options
    validationFailUnrecognisedParams = false
    validationLenientMode            = false
    validationSchemaIgnoreParams     = 'genomes,igenomes_base'
    validationShowHiddenParams       = false
    validate_params                  = true

}

// Load base.config by default for all pipelines
includeConfig 'conf/base.config'

// Load nf-core custom profiles from different Institutions
try {
    includeConfig "${params.custom_config_base}/nfcore_custom.config"
} catch (Exception e) {
    System.err.println("WARNING: Could not load nf-core/config profiles: ${params.custom_config_base}/nfcore_custom.config")
}

// Load nf-core/rnasplice custom profiles from different institutions.
// Warning: Uncomment only if a pipeline-specific instititutional config already exists on nf-core/configs!
// try {
//   includeConfig "${params.custom_config_base}/pipeline/rnasplice.config"
// } catch (Exception e) {
//   System.err.println("WARNING: Could not load nf-core/config/rnasplice profiles: ${params.custom_config_base}/pipeline/rnasplice.config")
// }

profiles {
    debug {
        dumpHashes             = true
        process.beforeScript   = 'echo $HOSTNAME'
        cleanup                = false
        nextflow.enable.configProcessNamesValidation = true
    }
    conda {
        conda.enabled          = true
        docker.enabled         = false
        singularity.enabled    = false
        podman.enabled         = false
        shifter.enabled        = false
        charliecloud.enabled   = false
        apptainer.enabled      = false
    }
    mamba {
        conda.enabled          = true
        conda.useMamba         = true
        docker.enabled         = false
        singularity.enabled    = false
        podman.enabled         = false
        shifter.enabled        = false
        charliecloud.enabled   = false
        apptainer.enabled      = false
    }
    docker {
        docker.enabled         = true
        conda.enabled          = false
        singularity.enabled    = false
        podman.enabled         = false
        shifter.enabled        = false
        charliecloud.enabled   = false
        apptainer.enabled      = false
        docker.runOptions      = '-u $(id -u):$(id -g)'
    }
    arm {
        docker.runOptions      = '-u $(id -u):$(id -g) --platform=linux/amd64'
    }
    singularity {
        singularity.enabled    = true
        singularity.autoMounts = true
        conda.enabled          = false
        docker.enabled         = false
        podman.enabled         = false
        shifter.enabled        = false
        charliecloud.enabled   = false
        apptainer.enabled      = false
    }
    podman {
        podman.enabled         = true
        conda.enabled          = false
        docker.enabled         = false
        singularity.enabled    = false
        shifter.enabled        = false
        charliecloud.enabled   = false
        apptainer.enabled      = false
    }
    shifter {
        shifter.enabled        = true
        conda.enabled          = false
        docker.enabled         = false
        singularity.enabled    = false
        podman.enabled         = false
        charliecloud.enabled   = false
        apptainer.enabled      = false
    }
    charliecloud {
        charliecloud.enabled   = true
        conda.enabled          = false
        docker.enabled         = false
        singularity.enabled    = false
        podman.enabled         = false
        shifter.enabled        = false
        apptainer.enabled      = false
    }
    apptainer {
        apptainer.enabled      = true
        apptainer.autoMounts   = true
        conda.enabled          = false
        docker.enabled         = false
        singularity.enabled    = false
        podman.enabled         = false
        shifter.enabled        = false
        charliecloud.enabled   = false
    }
    gitpod {
        executor.name          = 'local'
        executor.cpus          = 4
        executor.memory        = 8.GB
    }
    test                   { includeConfig 'conf/test.config'                   }
    test_full              { includeConfig 'conf/test_full.config'              }
    test_edger             { includeConfig 'conf/test_edger.config'             }
    test_rmats             { includeConfig 'conf/test_rmats.config'             }
    test_dexseq            { includeConfig 'conf/test_dexseq.config'            }
    test_suppa             { includeConfig 'conf/test_suppa.config'             }
    test_fastq             { includeConfig 'conf/test_fastq.config'             }
    test_genome_bam        { includeConfig 'conf/test_genome_bam.config'        }
    test_transcriptome_bam { includeConfig 'conf/test_transcriptome_bam.config' }
    test_salmon_results    { includeConfig 'conf/test_salmon_results.config'    }
}

// Set default registry for Apptainer, Docker, Podman and Singularity independent of -profile
// Will not be used unless Apptainer / Docker / Podman / Singularity are enabled
// Set to your registry if you have a mirror of containers
apptainer.registry   = 'quay.io'
docker.registry      = 'quay.io'
podman.registry      = 'quay.io'
singularity.registry = 'quay.io'

// Nextflow plugins
plugins {
    id 'nf-validation@1.1.3' // Validation of pipeline parameters and creation of an input channel from a sample sheet
}

// Load igenomes.config if required
if (!params.igenomes_ignore) {
    includeConfig 'conf/igenomes.config'
} else {
    params.genomes = [:]
}

// Export these variables to prevent local Python/R libraries from conflicting with those in the container
// The JULIA depot path has been adjusted to a fixed path `/usr/local/share/julia` that needs to be used for packages in the container.
// See https://apeltzer.github.io/post/03-julia-lang-nextflow/ for details on that. Once we have a common agreement on where to keep Julia packages, this is adjustable.

env {
    PYTHONNOUSERSITE = 1
    R_PROFILE_USER   = "/.Rprofile"
    R_ENVIRON_USER   = "/.Renviron"
    JULIA_DEPOT_PATH = "/usr/local/share/julia"
}

// Capture exit codes from upstream processes when piping
process.shell = ['/bin/bash', '-euo', 'pipefail']

// Disable process selector warnings by default. Use debug profile to enable warnings.
nextflow.enable.configProcessNamesValidation = false

def trace_timestamp = new java.util.Date().format( 'yyyy-MM-dd_HH-mm-ss')
timeline {
    enabled = true
    file    = "${params.outdir}/pipeline_info/execution_timeline_${trace_timestamp}.html"
}
report {
    enabled = true
    file    = "${params.outdir}/pipeline_info/execution_report_${trace_timestamp}.html"
}
trace {
    enabled = true
    file    = "${params.outdir}/pipeline_info/execution_trace_${trace_timestamp}.txt"
}
dag {
    enabled = true
    file    = "${params.outdir}/pipeline_info/pipeline_dag_${trace_timestamp}.html"
}

manifest {
    name            = 'nf-core/rnasplice'
    author          = """Ben Southgate, James Ashmore"""
    homePage        = 'https://github.com/nf-core/rnasplice'
    description     = """Alternative splicing analysis using RNA-seq."""
    mainScript      = 'main.nf'
    nextflowVersion = '!>=23.04.0'
    version         = '1.0.4'
    doi             = '10.5281/zenodo.8424632'
}

// Load modules.config for DSL2 module specific options
includeConfig 'conf/modules.config'

// Function to ensure that resource requirements don't go beyond
// a maximum limit
def check_max(obj, type) {
    if (type == 'memory') {
        try {
            if (obj.compareTo(params.max_memory as nextflow.util.MemoryUnit) == 1)
                return params.max_memory as nextflow.util.MemoryUnit
            else
                return obj
        } catch (all) {
            println "   ### ERROR ###   Max memory '${params.max_memory}' is not valid! Using default value: $obj"
            return obj
        }
    } else if (type == 'time') {
        try {
            if (obj.compareTo(params.max_time as nextflow.util.Duration) == 1)
                return params.max_time as nextflow.util.Duration
            else
                return obj
        } catch (all) {
            println "   ### ERROR ###   Max time '${params.max_time}' is not valid! Using default value: $obj"
            return obj
        }
    } else if (type == 'cpus') {
        try {
            return Math.min( obj, params.max_cpus as int )
        } catch (all) {
            println "   ### ERROR ###   Max cpus '${params.max_cpus}' is not valid! Using default value: $obj"
            return obj
        }
    }
}
```

## The Nextflow script for the pipeline and other scripts it calls

Find at https://github.com/nf-core/rnasplice/blob/1.0.4/workflows/rnasplice.nf

The other scripts, specific to certain algorithms/steps, such as STAR alignment, can be found either in the "subflows -> local" or "subflows -> nf-core" folders.

In the "local" subflows, we have the scripts for:
|[align_star.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/align_star.nf "align_star.nf")|
|[contrasts_check.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/contrasts_check.nf "contrasts_check.nf")
|[dexseq_deu.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/dexseq_deu.nf "dexseq_deu.nf")
|[drimseq_dexseq_dtu.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/drimseq_dexseq_dtu.nf "drimseq_dexseq_dtu.nf")
|[edger_deu.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/edger_deu.nf "edger_deu.nf")
|[input_check.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/input_check.nf "input_check.nf")
|[prepare_genome.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/prepare_genome.nf "prepare_genome.nf")
|[rmats.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/rmats.nf 
|[suppa.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/suppa.nf "suppa.nf")
|[tx2gene_tximport.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/tx2gene_tximport.nf "tx2gene_tximport.nf")
|[visualise_miso.nf](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/local/visualise_miso.nf "visualise_miso.nf")|

These are all pipeline-specific processes. There are also processes that are used by many of the nf-core pipelines, which are stored in the "nf-core" workflows:

|                                                                                                                                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [bam_sort_stats_samtools](https://github.com/nf-core/rnasplice/tree/1.0.4/subworkflows/nf-core/bam_sort_stats_samtools "bam_sort_stats_samtools")                               |
| [bam_stats_samtools](https://github.com/nf-core/rnasplice/tree/1.0.4/subworkflows/nf-core/bam_stats_samtools "bam_stats_samtools")                                              |
| [bedgraph_bedclip_bedgraphtobigwig](https://github.com/nf-core/rnasplice/tree/1.0.4/subworkflows/nf-core/bedgraph_bedclip_bedgraphtobigwig "bedgraph_bedclip_bedgraphtobigwig") |
| [fastq_fastqc_umitools_trimgalore](https://github.com/nf-core/rnasplice/tree/1.0.4/subworkflows/nf-core/fastq_fastqc_umitools_trimgalore "fastq_fastqc_umitools_trimgalore")    |
### Initial creation of genome and transcriptome indices

#### STAR independent installation and mouse genome index

I decided to create my STAR and Salmon indices in advance in order to remove potential sources of pipeline getting stuck, so I had to install both independent of the pipeline.

[From the ~~horse's~~ scientist's mouth](https://physiology.med.cornell.edu/faculty/skrabanek/lab/angsd/lecture_notes/STARmanual.pdf) who developed STAR, Alexander Dobin, I took the instructions on how to create one's own STAR index, and did so before running the pipeline (see also [here](https://github.com/alexdobin/STAR))

 To first get STAR separately from the Nextflow pipeline, I went into my Nextflow environment and ran:
 ```bash
 wget https://github.com/alexdobin/STAR/archive/2.7.11b.tar.gz
 tar -xzf 2.7.11b.tar.gz
 cd STAR-2.7.11b/source
```

Then, as instructed, I ran `make STAR` for the gcc C++ compiler to create a ready-to-run version of STAR on my system. Started around 11:57, took around 3 min to complete. 
Got a warning "make: warning:  Clock skew detected.  Your build may be incomplete."

I reset my system time with `sudo apt-get install ntp` and  `sudo service ntp restart`, then re-made the STAR build with `make clean` and `make STAR`, which now worked with no further errors.

I had to add the path to the folder where I compiled the executable to the PATH variable, which I did by adding to my .bashrc `export PATH=/home/iweber/Documents/Software/STAR-2.7.11b/source:$PATH`

To make the mouse STAR index, I ran:
```bash
STAR --runThreadN 6 --runMode genomeGenerate --genomeDir /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus --genomeFastaFiles /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna --sjdbGTFfile /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gtf --sjdbOverhang 149
```

Annnnnnnnd success! Took all of 27 min to complete.
![[2024-08-07_STAR_index_mouse_success.png]]
#### Salmon installation and Salmon index for the mouse transcriptome

For the Salmon index creation, I first got the latest Salmon version independent of the Nextflow pipeline as instructed on the[ Salmon website](https://salmon.readthedocs.io/en/latest/building.html#installation) using

`wget https://github.com/COMBINE-lab/salmon/releases/download/v1.10.0/salmon-1.10.0_linux_x86_64.tar.gz`

I decompressed the tar archive with `tar -xvzf salmon-1.10.0_linux_x86_64.tar.gz`, and then added the path to Salmon's bin folder to my PATH variable by including `export PATH=/home/iweber/Documents/Software/salmon-latest_linux_x86_64/bin:$PATH` in my .bashrc file. I could then see the command autocomplete, so I knew it works on my system :) `salmon --version` also returned "1.10.0", which is correct.


I also tried to get a Docker image with 

`sudo docker pull combinelab/salmon`

> [!NOTE]
> which...did not seem to download anything to my "Software" folder that I ran the command in ***pondering smiley*** . I'm sure this rather has something to do with me not understanding how the Docker image is supposed to work. 


Next, I went looking for information on how to set up the transcriptomic index with Salmon. The [Salmon manual](https://salmon.readthedocs.io/en/latest/salmon.html#using-salmon) sent me to this [RefGenie server/repository](http://refgenomes.databio.org) that has ready-made indices for well-studied species, and it indeed hosts a Salmon index for the mouse, matching the NCBI genome, [here](http://refgenomes.databio.org/v3/genomes/splash/0f10d83b1050c08dd53189986f60970b92a315aa7a16a6f1). I chose to download the complete[ Salmon index generated with selective alignment method](http://refgenomes.databio.org/v3/assets/splash/0f10d83b1050c08dd53189986f60970b92a315aa7a16a6f1/salmon_sa_index?tag=default), because the description says that using it will increase the accuracy of quantification.

I made a new folder, Salmon_index_M_musculus_mm10, in the genome folder (/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_M_musculus/GCF_000001635.27/), then used wget to download the index from RefGenie:

`wget http://refgenomes.databio.org/v3/assets/archive/0f10d83b1050c08dd53189986f60970b92a315aa7a16a6f1/salmon_sa_index?tag=default`

which...didn't work. Even though I saw the 12 GB download and it took around 30 min to do so, I had no files at the end in my working directory and only an odd file that popped up with `ls -lha`:
![[2024-08-07_Salmon_index_mouse_download_fail.png]]

ChatGPT told me that the file with the utterly weird privilege indicators (question marks) and the truncated name is likely the fault of a corrupted download, and that that likely happened because there are special characters (question mark) in the archive name on the website. So it suggested re-downloading the archive with a clearly defined name using

`wget "http://refgenomes.databio.org/v3/assets/archive/0f10d83b1050c08dd53189986f60970b92a315aa7a16a6f1/salmon_sa_index?tag=default" -O salmon_sa_index.tgz`

...but that only downloaded a tiny file, nothing close to the 12 GB I was expecting from the tgz archive. So I went the new-school way and just downloaded it through the browser *sweat drop smiley*

***Side note***: *I found out later that RefGenie is actually a Python package that allows downloading files related to some reference genome assemblies from the command line; [here's how to use it ](https://refgenie.databio.org/en/latest/)for further reference.*

## Prerequisites for running the rnasplice pipeline

### **Create contrast sheet**

***--contrasts contrastssheet.csv:*** I first need to create a contrast sheet, which tells the pipeline what kind of an experiment has been performed and how the conditions are called. 

> [!Straight from the pipeline's "Contrastsheet input" section:]
> The contrastsheet has to be a comma-separated file with 3 columns, and a header row as shown in the examples below.
> 
> ```
> contrast,treatment,control
> TREATMENT_CONTROL,TREATMENT,CONTROL
> ```
> 
> The contrastsheet can have as many columns as you desire, however, there is a strict requirement for the first 3 columns to match those defined in the table below.
> 
> | Column      | Description                                                               |
> | ----------- | ------------------------------------------------------------------------- |
> | `contrast`  | An arbitrary identifier, will be used to name contrast-wise output files. |
> | `treatment` | The treatment/target level for the comparison.                            |
> | `control`   | The control/base level for the comparison.                                |
> 

Therefore, my `contrastssheet_preeclampsia.csv` looks like:

```csv
contrast,treatment,control
PREECLAMPSIA_CONTROL,PREECLAMPSIA,CONTROL
```

### **Creating the sample sheet**

***--input samplesheet.csv:*** Next, I created a sample sheet (a .csv file telling the pipeline what the sample files are called and which ones are from the control and which ones from the treated animals). [Note from "Source configuration": when using FastQ files as input, file must be structured exactly as shown here] 

> [!straight from the pipeline's "Samplesheet input" section:]
>
>```
sample,fastq_1,fastq_2,strandedness,condition
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,forward,control
CONTROL_REP2,AEG588A2_S2_L002_R1_001.fastq.gz,AEG588A2_S2_L002_R2_001.fastq.gz,forward,control
CONTROL_REP3,AEG588A3_S3_L002_R1_001.fastq.gz,AEG588A3_S3_L002_R2_001.fastq.gz,forward,control```
> ```
> 
> The samplesheet can have as many columns as you desire, however, there is a strict requirement for at least 3 columns to match those defined in the table below. 
> 
> | Column              | Description                                                                                                                                                                            |     |
> | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
> | `sample`            | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`). |     |
> | `fastq_1`           | Full path to FastQ file for Illumina short reads 1. File has to be gzipped and have the extension “.fastq.gz” or “.fq.gz”.                                                             |     |
> | `fastq_2`           | Full path to FastQ file for Illumina short reads 2. File has to be gzipped and have the extension “.fastq.gz” or “.fq.gz”.                                                             |     |
> | `strandedness`      | Sample strand-specificity. Must be one of `unstranded`, `forward` or `reverse`.                                                                                                        |     |
> | `condition`         | The name of the condition a sample belongs to (e.g. ‘control’, or ‘treatment’) - these labels will be used for downstream analysis.                                                    |     |
> | `genome_bam`        | Full path to aligned BAM file, derived from splicing aware mapper (STAR, HiSat, etc). File has to be in “.bam” format.                                                                 |     |
> | `transcriptome_bam` | Full path to aligned transcriptome file, derived from splicing aware mapper (STAR, HiSat, etc). File has to be in “.bam” format.                                                       |     |
> | `salmon_results`    | Full path to the result folder produced by salmon quantification.                                                                                                                      | "   |
> 

I created the sample sheet in Notepad++, and I even remembered to set the line breaks to Unix line breaks (LF instead of CR LF).
  
| [](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA703836&o=acc_s%3Aa# "Add all items")[](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA703836&o=acc_s%3Aa# "Remove all items") | 1<br><br>[Run](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA703836&o=acc_s%3Aa#) | 2<br><br>[BioSample](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA703836&o=acc_s%3Aa#) | 5<br><br>[Experiment](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA703836&o=acc_s%3Aa#) | 6<br><br>GEO_Accession | 9<br><br>tissue                                |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ---------------------- | ---------------------------------------------- |
| 1                                                                                                                                                                                         | [SRR13761520](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR13761520)                | [SAMN18024800](https://www.ncbi.nlm.nih.gov/biosample/SAMN18024800)                           | [SRX10148223](https://www.ncbi.nlm.nih.gov/sra/SRX10148223)                                    | GSM5098819             | Cortex offspring from control mother mice      |
| 2                                                                                                                                                                                         | [SRR13761521](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR13761521)                | [SAMN18024799](https://www.ncbi.nlm.nih.gov/biosample/SAMN18024799)                           | [SRX10148224](https://www.ncbi.nlm.nih.gov/sra/SRX10148224)                                    | GSM5098820             | Cortex offspring from control mother mice      |
| 3                                                                                                                                                                                         | [SRR13761522](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR13761522)                | [SAMN18024798](https://www.ncbi.nlm.nih.gov/biosample/SAMN18024798)                           | [SRX10148225](https://www.ncbi.nlm.nih.gov/sra/SRX10148225)                                    | GSM5098821             | Cortex offspring from control mother mice      |
| 4                                                                                                                                                                                         | [SRR13761523](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR13761523)                | [SAMN18024797](https://www.ncbi.nlm.nih.gov/biosample/SAMN18024797)                           | [SRX10148226](https://www.ncbi.nlm.nih.gov/sra/SRX10148226)                                    | GSM5098822             | Cortex offspring from control mother mice      |
| 5                                                                                                                                                                                         | [SRR13761524](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR13761524)                | [SAMN18024796](https://www.ncbi.nlm.nih.gov/biosample/SAMN18024796)                           | [SRX10148227](https://www.ncbi.nlm.nih.gov/sra/SRX10148227)                                    | GSM5098823             | Cortex offspring from preeclampsia mother mice |
| 6                                                                                                                                                                                         | [SRR13761525](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR13761525)                | [SAMN18024795](https://www.ncbi.nlm.nih.gov/biosample/SAMN18024795)                           | [SRX10148228](https://www.ncbi.nlm.nih.gov/sra/SRX10148228)                                    | GSM5098824             | Cortex offspring from preeclampsia mother mice |
| 7                                                                                                                                                                                         | [SRR13761526](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR13761526)                | [SAMN18024794](https://www.ncbi.nlm.nih.gov/biosample/SAMN18024794)                           | [SRX10148229](https://www.ncbi.nlm.nih.gov/sra/SRX10148229)                                    | GSM5098825             | Cortex offspring from preeclampsia mother mice |
| 8                                                                                                                                                                                         | [SRR13761527](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR13761527)                | [SAMN18024793](https://www.ncbi.nlm.nih.gov/biosample/SAMN18024793)                           | [SRX10148230](https://www.ncbi.nlm.nih.gov/sra/SRX10148230)                                    | GSM5098826             | Cortex offspring from preeclampsia mother mice |


 Therefore, my `samplesheet_preeclampsia.csv` looks like:
```cs
sample,fastq_1,fastq_2,strandedness,condition
CONTROL_REP1,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761520_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761520_1.fastq.gz,reverse,CONTROL
CONTROL_REP2,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761521_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761521_2.fastq.gz,reverse,CONTROL
CONTROL_REP3,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761522_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761522_2.fastq.gz,reverse,CONTROL
CONTROL_REP4,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761523_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761523_2.fastq.gz,reverse,CONTROL
PREECLAMPSIA_REP1,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761524_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761524_2.fastq.gz,reverse,PREECLAMPSIA
PREECLAMPSIA_REP2,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761525_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761525_2.fastq.gz,reverse,PREECLAMPSIA
PREECLAMPSIA_REP3,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761526_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761526_2.fastq.gz,reverse,PREECLAMPSIA
PREECLAMPSIA_REP4,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761527_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761527_2.fastq.gz,reverse,PREECLAMPSIA
```


### **Stranded information?**
But where is the strandedness of the libraries indicated? There is no mention of this neither in the publication, nor in its Supplemental Data 1, nor in the Supplementary Materials and Methods. I only found a mention in their regular Materials and Methods section that they used the TruSeq Stranded mRNA Library Prep Kit from Illumina, in whose [protocol](https://support.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-mrna-workflow/truseq-stranded-mrna-workflow-reference-1000000040498-00.pdf)  I read that it encompasses a first-strand reverse transcription and then the generation of the second strand of the cDNA, complementary to the first. This means that the resulting cDNA has the forward strand identical to the reverse complement of the original mRNA  and so should be treated as "reverse" and specified as such in the subsequent process. However, how can I make super sure that this is true? Giving the wrong strandedness will render the entire analysis essentially useless, this is highly important. 
[explain the underlying biology]

Side note: how does the kit distinguish between what is the first strand (reverse strand) and the forward strand? According to the TruSeq protocol, this is done by using a desoxyribonucleotide in the second-strand preparation that is different from the first-strand preparation (dUTP instead of dTTP for the first strand - they will both hybridize with adenosine, but the presence of Ts in one cDNA strand and the presence of Us in the other makes it possible to tell apart which strand the reads stem from)

The blessings of online searching pointed me to a Python package called [How are we stranded here](https://github.com/signalbash/how_are_we_stranded_here) , which analyzes fastq files precisely to understand this. The knack: it also needs some additional information about the organism at hand, such as a gtf annotation file and a kallisto transcriptomic index. This seems like a very complicated option, so I asked [Ioana Lemnian](https://www.linkedin.com/in/ioana-lemnian-1a2690138/?originalSubdomain=de) whether that is necessary. She said no, because it can only be that the `_R1` FastQ files are reverse and `_R2` files forward, so the strandedness should be specified as `RF`  (she also sent me some useful resources: [this one from ECSeq](https://www.ecseq.com/support/ngs/how-do-strand-specific-sequencing-protocols-work) and [this from the Broad Institute](https://www.broadinstitute.org/videos/strand-specific-rna-seq-preferred)

One question remained in this context, though: how should one specify this in the sample sheet? It  only takes one single indication of strandedness for each sample and both of its `_R1` and `_R2` files with reads together, and that indication can only be either `forward`, `reverse`, or `unstranded`.  I realized nf-core has its very own Slack channel, where I swiftly got a detailed answer from [Thomas Danhorn](https://som.cuanschutz.edu/Profiles/Faculty/Profile/35847) , indicating that the strandedness in this case has to follow that of the R1 file, so, in my case, be `reverse`. 

This is how the sample sheet looks like in the end:
![[2024-08-05_samplesheet.png]]


### **Configuration of the type of source files**
Since I have FastQ files, I can leave the source configuration to the default, `--source fastq`.  

### **Gzipping FastQ files for pipeline with pigz**

I noticed in the parameters that the pipeline doesn't work with FastQ files directly, but only with their gzipped versions. I started the `gzip SRR13761520_1.fastq` command at 13:09, took around 10 min. So I know that doing the same with the remaining 15 files in sequence should take something like 150 minutes ~ 3 h. Which is why I'll only start after my recovery drive is complete, I switch off hyper-V, and I dare to restart my PC to see if it is indeed off and confirm my system didn't turn into blue pulp (BSOD).

The script I want to use to gzip all files at once: (~~pigz, which allows hyperthreading, won't work on my VirtualBox VM because of the same issues with GPU passthrough, so I'll have to take this slow route...~~):

```bash
gzip_several_fastqs.sh                                                                                                            
#!/bin/bash

# Specify directory containing FASTQ files
DIRECTORY="/mnt-win-ubu-shared/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq"

# Find all .fastq files in the specified directory and subdirectories. Write line by line, pipe each line with one file name into while loop that compresses it.
find "$DIRECTORY" -type f -name "*.fastq" | while read -r FILE; do
  echo "Compressing $FILE"
  gzip "$FILE"
done
```

Scratch the above, I finally fixed all of these issues and now can use pigz, taking advantage of its parallel processing capabilities. So I need only replace the command with pigz:

```bash
pigz_several_fastqs.sh                                                                                                            
#!/bin/bash

# Specify directory containing FASTQ files
DIRECTORY="/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/"

# Find all .fastq files in the specified directory and subdirectories. Write line by line, pipe each line with one file name into while loop that compresses it.
find "$DIRECTORY" -type f -name "*.fastq" | while read -r FILE; do
  echo "Compressing $FILE"
  pigz "$FILE"
done
```

### GTF file for the mouse mm10 genome

rnasplice also needs a GTF annotation file that indicates where genes, transcripts, exons, etc are located within the mouse genome. Turns out, I had already gotten the mouse gtf a few months back, when I downloaded the mouse genome from NCBI (https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/635/GCF_000001635.27_GRCm39/). This is good because I have the latest assembly of the mouse genome from NCBI, so it is more consistent to also use the NCBI annotations, especially since I am interested in looking at potentially disease-relevant genes, and I know NCBI has very good integration of its genomic data with its clinical databases, whereas Ensembl is somewhat better at having extremely detailed annotations, which come in handy for comparative/evolutionary studies.

However, the annotation file from NCBI is in [GFF3](https://ftp.ncbi.nlm.nih.gov/genomes/README_GFF3.txt) format, so I might need to convert it to GTF. I found an overview of what these two file types are made of at [Ensembl](https://www.ensembl.org/info/website/upload/gff.html), and it seems that GTF2 and GFF2 files are identical.  BUT: reading on on the parameters page, I found that -gff is also an option that allows the use of GFF files instead of GTF, so yay for no conversion needed!

Even better: the GTF file is also included in the NCBI FTP with downloads for this genome assembly.

To get the mouse GTF from the NCBI FTP (already had the genome from them), used `wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/635/GCF_000001635.27_GRCm39/GCF_000001635.27_GRCm39_genomic.gtf.gz` and then `pigz -d` to unzip it.

# Pipeline pilot experiment: *C. elegans* data from the course

> [!Side note for the future:]
> there is a test dataset for this pipeline (human immortalized cell lines, paired-end RNA-seq data from [Shen et al., 2014](https://github.com/nf-core/test-datasets/tree/rnasplice#full-test-dataset-origin) - the original rMATS paper) that can be called with 
> 

```bash
nextflow run nf-core/rnasplice -profile test_full,<docker/singularity/institute> --outdir <OUTDIR>
```

## The C. elegans data
In the NGS part of the bioinformatics course, we mapped some reads from the C. elegans genome. I'd like to use these as a test dataset for the pipeline, because the data consisted of far fewer reads than what I have for my mouse experiment, and so I should be able to see fast if the pipeline works or not.

I have the reads files stored as fastq.gz files under
`/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Mapping_exercise_C_elegans/Fastq_original_C_elegans/`

and the C. elegans genome stored under 
`/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna`

## C. elegans GTF file
To get the GTF file, an annotation file that specifies where genes and other genomic elements start and end within the genome, I went to Ensembl's FTP page and found that the *C. elegans* GTFs are stored under https://ftp.ensembl.org/pub/current_gtf/caenorhabditis_elegans/Caenorhabditis_elegans.WBcel235.112.gtf.gz. I navigated to my *C. elegans* genome folder and downloaded the file with

```bash
wget  https://ftp.ensembl.org/pub/current_gtf/caenorhabditis_elegans/Caenorhabditis_elegans.WBcel235.112.gtf.gz
```

For the relatively small *C. elegans* genome, this took all of 1 minute. I then unzipped it with pigz:

```bash
pigz -d Caenorhabditis_elegans.WBcel235.112.gtf.gz
```


## STAR index for C. elegans

I tried to prepared the STAR index for C. elegans using
```bash
STAR --runThreadN 6 --runMode genomeGenerate --genomeDir /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/STAR_index_C_elegans --genomeFastaFiles /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna --sjdbGTFfile /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/Caenorhabditis_elegans.WBcel235.112.gtf --sjdbOverhang 149
```

but got an error saying something is not right with the GTF file: "Fatal INPUT FILE error, no valid exon lines in the GTF file: /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/Caenorhabditis_elegans.WBcel235.112.gtf
Solution: check the formatting of the GTF file. One likely cause is the difference in chromosome naming between GTF and FASTA file."

As I learned from the Harvard Chan Bioinformatics Core [course on RNA-Seq](https://github.com/hbctraining/Intro-to-rnaseq-hpc-salmon-flipped/blob/main/lectures/alignment_quantification.pdf),  I need to use the GFF file from NCBI instead, or, at the very least, rename the chromosomes in the GTF files so that they have the same names as they do in the genome. GTF files and genomic files need to be not only from the same build of the genome (so mm10, hg38, etc) but also from the same source, such as NCBI or Ensembl, because the different databases have somewhat different ways of formatting the names of elements in their genomes, such as the names of chromosomes.  

So I got the GTF file from NCBI with `wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/985/GCF_000002985.6_WBcel235/GCF_000002985.6_WBcel235_genomic.gtf.gz`, then unzipped it with `pigz`.  I then repeated the index creation using the GTF file from NCBI:

```bash
STAR --runThreadN 6 --runMode genomeGenerate --genomeDir /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/STAR_index_C_elegans --genomeFastaFiles /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna --sjdbGTFfile /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.gtf --sjdbOverhang 149
```

It worked, except for a warning: "!!!!! WARNING: --genomeSAindexNbases 14 is too large for the genome size=100286401, which may cause seg-fault at the mapping step. Re-run genome generation with recommended --genomeSAindexNbases 12" 

I looked in the STAR manual to gain a better understanding of why this is happening. Apparently, this is because the C. elegans genome is very small, hence the request to run the index generation again with this parameter set to 12. So I deleted all of the files that STAR generated for the index, and started afresh with:

```bash
STAR --runThreadN 6 --runMode genomeGenerate --genomeDir /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/STAR_index_C_elegans --genomeFastaFiles /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna --sjdbGTFfile /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.gtf --sjdbOverhang 149 --genomeSAindexNbases 12
```

And ta-da! Two minutes later, with no more warnings, I had the index, a set of files that total some 1.4 GB in size      ***insert meow_party smiley*** 


## Salmon index for C. elegans
I had less luck with finding a pre-assembled C. elegans Salmon (transcriptomic) index than I had with the mouse one, so I needed to build this index from scratch.

### Getting transcriptome file for C. elegans
For this, according to the Salmon manual, I need a file with all of the annotated C. elegans transcripts, so something with RNA or cDNA in the name. I went to NCBI's [genome FTP repository for C. elegans](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/985/GCF_000002985.6_WBcel235/) and found two files, called "[GCF_000002985.6_WBcel235_rna.fna.gz](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/985/GCF_000002985.6_WBcel235/GCF_000002985.6_WBcel235_rna.fna.gz)" and "[GCF_000002985.6_WBcel235_rna_from_genomic.fna.gz](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/985/GCF_000002985.6_WBcel235/GCF_000002985.6_WBcel235_rna_from_genomic.fna.gz)", 13 and 14 MB in size, respectively. Which one to use, though? I checked the [FTP FAQ page](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/policies-annotation/genomeftp/) of the NCBI, but the descriptions about the two files are not necessarily helpful. Since this is just a pilot experiment, I decided to go with the simple rna.fna.gz file and downloaded it with wget.

> [!TO DO:]
> clarify this for the future

### Getting dependencies for index building

#### MashMap
To create the index, the Salmon manual talks about two ways to build a so-called *decoy-aware* transcriptome, and, for that, it first needs to build something called a *decoy file*. To do so, it needs a tool called [MashMap](https://github.com/marbl/MashMap.git).  I already had GCC and g++, which are needed for compiling the MashMap binaries, but didn't have cmake. 

##### cmake
To get an installation script, I ran 

`wget https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2-linux-x86_64.sh`

 then set the script to executable with `chmod u+x`, ran it with `./cmake-3.30.2-linux-x86_64.sh`, and added the path to the newly created binaries file to my PATH variable in .bashrc. I could then call it from the command line.

##### GNU GSL
MashMap also needs the GNU GSL tool, which I got in its latest stable version, 2.8, from https://www.gnu.org/software/gsl/ as a tar archive, and immdiately unpacked it. I went to the folder that generated, ran `./configure` to read my system properties, `make` to make a configuration suited to my system, which...took a moment, and many lines of code running in the background. It ended with the lines "`make[2]: Leaving directory '/home/iweber/Documents/Software/gsl-2.8'
`make[1]: Leaving directory '/home/iweber/Documents/Software/gsl-2.8`, and, finally, `sudo make install` to run the installation program that was just compiled. I now have access to `gsl-config --version`, for instance :) The binary is in /usr/local/bin, so I did not need to add it to my PATH variable.

##### Building MashMap
I downloaded MashMap from its git repository with `git clone https://github.com/marbl/MashMap.git` and went into the newly-created directory. Then, as per the [instructions](https://github.com/marbl/MashMap/blob/master/INSTALL.txt) on MashMap's GitHub repo, typed `cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Release` and then `cmake --build build`. This is what I got:

![[2024-08-08_MashMap_build_success.png]]

Looking into the MashMap folders, I saw a /bin folder and added it to my PATH variable, and now I can call it from the command line.

#### Get BedTools

Got the archive with 

`wget https://github.com/arq5x/bedtools2/releases/download/v2.31.1/bedtools-2.31.1.tar.gz` and unpacked it with `tar -vxzf`. I changed into the bedtools2 folder and compiled it with `make`. I got an error ending with 
```
cram/cram_io.c:57:10: fatal error: bzlib.h: No such file or directory
   57 | #include <bzlib.h>
      |          ^~~~~~~~~
compilation terminated.
make[1]: *** [Makefile:103: cram/cram_io.o] Error 1
make[1]: Leaving directory '/home/iweber/Documents/Software/bedtools2/src/utils/htslib'
make: *** [src/utils/htslib/htslib.mk:153: src/utils/htslib/libhts.a] Error 2```
```

So I knew I had to get this bzlib. I tried with
```bash
sudo apt-get update
sudo apt-get install libbz2-dev
```

and it seems to have worked. Even though it increased my anxiety when I saw it was also getting something related to CUDA...no error messages or warnings in the end.

I cleaned up the previous build with `make clean`, restarted my terminal, and restarted the build with `make`. And got the same issue but for a different library, lzma.h. Got annoyed, cleaned the build, and, as per the[ installation page of bedtools](https://bedtools.readthedocs.io/en/latest/content/installation.html), decided to just go with a pre-compiled version, which I got using `sudo apt-get install bedtools`, which worked like a charm and installed it into my user binaries (/usr/bin/, as I found out with `which bedtools.


### Building the decoys for *C. elegans*
#### Get SalmonTools

To create the decoys, I got  SalmonTools from GitHub with `git clone https://github.com/COMBINE-lab/SalmonTools.git` and went into the newly created directory, SalmonTools. ChatGPT advised to make a separate directory for building the compiled tool, so I did with `mkdir build` and changed into it. I configured the build with `cmake ..`, and then made it with `make`. It was indeed made, but with quite some errors:

```bash
[  7%] Creating directories for 'libspdlog'
[ 15%] Performing download step for 'libspdlog'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100  147k    0  147k    0     0   121k      0 --:--:--  0:00:01 --:--:--  922k
spdlog-v0.12.0.tar.gz: OK
[ 23%] No update step for 'libspdlog'
[ 30%] No patch step for 'libspdlog'
[ 38%] No configure step for 'libspdlog'
[ 46%] No build step for 'libspdlog'
[ 53%] Performing install step for 'libspdlog'
[ 61%] Completed 'libspdlog'
[ 61%] Built target libspdlog
[ 69%] Building CXX object src/CMakeFiles/salmon_tools_core.dir/FastxParser.cpp.o
[ 76%] Building CXX object src/CMakeFiles/salmon_tools_core.dir/ExtractUnmapped.cpp.o
In file included from /home/iweber/Documents/Software/SalmonTools/include/zstr.hpp:16,
                 from /home/iweber/Documents/Software/SalmonTools/src/ExtractUnmapped.cpp:10:
/home/iweber/Documents/Software/SalmonTools/include/strict_fstream.hpp: In static member function ‘static void strict_fstream::detail::static_method_holder::check_peek(std::istream*, const string&, std::ios_base::openmode)’:
/home/iweber/Documents/Software/SalmonTools/include/strict_fstream.hpp:128:39: warning: catching polymorphic type ‘class std::ios_base::failure’ by value [-Wcatch-value=]
  128 |         catch (std::ios_base::failure e) {}
      |                                       ^
/home/iweber/Documents/Software/SalmonTools/src/ExtractUnmapped.cpp: In function ‘void ExtractUnmapped(const string&, std::vector<std::__cxx11::basic_string<char> >::const_iterator, std::vector<std::__cxx11::basic_string<char> >::const_iterator)’:
/home/iweber/Documents/Software/SalmonTools/src/ExtractUnmapped.cpp:210:18: warning: catching polymorphic type ‘class args::Help’ by value [-Wcatch-value=]
  210 |     catch (args::Help)
      |                  ^~~~
/home/iweber/Documents/Software/SalmonTools/src/ExtractUnmapped.cpp:215:29: warning: catching polymorphic type ‘class args::ParseError’ by value [-Wcatch-value=]
  215 |     catch (args::ParseError e)
      |                             ^
In file included from /home/iweber/Documents/Software/SalmonTools/src/ExtractUnmapped.cpp:8:
/home/iweber/Documents/Software/SalmonTools/include/sparsepp/spp.h: In instantiation of ‘void spp::sparsetable<T, Alloc>::resize(spp::sparsetable<T, Alloc>::size_type) [with T = std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >; Alloc = spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > >; spp::sparsetable<T, Alloc>::size_type = long unsigned int]’:
/home/iweber/Documents/Software/SalmonTools/include/sparsepp/spp.h:2942:25:   required from ‘void spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::_move_from(spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::MoveDontCopyT, spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>&, spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::size_type) [with Value = std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >; Key = std::__cxx11::basic_string<char>; HashFcn = spp::spp_hash<std::__cxx11::basic_string<char> >; ExtractKey = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::SelectKey; SetKey = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::SetKey; EqualKey = std::equal_to<std::__cxx11::basic_string<char> >; Alloc = spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > >; spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::size_type = long unsigned int]’
/home/iweber/Documents/Software/SalmonTools/include/sparsepp/spp.h:3093:9:   required from ‘spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::sparse_hashtable(spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::MoveDontCopyT, spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>&, spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::size_type) [with Value = std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >; Key = std::__cxx11::basic_string<char>; HashFcn = spp::spp_hash<std::__cxx11::basic_string<char> >; ExtractKey = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::SelectKey; SetKey = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::SetKey; EqualKey = std::equal_to<std::__cxx11::basic_string<char> >; Alloc = spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > >; spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::size_type = long unsigned int]’
/home/iweber/Documents/Software/SalmonTools/include/sparsepp/spp.h:2881:26:   required from ‘bool spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::_resize_delta(spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::size_type) [with Value = std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >; Key = std::__cxx11::basic_string<char>; HashFcn = spp::spp_hash<std::__cxx11::basic_string<char> >; ExtractKey = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::SelectKey; SetKey = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::SetKey; EqualKey = std::equal_to<std::__cxx11::basic_string<char> >; Alloc = spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > >; spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::size_type = long unsigned int]’
/home/iweber/Documents/Software/SalmonTools/include/sparsepp/spp.h:3413:21:   required from ‘spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::value_type& spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::find_or_insert(const key_type&) [with DefaultValue = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::DefaultValue; Value = std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >; Key = std::__cxx11::basic_string<char>; HashFcn = spp::spp_hash<std::__cxx11::basic_string<char> >; ExtractKey = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::SelectKey; SetKey = spp::sparse_hash_map<std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >::SetKey; EqualKey = std::equal_to<std::__cxx11::basic_string<char> >; Alloc = spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > >; spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::value_type = std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >; spp::sparse_hashtable<Value, Key, HashFcn, ExtractKey, SetKey, EqualKey, Alloc>::key_type = std::__cxx11::basic_string<char>]’
/home/iweber/Documents/Software/SalmonTools/include/sparsepp/spp.h:3933:57:   required from ‘spp::sparse_hash_map<Key, T, HashFcn, EqualKey, Alloc>::mapped_type& spp::sparse_hash_map<Key, T, HashFcn, EqualKey, Alloc>::operator[](const key_type&) [with Key = std::__cxx11::basic_string<char>; T = std::__cxx11::basic_string<char>; HashFcn = spp::spp_hash<std::__cxx11::basic_string<char> >; EqualKey = std::equal_to<std::__cxx11::basic_string<char> >; Alloc = spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > >; spp::sparse_hash_map<Key, T, HashFcn, EqualKey, Alloc>::mapped_type = std::__cxx11::basic_string<char>; spp::sparse_hash_map<Key, T, HashFcn, EqualKey, Alloc>::key_type = std::__cxx11::basic_string<char>]’
/home/iweber/Documents/Software/SalmonTools/src/ExtractUnmapped.cpp:117:31:   required from here
/home/iweber/Documents/Software/SalmonTools/include/sparsepp/spp.h:2214:23: warning: ‘void* memcpy(void*, const void*, size_t)’ writing to an object of type ‘spp::sparsetable<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >, spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > > >::group_type’ {aka ‘class spp::sparsegroup<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >, spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > > >’} with no trivial copy-assignment; use copy-initialization instead [-Wclass-memaccess]
 2214 |                 memcpy(first, _first_group, sizeof(*first) * (std::min)(sz, old_sz));
      |                 ~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
In file included from /home/iweber/Documents/Software/SalmonTools/src/ExtractUnmapped.cpp:8:
/home/iweber/Documents/Software/SalmonTools/include/sparsepp/spp.h:1027:7: note: ‘spp::sparsetable<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >, spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > > >::group_type’ {aka ‘class spp::sparsegroup<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> >, spp::libc_allocator<std::pair<const std::__cxx11::basic_string<char>, std::__cxx11::basic_string<char> > > >’} declared here
 1027 | class sparsegroup
      |       ^~~~~~~~~~~
[ 84%] Linking CXX static library libsalmon_tools_core.a
[ 84%] Built target salmon_tools_core
[ 92%] Building CXX object src/CMakeFiles/salmontools.dir/SalmonTools.cpp.o
/home/iweber/Documents/Software/SalmonTools/src/SalmonTools.cpp: In function ‘int main(int, char**)’:
/home/iweber/Documents/Software/SalmonTools/src/SalmonTools.cpp:39:18: warning: catching polymorphic type ‘class args::Help’ by value [-Wcatch-value=]
   39 |     catch (args::Help) {
      |                  ^~~~
/home/iweber/Documents/Software/SalmonTools/src/SalmonTools.cpp:43:24: warning: catching polymorphic type ‘class args::Error’ by value [-Wcatch-value=]
   43 |     catch (args::Error e) {
      |                        ^
[100%] Linking CXX executable salmontools
[100%] Built target salmontools
```


#### Build decoys

I moved to the "scripts" folder in the main SalmonTools directory to find the script needed to build the decoys, "generateDecoyTranscriptome.sh". I gave myself execution privileges with `chmod u+x`.

To run the script, I used
```bash
cd /home/iweber/Documents/Software/SalmonTools/scripts/
./generateDecoyTranscriptome.sh -g /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna -t /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_rna.fna -a /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.gtf -m /home/iweber/Documents/Software/MashMap/build/bin/mashmap -b /usr/bin/bedtools -o /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/Salmon_decoys_C_elegans
```

This...kept not working. I got an error from MashMap saying

```bash
****************
*** getDecoy ***
****************
-g <Genome fasta> = /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna
-t <Transcriptome fasta> = /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_rna.fna
-a <Annotation GTF file> = /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.gtf
-m <mashmap binary> = /home/iweber/Documents/Software/MashMap/build/bin/mashmap
-b <bedtools binary> = /usr/bin/bedtools
-o <Output files Path> = /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/Salmon_decoys_C_elegans
[1/10] Extracting exonic features from the gtf
[2/10] Masking the genome fasta
[3/10] Aligning transcriptome to genome
/home/iweber/Documents/Software/MashMap/build/bin/mashmap: error while loading shared libraries: libgsl.so.28: cannot open shared object file: No such file or directory

***************
*** ABORTED ***
***************

An error occurred. Exiting...
```

Even after getting that library separately, knowing it's on my system with `find /usr -name "libgsl.so.28"` at `/usr/local/lib/libgsl.so.28`, adding that to my library PATH in .bashrc with `echo 'export LD_LIBRARY_PATH=/usr/local/lib/libgsl.so.28:$LD_LIBRARY_PATH' >> ~/.bashrc`, restarting the terminal, and re-building MashMap, it still would not find it and give the exact same error as above.

I then checked out this other [tutorial](https://combine-lab.github.io/alevin-tutorial/2019/selective-alignment/) from Salmon/Alevin, a tool that's part of Salmon. I tried a similar command to the suggested one:

```bash
grep "^>" GCF_000002985.6_WBcel235_rna.fna | cut -d " " -f 1 | sed 's/>//g' > decoys.txt
```
and got a text file, decoys.txt, filled with one NCBI transcript identifier per row (NM_...).

Then, I adapted the command for creating the second file, the concatenated transcriptome and genome reference file:

```bash
cat GCF_000002985.6_WBcel235_rna.fna GCF_000002985.6_WBcel235_genomic.fna | pigz > gentrome.fa.gz
```

### Building the decoy-aware transcriptome index for *C. elegans*


As on the [Alevin/Salmon tutorial page](https://combine-lab.github.io/alevin-tutorial/2019/selective-alignment/), I ran
```bash
salmon index -t gentrome.fa.gz -d decoys.txt -p 12 -i salmon_index --gencode
```

Which gave me many warnings identical to "[2024-08-08 14:09:10.141] [puff::index::jointLog] [warning] Entry with header [NR_131692.1], had length less than equal to the k-mer length of 31 (perhaps after poly-A clipping)" and one critical error saying "[2024-08-08 14:09:10.573] [puff::index::jointLog] [critical] Observed a non-decoy sequence [NC_003279.8] after having already observed a decoy. However, it is required that any decoy target records appear, consecutively, at the end of the input fasta file.  Please re-format your input file so that all decoy records appear contiguously at the end of the file, after all valid (non-decoy) records". 

This has something to do with the Note on the Alevin page mentioned above: "the genome targets (decoys) should come after the transcriptome targets in the reference"

I installed an app called Seqkit, which eases the handling of FastA and FastQ files (and a language it needs, Go: `sudo apt-get install golang`)
```bash
wget https://github.com/shenwei356/seqkit/releases/download/v2.8.2/seqkit_linux_amd64.tar.gz
tar -vxzf seqkit_linux_amd64.tar.gz
```
This immediately popped out the executable for seqkit, so I added the path to it to the PATH variable.

With Seqkit, I performed
```bash
seqkit grep -v -f decoys.txt gentrome.fa.gz -o non_decoy.fa
```
to extract the non-decoy information from the compressed file I created before (concatenated transcriptome and genome reference file), and

```bash
seqkit grep -f decoys.txt gentrome.fa.gz -o decoy.fa
```
to extract specifically the decoys.

To re-assemble the compressed file in the correct order, I ran
```bash
cat non_decoy.fa decoy.fa | pigz > gentrome_corrected.fa.gz
```

And then attempted to build the index with the corrected file:
```bash
salmon index -t gentrome_corrected.fa.gz -d decoys.txt -p 12 -i salmon_index
```
(I chose to remove the  --gencode option - the [Alevin/Salmon tutorial page](https://combine-lab.github.io/alevin-tutorial/2019/selective-alignment/) I got the command from says "NOTE: `--gencode` flag is for removing extra metdata in the target header separated by `|` from the gencode reference. You can skip it if using other references.", and I am using NCBI, not GENCODE references, so it should be safe? )

> [!To ask Ioana]
> ask if removing the GENCODE flag was indeed the correct move

The index creation took off at around 2:30 and mightily strained my CPU (~70% usage by the virtual machine, with occasional GPU use), but was done in less than 3 minutes, and I now have a folder called "salmon_index" at around 500 MB size.

> [!If pipeline doesn't work, figure out in more detail what's happening here]
> 
> 
> The index finished building with the messages
> "[2024-08-08 14:29:48.453] [puff::index::jointLog] [info] Replaced 0 non-ATCG nucleotides
>  [2024-08-08 14:29:48.453] [puff::index::jointLog] [info] Clipped poly-A tails from 22 transcripts wrote 37798 cleaned references [2024-08-08 14:29:51.446] [puff::index::jointLog] [info] Filter size not provided; estimating from number of distinct k-mers [2024-08-08 14:30:02.884] [puff::index::jointLog] [info] ntHll estimated 97277338 distinct k-mers, setting filter size to 2^31 Threads = 12 Vertex length = 31 Hash functions = 5 Filter size = 2147483648 Capacity = 2 Files: salmon_index/ref_k31_fixed.fa -------------------------------------------------------------------------------- Round 0, 0:2147483648 Pass Filling Filtering 1 6 16 2 3 1 True junctions count = 522768 False junctions count = 794481 Hash table size = 1317249 Candidate marks count = 4277706 -------------------------------------------------------------------------------- TBB Warning: The number of workers is currently limited to 5. The request for 11 workers is ignored. Further requests for more workers will be silently ignored until the limit changes. Reallocating bifurcations time: 0 True marks count: 2839486 Edges construction time: 165 -------------------------------------------------------------------------------- Distinct junctions = 522768 TwoPaCo::buildGraphMain:: allocated with scalable_malloc; freeing. TwoPaCo::buildGraphMain:: Calling scalable_allocation_command(TBBMALLOC_CLEAN_ALL_BUFFERS, 0); allowedIn: 15 Max Junction ID: 523362 seen.size():4186905 kmerInfo.size():523363 approximateContigTotalLength: 38939053 counters for complex kmers: (prec>1 & succ>1)=28528 | (succ>1 & isStart)=70 | (prec>1 & isEnd)=77 | (isStart & isEnd)=31 contig count: 779268 element count: 120440207 complex nodes: 28706 # of ones in rank vector: 779267 [2024-08-08 14:33:20.452] [puff::index::jointLog] [info] Starting the Pufferfish indexing by reading the GFA binary file. [2024-08-08 14:33:20.452] [puff::index::jointLog] [info] Setting the index/BinaryGfa directory salmon_index size = 120440207 ----------------------------------------- | Loading contigs | Time = 33 ms ----------------------------------------- size = 120440207 ----------------------------------------- | Loading contig boundaries | Time = 17.347 ms ----------------------------------------- Number of ones: 779267 Number of ones per inventory item: 512 Inventory entries filled: 1523 779267 [2024-08-08 14:33:20.629] [puff::index::jointLog] [info] Done wrapping the rank vector with a rank9sel structure. [2024-08-08 14:33:20.635] [puff::index::jointLog] [info] contig count for validation: 779,267 [2024-08-08 14:33:20.719] [puff::index::jointLog] [info] Total # of Contigs : 779,267 [2024-08-08 14:33:20.719] [puff::index::jointLog] [info] Total # of numerical Contigs : 779,267 [2024-08-08 14:33:20.729] [puff::index::jointLog] [info] Total # of contig vec entries: 2,890,699 [2024-08-08 14:33:20.729] [puff::index::jointLog] [info] bits per offset entry 22 [2024-08-08 14:33:20.765] [puff::index::jointLog] [info] Done constructing the contig vector. 779268 [2024-08-08 14:33:21.424] [puff::index::jointLog] [info] # segments = 779,267 [2024-08-08 14:33:21.424] [puff::index::jointLog] [info] total length = 120,440,207 [2024-08-08 14:33:21.437] [puff::index::jointLog] [info] Reading the reference files ... [2024-08-08 14:33:21.922] [puff::index::jointLog] [info] positional integer width = 27 [2024-08-08 14:33:21.922] [puff::index::jointLog] [info] seqSize = 120,440,207 [2024-08-08 14:33:21.922] [puff::index::jointLog] [info] rankSize = 120,440,207 [2024-08-08 14:33:21.922] [puff::index::jointLog] [info] edgeVecSize = 0 [2024-08-08 14:33:21.922] [puff::index::jointLog] [info] num keys = 97,062,197 for info, total work write each : 2.331 total work inram from level 3 : 4.322 total work raw : 25.000 [Building BooPHF] 100 % elapsed: 0 min 4 sec remaining: 0 min 0 sec Bitarray 508580416 bits (100.00 %) (array + ranks ) final hash 0 bits (0.00 %) (nb in final hash 0) [2024-08-08 14:33:25.534] [puff::index::jointLog] [info] mphf size = 60.6275 MB [2024-08-08 14:33:25.626] [puff::index::jointLog] [info] chunk size = 10,036,684 [2024-08-08 14:33:25.626] [puff::index::jointLog] [info] chunk 0 = [0, 10,036,684) [2024-08-08 14:33:25.626] [puff::index::jointLog] [info] chunk 1 = [10,036,684, 20,073,368) [2024-08-08 14:33:25.626] [puff::index::jointLog] [info] chunk 2 = [20,073,368, 30,110,075) [2024-08-08 14:33:25.626] [puff::index::jointLog] [info] chunk 3 = [30,110,075, 40,146,759) [2024-08-08 14:33:25.626] [puff::index::jointLog] [info] chunk 4 = [40,146,759, 50,183,443) [2024-08-08 14:33:25.626] [puff::index::jointLog] [info] chunk 5 = [50,183,443, 60,220,129) [2024-08-08 14:33:25.627] [puff::index::jointLog] [info] chunk 6 = [60,220,129, 70,256,813) [2024-08-08 14:33:25.627] [puff::index::jointLog] [info] chunk 7 = [70,256,813, 80,293,497) [2024-08-08 14:33:25.627] [puff::index::jointLog] [info] chunk 8 = [80,293,497, 90,330,181) [2024-08-08 14:33:25.627] [puff::index::jointLog] [info] chunk 9 = [90,330,181, 100,366,865) [2024-08-08 14:33:25.627] [puff::index::jointLog] [info] chunk 10 = [100,366,865, 110,403,549) [2024-08-08 14:33:25.627] [puff::index::jointLog] [info] chunk 11 = [110,403,549, 120,440,177) [2024-08-08 14:33:29.572] [puff::index::jointLog] [info] finished populating pos vector [2024-08-08 14:33:29.572] [puff::index::jointLog] [info] writing index components [2024-08-08 14:33:29.987] [puff::index::jointLog] [info] finished writing dense pufferfish index [2024-08-08 14:33:30.022] [jLog] [info] done building index ",
> 
> but I had a lot of warnings of the form 
> "R_131708.1], had length less than equal to the k-mer length of 31 (perhaps after poly-A clipping)",
> 
> and, at the end, the warnings 
> 
> "[2024-08-08 14:29:48.451] [puff::index::jointLog] [warning] Removed 221 transcripts that were sequence duplicates of indexed transcripts. [2024-08-08 14:29:48.451] [puff::index::jointLog] [warning] If you wish to retain duplicate transcripts, please use the `--keepDuplicates` flag [2024-08-08 14:29:48.451] [puff::index::jointLog] [warning] There were 221 duplicate decoy sequences.". 
> 
> I asked ChatGPT: where do these warnings come from, and is this index safe to use? Its answer was:
> 
> ### Understanding the Warnings During Salmon Indexing
> 
> The warnings you encountered during the Salmon indexing process provide information about potential issues or optimizations that Salmon performed on the input sequences. Let's break them down:
> 
> 1. **Warnings about Sequences Shorter than K-mer Length:**
>    - **Warning:** `R_131708.1], had length less than or equal to the k-mer length of 31 (perhaps after poly-A clipping)`
>    - **Explanation:** Salmon uses k-mers (subsequences of length 31 by default) to build its index. If a sequence is shorter than this k-mer length (or exactly equal to it), it cannot be effectively used in the indexing process. This often happens with very short sequences or those that are clipped due to poly-A tail removal. Salmon flags these sequences because they might not contribute useful information to the index.
>    - **Impact:** These sequences are ignored in the index, but this generally shouldn't be an issue unless these sequences are critical to your analysis. The fact that they are clipped or short suggests they might not be biologically significant or that their inclusion wouldn't provide meaningful quantification data.
> 
> 2. **Warnings about Duplicate Transcripts and Decoys:**
>    - **Warning:** `Removed 221 transcripts that were sequence duplicates of indexed transcripts.` and `There were 221 duplicate decoy sequences.`
>    - **Explanation:** During indexing, Salmon detected sequences that were exact duplicates either within the transcriptome or between the transcriptome and the decoy sequences. By default, Salmon removes these duplicates to avoid redundancy in the index.
>    - **Impact:** Removing duplicates typically optimizes the index by reducing its size and improving performance. However, if retaining these duplicates is important for your specific analysis, you can use the `--keepDuplicates` flag to prevent their removal.
> 
> ### Is the Index Safe to Use?
> 
> Given the details you provided, the index should generally be safe to use. The warnings indicate that Salmon performed optimizations by removing duplicates and ignoring sequences that couldn't be indexed due to their short length. These are standard procedures that should not negatively impact the majority of analyses.
> 
> However, consider the following:
> 
> - **Short Sequences:** If the sequences flagged for being shorter than the k-mer length are crucial to your research, you might want to review those sequences to ensure they are not important.
>   
> - **Duplicate Sequences:** If the presence of duplicate sequences (either in the transcriptome or decoys) is critical to your analysis, consider re-running the index with the `--keepDuplicates` flag.
> 
> ### Summary of Steps to Proceed:
> - **Proceed with the Current Index:** If the warnings do not raise concerns for your specific analysis, proceed with using the current index.
> - **Rebuild with Adjustments:** If you believe the short or duplicate sequences might be important, consider adjusting the Salmon command by including flags like `--keepDuplicates` and possibly revisiting the input FASTA files to ensure no critical sequences were removed.
> 
> You can now proceed with your analysis, but keep these considerations in mind if you encounter unexpected results or if the removed sequences were critical to your research objectives."

## Sample sheet and contrasts sheet


I, of course, still need the sample sheet and the contrast sheet for this experiment as well. I have reads from two samples, CHS_1063 and CHS_1109. I tried searching for their names to see what kind of experiment they stemmed from and couldn't find any info on the quick, so I will simply assume that CHS_1063 is "control" and CHS_1109 is "treatment".

Here's how the sample sheet looks like:
```
sample,fastq_1,fastq_2,strandedness,condition
CONTROL_REP1,CHS_1063_R1.fastq.gz,CHS_1063_R2.fastq.gz,reverse,CONTROL
TREATMENT_REP1,CHS_1109_R1.fastq.gz,CHS_1109_R1.fastq.gz,reverse,TREATMENT
```

And the contrasts sheet:
```
contrast,treatment,control
TREATMENT_CONTROL,TREATMENT,CONTROL
```


## Running pipeline for the *C. elegans* data

To run it for the C. elegans data, I will use
```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 
--input /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/samplesheet_C_elegans.csv 
--contrasts /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/contrastssheet_C_elegans.csv

--fasta /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna
~~--gtf /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/Caenorhabditis_elegans.WBcel235.112.gtf~~ # NO. USE GFF INSTEAD, because it's for sure from NCBI as well.
--gff /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/

--save-trimmed true # to save the reads after trimming

--aligner star_salmon
--star_index /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/STAR_index_C_elegans/
--salmon_index /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/salmon_index/

--save-unaligned true # to save, if possible, any reads that couldn't be aligned in the results directory for later inspection
--save-align-intermeds # to save BAM files separately

--rmats true # to run rMATS part of pipeline
--outdir p/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/Nextflow_results_test_pipeline/ 
-profile docker
```

In compact form:
```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 --input /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/samplesheet_C_elegans.csv --contrasts /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/contrastssheet_C_elegans.csv --fasta /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna --gff /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.gff --save-trimmed true --aligner star_salmon --star_index /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/STAR_index_C_elegans/ --salmon_index /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/salmon_index/ --save-unaligned true --save-align-intermeds true --rmats true --outdir p/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/Nextflow_results_test_pipeline/ -profile docker
```

I had to run the pipeline with sudo, likely because the data and workflow are located in my inter-OS shared folder. I got some errors saying "ERROR ~ .nextflow/plr/9b802ca2-0d20-4b86-8169-d1dc8af33a6e/nf-validation-1.1.3: Operation not supported",  [suggesting that it cannot create so-called symlinks](https://github.com/nf-core/fetchngs/issues/272), and that may be due to the owner of the inter-OS folder being root, not my user. That didn't fix it, so I had to run the pipeline in my regular Documents folder in the Ubuntu OS, which then did run.

The pipeline ran for a moment and then, predictably, crashed :)

The first time when it crashed, I got an error . Some research in the GitHub issues of Nextflow revealed that this likely has something to do with Nextflow not being able to create 

It took me a fine moment to scroll through all of the output to the end and see the error...
![[2024-08-08_first_pilot_pipeline_run_9.png]]

Embarassing, but true: I had created the sample sheet for this pilot experiment in Notepad++ and forgot to hit save after changing the file names to the ones from the C. elegans experiment ***insert monkey covering its eyes smiley*** I hit save, and ran the same command again....

(Now, the .csv samplesheet looks as such:

```
sample,fastq_1,fastq_2,strandedness,condition
CONTROL_REP1,/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/Fastq_original_C_elegans/CHS_1063_R1.fastq.gz,/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/Fastq_original_C_elegans/CHS_1063_R2.fastq.gz,reverse,CONTROL
TREATMENT_REP1,/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/Fastq_original_C_elegans/CHS_1109_R1.fastq.gz,/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/Fastq_original_C_elegans/CHS_1109_R2.fastq.gz,reverse,TREATMENT
```

)

The next error on the line was "ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:FASTQ_FASTQC_UMITOOLS_TRIMGALORE:TRIMGALORE (CONTROL_REP1)'

Caused by:
  Process requirement exceeds available CPUs -- req: 12; avail: 6


Command executed:

  [ ! -f  CONTROL_REP1_1.fastq.gz ] && ln -s CHS_1063_R1.fastq.gz CONTROL_REP1_1.fastq.gz
  [ ! -f  CONTROL_REP1_2.fastq.gz ] && ln -s CHS_1063_R2.fastq.gz CONTROL_REP1_2.fastq.gz
  trim_galore \
      --fastqc \
      --cores 8 \
      --paired \
      --gzip \
      CONTROL_REP1_1.fastq.gz \
      CONTROL_REP1_2.fastq.gz
  
  cat <<-END_VERSIONS > versions.yml
  "NFCORE_RNASPLICE:RNASPLICE:FASTQ_FASTQC_UMITOOLS_TRIMGALORE:TRIMGALORE":
      trimgalore: $(echo $(trim_galore --version 2>&1) | sed 's/^.*version //; s/Last.*$//')
      cutadapt: $(cutadapt --version)
  END_VERSIONS

Command exit status:
  -

Command output:
  (empty)

Work dir:
  /home/iweber/Documents/work/28/40f5dd10796fb6d7bf9a03cf39569b

Tip: you can replicate the issue by changing to the process work dir and entering the command `bash .command.run`

 -- Check '.nextflow.log' file for details
"

This clearly says that, normally, the pipeline would try to use 12 cores, and I only have 6 available on my virtual machine. Therefore, I need to limit the number of cores for all processes using `--max_cpus 6`:

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 --input /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/samplesheet_C_elegans.csv --contrasts /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/contrastssheet_C_elegans.csv --fasta /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna --gff /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.gff --save-trimmed true --aligner star_salmon --star_index /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/STAR_index_C_elegans/ --salmon_index /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/salmon_index/ --save-unaligned true --save-align-intermeds true --rmats true --outdir p/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/Nextflow_results_test_pipeline/ --max-cpus 6 -profile docker 
```

This did not work, raising the exact same error as before. I read on [Nextflow's website that this means I will have to modify its configuration files](https://www.nextflow.io/docs/latest/config.html), and, since the page relates to the latest version of the program, I figured that, before that, I'd rather heed its warning to update the software in its entirety (when running the pipelines, it kept telling me I'm running a version 3 versions older than the current one, 24.04). I used `sudo nextflow self-update`, and it worked. 

### Configuration to use fewer cores

Nextflow has a basic configuration file, but can use customized configuration files as well to get parameters for how it runs pipelines. 

In the so-called scopes, Nextflow can get grouped info about the variables related to a certain topic. For example, there is a scope/group of variables pertaining specifically controls [conda-related variables](https://www.nextflow.io/docs/latest/config.html#scope-conda) when running the pipeline in conda. However, what I am likely needing are the variables related to the [executor scope](https://www.nextflow.io/docs/latest/config.html#scope-executor). Specifically, I need to set `executor.cpus = 6` and `executor.memory = 94 GB`. There are other neat settings that only work on HPCs managed by, for example, the [SLURM](https://slurm.schedmd.com/documentation.html) resource manager, such as executor.perCpuMemAllocation.

I also noticed that Nextflow tried to run each workflow three times. This is likely set by executor.retry.maxAttempt, that has a default of 3. However, I'm pretty sure that, if my PC can't handle something in the first go, it also won't in the second or third, so I will set `executor.retry.maxAttempt = 1`.

What could also be interesting is the [timeline scope](https://www.nextflow.io/docs/latest/config.html#scope-timeline). Here, one can ask for an execution timeline file to be generated with ` timeline.enabled = true`, and that might give me more information 

So, to sum up, what I need to change is:
```Groovy
executor{
	$local{
		cpus = 6
		memory = '94 GB'
		retry.maxAttempt = 1
	}
}

timeline.enabled = true
```
( I could also write this in the dot notation as executor.$local.cpus = 6, but why type more :) 

Where does one find the configuration file of an nf-core pipeline, though? I checked here https://nf-co.re/docs/usage/getting_started/configuration (and I wish I had done sooner, I just saw now that there is the possibility to test pipelines with a minimal or large public dataset, using profile `test` or profile `test_full`). 

When looking for the config files, I remembered I had also seen some warnings related to invalid options: 

```
WARN: The following invalid input values have been detected:

* --save-trimmed: true
* --saveTrimmed: true
* --save-unaligned: true
* --saveUnaligned: true
* --save-align-intermeds: true
* --saveAlignIntermeds: true
* --max-cpus: 6
* --maxCpus: 6
```

For some reason, some of the underscores in the options have been replaced by regular dashes! So there's actually no need to tinker with the configuration file, just to use the correct parameter names **facepalm**

I restarted the pipeline at 8:54 with:

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 --input /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/samplesheet_C_elegans.csv --contrasts /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/contrastssheet_C_elegans.csv --fasta /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna --gff /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.gff --save_trimmed true --aligner star_salmon --star_index /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/STAR_index_C_elegans/ --salmon_index /mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Genomes/genome_C_elegans/salmon_index/ --save_unaligned true --save_align_intermeds true --rmats true --outdir p/mnt/mnt-win-ubu-shared/Win_Ubuntu_shared/Pipeline_test_C_elegans/Nextflow_results_test_pipeline/ --max_cpus 6 -profile docker 
```

It ran for around half an hour and failed at the edgeR step, I believe because of the GTF annotation file (GCF_000002985.6_WBcel235_genomic.gtf).  The error message said:

```Groovy
ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:EDGER_DEU:SUBREAD_FLATTENGTF (GCF_000002985.6_WBcel235_genomic.gtf)'

Caused by:
  Process `NFCORE_RNASPLICE:RNASPLICE:EDGER_DEU:SUBREAD_FLATTENGTF (GCF_000002985.6_WBcel235_genomic.gtf)` terminated with an error exit status (1)


Command executed:

  flattenGTF -t exon -g gene_id -C -a GCF_000002985.6_WBcel235_genomic.gtf -o annotation.saf
  
  cat <<-END_VERSIONS > versions.yml
  "NFCORE_RNASPLICE:RNASPLICE:EDGER_DEU:SUBREAD_FLATTENGTF":
      subread: $( echo $(flattenGTF -v 2>&1) | sed -e "s/flattenGTF v//g")
  END_VERSIONS

Command exit status:
  1

Command output:
  (empty)

Command error:
  Unable to find image 'quay.io/biocontainers/subread:2.0.1--hed695b0_0' locally
  2.0.1--hed695b0_0: Pulling from biocontainers/subread
  1dbcab28ce46: Already exists
  cfb1ba34637d: Already exists
  ace2d8a63dd5: Already exists
  75c080ef15eb: Already exists
  316957f8baaf: Already exists
  dbd31e1d863d: Already exists
  2f8531d5a6ec: Already exists
  1dbcab28ce46: Already exists
  2e178fd72baf: Already exists
  2912e793bf3d: Pulling fs layer
  2912e793bf3d: Download complete
  2912e793bf3d: Pull complete
  Digest: sha256:ccee1f6ebb924fd0b3b6db646a51dabc905697aa25be132386dd490c2318286c
  Status: Downloaded newer image for quay.io/biocontainers/subread:2.0.1--hed695b0_0
  
  Flattening GTF file: GCF_000002985.6_WBcel235_genomic.gtf
  Output SAF file: annotation.saf
  
  Looking for 'exon' features... (grouped by 'gene_id')
  
  
  ERROR: failed to find the gene identifier attribute in the 9th column of the provided GTF file.
  The specified gene identifier attribute is 'gene_id'.
  An example of attributes included in your GTF annotation is 'transcript_id "id-CELE_T22C1.13"; gene_name "mir-8209";'.
  The program has to terminate.
  
  ERROR: Unable to open the GTF file.

Work dir:
  /home/iweber/work/b5/5edcfd637a9a3d52ac7d2a792c1227

Tip: you can replicate the issue by changing to the process work dir and entering the command `bash .command.run`

 -- Check '.nextflow.log' file for details
````


### Fixing GTF file?

I also saw a message saying "unable to open the GTF file" above. To address this, I decided to copy the contents of my Genomes folder into my Documents folder so that Nextflow can run without any further issues of not being able to create symlinks or opening files.

I used my tried and tested friend, [FreeFileSync](https://freefilesync.org/) (open source, with nice perks upon donation of any amount).

I tried running the pipeline with the GTF file instead of GFF

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
-w /home/iweber/Documents/Backup_shared_folder/Pipeline_test_C_elegans/ \
--outdir /home/iweber/Documents/Backup_shared_folder/Pipeline_test_C_elegans/Nextflow_results_test_pipeline/ \
--input /home/iweber/Documents/Backup_shared_folder/Pipeline_test_C_elegans/samplesheet_C_elegans.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pipeline_test_C_elegans/contrastssheet_C_elegans.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.fna \
--gtf /home/iweber/Documents/Backup_shared_folder/Genomes/genome_C_elegans/GCF_000002985.6_WBcel235_genomic.gtf \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_C_elegans/STAR_index_C_elegans \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_C_elegans/salmon_index \
--save_unaligned true \
--save_align_intermeds true \
--rmats true \
-profile docker 
```

Annnd it still didn't work. BUT. Knowing that the pipeline works in principle, I think I can now move on with my main mouse pipeline.



> [!In case still needed:]
> So, how do I need to modify the GTF file to continue?
> 
> I found this [Biostars thread](https://www.biostars.org/p/432735/) that shares several possible solutions (also, the problem is apparently in featureCounts, not edgeR).
> 
> The first (and easiest) proposed solution is to remove any empty fields in the gene_id columns.


# Running pipeline for actual experiment

## Pigz compression of FastQ files

I used the script mentioned [[#**Gzipping FastQ files for pipeline with pigz**]] with minor alterations for the new location: /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/

```bash
gzip_several_fastqs.sh                                                                                                            
#!/bin/bash

# Specify directory containing FASTQ files
DIRECTORY="/mnt-win-ubu-shared/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq"

# Find all .fastq files in the specified directory and subdirectories. Write line by line, pipe each line with one file name into while loop that compresses it.
find "$DIRECTORY" -type f -name "*.fastq" | while read -r FILE; do
  echo "Compressing $FILE"
  gzip "$FILE"
done
```

It completed successfully, and now I have .fastq.gz files instead of the FastQ ones. I also updated the sample sheet:

```cs
sample,fastq_1,fastq_2,strandedness,condition
CONTROL_REP1,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761520_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761520_1.fastq.gz,reverse,CONTROL
CONTROL_REP2,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761521_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761521_2.fastq.gz,reverse,CONTROL
CONTROL_REP3,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761522_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761522_2.fastq.gz,reverse,CONTROL
CONTROL_REP4,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761523_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761523_2.fastq.gz,reverse,CONTROL
PREECLAMPSIA_REP1,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761524_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761524_2.fastq.gz,reverse,PREECLAMPSIA
PREECLAMPSIA_REP2,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761525_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761525_2.fastq.gz,reverse,PREECLAMPSIA
PREECLAMPSIA_REP3,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761526_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761526_2.fastq.gz,reverse,PREECLAMPSIA
PREECLAMPSIA_REP4,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761527_1.fastq.gz,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/SRR13761527_2.fastq.gz,reverse,PREECLAMPSIA
```


## Unzipping .tgz Salmon index and BSOD

I realized that the Salmon index I had downloaded for the mouse was still stored as a .tgz archive, and I started unpacking it with the usual `tar -vxzf` command. I am not sure if it was connected, but, at some point in the process, my PC crashed with a BSOD. This time, space was not the issue - I still have 458 GB free on the partition I allotted to the virtual machine, and I can't believe the index is that large (compressed, it was around 12 GB, so I suspect it will be at most around 50 GB unzipped).

I made backups of everything:

1. restore points for ~~Windows OS partition, VM partition, and data drive~~
2. ~~File History~~
3. Windows recovery drive
4. Folder backups external HDD

I also changed the VM settings:
- Hardware -> Processors: for reasons I can't explain (probably transferred from VirtualBox), I had these options set to 6 processors and 1 core per processor. However, in reality, I have only 1 processor, the one from my laptop, with its 8 cores and 16 threads, so I set the options to "Number of processors: 1" and "Number of cores per processor: 6"
- Options -> Advanced -> activated "Log virtual machine progress periodically"
- Display -> Graphics memory: downsized max amount of guest memory that can be used for graphics memory from 8 GB to 4 GB
- 

In general VM settings ( Edit -> Preferences):
- Memory -> Additional memory: activated "fit all virtual machine memory into reserved host RAM"
- Memory -> Reserved memory: downsized from 114432 MB to 98000 MB (98 GB)

Things I DID NOT change yet, because they seem too risky to my beginner mind:
- there is a possibility to limit the number of disk input/output operations to prevent the VM from overwhelming the disk it operates on (which, in this case, is the same disk that my Windows host is running on - I really should get a second ultrafast 2+ TB SSD and move it to this one...). This would involve changing the virtual machine's .vmx file and adding a line to limit the operations (disk.maxIOPS = "500")

I tried unzipping the file again with the new settings: `tar -vxzf` and it worked! No more BSOD, and I now have a folder called "default" with all of the index components. 


## Pipeline parameters

### Initial
I changed:
- --max_memory 90GB to make sure the pipeline leaves 5 GB for Ubuntu to run properly (apparently, [Linux needs far less RAM than Windows](https://raspberrytips.com/how-much-ram-for-ubuntu/) - I know this being news to me probably makes the Linux pros smile and go "aww!" :) )
- to cap Nextflow resource usage overall and be on the safe side, I followed the instructions from the [rnasplice parameters page](https://nf-co.re/rnasplice/1.0.4/docs/usage/#running-the-pipeline) and added to my .bashrc file: `NXF_OPTS='-Xms1g -Xmx4g'
- `--save_reference true`  saves anything the pipeline downloads by itself, e.g. STAR indices, so that they can be re-used in further runs

To be sure-sure I am working in the work folder I want to set:
```bash
cd /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/
```

Activate the Nextflow conda environment:
```bash
conda activate Nextflow
```

Actual pipeline parameters
```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gtf /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gtf \
--clip_R1 10 \
--clip_R2 10 \
--stringency 5 \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--sjdb_overhang 149 \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/correct_Salmon_index_M_musculus_mm10/default \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker 
```

IF NEEDED LATER: `-resume [run_name]` to not repeat already finalized analysis steps! [Documentation for -resume](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html) Also see [here](https://www.nextflow.io/blog/2022/caching-behavior-analysis.html): " Nextflow generates a unique task hash, e.g. 22/7548fa… for each task in a workflow. The hash takes into account the complete file path, the last modified timestamp, container ID, content of script directive among other factors. If any of these change, the task will be re-executed. Nextflow maintains a list of task hashes for caching and traceability purposes.". Here's the complete list of things that factor into resuming: [caching and resuming](https://www.nextflow.io/docs/latest/cache-and-resume.html)


I immediately saw the warning: 

```bash
WARN: The following invalid input values have been detected:

* --clip_R1: 10
* --clip_R2: 10
* --stringency: 5
* --sjdb_overhang: 149
```





So I suppose TrimGalore and STAR don't take the values for these parameters from the CLI - I'd probably need to modify the nextflow.config file directly to achieve this.

> [!If still needed later]
> Easy fix for the clipping (I mis-wrote the Rs as capital R instead of minuscule):
> --clip_r1 10
> --clip_r2 10

And I got the first error: 
```bash
ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)'

Caused by:
  Process `NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)` terminated with an error exit status (1)


Command executed:

  gffread --table transcript_id,gene_id,gene_name GCF_000001635.27_GRCm39_genomic.gtf | sort -u 1> GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
  
  cat <<-END_VERSIONS > versions.yml
  "NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:GFFREAD_TX2GENE":
      gffread: $(gffread --version 2>&1)
  END_VERSIONS

Command exit status:
  1

Command output:
  (empty)

Command error:
  Error: no valid ID found for GFF record
```

This one's new and not encountered when trying to run the pipeline on the C. elegans data. This seems, once more, to be an issue due to differences between versions of the GTF format. As I also can get the gff file for the GRCm39 from [the NCBI FTP](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/635/GCF_000001635.27_GRCm39/), I will attempt to run the pipeline using this one instead of the GTF file.

### GFF instead of GTF
I used `wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/635/GCF_000001635.27_GRCm39/GCF_000001635.27_GRCm39_genomic.gff.gz` to get the file, and `pigz -d GCF_000001635.27_GRCm39_genomic.gff.gz to decompress it.

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--clip_R1 10 \
--clip_R2 10 \
--stringency 5 \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--sjdb_overhang 149 \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/correct_Salmon_index_M_musculus_mm10/default \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker 
```
Started around 15:15.

### Slow progress and crash/shutdown by Windows

Around 18:15, TrimGalore was about to end. I saw that I had around 300 GB still free on the VM partition, and started to worry that it might fill and crash the partition if it manages to get to the STAR and Salmon part of the pipeline. So I synced the folder to my backup folder in OneDrive (yes, not the best backup solution most likely, but it works for now, since it's publicly available data) and...deleted anything but the mouse genome and the pre-eclampsia experiment files the shared inter-OS folder *insert sweat smiley* This now leaves 343 GB free on the partition for the virtual machine, and I dearly hope this will be sufficient to store all of the results from the analyses. I suddenly regret telling the pipeline to save alignment intermediate files such as SAM files...

Hmmm, at 19:24, the pipeline had still not finished the TrimGalore/FastQC part, and still saying: 42 processes waiting for input. However, looking in the results folder of trimgalore, I *am* seeing reads in fastq.gz format for all of the original fastq files, and the latest ones, judged by the "modified" time point, are from 18:21. It's been an hour since, and the pipeline does not seem to be progressing. Perhaps this is a good chance to stop it and re-start it, this time indicating to not save alignment intermediate files?

The results folder was, at 19:31, at 33,6 GB size. The "work" folder of Nextflow was 34 GB at 19:35.
This did not change around 9 PM, either (I checked over TeamViewer, Nextflow was showing the exact same thing as before, 42 processes later).

I let the pipeline work overnight, but, the next morning (15.8.), I realized that something had happened overnight and my PC had restarted itself. I don't know what crashed, but I can't even see the pipeline appear at all with `nextflow log`. In fact, I can't see any of the pipelines I ran yesterday, regardless of whether I call Nextflow from the conda environment I created specifically for it or from the base environment. The last pipelines that ran which I can see in the log are the C. elegans ones from 9.8.! BUT I can see them if I change into the work directory for the pre-eclampsia experiment xD (good to know!). My last pipeline was "awesome_jepsen" with the session ID d2143e7b-2e6a-41e4-850d-cb8af9596f82, which I can use to eventually resume the pipeline.


### Figuring out cause of shutdown
However, I also wanted to see what happened last night and why my PC was restarted, especially whether it crashed or just tried to update. I went to the Windows Event Viewer and went through the messages from last night.

Looks like my Windows system has been very busy. I have some potentially relevant warnings and error messages since yesterday evening from before the pipeline froze: 
- At 6 PM, TPM-WMI Event 1800 "A reboot is required before installing the update. Reason: 6". - At 1:43 AM, DistributedCOM, EventID 10010, "The server {9BA05972-F6A8-11CF-A442-00A0C90A8F39} did not register with DCOM within the required timeout." - At 1:44 AM, ServiceControlManager EventID 7043 "The Delivery Optimization service did not shut down properly after receiving a preshutdown control.", 
- At 1:48 AM, TPM-WMI EventID 1796 "The Secure Boot update failed to update a Secure Boot variable with error Secure Boot is not enabled on this machine.. For more information, please see https://go.microsoft.com/fwlink/?linkid=2169931" , 
- At 6 AM, EventID TPM-WMI EventID 1796 (as the one before). But I don't have anything with EventIDs 1074, 6008, or 41. The most I see is a 7034 from ServiceControlManager with the description "The System Update service terminated unexpectedly. It has done this 1 time(s)." 

- However, lots of things seem to have happened around 1:44 AM. In sequence, the messages start with 
- an error 7043 "The Delivery Optimization service did not shut down properly after receiving a preshutdown control.", 

- 6006 "The Event log service was stopped." ,
- 109 "The kernel power manager has initiated a shutdown transition. Shutdown Reason: Kernel API", 
- 13 "The operating system is shutting down at system time ‎2024‎-‎08‎-‎14T23:44:19.417683100Z.", 
- 12 "The operating system started at system time ‎2024‎-‎08‎-‎14T23:44:42.500000000Z." , 
- 20 "The last shutdown's success status was true. The last boot's success status was true.". 

What happened here? It looks like my Windows system tried to install some update related to TPM-WMI and restarted my system around 1:43 AM. 

About the messages in the event log, ChatGPT said:

> [!ChatGPT]
> The sequence of events you’ve provided indicates that your Windows system went through an unexpected or forced shutdown and reboot around 1:44 AM. Let’s break down what likely happened based on the event log messages:
> 
> 1. **TPM-WMI Events and Reboot Requirement (6 PM)**
> 
> - **Event 1800**: "A reboot is required before installing the update. Reason: 6."
> - This indicates that earlier in the evening, Windows identified that a reboot was necessary to complete some updates, likely related to TPM (Trusted Platform Module) or Secure Boot.
> 
> 3. **Service Control Manager Errors (1:44 AM)**
> 
> - **EventID 7043**: "The Delivery Optimization service did not shut down properly after receiving a preshutdown control."
> - **EventID 7031**: "The Autodesk Desktop Licensing Service service terminated unexpectedly."
> - **EventID 7034**: "The System Update service terminated unexpectedly."
> - These events suggest that Windows initiated a shutdown process at 1:44 AM, but certain services did not shut down properly or crashed. The "preshutdown control" refers to the command sent to services to gracefully stop before the system shuts down.
> 
> 5. **Kernel Power Shutdown Initiated (1:44 AM)**
> 
> - **EventID 109**: "The kernel power manager has initiated a shutdown transition. Shutdown Reason: Kernel API."
> - **EventID 13**: "The operating system is shutting down at system time ‎2024‎-‎08‎-‎14T23:44:19.417683100Z."
> - **EventID 12**: "The operating system started at system time ‎2024‎-‎08‎-‎14T23:44:42.500000000Z."
> - These logs indicate that the kernel (core of the operating system) initiated a shutdown. The "Kernel API" reason suggests that this was not a user-initiated shutdown but likely caused by an internal system command or process (possibly related to the TPM/Secure Boot update).
> 
>  6. **System Reboot (1:44 AM)**
> 
> - The system logs show that the system successfully restarted shortly after shutting down at 1:44 AM.
> - **EventID 20**: "The last shutdown's success status was true. The last boot's success status was true."
> - This suggests that the shutdown and subsequent reboot were completed without errors, but the timing and the unexpected nature of the shutdown indicate it was likely triggered by an automated process, potentially related to updates.
> 
> **What Likely Happened**
> 
> - Your system was likely processing a critical update related to Secure Boot or TPM, as indicated by the TPM-WMI events. Windows required a reboot to complete these updates, and it seems that the system initiated this reboot automatically in the early hours of the morning.
> - The DistributedCOM error and service shutdown errors suggest that not all processes could cleanly stop before the shutdown, which is typical during an abrupt system shutdown.
> - The "Kernel API" shutdown reason indicates that this was likely an automated process rather than something you initiated manually.


To prevent any potential automated restarts by Windows, I changed my active hours to between 3 PM and 9 AM. I also paused updates until September 19th - hope this isn't a terrible idea.

### Reactivate 3D acceleration (GPU usage) by the VM

I hoped that changing this will make the pipeline running a lot faster, and hopefully prevent any further issues. However, I saw that the "accelerate 3D graphics" options 

I also changed the VM settings again: 
- Hardware -> Memory -> Memory for this virtual machine: lowered to 92500 MB (90.5 GB) to avoid memory swapping
- Hardware -> Processors: left as "Number of processors: 1" and "Number of cores per processor: 6"
- Hardware -> Display -> Graphics memory: increased max amount of guest memory back to 8 GB
- Options -> Advanced -> activated "Log virtual machine progress periodically"
 

In general VM settings ( Edit -> Preferences):
- Memory -> Additional memory: left "fit all virtual machine memory into reserved host RAM" activated
- Memory -> Reserved memory: left at 98000 MB (90.5 GB)

Things I still DID NOT change, because they seem too risky to my beginner mind:
- still did npt limit the number of disk input/output operations (disk.maxIOPS) 

### Pipeline re-run with GPU usage activated

To be sure-sure I am working in the work folder I want to set:
```bash
cd /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/
```

Activate the Nextflow conda environment:
```bash
conda activate Nextflow
```

I tried re-running the same pipeline as yesterday with `sudo nextflow run nf-core/rnasplice -r 1.0.4 -resume d2143e7b-2e6a-41e4-850d-cb8af9596f82`, but that did not actually restart the pipeline (it called it a different name, "magical_thompson", and gave an error about missing inputs, outdir, contrasts).

I tried to re-run the exact same command as yesterday, including the not-yet corrected parameters for clipping to be sure Nextflow correctly identifies it as the same pipeline, and appended `-resume d2143e7b-2e6a-41e4-850d-cb8af9596f82`.

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--clip_R1 10 \
--clip_R2 10 \
--stringency 5 \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--sjdb_overhang 149 \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/correct_Salmon_index_M_musculus_mm10/default \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume d2143e7b-2e6a-41e4-850d-cb8af9596f82
```

I am not sure if this resumed the exact same run. I now have a run called "intergalactic_woese". However, when looking at what Nextflow currently displays, I'm seeing what I saw last night as well:
![[2024-08-15_Pipeline_restart_1.png]]

This "Plus 33 more processes waiting for tasks" actually changed, but not for better: I could swear it was initially at "32 more", not 33!

But, while making the screenshot, I heard the ventilators ventilate hard, and, suddenly, the picture changed:
![[2024-08-15_Pipeline_progress.png]]
One of the "STAR" processes (09/389016) now has files associated with it, PREECLAMPSIA_REP2. The size of my "results" folder has now also increased to 39,8 GB!

At 12:38, the STAR process for the first file reached 12% (20 min) -> if the speed is constant, I'd need around 2.8 h per sample for it to complete. For 7 more samples, that's 20 hours more -> it'll likely need until tomorrow to finish. My best bet is to probably stop anything else that's particularly resource-intensive on both the host and the guest OS and let it do its job.

At 1:05, we're at 25% of a second sample, CONTROL_REP2! So, in around 50 min, we processed 125% of a file (yes, silly calculation) -> it took around 40 min to complete one sample. The size of the results folder jumped to 66 GB -> looking at around 20 GB per sample -> will need around 160 GB total solely for the SAM files resulting from STAR. It's good that my inter-OS shared folder is now entirely saved in OneDrive and on the other hard drive, because I could delete all of its non-git-related contents, so now I have 480 GB empty disk space for the VM to go nuts with.

What's also great, as for most Nextflow pipelines: it looks like some of the samples are also undergoing the quantification with Salmon now! (4th to last row)

![[2024-08-15_Pipeline_progress_2.png]]

The pipeline ran for some 3h30, and finished running the alignment with STAR (STAR_ALIGN), the sorting of the SAM files with Samtools (SAMTOOLS_SORT), the quantification of the BAM files produced by STAR using Salmon (SALMON_QUANT_STAR), and the [pseudomapping]***is this correct?*** and quantifcation with Salmon alone (SALMON_QUANT_SALMON). Many other smaller steps completed too, which, I'd wager, are genome-specific, since they seem to consist of only 1 step and not 8 (number of samples). 
![[2024-08-15_tximport_fail.png]]

Sadly, it failed due to an error stemming from ***tximport***. 

### tximport error with identifiers

The tximport error read:

```bash
Error in .local(object, ...) : 
    None of the transcripts in the quantification files are present
    in the first column of tx2gene. Check to see that you are using
    the same annotation for both.
  
  Example IDs (file): [ENSMUST00000196221.1, ENSMUST00000179664.1, ENSMUST00000177564.1, ...]
  
  Example IDs (tx2gene): [gene-Bod1-ps, gene-Btf3-ps10, gene-Btf3-ps11, ...]
  
    This can sometimes (not always) be fixed using 'ignoreTxVersion' or 'ignoreAfterBar'.
  
  Calls: <Anonymous> -> <Anonymous> -> .local
  Execution halted

Work dir:
  /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/f9/fa69fe2c73e138ff019c77f1df833e

Tip: when you have fixed the problem you can continue the execution adding the option `-resume` to the run command line

 -- Check '.nextflow.log' file for details

```

There's a thread relating to tximeta throwing a similar error: https://github.com/thelovelab/tximeta/issues/63 Something may be amiss with the metadata from NCBI that messes up how Salmon works with the annotations overall.

There is something potentially awry with the GFF file that makes these odd gene-Bod1-ps show up. I didn't want to tamper with the file I used for the pipeline in order to be able to resume the pipeline later, so I made a copy. I reasoned that, if I have these odd identifiers, they should sort before the usual NCBI transcript identifiers (NM_, NR_,...). So I sorted the file alphabetically, and displayed the first 100 rows:

```bash
sort GCF_000001635.27_GRCm39_genomic.gff | head -n 100
```

What I got was, to my understanding, a regular GFF format from RefSeq, and no sign of the odd identifiers:
![[2024-08-15_NCBI_GFF_file_contents_1.png]]

Next, I wanted to see what the tx2gene file contains. I went to the work folder I specified to Nextflow and searched for files with that pattern in their name:

```bash
(base) iweber@iweber-VirtualBox:~/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder$ sudo find -name "*tx2gene*"
[sudo] password for iweber: 
./fe/354fda8c110a2cfffb1588d5cf8ce6/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv # modified 14.8., 15:17
./a7/b0f3a354121a73f22dcc404dd0bce3/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv # modified 14.8., 15:18
./2a/be42ba8de16fcc5c20c7cbbd5075c9/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv # modified 14.8., 14:37
./f9/fa69fe2c73e138ff019c77f1df833e/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv # modified 14.8., 15:17
```


They indeed all contain these odd identifier names, such as the ones shown in the error ([gene-Bod1-ps](https://www.ncbi.nlm.nih.gov/gene/102637743), an existing pseudogene), but also others, like [Gene-Gm13602 ](https://www.ncbi.nlm.nih.gov/gene/?term=Gene-Gm13602)(a predicted gene).

When opened with LibreOffice, the files all contain 3 columns, which start at the top with 
"gene-Bod1-ps gene-Bod1-ps Bod1-ps 
gene-Btf3-ps10 gene-Btf3-ps10 Btf3-ps10 
gene-Btf3-ps11 gene-Btf3-ps11 Btf3-ps11 
gene-Btf3-ps3 gene-Btf3-ps3 Btf3-ps3 
gene-Btf3-ps4 gene-Btf3-ps4 Btf3-ps4 
gene-Btf3-ps6 gene-Btf3-ps6 Btf3-ps6 
gene-Btf3-ps7 gene-Btf3-ps7 Btf3-ps7 

gene-Btf3-ps8 gene-Btf3-ps8 Btf3-ps8 " and then, at some point, switch over to something more like 
"id-Igha gene-Igha Igha 
id-Ighd gene-Ighd Ighd
id-Ighd1-1 gene-Ighd1-1 Ighd1-1 
id-Ighd2-3 gene-Ighd2-3 Ighd2-3 
id-Ighd2-4 gene-Ighd2-4 Ighd2-4 
id-Ighd2-5 gene-Ighd2-5 Ighd2-5 
id-Ighd2-6 gene-Ighd2-6 Ighd2-6 
id-Ighd2-7 gene-Ighd2-7 Ighd2-7
...", 

then, 

"rna-AF357341 gene-AF357341 AF357341 
rna-AF357428 gene-AF357428 AF357428 
rna-ATP6 gene-ATP6 ATP6 
rna-ATP8 gene-ATP8 ATP8 
rna-COX1 gene-COX1 COX1 
rna-COX2 gene-COX2 COX2 
...
...
...
rna-Mir100 gene-Mir100 Mir100 
rna-Mir100-2 gene-Mir100 Mir100
rna-Mir101a gene-Mir101a Mir101a 
rna-Mir101a-2 gene-Mir101a Mir101a 
rna-Mir101b gene-Mir101b Mir101b 
..."


and, finally, the ones with regular NR NCBI identifiers: 
"rna-NM_001001130.3 gene-Zfp85 Zfp85 
rna-NM_001001144.3 gene-Scap Scap 
rna-NM_001001152.2 gene-Zfp458 Zfp458 
rna-NM_001001160.3 gene-Fbxo41 Fbxo41 
rna-NM_001001176.2 gene-Taf9b Taf9b 
rna-NM_001001177.2 gene-Tsbp1 Tsbp1 
rna-NM_001001178.2 gene-Ccdc148"

What is the cause of the tx2gene files containing these identifiers? Can I somehow avoid such identifiers in the creation of the annotations that Salmon needs for quantification so that they don't show up?

And: where do the ENSMUS (Ensembl) type of identifiers come from? In the [tximport error thread](https://bioinformatics.stackexchange.com/questions/4038/tx2gene-file-for-tximport-issue) I mentioned above, I noticed that the person had this type of identifier in their quant.sf file generated by Salmon, and I went looking for the quant.sf files that Salmon had produced for each of my 8 samples in the results folder. And look what I found:

![[2024-08-16_Salmon_identifiers.png]]

I never used any annotations from Ensembl, but it is possible that the Salmon index I downloaded for the mouse is based on Ensembl/GENCODE identifiers! Where is this stored? ChatGPT said it's the txpInfo.bin file, which I cannot directly look into because it's an executable in machine language. 

Which means that, sadly, my next step is to build the mouse Salmon index from scratch, using the same GFF file that goes into the pipeline, and then re-run the pipeline.

### Build new Salmon index for the mouse genome based on NCBI data

So, back to building Salmon indices: https://salmon.readthedocs.io/en/latest/salmon.html#preparing-transcriptome-indices-mapping-based-mode

Since I had previously built the C. elegans index ([[#Getting dependencies for index building]]) I have MashMap, I have bedtools, and SalmonTools. I went back to the other [tutorial](https://combine-lab.github.io/alevin-tutorial/2019/selective-alignment/) from Salmon/Alevin regarding how to create the decoys for the index to do the same for the mouse:

I first created the decoys from the NCBI mouse genome:

```bash
grep "^>" GCF_000001635.27_GRCm39_genomic.fna | cut -d " " -f 1 > decoys.txt
sed -i.bak -e 's/>//g' decoys.txt
```

and then had a file that looked like this:
![[2024-08-16_decoys_new_mouse_index.png]]

As I suspect this will cause similar issues as I had with the C. elegans decoys ([[#Building the decoy-aware transcriptome index for *C. elegans*]]) with warnings that involved having non-decoy sequences (NC_... ones) after decoy ones -> must make sure that all of the non-decoy sequences (chromosome identifiers and their sequences) appear **first** in the file, and **then** the real decoys (NT, NR, etc). This is also the case in the Fasta file I generated for C. elegans (gentrome_corrected.fa.gz), and the index building worked in this case. So let's sort the decoys.txt I just generated alphabetically:

```bash
sort decoys.txt > decoys_sorted.txt
```

I could now see that it consists of NC_, NT_, and NW_ sequences, in this order ([overview transcript identifiers from NCBI RefSeq](https://www.ncbi.nlm.nih.gov/books/NBK21091/table/ch18.T.refseq_accession_numbers_and_mole/?report=objectonly)). But how to make sure they are assembled in the correct order in the "gentrome" Fasta file (the concatenated transcriptome and genome reference file), aka decoys last? I don't know of an easy way to do so directly when creating this concatenated reference file, so I'll do it the same way as for C. elegans before.

I first got the rna.fna file for the mouse transcripts with `wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/635/GCF_000001635.27_GRCm39/GCF_000001635.27_GRCm39_rna.fna.gz` into the same directory with the rest of this genome assembly, and then unzipped it with `pigz -d GCF_000001635.27_GRCm39_rna.fna.gz`. Finally, I ran

```bash
cat GCF_000001635.27_GRCm39_rna.fna GCF_000001635.27_GRCm39_genomic.fna| pigz > gentrome.fa.gz
```

With Seqkit, I performed
```bash
seqkit grep -v -f decoys.txt gentrome.fa.gz -o non_decoy.fa
```
to extract the non-decoy information from the compressed file I created before (concatenated transcriptome and genome reference file), and

```bash
seqkit grep -f decoys.txt gentrome.fa.gz -o decoy.fa
```
to extract specifically the decoys.

To re-assemble the compressed file in the correct order, I ran
```bash
cat non_decoy.fa decoy.fa | pigz > gentrome_corrected.fa.gz
```

And then attempted to build the index with the corrected file:
```bash
salmon index -t gentrome_corrected.fa.gz -d decoys.txt -p 12 -i salmon_index
```

Half an hour later, I had the index ("NCBI_Salmon_index_M_musculus_mm10"), with very few warnings (streaks of red equals signs):

```bash
Version Info: This is the most recent version of salmon.
index ["salmon_index"] did not previously exist  . . . creating it
[2024-08-16 14:32:43.574] [jLog] [info] building index
out : salmon_index
[2024-08-16 14:32:43.577] [puff::index::jointLog] [info] Running fixFasta

================
[Step 1 of 4] : counting k-mers
[2024-08-16 14:32:45.967] [puff::index::jointLog] [warning] Entry with header [NR_028434.1], had length less than equal to the k-mer length of 31 (perhaps after poly-A clipping)
[2024-08-16 14:32:45.967] [puff::index::jointLog] [warning] Entry with header [NR_028557.1], had length less than equal to the k-mer length of 31 (perhaps after poly-A clipping)
================
================
[2024-08-16 14:33:49.291] [puff::index::jointLog] [warning] Removed 625 transcripts that were sequence duplicates of indexed transcripts.
[2024-08-16 14:33:49.291] [puff::index::jointLog] [warning] If you wish to retain duplicate transcripts, please use the `--keepDuplicates` flag
================
[2024-08-16 14:33:49.291] [puff::index::jointLog] [info] Replaced 73,600,697 non-ATCG nucleotides
[2024-08-16 14:33:49.291] [puff::index::jointLog] [info] Clipped poly-A tails from 9,635 transcripts
wrote 135657 cleaned references
[2024-08-16 14:34:01.734] [puff::index::jointLog] [info] Filter size not provided; estimating from number of distinct k-mers
[2024-08-16 14:34:22.039] [puff::index::jointLog] [info] ntHll estimated 2269740504 distinct k-mers, setting filter size to 2^36
Threads = 12
Vertex length = 31
Hash functions = 5
Filter size = 68719476736
Capacity = 2
Files: 
salmon_index/ref_k31_fixed.fa
--------------------------------------------------------------------------------
Round 0, 0:68719476736
Pass	Filling	Filtering
1	226	484	
2	56	4
True junctions count = 14898458
False junctions count = 4965943
Hash table size = 19864401
Candidate marks count = 347350773
--------------------------------------------------------------------------------
TBB Warning: The number of workers is currently limited to 5. The request for 11 workers is ignored. Further requests for more workers will be silently ignored until the limit changes.

Reallocating bifurcations time: 5
True marks count: 340969289
Edges construction time: 227
--------------------------------------------------------------------------------
Distinct junctions = 14898458

TwoPaCo::buildGraphMain:: allocated with scalable_malloc; freeing.
TwoPaCo::buildGraphMain:: Calling scalable_allocation_command(TBBMALLOC_CLEAN_ALL_BUFFERS, 0);
allowedIn: 14
Max Junction ID: 14900429
seen.size():119203441 kmerInfo.size():14900430
approximateContigTotalLength: 1121476560
counters for complex kmers:
(prec>1 & succ>1)=3126999 | (succ>1 & isStart)=444 | (prec>1 & isEnd)=457 | (isStart & isEnd)=16
contig count: 25016334 element count: 3022906452 complex nodes: 3127916
# of ones in rank vector: 25016333
[2024-08-16 14:55:26.193] [puff::index::jointLog] [info] Starting the Pufferfish indexing by reading the GFA binary file.
[2024-08-16 14:55:26.193] [puff::index::jointLog] [info] Setting the index/BinaryGfa directory salmon_index
size = 3022906452
-----------------------------------------
| Loading contigs | Time = 261.54 ms
-----------------------------------------
size = 3022906452
-----------------------------------------
| Loading contig boundaries | Time = 136.48 ms
-----------------------------------------
Number of ones: 25016333
Number of ones per inventory item: 512
Inventory entries filled: 48861
25016333
[2024-08-16 14:55:29.836] [puff::index::jointLog] [info] Done wrapping the rank vector with a rank9sel structure.
[2024-08-16 14:55:30.071] [puff::index::jointLog] [info] contig count for validation: 25,016,333
[2024-08-16 14:55:39.047] [puff::index::jointLog] [info] Total # of Contigs : 25,016,333
[2024-08-16 14:55:39.047] [puff::index::jointLog] [info] Total # of numerical Contigs : 25,016,333
[2024-08-16 14:55:40.249] [puff::index::jointLog] [info] Total # of contig vec entries: 350,903,889
[2024-08-16 14:55:40.249] [puff::index::jointLog] [info] bits per offset entry 29
[2024-08-16 14:55:57.916] [puff::index::jointLog] [info] Done constructing the contig vector. 25016334
[2024-08-16 14:56:14.747] [puff::index::jointLog] [info] # segments = 25,016,333
[2024-08-16 14:56:14.747] [puff::index::jointLog] [info] total length = 3,022,906,452
[2024-08-16 14:56:16.348] [puff::index::jointLog] [info] Reading the reference files ...
[2024-08-16 14:56:34.545] [puff::index::jointLog] [info] positional integer width = 32
[2024-08-16 14:56:34.545] [puff::index::jointLog] [info] seqSize = 3,022,906,452
[2024-08-16 14:56:34.545] [puff::index::jointLog] [info] rankSize = 3,022,906,452
[2024-08-16 14:56:34.545] [puff::index::jointLog] [info] edgeVecSize = 0
[2024-08-16 14:56:34.545] [puff::index::jointLog] [info] num keys = 2,272,416,462
for info, total work write each  : 2.331    total work inram from level 3 : 4.322  total work raw : 25.000 
[Building BooPHF]  99.9 %   elapsed:   1 min 19 sec   remaining:   0 min 0  sec
Bitarray     11906737600  bits (100.00 %)   (array + ranks )
final hash        218736  bits (0.00 %) (nb in final hash 651)
[2024-08-16 14:57:53.689] [puff::index::jointLog] [info] mphf size = 1419.42 MB
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk size = 251,908,871
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 0 = [0, 251,908,871)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 1 = [251,908,871, 503,817,770)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 2 = [503,817,770, 755,726,641)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 3 = [755,726,641, 1,007,635,512)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 4 = [1,007,635,512, 1,259,544,383)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 5 = [1,259,544,383, 1,511,453,254)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 6 = [1,511,453,254, 1,763,362,125)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 7 = [1,763,362,125, 2,015,270,996)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 8 = [2,015,270,996, 2,267,179,890)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 9 = [2,267,179,890, 2,519,088,761)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 10 = [2,519,088,761, 2,770,997,632)
[2024-08-16 14:57:59.691] [puff::index::jointLog] [info] chunk 11 = [2,770,997,632, 3,022,906,422)
[2024-08-16 15:00:20.657] [puff::index::jointLog] [info] finished populating pos vector
[2024-08-16 15:00:20.657] [puff::index::jointLog] [info] writing index components
[2024-08-16 15:00:56.028] [puff::index::jointLog] [info] finished writing dense pufferfish index
[2024-08-16 15:00:56.806] [jLog] [info] done building index

```

### Re-run pipeline


How can I now re-run the pipeline without re-doing the trimming, alignment, and so on?

There is the possibility to [start the pipeline anew from already mapped reads](https://nf-co.re/rnasplice/usage#samplesheet-input): source configuration from genome BAM files or from transcriptome BAM files. Which ones do I have, though? Apparently, I already have both:

![[2024-08-16_STAR_results_for_restarting.png]]

My only concern is that the two kinds of input files completely split what I am able to do with the pipeline: the genome BAM files only let me run the “dexseq_exon”, “edger_exon” and “rmats” analysis methods, whereas the transcriptome ones only let me run the “dexseq_dtu” and “suppa” analysis methods. This means I will have to run the remainder of the pipeline as two separate branches, the rMATS/edgeR/DEXseq (exon) branch and the SUPPA/DEXseq branch. Or I could try resuming the previous run with a different salmon_index indicator? I don't think I can do that - when the pipeline stopped yesterday, the processes "SALMON_QUANT_STAR" and "SALMON_QUANT_SALMON" were shown as completed. I suspect I have to run Salmon all over again for both scenarios in order to have it work properly with the new index.



#### rMATS/edgeR/DEXseq (exon) branch (from genome BAM files)

To use this, I will have to use the `--source genome_bam` argument and the same contrasts sheet but a different sample sheet ("samplesheet_preeclampsia_genomic.csv"):
```cs
sample,condition,genome_bam
CONTROL_REP1,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/CONTROL_REP1.Aligned.out.bam
CONTROL_REP2,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/CONTROL_REP2.Aligned.out.bam
CONTROL_REP3,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/CONTROL_REP3.Aligned.out.bam
CONTROL_REP4,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/CONTROL_REP4.Aligned.out.bam
PREECLAMPSIA_REP1,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/PREECLAMPSIA_REP1.Aligned.out.bam
PREECLAMPSIA_REP2,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/PREECLAMPSIA_REP2.Aligned.out.bam
PREECLAMPSIA_REP3,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/PREECLAMPSIA_REP3.Aligned.out.bam
PREECLAMPSIA_REP4,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/PREECLAMPSIA_REP4.Aligned.out.bam
```

##### Parameters rMATS/edgeR/DEXseq (exon) branch

I changed folders into the new work folder for the branch with `/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_genomic/`.

I tried to leave as many of the original parameters in place as possible, with the exception of the new work and results folders I created for each of the two branches:
```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--source genome_bam \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_genomic \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_genomic \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/samplesheet_preeclampsia_genomic.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker
```

Started at 16:55, crashed around 17:15.

##### Contrasts sheet issue
 The pipeline (hash 941267b9-a228-4895-886f-b62db6df05cf, "happy_lattes") ran a big chunk of the processes contained within:
![[2024-08-16_genomic_branch_atcrash.png]]

However, it crashed with an error due to edgeR_exon:

```Groovy
ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:EDGER_DEU:EDGER_EXON (samplesheet_preeclampsia_genomic.csv)'

Caused by:
  Process `NFCORE_RNASPLICE:RNASPLICE:EDGER_DEU:EDGER_EXON (samplesheet_preeclampsia_genomic.csv)` terminated with an error exit status (1)


Command executed:

  run_edger_exon.R featurecounts samplesheet_preeclampsia_genomic.csv contrastssheet_preeclampsia.csv 10
  
  cat <<-END_VERSIONS > versions.yml
  "NFCORE_RNASPLICE:RNASPLICE:EDGER_DEU:EDGER_EXON":
      r-base: $(echo $(R --version 2>&1) | sed 's/^.*R version //; s/ .*$//')
      bioconductor-edger:  $(Rscript -e "library(edgeR); cat(as.character(packageVersion('edgeR')))")
  END_VERSIONS

Command exit status:
  1

Command output:
  (empty)

Command error:
  Unable to find image 'quay.io/biocontainers/mulled-v2-419bd7f10b2b902489ac63bbaafc7db76f8e0ae1:709335c37934db1b481054cbec637c6e5b5971cb-0' locally
  709335c37934db1b481054cbec637c6e5b5971cb-0: Pulling from biocontainers/mulled-v2-419bd7f10b2b902489ac63bbaafc7db76f8e0ae1
  c1a16a04cedd: Already exists
  4ca545ee6d5d: Already exists
  77553dce0681: Pulling fs layer
  77553dce0681: Verifying Checksum
  77553dce0681: Download complete
  77553dce0681: Pull complete
  Digest: sha256:63ebd4fa165ac8b0a37ee8c5ddd35a0c0abceb191375ffa5155bd7c90811b1bf
  Status: Downloaded newer image for quay.io/biocontainers/mulled-v2-419bd7f10b2b902489ac63bbaafc7db76f8e0ae1:709335c37934db1b481054cbec637c6e5b5971cb-0
  Loading required package: limma
  
  Warning message:
  In read.table(file = file, header = header, sep = sep, quote = quote,  :
 incomplete final line found by readTableHeader on 'contrastssheet_preeclampsia.csv'
 ====================
  Error in eval(ej, envir = levelsenv) : object 'PREECLAMPSIA' not found
  Calls: makeContrasts -> eval -> eval
  Execution halted
```

There seem to be issues with the contrasts sheet. The first one is a warning from the side of R that [the last line in the file is not empty](https://www.statology.org/r-incomplete-final-line-found-by-readtableheader/), as it would expect it to, which is probably not what caused the pipeline to stop. What did, however, cause it to stop, is likely the actual error about the missing object "PREECLAMPSIA". I suspect this is due to how I defined the sample sheet in this case (in the background, R is trying to fit a regression model, and the column names don't fit between the data frame used to build the model vs the one used for the prediction - https://www.statology.org/error-in-evalpredvars-data-env-object-not-found/ ). There may be other issues in the formatting of the sample sheet that cause the problem (https://help.galaxyproject.org/t/edger-multiple-contrasts-not-working/9707). I will try changing the sample sheet (that's where I had "control" and "treatment" this time instead of "CONTROL" and "PREECLAMPSIA" like in my previous run of the pipeline), and will try resuming it (I still am in the "genomic" work folder):


```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--source genome_bam \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_genomic \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_genomic \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/samplesheet_preeclampsia_genomic.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume 941267b9-a228-4895-886f-b62db6df05cf
```

It seems to still want to re-sort the BAM files :(
![[2024-08-16_genomic_branch_restarted.png]]

#### Run up to Sashimi crash
![[2024-08-16_genomic_branch_until_sashimi_crash.png]]

```Groovy
ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:VISUALISE_MISO:MISO_SASHIMI (2)'

Caused by:
  Process `NFCORE_RNASPLICE:RNASPLICE:VISUALISE_MISO:MISO_SASHIMI (2)` terminated with an error exit status (1)


Command executed:

  sashimi_plot --plot-event ENSG00000005302 index miso_settings.txt --output-dir sashimi
  
  cat <<-END_VERSIONS > versions.yml
  "NFCORE_RNASPLICE:RNASPLICE:VISUALISE_MISO:MISO_SASHIMI":
      python: $(python --version | sed "s/Python //g")
      misopy: $(python -c "import pkg_resources; print(pkg_resources.get_distribution('misopy').version)")
  END_VERSIONS

Command exit status:
  1

Command output:
  (empty)

Command error:
  /usr/local/lib/python2.7/site-packages/matplotlib/cbook/deprecation.py:107: MatplotlibDeprecationWarning: The mpl_toolkits.axes_grid module was deprecated in version 2.1. Use mpl_toolkits.axes_grid1 and mpl_toolkits.axisartist provies the same functionality instead.
    warnings.warn(message, mplDeprecation, stacklevel=1)
  Traceback (most recent call last):
    File "/usr/local/bin/sashimi_plot", line 11, in <module>
      sys.exit(main())
    File "/usr/local/lib/python2.7/site-packages/misopy/sashimi_plot/sashimi_plot.py", line 276, in main
      plot_label=plot_label)
    File "/usr/local/lib/python2.7/site-packages/misopy/sashimi_plot/sashimi_plot.py", line 142, in plot_event
      %(event_name, pickle_dir)
  Exception: Event ENSG00000005302 not found in pickled directory index. Are you sure this is the right directory for the event?

Work dir:
  /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_genomic/3c/f8c32ad33e440a86f7b6bf467f5279
```


I tried re-starting it in the same work dir with --sashimi_plot false:

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--sashimi_plot false \
--source genome_bam \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_genomic \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_genomic \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/samplesheet_preeclampsia_genomic.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume 941267b9-a228-4895-886f-b62db6df05cf
```

SUCCESS! It ran all the way down to creating a MultiQC report about all of the reads it aligned/mapped! [what else?]

#### SUPPA/DEXseq_dtu branch (from transcriptome BAM files)
To use this, I will have to use the `--source transcriptome_bam` argument and the same contrasts sheet but a different sample sheet ("samplesheet_preeclampsia_transcriptomic.csv"):

```cs
sample,condition,transcriptome_bam
CONTROL_REP1,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/CONTROL_REP1.Aligned.toTranscriptome.out.bam
CONTROL_REP2,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/CONTROL_REP2.Aligned.toTranscriptome.out.bam
CONTROL_REP3,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/CONTROL_REP3.Aligned.toTranscriptome.out.bam
CONTROL_REP4,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/CONTROL_REP4.Aligned.toTranscriptome.out.bam
PREECLAMPSIA_REP1,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/PREECLAMPSIA_REP1.Aligned.toTranscriptome.out.bam
PREECLAMPSIA_REP2,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/PREECLAMPSIA_REP2.Aligned.toTranscriptome.out.bam
PREECLAMPSIA_REP3,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/PREECLAMPSIA_REP3.Aligned.toTranscriptome.out.bam
PREECLAMPSIA_REP4,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/PREECLAMPSIA_REP4.Aligned.toTranscriptome.out.bam
```
##### Parameters SUPPA/DEXseq_dtu branch 

I changed folders into the new work folder for the branch with `/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_transcriptomic/`.

I tried to leave as many of the original parameters in place as possible, with the exception of the new work and results folders I created for each of the two branches:

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--source transcriptome_bam \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_transcriptomic \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_transcriptomic \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/samplesheet_preeclampsia_transcriptomic.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker
```
...which failed fairly fast with an error:

```Groovy
ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:BAM_SORT_STATS_SAMTOOLS:SAMTOOLS_SORT (PREECLAMPSIA_REP2)'

Caused by:
  Process `NFCORE_RNASPLICE:RNASPLICE:BAM_SORT_STATS_SAMTOOLS:SAMTOOLS_SORT (PREECLAMPSIA_REP2)` terminated with an error exit status (137)


Command executed:

  samtools sort \
       \
      -@ 6 \
      -m 12288M \
      -o PREECLAMPSIA_REP2_sorted.bam \
      -T PREECLAMPSIA_REP2_sorted \
      PREECLAMPSIA_REP2.Aligned.toTranscriptome.out.bam
  
  cat <<-END_VERSIONS > versions.yml
  "NFCORE_RNASPLICE:RNASPLICE:BAM_SORT_STATS_SAMTOOLS:SAMTOOLS_SORT":
      samtools: $(echo $(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*$//')
  END_VERSIONS

Command exit status:
  137

Command output:
  (empty)

Command error:
  .command.sh: line 8:    33 Killed                  samtools sort -@ 6 -m 12288M -o PREECLAMPSIA_REP2_sorted.bam -T PREECLAMPSIA_REP2_sorted PREECLAMPSIA_REP2.Aligned.toTranscriptome.out.bam

Work dir:
  /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_transcriptomic/19/69cc0da8f00c5757bce5c3b01b150c
```


##### Fixing 137 error
The exit code 137 seems to have something to do with processes being out of memory, and, looking at the Command error "33 Killed samtools sort -@ 6 -m 12288M -o PREECLAMPSIA_REP2_sorted.bam -T PREECLAMPSIA_REP2_sorted PREECLAMPSIA_REP2.Aligned.toTranscriptome.out.bam", I think the way I indicated max memory until now isn't working: there's a parameter that says `-m 12288M`. The way the pipeline creators do on the Custom Configuration page is without the dot notation, so let's try again, resuming the same run (this one was 10497c48-b4b0-4990-a919-31eaa1fb3a29 , ecstatic_mercator): 

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90GB \
--source transcriptome_bam \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_transcriptomic \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_transcriptomic \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/samplesheet_preeclampsia_transcriptomic.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume 10497c48-b4b0-4990-a919-31eaa1fb3a29
```

...but this didn't change the outcome. I got the exact same error, with samtools_sort still having the parameter `-m 12288M`. Somehow, the limits I set to the pipeline overall don't seem to work for samtools, oddly enough. This means I have to create a custom configuration file to run the pipeline with.

##### Custom configuration file to fix memory usage issue for Samtools

The process I want to change the options for is one of the "nf-core" subworkflows,  "bam_sort_stats_samtools". The "main.nf" Nextflow script in the [bam_sort_stats_samtools GitHub folder](https://github.com/nf-core/rnasplice/blob/1.0.4/subworkflows/nf-core/bam_sort_stats_samtools/main.nf) seems to not be the script that causes the issue itself (description of the [bam_sort_stats_samtools subworkflow](https://nf-co.re/subworkflows/bam_sort_stats_samtools/)), but to just be used to call another one from a module, [nf-core/samtools/sort](https://nf-co.re/modules/samtools_sort/) and another module that makes the index, [samtools_index](https://nf-co.re/modules/samtools_index/). Both modules could be causing issues with the memory use, and I don't understand why limiting the memory overall doesn't do it for these two modules as well.

So, since I don't want to create a config file from scratch, not knowing how the original one is set up for the pipeline, perhaps going to the roots is the answer: where is the config file used to set how much memory processes are allowed to use? The scripts themselves listed above don't contain parameter settings for memory use. I then read here about [how to tune pipeline resources](https://nf-co.re/docs/usage/getting_started/configuration#tuning-workflow-resources and found out that all of the pipelines from nf-core do so using a `base.config` file. This means that I need to find out 1. where this is, 2. copy its contents with the memory adjustment to fit the maximal resources my PC can use, and 3. make the pipeline use the new config file instead of the base.config.

After some searching on my system, I found that the base.config file is located in `/home/iweber/.nextflow/assets/nf-core/rnasplice/` and looks like this:
![[2024-08-16_baseconfig_file.png]]
There's indeed an option for processes using high memory to be allowed to go up to 200 GB of RAM usage...which, of course, is not doable on my virtual machine that only allows 95 GB, and of which the pipeline should not use more than 90 GB. 

I changed the process_high_memory to 

```Groovy
withLabel:process_high_memory {
        memory = { check_max( 90.GB * task.attempt, 'memory' ) }
    }
```

and saved the file. I closed and re-opened the terminal, and re-ran the previous command in the transcriptomic work folder....no improvement - I still got the "terminated with an error exit status (137)" errors. Is it possible that the settings in the base.config file are overridden by settings set in some other config file?

Or maybe the issue is even simpler: Looking at the error more closely, I saw that it says "Killed samtools sort -@ 6 -m 12288M". For some reason, my brain read the amount megabyte as 128 GB, which, of course, it is not: it's 12 GB! This means that Samtools sort likely does not fall under the label of process_high_memory within the Nextflow base configuration file! In its own [main.nf ](https://github.com/nf-core/modules/blob/master/modules/nf-core/samtools/sort/main.nf)file among the nf-core modules, it is labelled as a process_medium! So I went back to my `base.config` file and changed the memory allotted to process_medium to 90 GB. Let's see if this does the trick...

```Groovy
 withLabel:process_medium {
        cpus   = { check_max( 6     * task.attempt, 'cpus'    ) }
        memory = { check_max( 90.GB * task.attempt, 'memory'  ) }
        time   = { check_max( 8.h   * task.attempt, 'time'    ) }
    }
```

....nope, it did not. Same error.

##### Updating modules and subworkflows to fix Samtools memory issues

I did some more research online, and found this as an open issue here: https://github.com/nf-core/rnasplice/issues/145, which pointed me to a potential solution: https://github.com/nf-core/methylseq/pull/330 simply use `nf-core modules update` to update all of the core modules, such as Samtools, used by this pipeline and others. 

I got a prompt saying

```Groovy
                                          ,--./,-.
          ___     __   __   __   ___     /,-._.--~\
    |\ | |__  __ /  ` /  \ |__) |__         }  {
    | \| |       \__, \__/ |  \ |___     \`-._,-`-,
                                          `._,._,'

    nf-core/tools version 2.14.1 - https://nf-co.re


WARNING  'repository_type' not defined in .nf-core.yml                          
? Is this repository an nf-core pipeline or a fork of nf-core/modules? 
==Pipeline==

INFO     To avoid this prompt in the future, add the 'repository_type' key to your .nf-core.yml file.    


? Would you like me to add this config now? [y/n] (y):
==y==
```
After selecting that this is a pipeline and yes, I want to add the config, I get an error "PermissionError: [Errno 13] Permission denied: '/.nf-core.yml'". When I tried to repeat the command with sudo (`sudo nf-core modules update`), it tells me: "sudo: nf-core: command not found". Why is this happening, and how can I run the command with sudo privileges? 

Turns out, using `sudo` doesn't just give you localized privileges for that one command you want to execute. `sudo`, in fact, creates a whole new shell, even though it works in the same terminal, and that shell doesn't always have identical settings to the one you use as a non-super-user! ([source](https://www.baeldung.com/linux/sudo-command-not-found)). That also means that commands your regular shell knows how to find because of the addresses to their binaries being stored in the PATH variable don't necessarily translate to the sudo shell, because it uses a different PATH variable! It's like activating a different user account on the computer, where not all of the software from other user accounts is accessible.

To make sudo use the exact same path, I could add the option `-E` to my command, which I will do for now: 

```bash
sudo -E nf-core modules update
```
...and which didn't work.

A more permanent solution is to modify the sudoers file (open _/etc/sudoers_ with `sudo visudo`, [source](https://www.digitalocean.com/community/tutorials/how-to-edit-the-sudoers-file)) and add to it 

```bash
# Keep path variable from current shell
Defaults env_keep+="PATH" 
```
(([source](https://www.baeldung.com/linux/sudo-command-not-found)).

I opened the sudoers file with sudo visudo, then tried typing the command above in it, which gave me an odd error message "no string under the cursor" (thanks, Vim, I guess? LE: I hadn't activated "insert" mode). Then, I performed a paste operation with Ctrl+V and accidentally pasted in something utterly unnecessary (a link to a website). When I wanted to undo it with Ctrl+Z, it threw me out of the document and back to the shell. If I now try to re-open the sudoers file again, it tells me "visudo: /etc/sudoers busy, try again later". How to cancel everything I did and make sure I don't break my sudoers file and my system with it?

I used `ps aux | grep visudo` to check for running visudo processes, and found four, three from the root user and one from my personal user:

```bash
root        6148  0.0  0.0  14700  6144 pts/0    T    11:13   0:00 sudo visudo
root        6149  0.0  0.0  14700  2484 pts/1    Ss   11:13   0:00 sudo visudo
root        6150  0.0  0.0   9044  2816 pts/1    T+   11:13   0:00 visudo
iweber      6167  0.0  0.0   9564  2688 pts/0    S+   11:20   0:00 grep --color=auto visudo
```

They have little status indicators: T = stopped, T+ = stopped, Ss = sleeping, and the grep command I just ran, which isn't relevant. So I could kill the first three processes, but I want more safety operations before that, such as trying to close the file without saving. To switch to the still running visudo process, I ran `jobs`, which showed me

```
[1]+  Stopped                 sudo visudo
```

I then ran `fg %1` to bring this process into the foreground, and could see the contents of the sudoers file again. I deleted what I had previously accidentally inserted, but also chose to exit without saving anything, just to be on the extra safe side, by typing `:q!`. I got back a message saying `visudo: /etc/sudoers.tmp unchanged`, which sounds promising. I ran the `ps aux | grep visudo` command again to check for any leftover running processes, and got only the grep as a running process for my user:

```bash
iweber      6181  0.0  0.0   9564  2688 pts/0    S+   11:34   0:00 grep --color=auto visudo
```

Because once burnt, twice shy, I made a backup of the sudoers file with

```bash
sudo cp sudoers sudoers.bak
```
, then opened it with `sudo visudo`. I moved up and down with the arrows to find the other Defaults, hit "i" to enter the INSERT mode of Vim, and then typed `Defaults env_keep+="PATH"`. I clicked `Esc` to exit the inserting mode, then typed `:wq` to write and quit.

And it was all in vain. I then re-started my terminal and typed the nf-core update command again, only to, again, get `sudo: nf-core: command not found`. I activated the Nextflow conda environment I had created, that also didn't help.

I then tried running the command with the full path to the executable. With the Conda environment activated, I ran `which nf-core` and got back `/home/iweber/anaconda3/envs/Nextflow/bin/nf-core`. I can now try running the command with sudo but using the full path:

```bash
sudo /home/iweber/anaconda3/envs/Nextflow/bin/nf-core modules update
```

I immediately got these strange prompts:

```Groovy
WARNING  'repository_type' not defined in .nf-core.yml                          
? Is this repository an nf-core pipeline or a fork of nf-core/modules? 
```

I selected "Pipeline", and then it proceeded:

```Groovy
INFO     To avoid this prompt in the future, add the 'repository_type' key to   
         your .nf-core.yml file.                                                
? Would you like me to add this config now? [y/n] (y): y
INFO     Config added to '.nf-core.yml'                                         
WARNING  Could not find a 'main.nf' or 'nextflow.config' file in '/'            
INFO     The 'modules.json' file is not up to date. Recreating the              
         'modules.json' file.                                                   
? Can't find a ./modules directory. Would you like me to create one? [y/n] (y):
```
I wasn't sure why the ./modules directory wasn't where it was supposed to be, so I typed n to cancel the operation. I thought that perhaps the problem is that I am not working in the correct location for the update, and perhaps I need to switch to the pipeline's folder, which I did with `cd /home/iweber/.nextflow/assets/nf-core/rnasplice/`. I tried repeating the update command here, which gave me an error saying "FileNotFoundError: [Errno 2] No such file or directory: 'pre-commit" and a giant traceback:

```Groovy
                                          ,--./,-.
          ___     __   __   __   ___     /,-._.--~\
    |\ | |__  __ /  ` /  \ |__) |__         }  {
    | \| |       \__, \__/ |  \ |___     \`-._,-`-,
                                          `._,._,'

    nf-core/tools version 2.14.1 - https://nf-co.re


╭─────────────────────────────── Traceback (most recent call last) ────────────────────────────────╮
│ /home/iweber/anaconda3/envs/Nextflow/bin/nf-core:10 in <module>                                  │
│                                                                                                  │
│    7                                                                                             │
│    8 if __name__ == '__main__':                                                                  │
│    9 │   sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])                       │
│ ❱ 10 │   sys.exit(run_nf_core())                                                                 │
│   11                                                                                             │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/nf_core/__main__.py:150 in     │
│ run_nf_core                                                                                      │
│                                                                                                  │
│    147 │   │   │   log.debug(f"Could not check latest version: {e}")                             │
│    148 │   │   stderr.print("\n")                                                                │
│    149 │   # Launch the click cli                                                                │
│ ❱  150 │   nf_core_cli(auto_envvar_prefix="NFCORE")                                              │
│    151                                                                                           │
│    152                                                                                           │
│    153 @tui()                                                                                    │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/rich_click/rich_command.py:367 │
│ in __call__                                                                                      │
│                                                                                                  │
│   364 │   │   # Include this here because I run into a false warning                             │
│   365 │   │   # in the PyCharm IDE otherwise; for some reason PyCharm doesn't                    │
│   366 │   │   # seem to think RichGroups are callable. (No issues with Mypy, though.)            │
│ ❱ 367 │   │   return super().__call__(*args, **kwargs)                                           │
│   368                                                                                            │
│   369                                                                                            │
│   370 class RichCommandCollection(CommandCollection, RichGroup):                                 │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/click/core.py:1157 in __call__ │
│                                                                                                  │
│   1154 │                                                                                         │
│   1155 │   def __call__(self, *args: t.Any, **kwargs: t.Any) -> t.Any:                           │
│   1156 │   │   """Alias for :meth:`main`."""                                                     │
│ ❱ 1157 │   │   return self.main(*args, **kwargs)                                                 │
│   1158                                                                                           │
│   1159                                                                                           │
│   1160 class Command(BaseCommand):                                                               │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/rich_click/rich_command.py:152 │
│ in main                                                                                          │
│                                                                                                  │
│   149 │   │   try:                                                                               │
│   150 │   │   │   try:                                                                           │
│   151 │   │   │   │   with self.make_context(prog_name, args, **extra) as ctx:                   │
│ ❱ 152 │   │   │   │   │   rv = self.invoke(ctx)                                                  │
│   153 │   │   │   │   │   if not standalone_mode:                                                │
│   154 │   │   │   │   │   │   return rv                                                          │
│   155 │   │   │   │   │   # it's not safe to `ctx.exit(rv)` here!                                │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/click/core.py:1688 in invoke   │
│                                                                                                  │
│   1685 │   │   │   │   super().invoke(ctx)                                                       │
│   1686 │   │   │   │   sub_ctx = cmd.make_context(cmd_name, args, parent=ctx)                    │
│   1687 │   │   │   │   with sub_ctx:                                                             │
│ ❱ 1688 │   │   │   │   │   return _process_result(sub_ctx.command.invoke(sub_ctx))               │
│   1689 │   │                                                                                     │
│   1690 │   │   # In chain mode we create the contexts step by step, but after the                │
│   1691 │   │   # base command has been invoked.  Because at that point we do not                 │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/click/core.py:1688 in invoke   │
│                                                                                                  │
│   1685 │   │   │   │   super().invoke(ctx)                                                       │
│   1686 │   │   │   │   sub_ctx = cmd.make_context(cmd_name, args, parent=ctx)                    │
│   1687 │   │   │   │   with sub_ctx:                                                             │
│ ❱ 1688 │   │   │   │   │   return _process_result(sub_ctx.command.invoke(sub_ctx))               │
│   1689 │   │                                                                                     │
│   1690 │   │   # In chain mode we create the contexts step by step, but after the                │
│   1691 │   │   # base command has been invoked.  Because at that point we do not                 │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/click/core.py:1434 in invoke   │
│                                                                                                  │
│   1431 │   │   │   echo(style(message, fg="red"), err=True)                                      │
│   1432 │   │                                                                                     │
│   1433 │   │   if self.callback is not None:                                                     │
│ ❱ 1434 │   │   │   return ctx.invoke(self.callback, **ctx.params)                                │
│   1435 │                                                                                         │
│   1436 │   def shell_complete(self, ctx: Context, incomplete: str) -> t.List["CompletionItem"]:  │
│   1437 │   │   """Return a list of completions for the incomplete value. Looks                   │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/click/core.py:783 in invoke    │
│                                                                                                  │
│    780 │   │                                                                                     │
│    781 │   │   with augment_usage_errors(__self):                                                │
│    782 │   │   │   with ctx:                                                                     │
│ ❱  783 │   │   │   │   return __callback(*args, **kwargs)                                        │
│    784 │                                                                                         │
│    785 │   def forward(                                                                          │
│    786 │   │   __self, __cmd: "Command", *args: t.Any, **kwargs: t.Any  # noqa: B902             │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/click/decorators.py:33 in      │
│ new_func                                                                                         │
│                                                                                                  │
│    30 │   """                                                                                    │
│    31 │                                                                                          │
│    32 │   def new_func(*args: "P.args", **kwargs: "P.kwargs") -> "R":                            │
│ ❱  33 │   │   return f(get_current_context(), *args, **kwargs)                                   │
│    34 │                                                                                          │
│    35 │   return update_wrapper(new_func, f)                                                     │
│    36                                                                                            │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/nf_core/__main__.py:940 in     │
│ modules_update                                                                                   │
│                                                                                                  │
│    937 │   │   │   ctx.obj["modules_repo_branch"],                                               │
│    938 │   │   │   ctx.obj["modules_repo_no_pull"],                                              │
│    939 │   │   )                                                                                 │
│ ❱  940 │   │   exit_status = module_install.update(tool)                                         │
│    941 │   │   if not exit_status and install_all:                                               │
│    942 │   │   │   sys.exit(1)                                                                   │
│    943 │   except (UserWarning, LookupError) as e:                                               │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/nf_core/components/update.py:1 │
│ 05 in update                                                                                     │
│                                                                                                  │
│   102 │   │                                                                                      │
│   103 │   │   # Verify that 'modules.json' is consistent with the installed modules              │
│   104 │   │   if not silent:                                                                     │
│ ❱ 105 │   │   │   self.modules_json.check_up_to_date()                                           │
│   106 │   │                                                                                      │
│   107 │   │   if not self.update_all and component is None:                                      │
│   108 │   │   │   choices = [f"All {self.component_type}", f"Named {self.component_type[:-1]}"   │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/nf_core/modules/modules_json.p │
│ y:627 in check_up_to_date                                                                        │
│                                                                                                  │
│    624 │   │   self.pipeline_components = original_pipeline_components                           │
│    625 │   │                                                                                     │
│    626 │   │   if dump_modules_json:                                                             │
│ ❱  627 │   │   │   self.dump(run_prettier=True)                                                  │
│    628 │                                                                                         │
│    629 │   def load(self):                                                                       │
│    630 │   │   """                                                                               │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/nf_core/modules/modules_json.p │
│ y:1061 in dump                                                                                   │
│                                                                                                  │
│   1058 │   │   │   # Sort the modules.json                                                       │
│   1059 │   │   │   self.modules_json["repos"] = nf_core.utils.sort_dictionary(self.modules_json  │
│   1060 │   │   │   if run_prettier:                                                              │
│ ❱ 1061 │   │   │   │   dump_json_with_prettier(self.modules_json_path, self.modules_json)        │
│   1062 │   │   │   else:                                                                         │
│   1063 │   │   │   │   with open(self.modules_json_path, "w") as fh:                             │
│   1064 │   │   │   │   │   json.dump(self.modules_json, fh, indent=4)                            │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/nf_core/lint_utils.py:104 in   │
│ dump_json_with_prettier                                                                          │
│                                                                                                  │
│   101 │   """                                                                                    │
│   102 │   with open(file_name, "w") as fh:                                                       │
│   103 │   │   json.dump(file_content, fh, indent=4)                                              │
│ ❱ 104 │   run_prettier_on_file(file_name)                                                        │
│   105                                                                                            │
│   106                                                                                            │
│   107 def ignore_file(lint_name: str, file_path: Path, dir_path: Path) -> List[List[str]]:       │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/site-packages/nf_core/lint_utils.py:77 in    │
│ run_prettier_on_file                                                                             │
│                                                                                                  │
│    74 │                                                                                          │
│    75 │   nf_core_pre_commit_config = Path(nf_core.__file__).parent / ".pre-commit-prettier-co   │
│    76 │   try:                                                                                   │
│ ❱  77 │   │   subprocess.run(                                                                    │
│    78 │   │   │   ["pre-commit", "run", "--config", nf_core_pre_commit_config, "prettier", "--   │
│    79 │   │   │   capture_output=True,                                                           │
│    80 │   │   │   check=True,                                                                    │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/subprocess.py:548 in run                     │
│                                                                                                  │
│    545 │   │   kwargs['stdout'] = PIPE                                                           │
│    546 │   │   kwargs['stderr'] = PIPE                                                           │
│    547 │                                                                                         │
│ ❱  548 │   with Popen(*popenargs, **kwargs) as process:                                          │
│    549 │   │   try:                                                                              │
│    550 │   │   │   stdout, stderr = process.communicate(input, timeout=timeout)                  │
│    551 │   │   except TimeoutExpired as exc:                                                     │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/subprocess.py:1026 in __init__               │
│                                                                                                  │
│   1023 │   │   │   │   │   self.stderr = io.TextIOWrapper(self.stderr,                           │
│   1024 │   │   │   │   │   │   │   encoding=encoding, errors=errors)                             │
│   1025 │   │   │                                                                                 │
│ ❱ 1026 │   │   │   self._execute_child(args, executable, preexec_fn, close_fds,                  │
│   1027 │   │   │   │   │   │   │   │   pass_fds, cwd, env,                                       │
│   1028 │   │   │   │   │   │   │   │   startupinfo, creationflags, shell,                        │
│   1029 │   │   │   │   │   │   │   │   p2cread, p2cwrite,                                        │
│                                                                                                  │
│ /home/iweber/anaconda3/envs/Nextflow/lib/python3.12/subprocess.py:1955 in _execute_child         │
│                                                                                                  │
│   1952 │   │   │   │   │   if errno_num != 0:                                                    │
│   1953 │   │   │   │   │   │   err_msg = os.strerror(errno_num)                                  │
│   1954 │   │   │   │   │   if err_filename is not None:                                          │
│ ❱ 1955 │   │   │   │   │   │   raise child_exception_type(errno_num, err_msg, err_filename)      │
│   1956 │   │   │   │   │   else:                                                                 │
│   1957 │   │   │   │   │   │   raise child_exception_type(errno_num, err_msg)                    │
│   1958 │   │   │   │   raise child_exception_type(err_msg)                                       │
╰──────────────────────────────────────────────────────────────────────────────────────────────────╯
FileNotFoundError: [Errno 2] No such file or directory: 'pre-commit'
```

Where could this file or directory named ***pre-commit*** be located? This might give me an indication of where I need to run the update modules command for it to take effect. A simple "find /home -name pre-commit" returned a bunch of files from my initial Nextflow work folder ("Pre_eclampsia_Nextflow_work_folder") that are locked and give me a "permission denied" error. Using `sudo find /home -name pre-commit` returned exactly one folder, "/home/iweber/anaconda3/envs/Nextflow/bin/pre-commit". So maybe this is where I need to change to in order to run the update command?

Let's try `cd /home/iweber/anaconda3/envs/Nextflow/bin/` and then `sudo /home/iweber/anaconda3/envs/Nextflow/bin/nf-core modules update`. Which means it's still not the right folder. I still think that the `/home/iweber/.nextflow/assets/nf-core/rnasplice/` folder is the best bet: this is for sure where the modules folder is. The file nf-core itself is a Python script that imports a module from the  `nf_core.__main__` library called `run_nf_core` and then proceeds to call whichever script one specifies when one calls the nf-core scripts to be executed from the command lines. This means that, in my case, what I am trying to do is to execute the nf-core script with the option "modules", which, in turn, will call the "modules" script, that probably includes a function or link to another script called "update".


I realized at some point that I can try updating the thing itself that causes the issue, in this case, the subworkflow that the module samtools is included in, namely bam_sort_stats_samtools.

I changed to the directory where the rnasplice pipeline is stored, /home/.nextflow/assets/nf-core/rnasplice, and then ran

```bash
nf-core subworkflows update bam_sort_stats_samtools
```

I got a message asking if I wanted to see what had changed between my version and the current version:

```Groovy
? Do you want to view diffs of the proposed changes? Preview diff in terminal, choose whether to update files
INFO     Changes in module 'nf-core/bam_sort_stats_samtools' between (735e1e04e7e01751d2d6e97055bbdb6f70683cc1) and (46eca555142d6e597729fcb682adcc791796f514)                                       
INFO     Changes in 'bam_sort_stats_samtools/main.nf':
 --- subworkflows/nf-core/bam_sort_stats_samtools/main.nf
 +++ subworkflows/nf-core/bam_sort_stats_samtools/main.nf                                                        
 @@ -15,7 +15,7 @@
      ch_versions = Channel.empty()
 -    SAMTOOLS_SORT ( ch_bam )
 +    SAMTOOLS_SORT ( ch_bam, ch_fasta )
      ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions.first())
      SAMTOOLS_INDEX ( SAMTOOLS_SORT.out.bam ) 
INFO     Changes in 'bam_sort_stats_samtools/meta.yml':
 --- subworkflows/nf-core/bam_sort_stats_samtools/meta.yml                                               
 +++ subworkflows/nf-core/bam_sort_stats_samtools/meta.yml                                 
 @@ -6,12 +6,13 @@                   
    - bam                   
    - sam                    
    - cram               
 -modules:            
 +components: 
    - samtools/sort         
    - samtools/index       
    - samtools/stats       
    - samtools/idxstats    
    - samtools/flagstat     
 +  - bam_stats_samtools                                                                                
  input:                                                                                               
    - meta:                  
        type: map                                                                         
 @@ -64,3 +65,6 @@
  authors:        
    - "@drpatelh" 
    - "@ewels"                                                                                           
 +maintainers:   
 +  - "@drpatelh"                                                                   +  - "@ewels"                                                                     
INFO     'subworkflows/nf-core/bam_sort_stats_samtools/tests/main.nf.test.snap' was created
INFO     'subworkflows/nf-core/bam_sort_stats_samtools/tests/tags.yml' was created
INFO     'subworkflows/nf-core/bam_sort_stats_samtools/tests/main.nf.test' was created                                                                                                               
? Update subworkflow 'bam_sort_stats_samtools'? (y/N)
```

There are indeed changes to the samtools module, so I chose "yes". I got another prompt:

```Groovy
WARNING  All modules and subworkflows linked to the updated subworkflow will be asked for update.
         It is advised to keep all your modules and subworkflows up to date.
         It is not guaranteed that a subworkflow will continue working as expected if all modules/subworkflows used in it are not up to date.
? Would you like to continue updating all modules and subworkflows? (Y/n)
```
and, since it sounds sensible, I chose "yes" again. I had to confirm individually if I want to update each individual module (and, strangely enough, I was not asked for any sudo permissions this time around - maybe because I had already "logged in" as a sudo user earlier in the same shell?). I saved all of the messages in a text file called "2024-08-18_update_subworkflows_completed".


##### Re-run pipeline after subworkflow/module update

I attempted to re-run the pipeline from yesterday, before I had updated all of the subworkflows. I double-checked I am resuming the correct pipeline by looking up the hash with `sudo nextflow log`

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90GB \
--source transcriptome_bam \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_transcriptomic \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_transcriptomic \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/samplesheet_preeclampsia_transcriptomic.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume 10497c48-b4b0-4990-a919-31eaa1fb3a29
```

Annnd same problem as before.

I tried updating absolutely all of the modules with `nf-core modules update --all` from within the rnasplice folder, then `nf-core subworkflows update --all`, which told me that the samtools-related ones were already up to date:

```Groovy

? Do you want to view diffs of the proposed changes? No previews, just update everything
# Modules
INFO     Updating 'nf-core/cat/fastq'
INFO     Updating 'nf-core/custom/dumpsoftwareversions'
INFO     Updating 'nf-core/custom/getchromsizes'
INFO     Updating 'nf-core/fastqc'
INFO     Updating 'nf-core/fastq_fastqc_umitools_trimgalore'
INFO     Updating 'nf-core/trimgalore'
INFO     Updating 'nf-core/umitools/extract'
INFO     Updating 'nf-core/gffread'
INFO     Updating 'nf-core/gunzip'
INFO     Updating 'nf-core/multiqc'
INFO     Updating 'nf-core/rsem/preparereference'
INFO     Updating 'nf-core/salmon/index'
INFO     Updating 'nf-core/salmon/quant'
INFO     'modules/nf-core/samtools/flagstat' is already up to date
INFO     'modules/nf-core/samtools/idxstats' is already up to date
INFO     'modules/nf-core/samtools/index' is already up to date 
INFO     'modules/nf-core/samtools/sort' is already up to date
INFO     'modules/nf-core/samtools/stats' is already up to date
INFO     Updating 'nf-core/star/align'      
INFO     Updating 'nf-core/subread/featurecounts'
INFO     'modules/nf-core/trimgalore' is already up to date
INFO     Updating 'nf-core/ucsc/bedclip'
INFO     Updating 'nf-core/bedgraph_bedclip_bedgraphtobigwig'
INFO     Updating 'nf-core/ucsc/bedgraphtobigwig'
INFO     'modules/nf-core/ucsc/bedgraphtobigwig' is already up to date
INFO     'modules/nf-core/umitools/extract' is already up to date
INFO     Updating 'nf-core/untar'
INFO     Updates complete ✨ 

# Subworkflows
INFO     'subworkflows/nf-core/bam_sort_stats_samtools' is already up to date
INFO     'subworkflows/nf-core/bam_stats_samtools' is already up to date
INFO     'subworkflows/nf-core/bedgraph_bedclip_bedgraphtobigwig' is already up to date
INFO     'subworkflows/nf-core/fastq_fastqc_umitools_trimgalore' is already up to date
INFO     Updates complete ✨   
```

I decided it might make more sense to simply try the entirety of the pipeline again, since I did not have this issue neither in previous runs, nor when running the genomic branch.

Maybe interesting for some point in the future: [optimizing memory settings for Samtools sort](https://bioinformatics.stackexchange.com/questions/18538/samtools-sort-most-efficient-memory-and-thread-settings-for-many-samples-on-a-c)

### Attempt to re-run pipeline in its entirety in hopes it will recognize the already aligned files

I could try to run the pipeline again just using `--pseudo_aligner salmon` to re-generate the Salmon quantification files based on the new index, in addition to `--skip_alignment` parameter set to `true` to not re-create the alignments. However, I am not sure if this will fix the issue with SAMTOOLS_SORT, which was not an issue in the genomic branch of the pipeline.

To be sure-sure I am working in the work folder I want to set:
```bash
cd /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/
```

Activate the Nextflow conda environment:
```bash
conda activate Nextflow
```

I tried to re-run the exact same command as on August 15th, skipping the parameters for clipping, including the path to the new Salmon index, and appended `-resume d2143e7b-2e6a-41e4-850d-cb8af9596f82`.

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume d2143e7b-2e6a-41e4-850d-cb8af9596f82
```

As an agnostic, I prayed to my pantheon of deities that the pipeline would recognize already generated results and that space on my hard drive will be enough for the new results. Started around 15:20 PM.

It failed around 7 PM due to the same error around tximport.
![[2024-08-18_state_up_to_tximport_error.png]]

```bash
ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_SALMON:TXIMPORT (GCF_000001635.27_GRCm39_genomic.tx2gene.tsv)'

Caused by:
  Process `NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_SALMON:TXIMPORT (GCF_000001635.27_GRCm39_genomic.tx2gene.tsv)` terminated with an error exit status (1)
Command executed:
  tximport.R GCF_000001635.27_GRCm39_genomic.tx2gene.tsv salmon salmon.merged
  
  cat <<-END_VERSIONS > versions.yml
  "NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_SALMON:TXIMPORT":
      r-base: $(echo $(R --version 2>&1) | sed 's/^.*R version //; s/ .*$//')
      bioconductor-tximeta: $(Rscript -e "library(tximeta); cat(as.character(packageVersion('tximeta')))")
  END_VERSIONS

Command exit status:
  1

Command output:
  (empty)

Command error:
  reading in files with read.delim (install 'readr' package for speed up)
  1 2 3 4 5 6 7 8 
  reading in files with read.delim (install 'readr' package for speed up)
  1 2 3 4 5 6 7 8 
  reading in files with read.delim (install 'readr' package for speed up)
  1 2 3 4 5 6 7 8 
  Error in .local(object, ...) : 
    None of the transcripts in the quantification files are present
    in the first column of tx2gene. Check to see that you are using
    the same annotation for both.
  
  Example IDs (file): [NM_001001130.3, NM_001001144.3, NM_001001152.2, ...]
  Example IDs (tx2gene): [gene-Bod1-ps, gene-Btf3-ps10, gene-Btf3-ps11, ...]
  
    This can sometimes (not always) be fixed using 'ignoreTxVersion' or 'ignoreAfterBar'.
  
  Calls: <Anonymous> -> <Anonymous> -> .local
  Execution halted

Work dir:
  /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/e4/91ebd6e629d26b810b86688181306f
```
The last folder is also where I have a symlink to a tx2gene.tsv file. The symlink points to an address /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6, where there is indeed a file called "GCF_000001635.27_GRCm39_genomic.tx2gene.tsv" which, indeed, contains again these non-NCBI identifiers ("gene-Bod-etc"). This means the pipeline did not regenerate this file simply because I am now indicating a different Salmon index for the mouse, so this is the file that I will have to regenerate. 


#### Regenerate a correct tx2gene file

The tx2gene file contains information about what transcripts are transcribed from each gene. In essence, it is a small relational table with one column for transcripts and one column for genes, and the information can be extracted from the GFF annotation file associated with most genome assemblies.

To create the files, I used a suite of tools called [gffutils](https://gffutils.readthedocs.io/en/latest/). Following the instructions, I installed gffutils in a conda environment with Python 3.8 activated (the latest Python version it works with):

```bash
conda create -n gffutils python=3.8
conda activate gffutils
cd /home/iweber/Documents/Software
wget https://github.com/fls-bioinformatics-core/GFFUtils/archive/refs/tags/v0.12.0.tar.gz
tar -xvzf v0.12.0.tar.gz
```

This created a folder called "GFFUtils-0.12.0" that contains a whole bunch of scripts. I changed into the directory with `cd GFFUtils-0.12.0/`. The gffutils website says to first install requirements by using pip, so I ran `pip install -r requirements.txt` , which told me "Successfully installed genomics-bcftbx-1.13.1 xlrd-2.0.1 xlsxwriter-3.2.0 xlutils-2.0.0 xlwt-1.3.". I then ran the installation with `pip install GFFUtils` (interestingly, this actually started an installation process, even though it looks like a folder - I presume it has something to do with the `__init__.py` script inside, whose name reminds me of a magic method). I got a message saying "Successfully installed GFFUtils-0.13 argcomplete-3.5.0 argh-0.31.3 importlib-metadata-8.2.0 packaging-24.1 pyfaidx-0.8.1.2 simplejson-3.19.3 zipp-3.20.0".

I created a new directory in my mouse genome folder ("/home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/tx2gene_new/") and changed to it. In it,  I created a script, `create_tx2gene.py` ([inspiration](https://divingintogeneticsandgenomics.com/post/how-to-make-a-transcript-to-gene-mapping-file/)):

```Python
#!/usr/bin/env python3
import gffutils
import pandas as pd

# Path to GFF file
gff_file = '/home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff'

# Create a gffutils database in memory
db = gffutils.create_db(gff_file, dbfn=':memory:', force=True, keep_order=True, merge_strategy='merge', sort_attribute_values=True)

# Extract transcript-to-gene mappings
tx2gene = []

for transcript in db.features_of_type('mRNA'):  # 'mRNA' corresponds to transcripts in GFF
    gene_id = transcript.attributes.get('Parent')[0]  # Assuming 'Parent' contains the gene ID
    transcript_id = transcript.id
    tx2gene.append((transcript_id, gene_id))

# Convert to DataFrame and save to a tsv file
df = pd.DataFrame(tx2gene, columns=['TXNAME', 'GENEID'])
df.to_csv('tx2gene.tsv', sep='\t', index=False)

```

I wondered if the quant.sf files that tximport will use the tx2gene files for really only contain mRNA identifiers (the NM_ kind, which I easily saw are present with `head -n 100 quant.sf`), or more. I ran `sudo grep -E '^NR_|^XR_' /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/salmon/CONTROL_REP1/quant.sf`, and saw that a whole bunch of other transcript types are present, such as 

- **`NM_`**: mRNA (protein-coding transcripts)
- **`NR_`**: Non-coding RNA (often long non-coding RNAs, lncRNAs, or small nuclear RNAs, snRNAs)
- **`XR_`**: Predicted or provisional non-coding RNA
- **`XM_`**: Predicted mRNA (not experimentally confirmed)
- **`YP_`**: Predicted protein (rare in transcript quantification data)
- **`NP_`**: Protein-coding (typically used for proteins, rare in transcript quantification)
- **`AP_` or `WP_`**: Protein (alternative locus, rarely used in RNA-seq)
- **`R_`**: Other potential types depending on specific databases or organisms (e.g., ribosomal RNAs might use `RR_`, but these are typically not included in standard transcriptomes).
`

And, sure enough, I found lots of NR_, XR_, XM_ transcripts. I did not find any of the other types (a call to `sudo grep -E '^YP_|^NP_|^AP_|^WP_|^R_|^RR_' /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/salmon/CONTROL_REP1/quant.sf` did not return any results, and it did not do so for any of the quant.sf files of the other samples).

I modified the Python script to contain GFF feature names that capture these identifiers:

```Python
#!/usr/bin/env python3

import gffutils
import pandas as pd

# Specify the path to GFF file
gff_file = '/home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff'

# Create a gffutils database in memory
db = gffutils.create_db(gff_file, dbfn=':memory:', force=True, keep_order=True, merge_strategy='merge', sort_attribute_values=True)

# Extract transcript-to-gene mappings
tx2gene = []

# Loop through all relevant RNA types based on identifiers found with grep
for transcript in db.features_of_type(['mRNA', 'snRNA', 'lncRNA', 'ncRNA']):
    gene_id = transcript.attributes.get('Parent')[0]
    transcript_id = transcript.id
    tx2gene.append((transcript_id, gene_id))

# Convert to DataFrame and save to a tab-separated value file
df = pd.DataFrame(tx2gene, columns=['TXNAME', 'GENEID'])
df.to_csv('GCF_000001635.27_GRCm39_genomic.tx2gene.tsv', sep='\t', index=False)
```

I chose to name the file exactly as the one I want to replace in the Nextflow work directory. Closed the file and made it executable with `chmod u+x create_tx2gene.py`.

I made a backup copy of the original (misconstructed) tx2gene file:

`sudo cp /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/tx2gene_new/GCF_000001635.27_GRCm39_genomic.tx2gene_FAULTY.tsv`

And then I ran the script to create a new tx2gene file with `./create_tx2gene.py`. I checked with `stat GCF_000001635.27_GRCm39_genomic.tx2gene.tsv` when the file was created and finished, and it took around 6.5 hours to create!

The file now looks like this:
![[2024-08-20_new_tx2gene_tsv2.png]]
![[2024-08-20_new_tx2gene_tsv.png]]

It's good, but...the identifiers still don't look like the ones in the quant.sf files. They all have a prefix indicating whether it's a gene or a transcript.

I first modified the TSV file name to "GCF_000001635.27_GRCm39_genomic.tx2gene_regenerated.tsv", and I then fixed the identifiers with a small Python script, "fix_identifiers_tx2gene.py". 

```Python
#!/usr/bin/env python3

import pandas as pd

# Load the tx2gene file
tx2gene = pd.read_csv('GCF_000001635.27_GRCm39_genomic.tx2gene_regenerated.tsv', sep='\t', header=0)

# Remove the 'rna-' prefix from the TXNAME column
tx2gene['TXNAME'] = tx2gene['TXNAME'].str.replace('rna-', '', regex=False)

# Remove the 'gene-' prefix from the GENEID column
tx2gene['GENEID'] = tx2gene['GENEID'].str.replace('gene-', '', regex=False)

# Save the modified tx2gene file
tx2gene.to_csv('GCF_000001635.27_GRCm39_genomic.tx2gene.tsv', sep='\t', index=False)
```

I made the script executable and ran it, which took seconds. Et voila!
![[2024-08-20_new_tx2gene_tsv_after_fixing_ids.png]]

#### Replace reconstructed tx2gene file

Now, to copy this file into the work directories where the still-faulty version is present, I searched again for where all of these files were lurking with `sudo find /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/ -type f -name "*tx2gene*"`
 And found several files:

```bash
1 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/tximport/tximport.tx2gene.tsv

2 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/genome/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv

3 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_transcriptomic/genome/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv

4 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/tximport.tx2gene.tsv
 
5 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv

6 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/a7/b0f3a354121a73f22dcc404dd0bce3/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv

7 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_transcriptomic/e5/928599fba977ddf9e27d86a4c83419/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv

8 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/2a/be42ba8de16fcc5c20c7cbbd5075c9/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
```

Interesting that, now that I searched in the entirety of my project folder, I can see that these .tsv files are present in both the work and the results directories, sometimes with a name like the file I regenerated just now (GCF_000001635.27_GRCm39_genomic.tx2gene.tsv), sometimes as tximport.tx2gene.tsv. I wondered if these two old file types have the exact same contents.
I compared this one

1 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/tximport/tximport.tx2gene.tsv

with this one:

2 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/genome/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv

I immediately saw that the tximport.tx2gene.tsv has 141.228 lines (4.2 MB), as opposed to the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv (141.898 lines, 5.2 MB), so both are much larger in comparison to my 2.1 MB regenerated version. I suspect Salmon/tximport created this file including absolutely every kind of transcript, not as narrowly defined as I did when I used gffutils.

Additionally, the files called "GCF_000001635.27_GRCm39_genomic.tx2gene.tsv" are larger at least in part because they contain a third column!
![[2024-08-20_GCF_tx2gene_file_structure.png]]

I checked what the other files are:

In 3,
/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_transcriptomic/genome/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
there is a 5.2 MB file.

This one
4 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/tximport.tx2gene.tsv is a 4.2 MB file like the other tximport.tx2gene.tsv I saw before.

The same folder contains a symlink to 
6 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/a7/b0f3a354121a73f22dcc404dd0bce3/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv, the 5.2 MB file.

Number 5 contains a proper .tsv file (no symlink), 5.2 MB
5 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv

This one
7 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_transcriptomic/e5/928599fba977ddf9e27d86a4c83419/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv 
contains a regular .tsv file of 5.2 MB.

Finally, this one
8 /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/2a/be42ba8de16fcc5c20c7cbbd5075c9/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
is 0 bytes, so I presume the process this folder was created for was stopped before the .tsv file was populated.

But the basic question still remains: which file do I need to replace for the pipeline to continue? 
To get a better idea of what processes used which files, I looked for the execution_trace txt files. I went to the pipeline_info folder in the output directory of my complete pipeline (so not the separate genomic and transcriptomic branches I ran as well) (/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/pipeline_info/). I peeked into one of them manually and saw mention of "TX2GENE", so I searched through all of the text files in that folder (all are execution traces) to see where it contains mentions of tx2gene.tsv files. I did so with `grep -Hn 'TX2GENE' *.txt`, and what I got back was:

```bash
execution_trace_2024-08-14_14-37-07.txt:3:6	2a/be42ba	32450	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)	FAILED	1	2024-08-14 14:37:49.993	515ms	421ms	-	-	-	-	-


execution_trace_2024-08-14_15-17-06.txt:10:10	fe/354fda	42739	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED	0	2024-08-14 15:17:43.142	11.8s	10s	101.7%	431 MB	449.1 MB	964.5 MB	10 MB
execution_trace_2024-08-14_15-17-06.txt:12:9	a7/b0f3a3	43907	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED	0	2024-08-14 15:17:52.800	11.1s	9s	99.6%	439 MB	457.2 MB	964.5 MB	10 MB


execution_trace_2024-08-15_12-10-30.txt:7:11	fe/354fda	42739	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED	0	2024-08-14 15:17:43.142	11.8s	10s	101.7%	431 MB	449.1 MB	964.5 MB	10 MB
execution_trace_2024-08-15_12-10-30.txt:8:6	a7/b0f3a3	43907	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED	0	2024-08-14 15:17:52.800	11.1s	9s	99.6%	439 MB	457.2 MB	964.5 MB	10 MB
execution_trace_2024-08-15_12-10-30.txt:66:65	f9/fa69fe	246777	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_SALMON:TXIMPORT (GCF_000001635.27_GRCm39_genomic.tx2gene.tsv)	FAILED	1	2024-08-15 15:40:36.894	1m 48s	1m 48s	-	-	-	-	-


execution_trace_2024-08-18_15-22-19.txt:12:11	fe/354fda	42739	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED	0	2024-08-14 15:17:43.142	11.8s	10s	101.7%	431 MB	449.1 MB	964.5 MB	10 MB
execution_trace_2024-08-18_15-22-19.txt:13:9	a7/b0f3a3	43907	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED	0	2024-08-14 15:17:52.800	11.1s	9s	99.6%	439 MB	457.2 MB	964.5 MB	10 MB
execution_trace_2024-08-18_15-22-19.txt:94:92	3c/3593b1	144000	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:TXIMPORT (GCF_000001635.27_GRCm39_genomic.tx2gene.tsv)	COMPLETED	0	2024-08-18 18:51:08.257	33.2s	32s	97.5%	526.1 MB	1.4 GB	259 MB162.5 MB
execution_trace_2024-08-18_15-22-19.txt:95:94	e4/91ebd6	145127	NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_SALMON:TXIMPORT (GCF_000001635.27_GRCm39_genomic.tx2gene.tsv)	FAILED	1	2024-08-18 18:51:41.449	7.2s	7.1s	-	-	-	-	-
```

I have several execution trace files, with the most recent one for the complete pipeline run being the one from Sunday (execution_trace_2024-08-18_15-22-19). Here, I can see that the pipeline seems to rather use the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file, and not the simple tximport.tx2gene.tsv file I've seen before, and TXIMPORT failed using this particular file (last line in the trace).

It also looks like this tsv file is generated by the process TX2GENE_TXIMPORT_SALMON:GFFREAD_TX2GENE based on a gtf file (GCF_000001635.27_GRCm39_genomic.gtf). This is quite odd, since I gave the pipeline a GFF file as input, but perhaps it converted it to GTF itself?

And also, if a step, such as this TX2GENE_TXIMPORT_SALMON:GFFREAD_TX2GENE process has results that are cached, can I find and alter those results by going to the work folder called fe/354fda....? (/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6/) Or would I need to go to the folder from which the GCF file is then used by TXIMPORT, e4/91ebd6...? (This one points to the same work subfolder as above, /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6/)

In the folder mentioned in the last entry of the trace, /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/e4/91ebd6e629d26b810b86688181306f/ folder, I indeed have yet another symlink to a GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file, namely located in /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6/ This is the folder mentioned in the second-to-last command, which does contain a proper GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file, and a symlink to a GTF file, GCF_000001635.27_GRCm39_genomic.gtf.

What I make of this is that I'm looking at some error that was likely propagated down different runs of the pipeline. The run from Sunday, with the execution trace I mention, refers to the results of a previous run, stored, in this case, in the "fe" folder. This is where the initial .tsv file was generated from a GTF file that is only referenced here as a symlink. This, in turn, was generated in another process, stored in folder 4f/788081b04c8224dcce0ad7247538b2/. Here, aside from the original GTF file, there is a GFF file, which is present as a symlink to the input GFF file I gave the pipeline, from my "Genomes/genome_M_musculus" folder. I peeked into this GTF file to see if it's the root of all evil, and it doesn't look like it:

```bash
sudo head -n 100 GCF_000001635.27_GRCm39_genomic.gtf
NC_000067.7	cmsearch	transcript	3172239	3172348	.	+	.	transcript_id "rna-XR_004936710.1"; gene_id "gene-Gm26206"; gene_name "Gm26206"; Dbxref "GeneID:115487594,RFAM:RF00026,GenBank:XR_004936710.1,MGI:MGI:5455983"; Name "XR_004936710.1"; gbkey "ncRNA"; gene "Gm26206"; inference "COORDINATES: profile:INFERNAL:1.1.1"; product "U6 spliceosomal RNA"; transcriptID "XR_004936710.1"; description "predicted gene%2C 26206"; gene_biotype "snRNA";

NC_000067.7	cmsearch	exon	3172239	3172348	.	+	.	transcript_id "rna-XR_004936710.1"; gene_id "gene-Gm26206"; gene_name "Gm26206"; Dbxref "GeneID:115487594,RFAM:RF00026,GenBank:XR_004936710.1,MGI:MGI:5455983"; gbkey "ncRNA"; gene "Gm26206"; inference "COORDINATES: profile:INFERNAL:1.1.1"; product "U6 spliceosomal RNA"; transcriptID "XR_004936710.1";

NC_000067.7	Gnomon	transcript	3269956	3741733	.	-	.	transcript_id "rna-XM_006495550.5"; gene_id "gene-Xkr4"; gene_name "Xkr4"; Dbxref "GeneID:497097,GenBank:XM_006495550.5,MGI:MGI:3528744"; Name "XM_006495550.5"; gbkey "mRNA"; gene "Xkr4"; model_evidence "Supporting evidence includes similarity to: 3 mRNAs%2C 3 ESTs%2C 4 Proteins%2C 766 long SRA reads%2C and 100%25 coverage of the annotated genomic feature by RNAseq alignments%2C including 17 samples with support for all annotated introns"; product "X-linked Kx blood group related 4%2C transcript variant X1"; transcriptID "XM_006495550.5"; description "X-linked Kx blood group related 4"; gene_biotype "protein_coding"; gene_synonym "Gm210,mKIAA1889,XRG4";

NC_000067.7	Gnomon	exon	3269956	3277540	.	-	.	transcript_id "rna-XM_006495550.5"; gene_id "gene-Xkr4"; gene_name "Xkr4"; Dbxref "GeneID:497097,GenBank:XM_006495550.5,MGI:MGI:3528744"; gbkey "mRNA"; gene "Xkr4"; product "X-linked Kx blood group related 4%2C transcript variant X1"; transcriptID "XM_006495550.5";
```

The problems seem to have started with the conversion of this GTF file into the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file, located in /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6/. This tx2gene file has the three-column format with identifiers formatted like:
![[Pasted image 20240820102426.png]]
![[Pasted image 20240820102410.png]]
![[Pasted image 20240820102318.png]]
![[Pasted image 20240820102347.png]]

This was created last Wednesday, so it must have been right at the start of the pipeline run when I accidentally used the wrong index. Which means it's been cached ever since and the pipeline has been attempting to use this file ever since. Also, considering that it has so many more lines than the file I generated and this particular format, I think I should target this file.

Blessed be those that read, but I also realized that the[ pipeline output description page](https://nf-co.re/rnasplice/1.0.4/docs/output/) also mentions the tximport.tx2gene.tsv file as being a ***filtered*** file containing gene to transcripts ids mappings. This would explain why the file I myself generated from the GFF with Gffutils is smaller than the one I just found in the work directory of the pipeline. So is it possible that these smaller tximport.tx2gene.tsv files are built in sequence, based on the initially faulty GCF_000001635.27_GRCm39_genomic.tx2gene.tsv files? I searched my project directory to see where these tximport.tx2gene.tsv pop up with `sudo find -name "*tximport**"` in my project directory, and found:
```

./Pre_eclampsia_mice_rnasplice_results/star_salmon/tximport/tximport.tx2gene.tsv
./Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/tximport.tx2gene.tsv
```

I suspect the file in the results folder is the same as the one on the work folder, and it's being saved because I activated options to save intermediates for nearly everything. In the work folder that was returned above, there isn't only the tximport.tx2gene.tsv file, but also a symlink to a GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file, which leads to /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/a7/b0f3a354121a73f22dcc404dd0bce3/. This is precisely the third-from-last entry in the execution trace, the one from the process GFFREAD_TX2GENE (GCF_000001635.27_GRCm39_genomic.gtf)that completed on	2024-08-14 15:17:52.800, so last Wednesday. Which means that it's *this* is the root of all evil *takes out silver weapons*.

Can I force the pipeline to re-do this step that created this tsv file, even though this step is cached? All roads lead to the folder a7/b0f3a354121a73f22dcc404dd0bce3, so I suspect that deleting this will then make quick work of forcing the pipeline to regenerate the file. But is there any warranty that it will do so correctly this time around? Likely not, and I don't know which parameters I have to change for it to stop adding these prefixes to the transcript identifiers. So, what I can do is to delete all of the files that have dependencies to this one. Which ones would those be? ChatGPT suggested to use find with -type l and -lname:

`sudo find /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/ -type l -lname "/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/a7/b0f3a354121a73f22dcc404dd0bce3/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv"`

The only result is 
/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv

What symlinks point to this file?

`sudo find /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/ -type l -lname "/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv"`

Apparently, none other. So, the rabbit hole we're down is:

4f: folder where the pipeline first created the GTF file from the GFF file I provided it with
a7/b0f3a354121a73f22dcc404dd0bce3: folder where the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file was created (also contains symlink to the GTF file the pipeline created)
3c: most recent use of the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file

Which means that... I need to modify the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file in a7 and pray that the symlink holds. I will need to also remove the tximport.tx2gene.tsv file from /Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/tximport.tx2gene.tsv because I want the pipeline to re-generate that based on the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file I now generate.

I will make a backup copy of the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv file,:

`sudo cp /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/a7/b0f3a354121a73f22dcc404dd0bce3/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/tx2gene_new/GCF_000001635.27_GRCm39_genomic_FAULTY.tx2gene.tsv`

To find out exactly which prefixes I have in the huge file, I changed into the a7/b0f3a354121a73f22dcc404dd0bce3 folder and used:

```bash
sudo grep -o -E '(^|[\t])[^,;[:space:]]+-' GCF_000001635.27_GRCm39_genomic.tx2gene.tsv | awk -F'-' '{print $1}' | tr -d '\t' | sort | uniq
```

This returned a list of identifiers I don't quite believe is right:
```
gene
id
rna
t14
t15
t4
t7a
t7c
t7f
ta3
tap1
tap10
tap11
tap12
tap13
tap15
tap16
tap17
tap19
tap2
tap20
tap21
tap22
tap24
tap26
tap27
tap28
tap29
tap3
tap31
tap4
tap5
tap6
tap7
tap8
tap9
tf1
tf3
tges3
thl17
tk
tl1
tma
tmn1
tnl5
to4
tp
tp6v0c
ts8
txbp3
```
Searching in the file for, for example, all instances of "tap31-" immediately showed that the regex was still catching parts of gene names that contained a dash for reasons other than having a prefix, e.g. gene-Krtap31-2. So I asked ChatGPT for an updated regex:

`sudo grep -o -E '(^|[\t])[^,;[:space:]]+-[^-]*[^0-9]-' GCF_000001635.27_GRCm39_genomic.tx2gene.tsv | awk -F'-' '{print $1}' | tr -d '\t' | sort | uniq`

and now I only got 
```
gene
id
rna
t7a (happens due to some miRNA gene names called "Mirlet7a-1, 2 etc")
t7c
t7f
tk (gene-Stk-ps2)
tma (gene-Ptma-ps2)
tp (still a lot of identifiers containing tp-)
tp6v0c (gene-Atp6v0c-ps2 and Atp6v0c-ps2)
```
The hits that aren't gene-, id-, or rna- all start with a "t," so somehow the regular expression is interpreted as looking for something following the letter t and not the tab character. 

The good thing is: I know I only need to worry about gene-, id-, and rna- as prefixes that need to be removed, and I can look specifically for them, not for a regex as I did above. Let's make sure they don't appear anywhere that's *not* at the start of the line:

`grep -E 'gene-|id-|rna-' GCF_000001635.27_GRCm39_genomic.tx2gene.tsv | grep -v -E '^gene-|^id-|^rna-'`

And the command returned nothing, so nope. Anywhere they are, it's at the start of the line.
To remove the gene-, id-, rna- prefixes, I used SED with regular expressions ([tutorial](https://www.tutorialspoint.com/unix/unix-regular-expressions.htm), here in more details for [regex with grep](https://linuxize.com/post/regular-expressions-in-grep/)):

`sudo sed -E -i 's/^(gene-|id-|rna-)//; s/[\t](gene-|id-|rna-)/\t/g' GCF_000001635.27_GRCm39_genomic.tx2gene.tsv`

This replaces any occurrence of the pattern at the start of the line with nothing (hence having just a slash after the slash separating the pattern to be replaced from what to replace it with), and also looks after tab characters and replaces pattern hits with exactly only a tab character. And the option "-i" makes sure it does so in-place, meaning modifying the file without creating a copy, which I want in order to maintain any symlinks and the possibility to resume the pipeline. "-E" enables use of Extended RegEx so that I can have the different variants of the pattern to be replaced.

With a slight tremor, I opened the file and saw:
![[Pasted image 20240820154735.png]]
![[Pasted image 20240820154759.png]]

Success!!! And now let's clean up the rest of the mess.

I moved the tximport.tx2gene.tsv file from /Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/tximport.tx2gene.tsv 

out and into my tx2gene backup directory

```
sudo mv /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/tximport.tx2gene.tsv /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/tx2gene_new/FAULTYfrom3c_tximport.tx2gene.tsv
```

However, I realized I had the same genomic .tsv file in other places, too, such as:
/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/fe/354fda8c110a2cfffb1588d5cf8ce6/. Just to be on the safe side, I switched to this folder and ran the same sed command:

`sudo sed -E -i 's/^(gene-|id-|rna-)//; s/[\t](gene-|id-|rna-)/\t/g' GCF_000001635.27_GRCm39_genomic.tx2gene.tsv`

which worked as expected.

I though, for good measure, to delete the parent folder of the last genomic.tx2gene.tsv, /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/2a/be42ba8de16fcc5c20c7cbbd5075c9/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv, so as to make the pipeline re-do the entire operation that didn't finish and left this file at 0 bytes, but reconsidered and decided against it. Modifying the contents of the other .tsv files already runs a risk of the pipeline not being able to resume. Deleting a full folder like this poses an even higher risk, so I will try to see if it works first.




I really, really wonder, and really, really hope that this will have been the end of the story, but let's run the pipeline first and fix the inevitable mistakes after.

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume d2143e7b-2e6a-41e4-850d-cb8af9596f82
```

Started around 16:30.

It finished quantifying with Salmon around 17:20, but then failed again at the tximport step, this time with the error:

```
-[nf-core/rnasplice] Pipeline completed with errors-
ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:TX2GENE_TXIMPORT_STAR_SALMON:TXIMPORT (GCF_000001635.27_GRCm39_genomic.tx2gene.tsv)'

Error in .local(object, ...) : 
    None of the transcripts in the quantification files are present
    in the first column of tx2gene. Check to see that you are using
    the same annotation for both.
  Example IDs (file): [rna-XR_004936710.1, rna-XM_006495550.5, rna-NM_001011874.1, ...]
  Example IDs (tx2gene): [Bod1-ps, Btf3-ps10, Btf3-ps11, ...]

Work dir:
  /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/18/e6b6c2d71c95100ffda7594b692c83
```

It tells me the problem is in folder 18/e6b6c2d71c95100ffda7594b692c83 .
I looked into the quant.sf files that Salmon just generated and which are symlinked into this folder, and somehow, these quant.sf files now have the indices that the files *didn't* initially have, but which the tx2gene files had.  And now of course my tx2gene file GCF_000001635.27_GRCm39_genomic.tx2gene.tsv in this folder symlinks to the one in the a7 folder, which I had modified to remove the identifiers from (why oh why...).

/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/a7/b0f3a354121a73f22dcc404dd0bce3/

What happens if I restart the pipeline right now? Just to make sure Salmon won't try to requantify the files...No, it fortunately doesn't:
![[2024-08-20_rerun_modified_tx2genes_afterkill.png]]

So I need to fix the GCF_000001635.27_GRCm39_genomic.tx2gene.tsv in 
/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/a7/b0f3a354121a73f22dcc404dd0bce3/ by...replacing its contents with the *original* contents (I can't copy and paste so as to not ruin the symlinks). Apparently, cat does change the contents of files directly, without affecting the so-called inode of the file. I [checked](https://web.eecs.utk.edu/~huangj/cs360/360/notes/Links/lecture.html) the inode of this file with the "**-i**" flag of **ls**:

```bash
ls -i GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
90058394 GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
```

I will first run a test drive with something else to make sure cat works as such on my system as well (yes, I know it's silly, but my anxiety at needing to re-run the entirety of the pipeline is too high).

I went to my scripts folder and made a copy of one of the files there, wrote the contents of another script into it, then tested if it affects its inode:

```bash
ls -i "trimmomatic_script (copy).sh" 
89655035 'trimmomatic_script (copy).sh'
cat pigz_several_fastqs.sh > 'trimmomatic_script (copy).sh'
89655035 'trimmomatic_script (copy).sh'
```
 and could confirm the inode was still 89655035 for 'trimmomatic_script (copy).sh'.

Okay, now for my .tsv files. I checked that my file GCF_000001635.27_GRCm39_genomic_FAULTY.tx2gene.tsv still have the prefixes that I now apparently need. Then, I ran the cat command to replace the contents of the file that's causing the issues:

```bash
sudo cat /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/tx2gene_new/GCF_000001635.27_GRCm39_genomic_FAULTY.tx2gene.tsv > /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/a7/b0f3a354121a73f22dcc404dd0bce3/GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
```
 And I got a "permission denied" error, even with sudo! The file's permissions look like
`-rw-r--r-- 1 root root 3956126 Aug 20 15:46 GCF_000001635.27_GRCm39_genomic.tx2gene.tsv`, meaning it should work just fine with sudo.

I tried changing the file owner to me for both files:
`sudo chown iweber:root GCF_000001635.27_GRCm39_genomic.tx2gene.tsv`
`sudo chown iweber:root /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/tx2gene_new/GCF_000001635.27_GRCm39_genomic_FAULTY.tx2gene.tsv`

I'm now the owner of the files:
```bash
ls -lat
-rw-r--r-- 1 iweber root 3956126 20. Aug 15:46 GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
```

I gave myself read and write permissions:
```sudo chmod 664 GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
sudo chmod 664 /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/tx2gene_new/GCF_000001635.27_GRCm39_genomic_FAULTY.tx2gene.tsv
```

..., saw that I now have read and write permissions:
`-rw-rw-r-- 1 iweber root 3956126 20. Aug 15:46 GCF_000001635.27_GRCm39_genomic.tx2gene.tsv`

and then re-ran the cat command. And it worked, now the file in a7/b0f3a354121a73f22dcc404dd0bce3/ is again 5.2 MB and contains the prefixes!

Undoing the permissions changes:
`sudo chmod 644 GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
`sudo chown root:root GCF_000001635.27_GRCm39_genomic.tx2gene.tsv`

Initial permissions and ownership is restored:
`-rw-r--r-- 1 root root 5234991 20. Aug 18:55 GCF_000001635.27_GRCm39_genomic.tx2gene.tsv`

And the file's inode is:
```bash
ls -i GCF_000001635.27_GRCm39_genomic.tx2gene.tsv 
90058394 GCF_000001635.27_GRCm39_genomic.tx2gene.tsv
```

So I managed to modify it without changing the inode! Let's see what the pipeline has to say to that - re-running with same parameters as above.

It passed the tximport steps, finally!!!

#### Re-run pipeline after tx2gene fix
It failed, as I expected, at the Sashimi plot generation step, but that's okay, I had simply not changed that before because I was afraid it would prevent the pipeline from resuming before I could see the tximport progress.

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--sashimi_plot false \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume d2143e7b-2e6a-41e4-850d-cb8af9596f82
```

started around 7 PM.

8 PM:
work folder:  165.7 GB
results folder: 166.1 GB

20.30: results folder 166.9 GB

![[2024-08-20_rerun_until_SUPPA_fail.png]]
State at crash

Pipeline crashed with an error from the SUPPA Python script:
```bash
ERROR ~ Error executing process > 'NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:DIFFSPLICE_IOI (PREECLAMPSIA-CONTROL)'

Caused by:
  Process `NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:DIFFSPLICE_IOI (PREECLAMPSIA-CONTROL)` terminated with an error exit status (1)


Command executed:

  suppa.py \
      diffSplice \
      -m empirical \
      -gc -pa -s -c  \
      -a 1000 \
      -l 0 \
      -al 0.05 \
      -th 0 \
      -nan 0 \
      -i events.ioi \
      -p transcript_PREECLAMPSIA.psi transcript_CONTROL.psi \
      -e PREECLAMPSIA.tpm CONTROL.tpm \
      -o PREECLAMPSIA-CONTROL_transcript_diffsplice
  
  cat <<-END_VERSIONS > versions.yml
  "NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:DIFFSPLICE_IOI":
      suppa: $(python -c "import pkg_resources; print(pkg_resources.get_distribution('suppa').version)")
  END_VERSIONS

Command exit status:
  1

Command output:
  Calculating differential analysis between conditions: transcript_PREECLAMPSIA and transcript_CONTROL 
  Saving between_conditions_avglogtpm...
  Saved PREECLAMPSIA-CONTROL_transcript_diffsplice_avglogtpm.tab

Command error:
  ERROR:__main__:Unknown error: (<class 'UnboundLocalError'>, UnboundLocalError("local variable 'i' referenced before assignment",), <traceback object at 0x7f8aa5b52d88>)
  Calculating differential analysis between conditions: transcript_PREECLAMPSIA and transcript_CONTROL 
  Saving between_conditions_avglogtpm...
  Saved PREECLAMPSIA-CONTROL_transcript_diffsplice_avglogtpm.tab

Work dir:
  /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/70/2bf3a959d4216c3e18ced0c84206f9
```

Potential problem with NAs in files? Or some other formatting issues? See https://github.com/comprna/SUPPA/issues/140

#### Fix SUPPA issues

The error:
```bash
Command executed:

  suppa.py \
      diffSplice \
      -m empirical \
      -gc -pa -s -c  \
      -a 1000 \
      -l 0 \
      -al 0.05 \
      -th 0 \
      -nan 0 \
      -i events.ioi \
      -p transcript_PREECLAMPSIA.psi transcript_CONTROL.psi \
      -e PREECLAMPSIA.tpm CONTROL.tpm \
      -o PREECLAMPSIA-CONTROL_transcript_diffsplice
```

seems to stem from a part of the SUPPA script called diffSplice. The processes that failed are called "DIFFSPLICE_IOE" and "DIFFSPLICE_IOI"

I checked [the SUPPA tutorial](https://github.com/comprna/SUPPA/wiki/SUPPA2-tutorial) to better understand what all of the options do and how files such as the "events.ioi" file are supposed to look like. In principle, it works on the basis of the transcript quantification completed in a previous step of the pipeline by Salmon. It uses a script, `multipleFieldSelection.py`, to extract the TPMs of transcripts from the Salmon quant.sf files and write them to an "iso_tpm.txt" file, and then uses the GTF annotation file to calculate the abundance of splicing events (so of course the IDs have to match).

I checked the quant.sf file from /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/star_salmon/salmon/CONTROL_REP1/:

Name	                       Length	EffectiveLength	TPM	    NumReads
rna-XR_004936710.1	110	    16.709	        0.000000	    0.000
rna-XM_006495550.5	12274	11879.509	23.364650	2076.226
rna-NM_001011874.1	3634	3239.509	    0.000000 	0.000
rna-XR_004935518.1	10074	9679.509 	0.000000	    0.000
rna-XM_011238395.4	2104	1709.509 	0.952673	   12.182
rna-XM_036152287.1	2764	2369.509	    0.484718	   8.591
rna-XR_004935517.1	24629	24234.509	0.011033	   2.000
gene-Gm57489	         969 	574.710	    0.000000	   0.000
gene-Gm27396	            58	11.497	        0.000000	   0.000
rna-XM_030252325.2	3710	3315.509	    0.000000	   0.000

It looks, in my beginner's eyes, [as I'd expect it to](https://salmon.readthedocs.io/en/latest/file_formats.html). How do the other ones look like? I suspect they'll all symlink to the same files in the results folder.

/ab/c61dc5c2641fa81cdf6f92cd0d8bd1/CONTROL_REP1/quant.sf - proper file. PREFIXES.
/ed/2cde806049b50d88f814ac5e86c19c/CONTROL_REP1/quant.sf - proper file. no prefixes.
/eb/f89d2deaafc4be440ddb966ba6523e/CONTROL_REP1/quant.sf - proper file. no prefixes.
/0d/947583d9f0b8520c8c05bbef3862e9/CONTROL_REP1/quant.sf - proper file, ENSEMBL IDs!!!

/9b/db66786facbbb6da1b9cf03e513b51/CONTROL_REP2/quant.sf
/94/308f503d9805bc2550cbed967da885/CONTROL_REP2/quant.sf
/ba/4c947178f55e00ad8587e0aefbe7bf/CONTROL_REP2/quant.sf

/67/63a35fc7486b580597422d6c1f9941/CONTROL_REP3/quant.sf
/9c/00b355eb2fb1502013c25167b7e1ec/CONTROL_REP3/quant.sf
/c0/27d16ed774cb1ce2260ed19b38cbd6/CONTROL_REP3/quant.sf
/16/9d22682e0c70d983d6fa6b2190fa5d/CONTROL_REP3/quant.sf

/11/a5ffd28abb00b85ee642b57a88226c/CONTROL_REP4/quant.sf
/7a/e172c9b55d3c5eeca0be1623d578c6/CONTROL_REP4/quant.sf
/89/a17e8c1dee5f264ab0f1883cbe3c1a/CONTROL_REP4/quant.sf
/86/8d2678d785ab216e3cc81eaebab5b6/CONTROL_REP4/quant.sf

/af/285ff63164456209bb1a0025119ec1/PREECLAMPSIA_REP1/quant.sf
/c1/5ce88b2fb4e0d6396e0356f61d18e1/PREECLAMPSIA_REP1/quant.sf
/47/8761a0dc2b9c1fa8d98bff4554baa9/PREECLAMPSIA_REP1/quant.sf
/c6/de63fccef598cea3cb78aa5db47188/PREECLAMPSIA_REP1/quant.sf

/3b/7c98bef7fe6d32e7224ab6579a603d/PREECLAMPSIA_REP2/quant.sf
/ee/2d458a66b1c9c884fcc483f1cf3a9d/PREECLAMPSIA_REP2/quant.sf
/ae/08fad176e185b39a563143e9b113e2/PREECLAMPSIA_REP2/quant.sf
/31/4c3480a59ac76de6e9dd7089ddffa1/PREECLAMPSIA_REP2/quant.sf

/81/6919e25d0e14867f32f8d5badbb744/PREECLAMPSIA_REP3/quant.sf
/99/5490e2e6cbf7c23e2f0548a2468829/PREECLAMPSIA_REP3/quant.sf
/bd/075e2e22cbe4725b8c874351101707/PREECLAMPSIA_REP3/quant.sf
/c1/0abac52c6cbe552a4c069b48d10fba/PREECLAMPSIA_REP3/quant.sf

/e0/8ad9657ccd23e71b5ce33adae4bb8d/PREECLAMPSIA_REP4/quant.sf
/2a/1984a7b79b83028bc746e5ecff4639/PREECLAMPSIA_REP4/quant.sf
/6d/73353a23db5e4d7cb7d9e2c92a3d65/PREECLAMPSIA_REP4/quant.sf
/d6/2b2e91c96f22feb414198b7404c536/PREECLAMPSIA_REP4/quant.sf



I have two "suppa" folders in my results, once in the "salmon" folder (263.7 MB) and once in the "star_salmon" folder (263.2 MB). They each consist of:

```Groovy
generate_events
	per_isoform
		events.ioi
	per_local_event
		events.ioe
		GTF and .ioe files for each type of splicing event          (A3, A5, AL, MX, RI, SE)
psi_per_isoform
	suppa_isoform.psi
psi_per_local_event
	suppa_local.psi
split_files
	per_isoform
		transcript_CONTROL.psi
		transcript_PREECLAMPSIA.psi
	per_local_event
		local_CONTROL.psi
		local_PREECLAMPSIA.psi
	tpms
		CONTROL.tpm
		PREECLAMPSIA.tpm
```

It looks like the two folders in salmon and salmon_star were created at different times (salmon_star later) and are otherwise mostly identical. The only differences (salmon left, star_salmon right):
![[Pasted image 20240821092610.png]]

This is what the pipeline does (from the [tutorial](https://github.com/comprna/SUPPA/wiki/SUPPA2-tutorial)):
![[SUPPA_roadmap.png]]


The files that diffSplice uses (as per [dedicated tutorial section](https://github.com/comprna/SUPPA/wiki/SUPPA2-tutorial#differential-splicing-with-local-events)) are the .ioe/.ioi, the .psi, and the .tpm files.

The IOE files contain information taken from the GTF annotation file about where exons are located in the genome, and what transcripts and genes they belong to. I immediately saw something I will need to check in the options the pipeline ran with:

> [!CHECK!!!!]
> 	IMPORTANT: On this occasion, we have used Ensembl. If the user decides to use RefSeq annotation, we suggest using the ==***--pooled-genes*** option==. RefSeq genes are labeled according to the mRNA sequences they contain, not by the gene locus. This could cause that the same id is mapped to two different places in the genome. Also, sometimes two overlapping isoforms that share some exon or splice-sites are labeled as different genes. The pooled-genes option redefines a gene as a locus with transcripts on the same strand that overlap each other in genome extent and share at least one splice-site pairwise. These issues are a big deal to calculate events and estimate PSIs, since you would be assigning wrong contributions to the events because those transcripts should be considered together as part of the same gene.

Luckily, the [parameters page](https://nf-co.re/rnasplice/parameters#input) of the pipeline says that this parameter, `--generateevents_pool_genes`, is set to true by default (yup, I should've checked that more carefully beforehand.)

##### tpm files
The iso_tpm example file from the SUPPA developers looks like this:
![[2024-08-21_iso_tpm_example_file.png]]

In the rnasplice pipeline, the file that's generated is called suppa_tpm.txt instead. The one from the folder a6/26f0de2c425f9543d3a9feb3819fd1/ looks similar to the one the developers provide:
![[2024-08-21_suppa_tpm_file.png]]
This one doesn't have the prefixes to the identifiers, as opposed to the salmon quant.sf file I just opened. But do none of them have them?




##### events.ioe files
This is how the events.ioe file looks like from the salmon directory:
![[2024-08-21_suppa_events_ioe_file.png]]
There's the name of the chromosome in the first column, the identifier of the gene, an ID for the splicing event itself (containing one of the codes A3, A5, MX, AL, AF, SE, etc for the type of splicing event), which includes two pairs of genomic coordinates (I'm guessing which part of the "genome" is included based on the event happening or not). Finally, there are two more columns: one called "alternative_transcripts" (??containing possible transcripts resulting from this event?), and a fourth one called "total_transcripts" (??).

Again, to my untrained eye, this looks okay.

I ran `sudo find /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/ -name "events.ioe"` to find all of the files.

~~3b/4cebe93ef7279d6ecd34bdf091da0c/events.ioe~~ - symlink to 8f/02557324e537987e9d004
~~94/f58eb18a126bfe5f5bf14f039b04e0/events.ioe~~ - symlink to 69/92c17f8bb1c99bb34d143392
~~a3/25537db88f97da97a364ac984e73b5/events.ioe~~ - symlink to 8f/02557324e537987e9d0048b9
1b/e0d509741ed62da01ca01becfdac10/events.ioe - proper file. no prefixes.
69/92c17f8bb1c99bb34d1433923f0a3a/events.ioe - proper file. PREFIXES.
f7/39b5eecae178b9e5e88d3c979671f9/events.ioe - proper file. no prefixes.
8f/02557324e537987e9d0048b909a142/events.ioe - proper file. PREFIXES.




##### events.ioi files

I ran `sudo find /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/ -name "events.ioi"`, and found four in the work folders (which makes sense retrospectively, since I had two completed pipeline runs:

63/a29e5ff0d741615e2f2b88816b8284/events.ioi - no prefixes.
df/8384fea229fab3ca6f03b6283d52b7/events.ioi - PREFIXES
fc/ffa5ce1850fc6f3d5ed20a545f82e6/events.ioi - PREFIXES
~~70/2bf3a959d4216c3e18ced0c84206f9/events.ioi~~ - this one's the only symlink, and it links to the                                                                                       df/8384fea229fab3ca6f03b6283d52b7 folder.

##### PSI files

From either the .ioe or the .ioi coordinates plus the tpm file (suppa_tpm.txt in the case of the pipeline), SUPPA generates the PSI files, which show how often an event happens  ("Percent Spliced In" is the usual metric for quantifying changes in alternative splicing. Easiest to understand for an exon - in what percentage of all transcripts is it included?). 

The PSI file should look like
```
Event_ID	SRR1513329	SRR1513330	SRR1513331	SRR1513332	SRR1513333	SRR1513334
ENSG00000149554;SE:chr11:125496728-125497502:125497725-125499127:+	0.7471194793	0.7892328982	0.781078454	0.4554597402	0.4493233894	0.4237912839
```

It looks like the Salmon part of the pipeline (salmon folder) managed to obtain the PSI files "per local event" (split_files -> per_local_event) but not the ones "per isoform" (split_files -> per_isoform).

###### PSI files in salmon folder:
![[2024-08-21_suppa_psi_files_salmon.png]]
suppa_local.psi, local_CONTROL.psi, and local_PREECLAMPSIA.psi are all rather large, around 11 MB, whereas suppa_isoform.psi, transcript_CONTROL.psi, and transcript_PREECLAMPSIA.psi are all tiny. 

Small wonder, since they are all empty:
![[2024-08-21_suppa_psi_file_salmon_transcript.png]]

The tutorial says that the suppa_local.psi and suppa_isoform.psi files get split into the different conditions in order to let the diffSplice script quantify the differences between treated-untreated. So generating the suppa_local.psi file apparently worked, but not generating the suppa_isoform.psi, and that's where at least some of the problems stem from.

How does the suppa_local.psi from the salmon folder look like?
![[2024-08-21_suppa_local_psi_NAs.png]]

Not good, it's all NAs everywhere. 
So somehow, getting the PSI values is the part that didn't work properly in the Salmon part.

Is it possible that the problem is again a mismatch between identifiers? The SUPPA tutorial has a note "Transcript_IDs in the expression file must be the same as the transcript_IDs in the .ioe file, including the version numbers, otherwise it won't work.". Could it be that the issue is having the non-prefixed IDs in the suppa_tpm.txt but having prefixes in the  events.ioe file? But no, I've already seen that that one contains proper-looking NCBI identifiers. 

However, I spotted the problem, and I think it's the last two columns in the events.ioe file:
![[2024-08-21_suppa_events_ioe_file_identifiers.png]]

> [!To do ]
> Here, I still have those rna- prefixes in front of all of the transcript IDs!!! This is probably why the pipeline can't quantify the PSIs properly -> I will have to remove all of these prefixes and *then* restart this part of the pipeline! The events.ioi of course has the very same issue!


###### PSI files in star_salmon folder:
![[2024-08-21_suppa_psi_files_star_salmon.png]]

The star_salmon part only generated two files, suppa_local.psi and suppa_isoform.psi, which do seem to both contain lots of info but also lots of "nan" values. They're not ***only*** NAs like the .psi files from the salmon part, so here, some exons/splice sites might just not get used at all...or is it so simple? If I look at the values, in some samples it appears as 1 vs 0, which strikes me as rather odd.

suppa_local.psi:
![[2024-08-21_suppa_local_star_salmon.png]]

suppa_isoform.psi:
![[2024-08-21_suppa_isoform_star_salmon.png]]


Interestingly, this part of the pipeline generated some somewhat more sensible-looking psi files, in spite of also having the prefixes in the .ioe and .ioi files.

The part of the pipeline that gave the error, diffSplice, should use the PSI files and the .tpm files, PREECLAMPSIA.tpm and CONTROL.tpm. The same type of split applied to the psi files happens to the suppa_tpm.txt file, resulting in the CONTROL.tpm and PREECLAMPSIA.tpm files, so that's where they come from.


##### Fix mismatch between suppa_tpm.txt files and .ioe and .ioi files

###### tpm files and prefixes
Double checking where I have the suppa_tpm.txt files, and whether they have or don't have the prefixed IDs:

```bash
sudo find -name "suppa_tpm.txt"
1 ./Pre_eclampsia_mice_rnasplice_results/salmon/tximport/suppa_tpm.txt -no prefixes
2 ./Pre_eclampsia_mice_rnasplice_results/star_salmon/tximport/suppa_tpm.txt -PREFIXES

3 ./Pre_eclampsia_Nextflow_work_folder/94/f58eb18a126bfe5f5bf14f039b04e0/suppa_tpm.txt -PREFIXES

4 ./Pre_eclampsia_Nextflow_work_folder/a6/26f0de2c425f9543d3a9feb3819fd1/suppa_tpm.txt -no prefixes

5 ./Pre_eclampsia_Nextflow_work_folder/2e/e854754f8b8356ae2d0484f72704ae/suppa_tpm.txt -PREFIXES

6
./Pre_eclampsia_Nextflow_work_folder/a3/25537db88f97da97a364ac984e73b5/suppa_tpm.txt -no prefixes

7
./Pre_eclampsia_Nextflow_work_folder/1c/c6527462913e81a675c76bda7b5b85/suppa_tpm.txt -no prefixes

8
./Pre_eclampsia_Nextflow_work_folder/4b/be20738da4815ab9d8e928e633da53/suppa_tpm.txt -PREFIXES

9
./Pre_eclampsia_Nextflow_work_folder/3c/3593b1fa74aefe7ba55a9c5f6549be/suppa_tpm.txt -PREFIXES

10
./Pre_eclampsia_Nextflow_work_folder/b1/401dd8bb1ca47549d3bc1f7d8deed1/suppa_tpm.txt -no prefixes

11
./Pre_eclampsia_Nextflow_work_folder/b0/f0e97555e06ec3fd61e8aac89f3e9e/suppa_tpm.txt -PREFIXES

```

I have two files in the "results" folder. The suppa_tpm.txt file without prefixes is in the "salmon" branch, the one without prefixes is in the "star_salmon" branch. Interestingly, the "salmon" branch, where the tpm file has no prefixes, is the one with more problems upon quantification.

In the work folder, I have WITH prefixes the work folders
3. ~~/94/f58eb18a126bfe5f5bf14f039b04e0 ~~- symlink to /4b/be20738da4815ab9d8e928e633da53
 5. ~~/2e/e854754f8b8356ae2d0484f72704ae~~ - symlink to /4b/be20738da4815ab9d8e928e633da53
 8. /4b/be20738da4815ab9d8e928e633da53 - proper file, PREFIXES.
 9. /3c/3593b1fa74aefe7ba55a9c5f6549be - proper file, PREFIXES.
 11. ~~/b0/f0e97555e06ec3fd61e8aac89f3e9e~~ symlink to /4b/be20738da4815ab9d8e928e633da53

WITHOUT prefixes:
4. /a6/26f0de2c425f9543d3a9feb3819fd1 - proper file, no prefixes.
6. ~~/a3/25537db88f97da97a364ac984e73b5~~ - symlink to /a6/26f0de2c425f9543d3a9feb3819fd1
7. ~~/1c/c6527462913e81a675c76bda7b5b85~~ - symlink to /a6/26f0de2c425f9543d3a9feb3819fd1
10. ~~/b1/401dd8bb1ca47549d3bc1f7d8deed1~~ symlink to /a6/26f0de2c425f9543d3a9feb3819fd1

That means I have 1 tpm file without prefixes, the one in /a6/26f0de2c425f9543d3a9feb3819fd1, and two with prefixes, /4b/be20738da4815ab9d8e928e633da53 and /3c/3593b1fa74aefe7ba55a9c5f6549be 


So the problem seems to arise from the fact that I have a number of quantification files from Salmon, some from an old run of the pipeline where I specified the wrong index (Ensembl identifiers), some that have the prefixes in front of the NCBI IDs, and some that don't have the prefixes. And then the same happens for the .ioe and .ioi annotation files and the tpm files. 
This means that the easiest way out would probably be to start SUPPA from scratch, using its own script and giving it a GTF file and Salmon quantification files that I know all have matching identifiers, either with or without prefixes. But I'd still prefer to do this in the context of the rnasplice pipeline, because that makes it a lot easier to trace back and fix errors, as I've done so far. So I need to make sure that I start the same run, but delete the GTF and quant.sf files that *have* the prefixes in their work folders in the hope that the pipeline will now build them all correctly.


Let's check out the traces to better understand which process generated which files, especially for my last pipeline run:
/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/pipeline_info

Find entries related to SUPPA in the execution traces in the pipeline_info folder:
```bash
sudo grep -Hni "SUPPA" /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results/pipeline_info/*.txt
```
-H = print file name 
-n = print line number and contents
-i = case-insensitive search

(side note, I found out that Nextflow also allows one to specify an [option "-with-report"](https://www.nextflow.io/docs/latest/tracing.html#execution-report) that creates an html file where the information from the traces is gathered in a much more human-friendly way, with plots about performance, etc)

Pasted results into "2024-08-22_SUPPA_tasks_execution_traces.xlsx".

I have two batches of processes related to SUPPA that are marked "COMPLETED" (and not "CACHED", which indicates that these processes picked up the data from one of their predecessors that was COMPLETED). 

***One is from the 14th of August (my very first run of the pipeline):***
63/a29e5f	29773	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:GENERATE_EVENTS_IOI (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED
1b/e0d509	29732	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:GENERATE_EVENTS_IOE (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED
f7/39b5ee	29751	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:GENERATE_EVENTS_IOE (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED
fc/ffa5ce	38378	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:GENERATE_EVENTS_IOI (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED
69/92c17f	38393	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:GENERATE_EVENTS_IOE (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED
df/8384fe	44336	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:GENERATE_EVENTS_IOI (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED
8f/025573	45724	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:GENERATE_EVENTS_IOE (GCF_000001635.27_GRCm39_genomic.gtf)	COMPLETED

***And one is from the 20th:***
1c/c65274	99337	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:PSIPERISOFORM (suppa_tpm.txt)	COMPLETED
a3/25537d	100294	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:PSIPEREVENT (suppa_tpm.txt)	COMPLETED
d0/285534	101163	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:SPLIT_FILES_IOI (suppa_isoform.psi)	COMPLETED
b0/f0e975	101137	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:SPLIT_FILES_TPM (suppa_tpm.txt)	COMPLETED
b1/401dd8	101130	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:SPLIT_FILES_TPM (suppa_tpm.txt)	COMPLETED
5c/3033d5	101911	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:SPLIT_FILES_IOE (suppa_local.psi)	COMPLETED
2e/e85475	120384	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:PSIPERISOFORM (suppa_tpm.txt)	COMPLETED
94/f58eb1	121280	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:PSIPEREVENT (suppa_tpm.txt)	COMPLETED
70/2bf3a9	121738	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:DIFFSPLICE_IOI (PREECLAMPSIA-CONTROL)	FAILED

***Everything else was used from a cache, e.g. on the 20th:***
8f/025573	45724	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:GENERATE_EVENTS_IOE (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED
fc/ffa5ce	38378	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:GENERATE_EVENTS_IOI (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED
69/92c17f	38393	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:GENERATE_EVENTS_IOE (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED
df/8384fe	44336	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:GENERATE_EVENTS_IOI (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED
8f/025573	45724	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:GENERATE_EVENTS_IOE (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED
fc/ffa5ce	38378	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:GENERATE_EVENTS_IOI (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED
df/8384fe	44336	NFCORE_RNASPLICE:RNASPLICE:SUPPA_SALMON:GENERATE_EVENTS_IOI (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED
69/92c17f	38393	NFCORE_RNASPLICE:RNASPLICE:SUPPA_STAR_SALMON:GENERATE_EVENTS_IOE (GCF_000001635.27_GRCm39_genomic.gtf)	CACHED

It looks like I might still have the IOE and IOI files I generated the first time around, before I had to modify any of the identifiers for tximport to work, and the pipeline used these when calculating the PSI per isoform, per event, etc. I'll check the work folder for some of the cached operations, to see if they symlink to the files created on the 14th. And no, it is the actual folder that was created on the 14th! This is true for all of the other cached results. So the pipeline simply used the cached files stored in these directories. Which means this is likely the root of all evil in this case ***[chuckle]***.

I now also know where are the .ioi and .ioe files for this run are located:
8f/025573 - events.ioe, plus all of the parts relating to specific exons, alternative splice site, etc. Contains prefixes.
69/92c17f - events.ioe, plus all of the parts relating to specific exons, alternative splice site, etc. Contains prefixes.
df/8384fe - events.ioi. Contains prefixes.
fc/ffa5ce	 - events.ioi. Contains prefixes.

This is all getting extremely convoluted. The easiest way would probably be to delete all of the folders in the work folders that I identified as containing "COMPLETED" processes, and starting the pipeline again with only SUPPA activated and all other outcome options set to false, to not have it run any other parts of the pipeline.

I went systematically through the work folder, based on the Excel file, and deleted the files one by one with `sudo rm -r` to avoid any other issues.

## Interim pipeline run continuation without SUPPA

started around 11:30 AM
12:24: results folder = 167 GB, work folder = 166.6 GB
```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--sashimi_plot false \
--suppa false \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-resume d2143e7b-2e6a-41e4-850d-cb8af9596f82
```

## Resume pipeline with new SUPPA run 

I will try to let the pipeline run SUPPA only and directly from Salmon quant.sf files, with the option
--source salmon_results activated.

The sample sheet needs to look like:

```
sample,condition,salmon
CONTROL_REP1,control,AEG588A1.tar.gz
CONTROL_REP2,control,AEG588A2.tar.gz
CONTROL_REP3,control,AEG588A3.tar.gz
TREATMENT_REP1,treatment,AEG588A4.tar.gz
TREATMENT_REP2,treatment,AEG588A5.tar.gz
TREATMENT_REP3,treatment,AEG588A6.tar.gz
```

The quant.sf files that seem to have worked were the ones used in the star_salmon run of the pipeline. The ones in the results file that fit it are the ones WITH the prefixes, so that's what I should give the pipeline.

I made the file samplesheet_preeclampsia_SalmonSUPPA.csv:
```
sample,condition,salmon_results
CONTROL_REP1,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/salmon/CONTROL_REP1
CONTROL_REP2,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/salmon/CONTROL_REP2
CONTROL_REP3,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/salmon/CONTROL_REP3
CONTROL_REP4,CONTROL,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/salmon/CONTROL_REP4
PREECLAMPSIA_REP1,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/salmon/PREECLAMPSIA_REP1
PREECLAMPSIA_REP2,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/salmon/PREECLAMPSIA_REP2
PREECLAMPSIA_REP3,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/salmon/PREECLAMPSIA_REP3
PREECLAMPSIA_REP4,PREECLAMPSIA,/home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/salmon/PREECLAMPSIA_REP4
```


I also used --suppa_tpm to give the pipeline a distinct tpm file, one of the ones with prefixes, and set --diffsplice_paired to false to better reflect the experimental setup.

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--source salmon_results \
--rmats false \
--dexseq_dtu false \
--dexseq_exon false \
--edger_exon false \
--suppa_tpm /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/suppa_tpm.txt \
--diffsplice_paired false \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_SalmonSUPPA \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_SalmonSUPPA \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/samplesheet_preeclampsia_SalmonSUPPA.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-with-report
```

Annnd it completed successfully :) I tried looking into the execution_timeline and execution_report files, and initially couldn't, because, apparently, I am not the owner. Rectified that for the files execution_timeline_2024-08-22_17-46-37.html and execution_report_2024-08-22_17-46-37.html using `sudo chown`, and I could then open the reports.

They are a dream to look at. They even contain the info that's in the trace files, with even more detailed information on how long the tasks ran, how much resources they used up, etc.

Here's a snippet from the timeline:
![[2024-08-22_SUPPA_pipeline_timeline.png]]

And here from the report (it's interactive!)
![[2024-08-22_SUPPA_pipeline_report.png]]
![[2024-08-22_SUPPA_pipeline_report2.png]]

> [!NB for future use:]
> They're using something called Plotly to create the interactive plots, which is Python-based

# Original authors' results

From GEO page "Methods: E17.5 cortex mRNA profiles of offspring from control and preeclampsia mother mice were generated by deep sequencing, in triplicate, using Illumina GAIIx. The sequence reads that passed quality filters were analyzed at the transcript isoform level with two methods: Burrows–Wheeler Aligner (BWA) followed by ANOVA (ANOVA) and TopHat followed by Cufflinks.  
Results: Using an optimized data analysis workflow, we ==***mapped about 30 million sequence reads***==  per sample to the mouse genome (build mm9) and ==***identified 16,014 transcripts in the E17.5 cortexes of offspring from control and preeclampsia mother mice with BWA workflow***== and ==***34,115 transcripts with TopHat workflow***==."

# General stats

By analyzing the BAM files, Samtools Stats returned a total of around 40 million reads mapped per sample. From these 40 million, STAR returned 20 million uniquely mapped reads. Knowing that I have a read length of 150 bp, what's the coverage and depth I reached for this dataset? How does this fit with what people usually use for alternative splicing analysis? Also: it looks like I lost around 20% of most uniquely mapped reads in the Salmon step, leaving me with only around 15-16 million reads per sample. This may be due to the fact that the NCBI annotation file (GTF) I used is not as exhaustive as the GENCODE annotation file.

> [!To do]
> coverage calculation. A depth of 50-100x coverage is often desired for confident detection of **rare or tissue-specific splicing events**.

# Running DESeq2 to get gene expression results

For quantifying gene expression in a non-splice-sensitive way, I went with DESeq2, and decided to run it in a separate R project, called "". I made a script called "2024-08-22_DESeq2_pre-eclampsia", based on the one from the course from Ioana Lemnian[link to Ioana's page], but updated to reflect the DEseq2 [tutorial](https://bioconductor.org/packages/devel/bioc/vignettes/DESeq2/inst/doc/DESeq2.html).

> [!correspondence my variables ~ variables official tutorial]
> my_ddsTxi ~ dds and ddsTxi ~ : the DESeqDataSet which DESeq2 performs the analysis on
> my_dds_filtered ~ : version of the DESeq2DataSet after rows with low counts are removed
> my_DESeq_gene : raw DESeq2 result with nominal p values
> my_DESeqGene_result ~ res: DESeq2 result with p values adjusted for multiple comparisons with the Benjamini-Hochberg method (FDR)

## Run DESeq2
I used the Salmon quant.sf files generated by the star_salmon run of the pipeline, the ones containing prefixes for the identifiers. For the tx2gene file from the pipeline, I used "GCF_000001635.27_GRCm39_genomic_PREFIXES.tx2gene.tsv", which, in essence, is a copy of the file I initially termed "FAULTY" because it contained the prefixes. But it will do for the DESeq quantification.

I ran all of the DESeq2 steps and then tried the interactive plotting with the plotMA function from the DESeq2 package, but was not satisfied with the interactive selection of data points and how the gene names displayed. I therefore tried using Plotly (see above), but the plots would not display neither in the viewer nor open in a web browser. I read that this is an[ issue that the latest version of R causes with Rstudio's veiwer](https://github.com/rstudio/rstudio/issues/14603) and that a patched version (R-4.4.1patched) would fix it. I installed the new version from https://cran.r-project.org/bin/windows/base/rpatched.html and restarted RStudio. I then reopened RStudio, went to Tools -> Global Options -> General, and set the R installation to be used to the new, patched version. And now it works - I have Plotly plots in which I can click on individual dots to see the gene name associated with it.

## Authors' DEG analyses from source publication

"the clean reads were obtained and aligned to the mouse genome (mm10, NCBI) using **Hisat2** ([82](https://www.life-science-alliance.org/content/6/8/e202301957#ref-82)). **HTSeq** was applied to obtain gene counts, and gene expression was determined using the RPKM method ([83](https://www.life-science-alliance.org/content/6/8/e202301957#ref-83))."

"For the analysis of DEGs, the **EBSeq algorithm** ([85](https://www.life-science-alliance.org/content/6/8/e202301957#ref-85)) was applied to filter DEGs, after the significant analysis, _P_-value, and false discovery rates (FDRs) were calculated. The following criteria were used: (i) **log2(fold change) >0.585 or <−0.585** for E17.5 RNA-seq and >0.263 or <−0.263 for adult hippocampus RNA-seq; and (ii) FDR<0.05 ([86](https://www.life-science-alliance.org/content/6/8/e202301957#ref-86))."

By setting these criteria, the authors found a total of 256 DEGs with log2FCs between -4.61 and 4.68 (0,04 to 25-fold change). They set cutoffs at 0.585 and -0.585, which corresponds to a 1.5-fold increase or decrease down to 66%, respectively.

I am not convinced by the authors' use of EBSeq instead of DESeq2. Its latest update is 8 years ago, whereas DESeq2 is regularly maintained (last update is from a month ago, July 2024). Additionally, it uses RPKM, which is suitable for intra-sample gene expression level comparison, but NOT for DEG analysis between samples. EBSeq does have the advantage of having been developed specifically for identifying alternative transcript usage, so not just at the gene expression level, but it performs better on complex experimental setups (multiple intra- and inter-subject comparisons), whereas DESeq can also perform transcript-level analysis if the txi object it uses is previously generated with the "txOut = TRUE" argument. Interestingly, the authors still report their results at gene level, not transcript level.

`txi <- tximport(files, type = "salmon", txOut = TRUE)`

**EBSeq**: [https://academic.oup.com/bioinformatics/article/29/8/1035/228913](https://academic.oup.com/bioinformatics/article/29/8/1035/228913) and [https://bioconductor.org/packages/release/bioc/html/EBSeq.html](https://bioconductor.org/packages/release/bioc/html/EBSeq.html)

Tutorial: [https://github.com/lengning/EBSeq](https://github.com/lengning/EBSeq)


## Authors' GO analyses from source publication

**"GO analysis** was performed to facilitate elucidating the biological implications of the DEGs in the experiment. DEGs in the cortices of E17.5 embryos exposed to PE were compared with the genes in the Human Gene module of Simons Foundation for Autism Research Initiative using enrichment analysis via **phyper function in R**."


# Completing git repo with results

I tried adding all of the results to the git repo in one go, and that was too much data at once, and I think my connection kept dropping during the upload process. So, I want to now backroll the commit with all of these files, and try adding the results folders from the different parts of the pipeline separately. I used [this tutorial ](https://www.geeksforgeeks.org/whats-the-difference-between-git-reset-mixed-soft-and-hard/)to better understand the reset options for Git. It says:

> [!NOTE]
> "### Overview of git reset
> 
> - ****git reset –mixed:**** Resets the HEAD and updates the staging area, but leaves the working directory unchanged.
> - ****git reset –soft:**** Only resets the HEAD, leaving both the staging area and the working directory unchanged.
> - ****git reset –hard:**** Resets the HEAD, updates the staging area, and resets the working directory to match the specified commit."

So what I need to do is a mixed reset. I initially thought I might need to use `git revert`, since I am using an online repository and that would create a fully new commit when reverting to a previous state, so that the entire history of changes is preserved, including this change (doesn't lose commits between the current one and the one I'd be reverting to). However, I checked my online repository, and none of the results files seem to have uploaded. Plus, my last commit is from the week of August 11th:
![[2024-08-29_current_git_online_status.png]]

Based on [this tutorial](https://www.freecodecamp.org/news/git-reverting-to-previous-commit-how-to-revert-to-last-commit/),  it's safe to do a default (mixed) reset, with which I can set the head to point at the previous commit. To find out which one that was, I used `git log --oneline` in the Visual Studio Code terminal to display all of my commits. What I get is:

![[2024-08-29_current_git_log.png]]

So the commit I need to reset to is fa817ae, the one right before the current one. This will perform a mixed reset, after which I can add the changed files in smaller batches to the staging area and commit them in these smaller packets. I did it with `git reset fa817ae`, and all was good, and I could finally upload the results files in small batches and avoiding large ones, such as the .rds files that rMATS and DEXSeq exon produce.


# Check results of other pipeline components

For all of these, I used the results I got from the star_salmon arm of the pipeline (I copied the results folders to my Win-Ubu shared folder)

## Checking DEXSeq differential transcript usage (DTU) results

DEXSeq was originally created for the quantification of how often an exon is used in all of the transcripts that a gene locus generates. Like DESeq2, it uses tximport to create an object containing the reads for all genes across samples, imported from the Salmon quantification files.


Recommended workflow options:
![[2024-08-30_DEXSeq_DTU_workflow_from_tut.png]]

The DEXSeq author's recommendation is to use the `scaledTPM` method to generate the counts from the abundance data [how is this done? What are the differences between the scaling methods? See Trapnell et al., 2013]. The pipeline does this automatically by setting a parameter called `dtu_txi = 'dtuScaledTPM'` in the config file.

Next, the pipeline used [DRIMSeq](https://bioconductor.org/packages/release/workflows/vignettes/rnaseqDTU/inst/doc/rnaseqDTU.html#drimseq), just as per the [recommendations](https://bioconductor.org/packages/release/workflows/vignettes/rnaseqDTU/inst/doc/rnaseqDTU.html#dtu-testing), as a statistical model to identify differentially expressed transcripts from the cts object output by tximport. This complements the DEXSeq algorithm, which was originally created for estimating differences in exon usage, and can return lots of false positives in terms of significant FDRs when it comes to complete transcripts. Instead, DRIMSeq assumes that the counts for all of the transcripts that a gene produces, taken together, stay constant, but what differs is the proportion in which each transcript contributes to the total counts. This way, DRIMSeq can detect differential transcript usage between conditions when these ratios vary more strongly between conditions than they do between the samples of a single condition.

! In the cts object, the column sums should be equal to the number of reads that were mapped by Salmon !!!

The only objects I can find in the "results" folder are the DEXSeqDataSet, the results, and perGeneQValue in RDS format, and then the results and perGeneQValue in TSV format as well. So, if I want to look into what the pipeline did before that, such as the actual transcript reads generated by tximport, I'll have to find it in the "work" folder.

I have two folders where tximport worked, both from 20.8., and they both contain a variety of tsv files. The folders are 
a6/26f0de2c425f9543d3a9feb3819fd1 from "salmon" part of pipeline
4b/be20738da4815ab9d8e928e633da53 from "star_salmon" part of pipeline. These files are slightly larger, but also contain the prefixes.

I imported the TSV file DEXSeqResults.PREECLAMPSIA-CONTROL.tsv from the star_salmon part of the pipeline. It has several columns:

"groupID" - the gene the transcripts belong to
"featureID" - the transcript identifier (I double checked with `n_distinct(DEXSeq_res$featureID)`, and they're indeed all unique)            
"exonBaseMean" - confusingly, in this case, how highly expressed a transcript is across all of the samples
 "dispersion" - degree of variability in transcript usage between samples
"stat" - usually, the Wald test statistic calculated for this transcript
 "pvalue" -                   
"padj" - 
 "PREECLAMPSIA"  -                
"CONTROL" -
"log2fold_CONTROL_PREECLAMPSIA" - 

## Checking DEXSeq differential exon usage (DEU) results

perGeneQValue() function calculates a so-called Q value. This is a FDR calculated for the entirety of a gene, which tells us if at least one exon in that gene undergoes alternative usage (note: authors specifically use "differential usage" because exons at the 5' end of a gene can be differentially used for reasons other than alternative splicing, such as using different transcription start sites when alternative promoters get activated). To get the number of genes with at least one differentially used exon:
numbOfGenes = sum( perGeneQValue(dxr) < 0.1)

## Checking edgeR differential exon usage results

Tutorial: https://bioconductor.org/packages/devel/bioc/vignettes/edgeR/inst/doc/edgeRUsersGuide.pdf

edgeR is usually used for DEG analysis, but is used in the context of the rnasplice pipeline to perform differential exon usage analysis.

The rnasplice pipeline used featureCounts to generate the table of read counts (=reads aligning to each gene or exon, derived from the BAM files produced by STAR) that edgeR works on. edgeR can also work on the transcript level if the estimated abundances are input from Salmon quantification files via tximport.

From the pipeline, I got several result files from edgeR: exprs.csv, usage.exon.csv, a usage.gene.csv, and a usage.simes.csv. The ouput page of the pipeline says the following:

" Results CSV files are also output per comparison as `{contrast}.usage.usage.csv` [I suspect they mean usage.exon.csv] which contain the differential exon usage results, `{contrast}.usage.gene.csv` which contain results at a gene level identified with F-tests, and `{contrast}.usage.simes.csv` which contain results at a gene level using the Simes adjustment."


The edgeR manual says:
"Both exon-level and gene-level tests can be performed simultaneously using the diffSpliceDGE() function in edgeR. The exon-level test tests for the significant difference between the exon’s logFC and the overall logFC for the gene. Two testing methods at the gene-level are provided. The first is to conduct a gene-level statistical test using the exon-level test statistics. Whether it is a likelihood ratio test or a QL [quasi-likelihood] F-test depends on the pipeline chosen. The second is to convert the exon-level p-values into a genewise p-value by the Simes’ method. The first method is likely to be powerful for genes in which several exons are differentially spliced. The Simes’ method is likely to be more powerful when only a minority of the exons for a gene are differentially spliced."

"The quasi-likelihood (QL) method is highly recommended for differential expression analyses of bulk RNA-seq data as it gives stricter error rate control by accounting for the uncertainty in dispersion estimation. The likelihood ratio test can be useful in some special cases such as single cell RNA-seq and datasets with no replicates."

- exprs.csv - appears to include values related to exons (several data points per gene)
- usage.exon.csv - exon-level FDR and log2 fold changes
- usage.gene.csv - I assume these are the gene-level statistical tests using the exon-level test statistics
- usage.simes.csv - these have to be the genewise p-values, converted from the exon-level p-values by the Simes’ method
## Checking rMATS alternative splicing results

Tutorial explaining the output: https://bioinformatics.ccr.cancer.gov/docs/btep-coding-club/CC2023/rmats/

...I just saw on the rnasplice pipeline page something that eluded me before: "Furthermore, --rmats_read_len has to be set by the user and if the read length is variable, an average or median read length has to be specified." I checked, and I had not set such a parameter before. I know from the[ parameters page ](https://nf-co.re/rnasplice/1.0.4/parameters/#rmats-options)that the pipeline sets the default to 40, and, even though I do see that NOT_EXPECTED_READ_LENGTH is 0 for all samples in the read_outcomes_by_bam.txt file, the analysis might not be correct. This means I need to re-run the rMATS part of the pipeline with 
`--rmats_read_len 150`. In the meanwhile, I can set up my scripts to check the analysis quality and the results, as I will be able to reuse these once I have the new rmats results.

### ==**To do**==
 - [ ] check info from C:\Win_Ubuntu_shared\Pre-eclampsia_dataset_raw_and_processed\Pre_eclampsia_mice_rnasplice_results\rmats\PREECLAMPSIA-CONTROL\rmats_temp\2024-08-20-18_20_27_773885_read_outcomes_by_bam.txt
 - [ ] **check read coverage**
 - [x] **check distribution of p-values/FDR**
 - [ ] check JCEC datasets for each of the splicing event types

### rMATS pipeline part re-run with adjusted -- parameter

I checked the TSV file with the read length counts from the MultiQC report that the previously completed pipeline run had generated. It does indeed look like the median read length is 150 bp across all of the samples, with 518871962 reads from the total of 650708713 across all samples still being of this length after trimming (79%). This is why I set the --rmats_read_len parameter to 150. I first ran it without resuming the run that had successfully completed without SUPPA and soon realized that it was trying to re-trim all of the reads and re-align them, so I cancelled that run and added the "-resume d2143e7b-2e6a-41e4-850d-cb8af9596f82" to try to re-run the previous run. However, that gave me an error saying "Report file already exists: /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder/true -- enable the 'report.overwrite' option in your config file to overwrite existing files
" and then interrupted, so I understand that it considers the pipeline run completed and just wanted to rewrite the report, meaning it did not account for the change in the rMATS parameter. So I decided to continue today's run of the pipeline, 4718b1b9-5107-4741-a4b8-dd9b14854130. And whoops, got the same error again. So I set --report.overwrite=true ...which did not work, in any format whatsoever. 

I could set the parameter to false in the nextflow.config files - I found many of them on my system, but also one in "/home/iweber/.nextflow/assets/nf-core/rnasplice/", which I suspect is the one the pipeline actually uses. 

To be extra sure that this is the right config file, I accessed the nextflow.log files in my work directory, and they all have a line saying "Sep-04 11:07:50.453 [main] DEBUG nextflow.config.ConfigBuilder - Found config base: /root/.nextflow/assets/nf-core/rnasplice/nextflow.config", so I suspect that's the real location.  I wanted to access it, and tried from the command line with `sudo cd root/.nextflow/assets/nf-core/rnasplice`, but was denied permission regardless. This is when I learned about how to open an elevated/root shell, in which I am indeed acting as the "root" user: just run `sudo -i` ! I then used the cd command without the sudo to get to the rnasplice folder, and accessed the nextflow.config file via nano.

Instead of changing the report.overwrite parameter to false, I simply changed the name that the report will have. It usually is
```Groovy
report {
    enabled = true
    file    = "${params.outdir}/pipeline_info/execution_report_${trace_timestamp}.html"
```
so I changed it to 

```Groovy
report {
    enabled = true
    file    = "${params.outdir}/pipeline_info/execution_report_NR2${trace_timestamp}.html"
```

saved, and then exited the root shell with `exit`. I tried re-running:

```bash
cd /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder

conda activate Nextflow

sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--multiqc_title "rMATS_run_multiQC" \
--rmats true \
--rmats_read_len 150 \
--sashimi_plot false \
--suppa false \
--dexseq_dtu false \
--edger_exon false \
--dexseq_exon false \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_rMATS \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star_salmon \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--salmon_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/NCBI_Salmon_index_M_musculus_mm10 \
--save_unaligned true \
--save_align_intermeds true \
--save_reference true \
-profile docker \
-with-report true \
-resume 4718b1b9-5107-4741-a4b8-dd9b14854130
```

but it still didn't fix the issue, so I realized I have no time for this. I decided to start a fully new pipeline run while also kicking the Salmon run out, since this will not be needed for the rMATS output. I also created a new work folder to avoid any other collisions with the previous run of the pipeline.

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--multiqc_title "rMATS_run_multiQC" \
--rmats true \
--rmats_read_len 150 \
--sashimi_plot false \
--suppa false \
--dexseq_dtu false \
--edger_exon false \
--dexseq_exon false \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_rMATS \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_rMATS \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--save_reference true \
-profile docker \
-with-report true
```

This indeed restarted the entirety of the pipeline, which ran through the STAR part and reached the Samtools sort part. However, this is where my virtual machine crashed, because of lack of space (it would seem it produced over 200 GB of results!). In the error message the machine showed me, related to the vmdk disk, I chose the option to power off the VM, as I saw from Windows Explorer that space was the issue (there were something like 45 kB left on the VM partition *sweat smile*). I went to the VM folder and saw that I had three-four older snapshots, each some 94 GB in size, so I went to the Snapshot Manager in VMware and attempted to delete the old snapshots from there. I left the last two snapshots in place, an auto-snapshot and one I had created manually on August 23rd.

 Upon hitting "delete" on the old snapshots, it showed a progress bar for a fraction of a second, then gave me an error "An error occurred while consolidating disks: There is not enough space on the file system for the selected operation." After I hit ok, the snapshots vanished from the Snapshot Manager. I now had around 29 GB free on my drive. I noticed there is also a recycle bin folder outside of the VMware folder, and I emptied that one, leaving me with a total of 94 GB of space on the disk. I wanted to expand the virtual machine's disk size further, but it told me I cannot do that while there still are snapshots on the disk. So I went in to delete the last snapshots in the Snapshot Manager, only to now get an error "An error occurred while consolidating disks: The specified virtual disk needs repair."

However, I simply tried my luck and started the virtual machine, which...worked. I ran the log command for Nextflow, and found that my previous run had the hash 4b5f396a-a8f4-47b8-8a72-f78513d90127, so I used

```bash
sudo nextflow run nf-core/rnasplice -r 1.0.4 \
--max_cpus 6 \
--max_memory 90.GB \
--multiqc_title "rMATS_run_multiQC" \
--rmats true \
--rmats_read_len 150 \
--sashimi_plot false \
--suppa false \
--dexseq_dtu false \
--edger_exon false \
--dexseq_exon false \
-w /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_Nextflow_work_folder_rMATS \
--outdir /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_rnasplice_results_rMATS \
--input /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/samplesheet_preeclampsia.csv \
--contrasts /home/iweber/Documents/Backup_shared_folder/Pre-eclampsia_dataset_raw_and_processed/Pre_eclampsia_mice_raw_fastq/contrastssheet_preeclampsia.csv \
--fasta /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna \
--gff /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.gff \
--save_trimmed true \
--aligner star \
--star_index /home/iweber/Documents/Backup_shared_folder/Genomes/genome_M_musculus/GCF_000001635.27/STAR_index_M_musculus \
--save_reference true \
-profile docker \
-with-report true \
-resume 4b5f396a-a8f4-47b8-8a72-f78513d90127
```


### ==read outcomes check==
Columns Breakdown:

- **USED**: The number of reads that were successfully used in the splicing analysis.
- **NOT_PAIRED**: The number of reads that were discarded because they were not part of a properly paired-end read. In paired-end sequencing, both reads from a pair should map correctly for inclusion.
- **NOT_NH_1**: Reads that mapped to multiple locations in the genome (multimapped reads). These reads are often discarded since they do not provide unambiguous information about splicing.
- **NOT_EXPECTED_CIGAR**: Reads with an unexpected CIGAR string, indicating alignment issues. These reads may not support the expected splicing or exon-exon junctions.
- **NOT_EXPECTED_READ_LENGTH**: Reads that were discarded due to unexpected read length (should usually be 0, indicating consistent read length).
- **NOT_EXPECTED_STRAND**: Reads discarded due to unexpected strand orientation (may apply in strand-specific RNA-seq protocols).
- **EXON_NOT_MATCHED_TO_ANNOTATION**: Reads that mapped to exons but were discarded because they didn’t match the provided annotation.
- **JUNCTION_NOT_MATCHED_TO_ANNOTATION**: Reads mapping to junctions that didn’t match the annotation.
- **CLIPPED**: Reads with significant soft-clipping, where parts of the read weren’t aligned (generally removed from analysis).
- **TOTAL_FOR_BAM**: The total number of reads in the BAM file.

 Steps to Use This Information for Quality Check:

1. **Proportion of "USED" Reads**: The **USED** reads are the reads that were actually included in the rMATS splicing analysis. A high proportion of used reads relative to the total reads (given in `TOTAL_FOR_BAM`) suggests good data quality.
    
    You can calculate the proportion of used reads as:
    
    Proportion used=USEDTOTAL_FOR_BAM\text{Proportion used} = \frac{\text{USED}}{\text{TOTAL\_FOR\_BAM}}Proportion used=TOTAL_FOR_BAMUSED​
    
    If this value is low (e.g., below 80%), you may need to investigate the reasons why so many reads were discarded.
    
2. **Reasons for Discarded Reads**: Check the categories that account for reads that were discarded, such as:
    
    - **NOT_PAIRED**: If this number is high, it suggests issues with paired-end sequencing data.
    - **NOT_NH_1**: A high count here suggests that many reads map to multiple locations, possibly due to repetitive regions in the genome.
    - **NOT_EXPECTED_CIGAR** and **EXON_NOT_MATCHED_TO_ANNOTATION**: These categories could indicate issues with alignment quality or annotation mismatches. For example, if you're using an incorrect or incomplete annotation file, many reads might not match the expected exons or junctions.
    - **JUNCTION_NOT_MATCHED_TO_ANNOTATION**: This could be a sign that the annotations are incomplete, or the splicing patterns are highly novel or uncharacterized.
3. **Comparing Across Samples**: You can compare the read outcome statistics across different BAM files (representing different replicates or conditions) to ensure consistency. Large discrepancies between samples may indicate differences in sequencing quality or alignment quality.
    

Visualizing the Results in R

To systematically check this information and make it easier to interpret, you can load the file into R and calculate the proportion of reads used, along with a breakdown of discarded reads across categories.

1. **Load the File into R**

Here’s how you can read in the `read_outcomes_by_bam.txt` file and calculate the statistics:

`library(tidyverse)  # Load the data read_outcomes <- read_delim("path/to/read_outcomes_by_bam.txt", delim = "\t", col_names = FALSE)  # Reshape the data into a usable format # Assuming the file structure alternates between a BAM file name and corresponding stats read_outcomes <- read_outcomes %>%   mutate(group = rep(1:(n()/10), each = 10)) %>%  # Each BAM file has 10 lines of stats   pivot_wider(names_from = X1, values_from = X2) %>%   rename(BAM = BAM)  # Convert relevant columns to numeric read_outcomes <- read_outcomes %>%   mutate(across(c(USED, NOT_PAIRED, NOT_NH_1, NOT_EXPECTED_CIGAR,                    NOT_EXPECTED_READ_LENGTH, NOT_EXPECTED_STRAND,                    EXON_NOT_MATCHED_TO_ANNOTATION, JUNCTION_NOT_MATCHED_TO_ANNOTATION,                    CLIPPED, TOTAL_FOR_BAM), as.numeric))  # Calculate the proportion of reads used read_outcomes <- read_outcomes %>%   mutate(Proportion_Used = USED / TOTAL_FOR_BAM)  # View the cleaned data head(read_outcomes)`

 2. **Check the Proportion of Used Reads**

You can now visualize the proportion of reads used for each BAM file:

`# Bar plot of the proportion of reads used across BAM files ggplot(read_outcomes, aes(x = BAM, y = Proportion_Used)) +   geom_bar(stat = "identity", fill = "blue") +   theme_minimal() +   labs(title = "Proportion of Used Reads Across BAM Files",        x = "BAM File",        y = "Proportion of Reads Used") +   coord_flip()  # Flip coordinates for easier reading if many BAM files`

This will help you quickly identify whether certain samples have a low proportion of reads used.

 3. **Visualize Discarded Reads by Category**

You can also visualize the number of discarded reads across various categories (e.g., not paired, multimapped, not matching exons/junctions):

`# Reshape the data for plotting discarded reads by category read_discarded <- read_outcomes %>%   select(BAM, NOT_PAIRED, NOT_NH_1, NOT_EXPECTED_CIGAR,           EXON_NOT_MATCHED_TO_ANNOTATION, JUNCTION_NOT_MATCHED_TO_ANNOTATION) %>%   pivot_longer(cols = -BAM, names_to = "Category", values_to = "Count")  # Plot discarded reads by category ggplot(read_discarded, aes(x = BAM, y = Count, fill = Category)) +   geom_bar(stat = "identity", position = "stack") +   theme_minimal() +   labs(title = "Discarded Reads by Category Across BAM Files",        x = "BAM File",        y = "Number of Discarded Reads") +   coord_flip()  # Flip coordinates for easier reading`

This stacked bar plot will help you see which types of discarded reads are most prevalent for each sample.

 Summary of Quality Checks:

- **Proportion of Reads Used**: A high proportion of used reads indicates good quality data. You can set a threshold for what you consider acceptable (e.g., above 80% used).
- **Discarded Reads**: Check the reasons for discarded reads (e.g., unpaired, multimapped, CIGAR mismatch, not matching annotation). If a specific category accounts for many discarded reads, it may highlight issues with data quality, annotation, or alignment.
- **Comparing Samples**: Large differences in read usage across samples may indicate quality issues that need further investigation (e.g., library preparation issues, sequencing depth variation, alignment problems).

By using these insights from `read_outcomes_by_bam.txt`, you can ensure the quality of the data going into the rMATS analysis and better understand any potential sources of splicing noise or error.

### read coverage check

### p-value/FDR distribution check


### Checking JCEC files with the actual splicing events

Example for SE data: 
Imported JCEC file as tibble. The most relevant columns are, aside from the FDR, IncLevelDifference (this is the delta percent spliced in, dPSI, showing what the difference between the usage of an exon is between conditions), and IncLevel1 and IncLevel2, which show the inclusion values for control vs pre-eclampsia, each of them for the four replicates.

Many of the IncLevel1 and IncLevel2 observations contain NA values. Since rMATS needs a certain read coverage specifically across splice sites at the ends of exons to be able to calculate PSIs and dPSIs, not having enough coverage at these locations might be causing these results. 

## Checking SUPPA alternative splicing results


# Interactive Visualizations with Plotly

Things I learned:
- Color mappings are mandatorily inherited from one Plotly trace in a plot to the ones that come after/above it. If wanting to force a trace to only use points of one color, use color = I("color_of_choice")
- Plotly plot objects are potentially not saved properly in the RDS format. Even though I could open them in the Shiny app.R script and they seemed okay, once I launched the app, it briefly flickered open and immediately crashed with an error message about the file not being accessible.
- Shiny processes working directories differently than what getwd() returns. Even though one can manually import certain plots from the script itself outside of 


# Shiny app
## Citations
"If you use nf-core/rnasplice for your analysis please cite:

* The pipeline
  https://doi.org/10.5281/zenodo.8424632
* The nf-core framework
  https://doi.org/10.1038/s41587-020-0439-x
* Software dependencies
  https://github.com/nf-core/rnasplice/blob/master/CITATIONS.md"

Robinson, MD, McCarthy, DJ, Smyth, GK (2010). edgeR: a Bioconductor package for differential expression analysis of digital gene expression data. Bioinformatics 26, 139–140.

---
# ACTIVELY WORKING ON ^above

---

# To dos

check how authors
- [x] did their gene expression analysis
- [x] filtered for lowly expressed genes - INFO NOT FOUND 
and that's because they likely never did it and that's why they have fourfold increases/decreases for some genes - they have fields with 0 reads!
- [x] filtered DEGs for FDR and fold change
- [ ] ~~generated Z scores for the heatmap~~ no info on this in paper

find
- [x] their result tables of DEGs, their P values, and Z scores
- [ ] RNA-Seq data from adult hippocampi

test
- [x] expression levels and significance I find for the genes they highlight in figure 2G
- [x] same for any other data they have in result tables

git
- [x] change commit to exclude results and then add piecemeal before pushing to repo 

change
- [x] everything that's a data frame to a tibble
- [x] everything that isn't Plotly or ggplot2 to one of them
- [ ] exploratory graphs to be nicer

make
- [ ] MA plots for both LFC shrinkage and non-LFC shrinkage data
- [ ] volcano plots for both LFC shrinkage and non-LFC shrinkage data

run pipeline
- [ ] adult hippocampi RNA-seq data

compare
- [ ] genes and splicing de-regulated in embryonic cortices vs same in adult hippocampi - any overlap?

# Other useful Nextflow parameters
How Nextflow interprets strings in scripts:
https://www.nextflow.io/docs/latest/script.html#string-interpolation 
basics:
1. double quotation marks, but not single, allow Nextflow to read values stored in variables, e.g. $my_variable
2. using `\` at the end of a line is a non-breakable space -> can be used to spread a command across multiple lines while Nextflow still interprets it as one single line
3. blocks of text spanning several lines can be put in triple quotation marks
4. it also, of course, supports regular expressions https://www.nextflow.io/docs/latest/script.html#regular-expressions

The names of parameters that Nextflow knows and that can be set in scripts or otherwise: https://www.nextflow.io/docs/latest/script.html#regular-expressions launchDir, projectDir

For parameters to be used in case one ever publishes a pipeline, even if only just on GitHub or some other repository: https://www.nextflow.io/docs/latest/config.html#scope-manifest


# Installing R and RStudio on the virtual machine, plus relevant packages

From https://cran.r-project.org/
```
# update indices
sudo apt update -qq
# install two helper packages we need
sudo apt install --no-install-recommends software-properties-common dirmngr
# add the signing key (by Michael Rutter) for these repos
# To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
# Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
# add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
```
I updated R Studio to the current version (rstudio-2024.04.2-764-amd64.deb, installed with `sudo dpkg -i rstudio-2024.04.2-764-amd64.deb`). I then installed the Bioconductur package manager with

```R
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("tximport")
```
 and chose _not_ to update any packages it attempted to update. (I also installed DESeq2 by accident because it was in the same script). I also installed the R package `readr` using `pacman::p_install(readr)`, as this apparently accelerates tximport quite a lot.

To regenerate the tx2gene TSV file, ([install and use tximport](https://bioconductor.org/packages/release/bioc/html/tximport.html) in R), I thought I'd need a so-called TxDb object:  https://bioconductor.org/packages/release/bioc/vignettes/GenomicFeatures/inst/doc/GenomicFeatures.html

As per the tutorial, I installed the package GenomicFeatures with `BiocManager::install("GenomicFeatures")`. I got some errors at the end of the process:

```
ERROR: dependency ‘png’ is not available for package ‘KEGGREST’
* removing ‘/home/iweber/R/x86_64-pc-linux-gnu-library/4.4/KEGGREST’
ERROR: dependency ‘Rhtslib’ is not available for package ‘Rsamtools’
* removing ‘/home/iweber/R/x86_64-pc-linux-gnu-library/4.4/Rsamtools’
ERROR: dependency ‘Rsamtools’ is not available for package ‘GenomicAlignments’
* removing ‘/home/iweber/R/x86_64-pc-linux-gnu-library/4.4/GenomicAlignments’
ERROR: dependencies ‘XML’, ‘RCurl’ are not available for package ‘restfulr’
* removing ‘/home/iweber/R/x86_64-pc-linux-gnu-library/4.4/restfulr’
ERROR: dependency ‘KEGGREST’ is not available for package ‘AnnotationDbi’
* removing ‘/home/iweber/R/x86_64-pc-linux-gnu-library/4.4/AnnotationDbi’
ERROR: dependencies ‘XML’, ‘Rsamtools’, ‘GenomicAlignments’, ‘restfulr’ are not available for package ‘rtracklayer’
* removing ‘/home/iweber/R/x86_64-pc-linux-gnu-library/4.4/rtracklayer’
ERROR: dependencies ‘AnnotationDbi’, ‘rtracklayer’ are not available for package ‘GenomicFeatures’
* removing ‘/home/iweber/R/x86_64-pc-linux-gnu-library/4.4/GenomicFeatures’
```

# License
http://creativecommons.org/licenses/by/4.0/ probably best, version with attribution.


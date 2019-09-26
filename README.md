# Pipeline to analyse Whole Genome Sequencing (WGS) data
## tested in C elegans dataset

This project consists of a pipeline
to analyse whole genome data.

Fastq files that I used for testing
are obtained from the work entitled:
**"Optogenetic mutagenesis in Caenorhabditis elegans"**
of Kentaro Noma and Yishi Jin from San Diego University (1)
Thanks to these authors for their very interesting data!!

### Characteristics of the dataset  

The organism (C elegans) is diploid.
Reads are paired-end, obtained from Illumina technology.
Read length is 90bp

## BEFORE anything:
Read entirely my pipeline **wholeGenworkflow.sh** 
and verify that it serves your purpose.

## A) Preparing Directories

This *tree* (files and folders hierarchy) allows to work comfortably with this pipeline:
```
home/johanna/WGS 
├── genomesref
│   ├── species.project.release.annotations.gff3.gz
│   ├── species.project.release.genomic.fa.gz
│   └── derived files (indexes, reference vcf, etc)
├── OPTOCelegans
│   ├── fastq
│   │   └── every_fastq_file.gz
│   ├── QC
│   │   ├── every_fastqc.html
│   │   └── every_fastqc.zip
│   ├── TRIMM
│   │   └── trimming_results
│   ├── ALIGNED
│   │   └── alignement_results (sam, bam, FINAL.vcf, etc)
│   └── SRR_Acc_List.txt
├── ReadMe_personalProject
├── wholeGenworkflow.sh
└── other scripts(.sh,.py,.r,etc) if neccessary
```
I named working directory as "WGS". Feel free to change it i.e. "wholeGenSeq" or other coherent name with the technical context. 

These directories MUST exist before using the pipeline, even if zero files within:
* WGS
* genomesref
* OptoCelegans
   * fastq

 In next steps we will fill them, and create more, using the pipelines.
I strongly recommend to fit to this same tree structure in your computer.
You can also clone this work : 
```
git clone https://gitlab.com/JohannaGL/wgs.git
```
"OPTOCelegans" is the *project* here. You can add other projects and/or other *genomesref*, that's why the pipelines are not inside the project, so we can re-use them.

If working with other diploid species, be aware that VCF generator provided here *"gff2vcf_Celegans.py"* only works for the release W260 of C elegans.

## A) Preparing fastq files

+ If you have your own fastq files:
   +  put them in 'WGS/OPTOCelegans/fastq'

+ If you dont have them: 
   1. download Sra-ToolKit from NCBI, unzip.
   2. next, in a code or text editor, open **fastqFromSRA** provided here, change paths by yours and save.
   2. then, download the *SRR_Acc_List.txt" (from SRA NCBI) to location as shows the *tree*
   3. Finally, run **fastqFromSRA**. It oma K, Jin Y. Optogenetic mutagenesis in Caenorhabditis elegans. Nat Commun. 2015 Dec 3;6:8868. doi: 10.1038/ncomms9868. PMID: 26632265; PMCID: PMC4686824.works for paired end data. Run it in your linux shell, from the working directory:
```
~ $ cd WGS
~/WGS $ ./fastqFromSRA.sh
```
## B) Using 'wholeGenworkflow' pipeline

+ Open **wholeGenworkflow.sh** in a code editor or in gedit. 
+ Change the paths by yours
+ run
+ The pipeline asumes you have already in your system all the tools and software:
   + bwa
   + samtools
   + trimmomatic
   + picard
   + GATK4 (v 4.1.3.0) ==> I tested only with this version !
   + (eventually bcftools if VCF is created on the fly)

### References
1. Noma K, Jin Y. Optogenetic mutagenesis in Caenorhabditis elegans. Nat Commun. 2015 Dec 3;6:8868. doi: 10.1038/ncomms9868. PMID: 26632265; PMCID: PMC4686824.
### Other sources
https://gatkforums.broadinstitute.org/gatk/discussion/44/base-quality-score-recalibration-bqsr
https://www.biostars.org/p/281776/
https://github.com/gatk-workflows/gatk4-data-processing/blob/master/processing-for-variant-discovery-gatk4.wdl
##### author of this pipeline:
Johanna GALVIS - 2019

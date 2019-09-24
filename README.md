This project consists of a pipeline
to analyse eukaryotic whole genome data using Illumina tech.
Fastq files used for this exercise
are obtained from the work entitled:
"Optogenetic mutagenesis in Caenorhabditis elegans".
of Kentaro Noma and Yishi Jin from San Diego University

Thanks to these authors for their very interesting data!!

This tree (files and folders organisation) allows to work comfortably with this pipeline:

WorkingDirectory ( name it "WGS" or "wholeGenSeq", always coherent with the technical context ) 
├── genomesref
│   ├── species.project.release.annotations.gff3.gz
│   └── species.project.release.genomic.fa.gz
├── PROJECTNAME ( for our exercice, OPTOCelegans )
│   ├── fastq
│   │   └── every_fastq_file.gz
│   ├── QC
│   │   ├── every_fastqc.html
│   │   └── every_fastqc.zip
│   ├── TRIMM
│   │   └── trimming_results
│   ├── SAM_BAM_VCF
│   │   └── alignement_results
│   └── SRR_Acc_List.txt
├── ReadMe_personalProject
├── wholeGenworkflow.sh
└── other scripts(.sh,.py,.r,etc) if neccessary

I strongly recommend to fit to this same tree structure in your computer.

Johanna GALVIS - 2018
#!/bin/bash
#
# Pipeline para analisis de genoma eucariota
# Ejemplo de analisis en computador local con genoma no mayor 
# a 6GB (la capacidad de mi compu). nota: el genoma de C elegans tiene 100 Mpb
# referencia: ftp://ftp.wormbase.org/pub/wormbase/species/c_elegans/
# ((previamente se utilizo pipeline de recuperacion de fastq a partir de SRA))
# SE REQUIERE: SRR_Acc_List.txt, respetar la arborescencia sugerida ("tree") ver Readme.
# bwa, samtools, GATK, Picard, fastqc, trimmomatic.  
# ----------------------------------
# author: Johanna Galvis,2019

#==============================================================================
###################       DEFINE PATHS, FILES           #######################
#==============================================================================
mycores=2 #here the number of threads I can use, check your system
wdir="/home/johanna/WGS"
project="OPTOCelegans" #the name of the project  !!!!!! only name
ref="genomesref" #only name, not complete path
# project and the reference-annotation folders MUST BE INSIDE working dir
runslist="SRR_Acc_List.txt" # this runslist is inside project

fastasource="ftp://ftp.wormbase.org/pub/wormbase/species/c_elegans/sequence/genomic/c_elegans.PRJNA13758.WS260.genomic.fa.gz"

gtfgffsource="ftp://ftp.wormbase.org/pub/wormbase/species/c_elegans/gff/c_elegans.PRJNA13758.WS260.annotations.gff3.gz"

fastQC_exe="/home/johanna/Programs_bioinfo/fastqc_v0.11.8/FastQC/fastqc" 
picard_exe="/home/johanna/Programs_bioinfo/picard.jar"
gatk_exe="/home/johanna/Programs_bioinfo/gatk-4.1.3.0/gatk"
# trimmomatic folder (contains adapters files and executable):
trimmodir="/home/johanna/Programs_bioinfo/Trimmomatic-0.39/Trimmomatic-0.39"
# GenomeAnalysisToolKit folder:

# Results : I automatically generate folders : QC, TRIMMED, ALIGNED
# and additional results for reference data go to: $ref.

#==============================================================================
###################                PROGRAM             #######################
#==============================================================================

echo "  Your project $project must exist. \
*CAUTION : Any existing results will be DESTROYED*"

# 0 : download annotation and fasta files if neccesary:
cd $wdir/$ref # MOVE TO REFERENCE-GENOMES FOLDER
# download complete genome fasta file if not exists:
if [ ! -f *.fa.gz ];then
	wget $fastasource
fi
# download annotations file if not exists:
if [ ! -f *.gff3.gz ];then
	wget $gtfgffsource
fi

if [ -f *.gz ]; then 
	echo "   unzipping compressed files existing in ${ref}"
	gunzip -d -k *.gz
fi
fastafile=$(basename $(ls *.fa)) #find fasta name *Only 1 file expected !!
fastaprefix=${fastafile%.fa} #set fastaprefix (useful for .dic file step)
cd $wdir #GO BACK TO wdir

# ----------------------------------------------------------------------------
# 1 : MONITOR READS QUALITY: utilizamos fastqc 
# ----------------------------------------------------------------------------
# creacion de vinculo simbolico o symlink 'fastqc' en wdir:
if [ ! -h fastqc ]; then ln -s $fastQC_exe; fi    #no confundir fastqc (symlink) y fastq 

# creacion de folder QC y copia de resultados alli:
if [ -d $project/QC ]; then
	rm -r $project/QC #existing QC results are removed
	mkdir $project/QC
	echo "  -Performing quality control with FastQC, \
		results will be at '$project/QC' directory"
	for i in $(cat $project/$runslist); do 
		echo "  lectura : "$i
		./fastqc -o $project/QC -f fastq -t 2 \
		$project/fastq/${i}_1.fastq.gz \
		$project/fastq/${i}_2.fastq.gz
	done
fi
# ----------------------------------------------------------------------------
# 2 : TRIMM low quality bases: 
# ----------------------------------------------------------------------------

outtrim=$wdir/$project/TRIMMED #trimmed results directory

cd ${trimmodir}  #go to trimmomatic location 

echo "  Preparing to remove low quality bases, checking that trimmomatic works out"
java -jar trimmomatic-0.39.jar

if [ -d $outtrim ]; then
	rm -r -i $outtrim
	mkdir $outtrim	
	for i in $(cat $wdir/$project/$runslist); do 
	if [ -f $wdir/$project/fastq/${i}_1.fastq.gz ];then
		java -jar trimmomatic-0.39.jar PE -phred33 -threads ${mycores} \
		$wdir/$project/fastq/${i}_1.fastq.gz $wdir/$project/fastq/${i}_2.fastq.gz \
		$outtrim/${i}_1_trimm.fastq $outtrim/${i}_forward_unpaired.fq.gz \
 		$outtrim/${i}_2_trimm.fastq $outtrim/${i}_reverse_unpaired.fq.gz\
 ILLUMINACLIP:adapters/TruSeq3-PE-2.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
	
	else
		echo "  "${i}" no existe en folder fastq del proyecto actual"
	fi
	done
fi
echo "    going back to working directory"
cd $wdir; pwd

# ----------------------------------------------------------------------------
# 3 :  ALIGN THE TRIMMED READS TO A REFERENCE GENOME
# ----------------------------------------------------------------------------
# utilizamos BWA , debe estar instalado

# 3.a. building indexed genome

if [ ! -f *.ann ];then
	bwa index *.fa 
fi


# 3.b. Aligning, as reads > 70b (90bp) we use 'bwa mem' algorithm
cd $wdir
if [ -d $project/ALIGNED ];then
	echo " answer 'y' or  type 'Ctrl+C' if suppresion not desired"
	rm -r -i $project/ALIGNED
	mkdir $project/ALIGNED
fi

for j in $(cat $project/$runslist);do
	if [ -f $outtrim/${j}_1_trimm.fastq ];then
		echo "   Aligning "$j
		bwa mem -M -t ${mycores} -v 3 \
		-R "@RG\tID:${j}\tSM:${j}\tPL:ILLUMINA" \
		$ref/$fastafile \
		$outtrim/${j}_1_trimm.fastq \
		$outtrim/${j}_2_trimm.fastq \
		> $project/ALIGNED/${j}_aln.sam
	else
		echo "  "${j}" no existe en folder $outtrim "
	fi
done

# ----------------------------------------------------------------------------
# 4 : Processing sam files, and remove duplicates
# ----------------------------------------------------------------------------

# 4.a. : generate BAM file "_sorted.bam" and index it
cd $project/ALIGNED 

for j in $(cat $wdir/$project/$runslist);do
	if [ -f ${j}_aln.sam ];then
		echo "   sorting and indexing "$j
		#Like many Unix tools, SAMTools is able to read directly from stdout
		samtools view -Sb ${j}_aln.sam | \
		samtools sort -@ ${mycores} -o ${j}_sorted.bam
		 
		samtools index ${j}_sorted.bam ${j}_sorted.bam.bai
	else
		echo "  "${j}"_aln.sam no existe en "$project"/ALIGNED"
	fi
done

# 4.b. remove duplicates (PCR or optical duplicates, other artifactual ...)

echo "  checking picard 'MarkDuplicates' version"
java -jar $picard_exe MarkDuplicates --version
echo;

# sorted de-duplicated BAM file "_marked_dupli.bam" and indexation
for j in $(cat $wdir/$project/$runslist);do
	if [ -f ${j}_sorted_bam ];then
		java -jar $picard_exe MarkDuplicates \
		I=${j}_sorted.bam \
		O=${j}_marked_dupli.bam \
		M=${j}_marked_dup_metrics.txt \
		REMOVE_DUPLICATES=true VALIDATION_STRINGENCY=LENIENT

		java -jar $picard_exe BuildBamIndex I=${j}_marked_dupli.bam
	else
		echo "  "${j}"_sorted.bam no existe en "$project"/ALIGNED"
	fi
done


# ----------------------------------------------------------------------------
# 5 : Base Recalibration  https://vatlab.github.io/sos-docs/doc/examples/WGS_Call.html
# ----------------------------------------------------------------------------
# Note: realign indels ==> not required if HaplotypeCaller is used (germline changes)
# moreover, GATK4 no longer has RealignerTargetCreator nor IndelRealigner
# source info: https://vatlab.github.io/sos-docs/doc/examples/WGS_Call.html
# For somatic changes : mutect2

# 5.a VCF file preparation and indexing
cd $wdir/$ref
if [ ! -f *.vcf -a ! -f *.vcf.gz ]; then
	echo "   you do NOT have a VCF in "$wdir/$ref
	echo "   Running gff2vcf_Celegans.py to create VCF:"	
	python3 $wdir/gff2vcf_Celegans.py $wdir/$ref/*.gff3		
fi

if [ -f *.vcf ]; then
	vcf=$(ls $wdir/$ref/*.vcf)
	if [ ! -f *.vcf.gz ]; then		
		echo "    VCF validation (bcftools)==> vcf.gz"
		bcftools view -O z $vcf > $vcf.gz
	else
		echo "   VCF indexing"		
		$gatk_exe IndexFeatureFile \
		--feature-file $vcf.gz
	fi
fi

# 5.b Obtain .dict (picard) and fa.fai (samtools) 
if [ ! -f *.dict ];then
	outdict=$wdir/$ref/$fastaprefix.dict

	java -jar $picard_exe \
	CreateSequenceDictionary R=$fastafile O=$outdict

	samtools faidx $fastafile
fi

# 5.c  BASE RECALIBRATION, move to fasta location: $ref
cd $wdir/$ref
vcfok=$(ls *.vcf.gz)
for j in $(cat $wdir/$project/$runslist);do
	$gatk_exe BaseRecalibrator \
	-R $fastafile \
	--known-sites $vcfok \
	--input $wdir/$project/ALIGNED/${j}_marked_dupli.bam \
	--output $wdir/$project/ALIGNED/${j}_recalibrated.grp
done

# 5.d Generate recalibrated bam
cd $wdir/$project/ALIGNED
for j in $(cat $wdir/$project/$runslist);do
	$gatk_exe ApplyBQSR \
	--bqsr-recal-file ${j}_recalibrated.grp \
	--input ${j}_marked_dupli.bam \
	--output ${j}_recal.bam
done

# ----------------------------------------------------------------------------
# 6 : VARIANT CALLING
# ----------------------------------------------------------------------------
# the moment we were dreaming about, has FINALLY come!!! 
cd $wdir/$project/ALIGNED
for j in $(cat $wdir/$project/$runslist);do
	$gatk_exe HaplotypeCaller \
	--input ${j}_recal.bam \
	--output ${j}_FINAL.vcf
	-R $wdir/$ref/$fastafile
done
echo "   END OF PIPELINE. "

# ----------------------------------------------------------------------------



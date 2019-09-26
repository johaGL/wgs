#!/bin/bash
# Pipeline de recuperacion PAIRED-END de fastq a partir de repositorio SRA
# input : codigos de acceso SRA de las lecturas ("SRR_Acc_List.txt")
# output : folder "fastq" con forward "_1" y reverse "_2" de cada lectura
# ======================  Atencion !!!! ==================================
# SI EL FOLDER "fastq" EXISTE YA dentro del proyecto *NO* Funcionara
# ------------------------------------------------------------------------
# author: Johanna Galvis,2018
# REQUIERE el archivo "SRR_Acc_List.txt" descargado desde SRA de NCBI


project="OPTOCelegans" # YOURPROJECTFOLDER

fileAccessionCodes="SRR_Acc_List.txt"

# exportar path del binario (bin) de SRA ToolKit, segun ubicacion del descargable:
export PATH=$HOME/Programs_bioinfo/sra-tools/sratoolkit.2.9.2-ubuntu64/bin:$PATH

#Visualizacion de los primeros 5 "spots", si funciona continuara, de lo contrario aborta
echo "testing if your file $fileAccessionCodes is correct ( if not, wont continue )"
for sracode in $(cat $project/$fileAccessionCodes);do 
	echo "visualizing the first 5 spots for $sracode: " 
	fastq-dump -X 5 -Z --split-files $sracode  #visualize first 5 spots
done || exit

# continuacion , descarga, tomara tiempo
if [ ! -d $project/fastq ]; then
	echo "  READS (fastq files) will be downloaded -from SRA repo- to folder 'fastq' "
	echo "  creacion del folder 'fastq' en : "$project
	mkdir $project/fastq
	# download each fastq file, to directory "YOURPROJECTFOLDER/fastq" (-O):
	for sracode in $(cat $project/$fileAccessionCodes);do 
		echo "  descargando "$sracode" , puede tomar muuchos minutos"
		fastq-dump --clip --skip-technical --gzip --split-files -O $project/fastq $sracode ;
	done
else
	echo "no reads will be downloaded, 'fastq' folder exists in"$project
fi

# si no funciona o se desconecta del servidor hacer uno por uno con los codigos de acceso del .txt ; ejemplo:
#       fastq-dump --clip --skip-technical --gzip --split-files -O OPTOCelegans/fastq SRR2578341


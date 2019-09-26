#!usr/bin/env python3
"""
Error detectado en el VCF 
al intentar 'gatk IndexFeatureFile':
un alelo "K"  en la linea 740672 aprox.
ESTE SCRIPT HACE UN NUEVO ARCHIVO
EXCLUYENDO ESTE ALELO "K"
y todo alelo que no sea A,C,T,G
------------------------------
PENDIENTE: corregir en el gff2vcf para evitar a futuro
-------------------------------
Joha Galvis
"""

permitidos = ["A", "C", "T", "G"]

import os
import sys

vcf_in = sys.argv[1]
print("este es el vcf a corregir: "+vcf_in)
vcf_out = vcf_in[:-4]+".vcfcorrected"
vcf_w = open(vcf_out,"+w")

exclutxt = ""

with open(vcf_in, "r") as vcf:
    for line in vcf:
        if line.startswith("#"):
            vcf_w.write(line)
        else:
            tmp=line.split("\t")
            a1 = tmp[3]
            a2 = tmp[4]
            if (a1 in permitidos and a2 in permitidos):
                vcf_w.write(line)
            else:
                exclutxt += line

vcf_w.close()
excluded = open("excludedstuff","w")
excluded.write(exclutxt)
excluded.close()



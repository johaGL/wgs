#!usr/bin/env python3
"""
input: GFF3 file  *release WS260*
output: VCF file
this script re-uses all code from 
from https://gist.github.com/danielecook/5cd0e6e41d3db819a22d
thanks to DanieleCook. 
Modifications author: Johanna GALVIS
"""
import os
import sys

#complete PATH/NAME of gff3 file
filegff=sys.argv[1]
print("this is the file you entered:\n"+filegff)
vcffile=filegff[:-5]+".vcf" #set vcf filename (output) by excluding ".gff3"

acceptable_types = ['SNP', 'point_mutation']

# function to build dictionnary of each SNP or mutation:
# input: l[8] = 'variation=WBVar00604243;public_name=gk497391;strain=VC40173;substitution=C/T\n'
# ouput: {'variation':'WBVar...' , 'public_name' : '...'}etc
def parse_info(info):
    info_set = info.strip().split(";")
    ret_dict = {}
    for i in info_set:
        key, val = i.split("=")
        ret_dict[key] = val
    return ret_dict

with open(filegff, "r") as rgff:
    strain_list = []
    for line in rgff:
        if line.startswith("#"):
            pass
        else:
            l = line.split("\t")
            # l= ['I', 'Million_mutation', 'point_mutation', '566', '566', '.', '+', '.', 'variation=WBVar00604243;public_name=gk497391;strain=VC40173;substitution=C/T\n']
            if l[2] in acceptable_types:
                # l[8] = 'variation=WBVar00604243;public_name=gk497391;strain=VC40173;substitution=C/T\n'
                info_set = parse_info(l[8])
                if "strain" in info_set:
                    strains = info_set["strain"].split(",")
                    for i in strains:
                        if i not in strain_list and not i.startswith("VC"):
                            strain_list.append(i)                            
                        #VC is a cell lineage "individual neurons" not strain

#applied corrections regarding specificities of gff3 used:
vcf_header = """##fileformat=VCFv4.1
##FILTER=<ID=PASS,Description="All filters passed">
##contig=<ID=I,length=15072434>
##contig=<ID=II,length=15279421>
##contig=<ID=III,length=13783801>
##contig=<ID=IV,length=17493829>
##contig=<ID=V,length=20924180>
##contig=<ID=X,length=17718942>
##contig=<ID=MtDNA,length=13794>
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
"""

vcf = open(vcffile,'w+')
vcf.write(vcf_header)
vcf.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t%s\n" % '\t'.join(strain_list))

def process_genotypes(strains):
    gt_set = []
    for i in strain_list:
        if i in strains:
            gt_set.append("1/1:100")
        else:
            gt_set.append("0/0:100")            
    return '\t'.join(gt_set)
c = 1
with open(filegff, "r") as rgff:
    for line in rgff:
        if line.startswith("#"):
            pass
        else:
            l = line.strip().split("\t")
            if l[2] in acceptable_types:
                info_set = parse_info(l[8])
                CHROM = l[0]
                POS = l[3]
                ID = info_set["variation"]
                TYPE = l[2]
                if "substitution" in info_set.keys() and "strain" in info_set.keys():
                    variant_strains = [i for i in info_set["strain"].split(",") if not i.startswith("VC")]
                    if len(variant_strains) > 0:
                        GENOTYPES = process_genotypes(variant_strains)
                        REF, ALT = info_set["substitution"].split("/")
                        vcf_record=f"{CHROM}\t{POS}\t{ID}\t{REF}\t{ALT}\t100\t.\t.\tGT:GQ\t{GENOTYPES}\n"
                        vcf.write(vcf_record)
                        c += 1
                        if c % 1000 == 0:
                            print(f"{c} records")
            else:
                pass
vcf.close()
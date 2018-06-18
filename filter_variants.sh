#!/bin/bash

## SVDiscovery targeting deletion spanning 100 bp - 1M bp

## group names, t for tumor/normal, c for cancer type
t=$1
c=$2

## the path to master directory containing genomestrip scripts, input dependencies and output directories
mainRunDir=$3

#mergeoption="UNIQUIFY"
mergeoption="UNSORTED"

# input BAM
inputDir=${mainRunDir}"inputs/"
batchbamMapFile=$4

## input dependencies
genderMap=$5

## the dir name inside the input directory
refDir="Homo_sapiens_assembly19/"
refFile=${refDir}"Homo_sapiens_assembly19.fasta"

# output directory
batchName=$6
runDir=${mainRunDir}"outputs/"${batchName}"/"${t}"_"${c}"/"
outDir=${runDir}"vcfsbysample/"
mx="-Xmx6g"

# input discovery vcf
delVCF=${runDir}"delGenotype/del_genotype_"${t}"_"${c}".vcf"
cnvVCF=${runDir}"cnvGenotype/cnv_genotype_"${t}"_"${c}".vcf"

## output vcf file
delFilteredVCF=${runDir}"delGenotype/del_genotype_"${t}"_"${c}"_filtered.vcf"
cnvFilteredVCF=${runDir}"cnvGenotype/cnv_genotype_"${t}"_"${c}"_filtered.vcf"

# For SVAltAlign, you must use the version of bwa compatible with Genome STRiP.
export SV_DIR=/opt/svtoolkit
export PATH=${SV_DIR}/bwa:${PATH}
export LD_LIBRARY_PATH=${SV_DIR}/bwa:${LD_LIBRARY_PATH}

classpath="${SV_DIR}/lib/SVToolkit.jar:${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar:${SV_DIR}/lib/gatk/Queue.jar"

mkdir -p ${outDir} || exit 1

cp $0 ${outDir}/

# Run genotyping on the discovered sites.
#java -jar ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
#	-T VariantFiltration \
#	-R ${inputDir}${refFile} \
#	--variant ${delVCF} \
#	-o ${delFilteredVCF} \
#	--genotypeFilterExpression "FT == 'PASS'" --genotypeFilterName "FT_PASS"

java -jar ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
        -T VariantFiltration \
        -R ${inputDir}${refFile} \
        --variant ${cnvVCF} \
        -o ${cnvFilteredVCF} \
        --genotypeFilterExpression "FT == 'PASS' && PL != '.' && GT != '.'" --genotypeFilterName "cnv_filter" \
        || exit 1

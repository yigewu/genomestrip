#!/bin/bash

## SVDiscovery targeting deletion spanning 100 bp - 1M bp

# group names, t for tumor/normal, c for cancer type
t=$1
c=$2

## the path to master directory containing genomestrip scripts, input dependencies and output directories
mainRunDir=$3

# input BAM
inputDir=${mainRunDir}"inputs/"
batchbamMapFile=$4

## input dependencies
genderMap=$5

## the dir name inside the input directory
refDir="Homo_sapiens_assembly19/"
refFile=${refDir}"Homo_sapiens_assembly19.fasta"
ploidyFile=${refDir}"Homo_sapiens_assembly19.ploidymap.txt"

# output directory
batchName=$6
runDir=${mainRunDir}"outputs/"${batchName}"/"${t}"_"${c}"/"
outDir=${runDir}"cnvGenotype/"

## input vcf file
inVCFDir=${runDir}"cnvDiscovery/"
inVCF=${inVCFDir}"cnvdiscovery_"${t}"_"${c}".vcf"
inVCFgz=${inVCFDir}"results/gs_cnv.genotypes.vcf.gz"
if [ ! -e ${inVCF} -a -e ${inVCFgz} ]; then
    gunzip -c ${inVCFgz} > ${inVCF}
fi

## output vcf file
outVCF=${outDir}"cnv_genotype_"${t}"_"${c}".vcf"

## maximum heap memory
mx="-Xmx5g"

# For SVAltAlign, you must use the version of bwa compatible with Genome STRiP.
export SV_DIR=/opt/svtoolkit
export PATH=${SV_DIR}/bwa:${PATH}
export LD_LIBRARY_PATH=${SV_DIR}/bwa:${LD_LIBRARY_PATH}

classpath="${SV_DIR}/lib/SVToolkit.jar:${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar:${SV_DIR}/lib/gatk/Queue.jar"

mkdir -p ${outDir} || exit 1

cp $0 ${outDir}/

# Run genotyping on the discovered sites.
java ${mx} -cp ${classpath} \
    org.broadinstitute.sv.apps.GenerateHaploidCNVGenotypes \
    -R ${inputDir}${refFile} \
    -ploidyMapFile ${inputDir}${ploidyFile}\
    -genderMapFile ${inputDir}${genderMap} \
    -vcf ${inVCF} \
    -O ${outVCF} \
    -estimateAlleleFrequencies true \
    -genotypeLikelihoodThreshold 0.001 \
    || exit 1

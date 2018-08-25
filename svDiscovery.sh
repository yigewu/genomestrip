#!/bin/bash

## SVDiscovery targeting deletion spanning 100 bp - 1M bp

## group names, t for tumor/normal, c for cancer type
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
refDir=Homo_sapiens_assembly19
refFile=${refDir}/Homo_sapiens_assembly19.fasta

# output
batchName=$6
runDir=${mainRunDir}"outputs/"${batchName}"/"${t}"_"${c}
outDir=${runDir}"/svDiscovery/"
mx="-Xmx5g"

# input dependencies
export SV_DIR=/opt/svtoolkit

# tempory dir
SV_TMPDIR=${runDir}/tmpdir

# For SVAltAlign, you must use the version of bwa compatible with Genome STRiP.
export PATH=${SV_DIR}/bwa:${PATH}
export LD_LIBRARY_PATH=${SV_DIR}/bwa:${LD_LIBRARY_PATH}

classpath="${SV_DIR}/lib/SVToolkit.jar:${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar:${SV_DIR}/lib/gatk/Queue.jar"

mkdir -p ${outDir} || exit 1

cp $0 ${outDir}/

# Run discovery.
java -cp ${classpath} ${mx} \
    org.broadinstitute.gatk.queue.QCommandLine \
    -S ${SV_DIR}/qscript/SVDiscovery.q \
    -S ${SV_DIR}/qscript/SVQScript.q \
    -gatk ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
    --disableJobReport \
    -jobRunner ParallelShell \
    -maxConcurrentRun 4 \
    -cp ${classpath} \
    -configFile ${SV_DIR}/conf/genstrip_parameters.txt \
    -tempDir ${SV_TMPDIR} \
    -R ${inputDir}${refFile} \
    -genderMapFile ${inputDir}${genderMap} \
    -runDirectory ${outDir} \
    -md ${runDir}/metadata \
    -jobLogDir ${runDir}/logs \
    -minimumSize 100 \
    -maximumSize 1000000 \
    -suppressVCFCommandLines \
    -I ${inputDir}${batchbamMapFile} \
    -O ${outDir}"discovery_"${t}"_"${c}".vcf" \
    -P select.validateReadPairs:false \
    -run \
    || exit 1

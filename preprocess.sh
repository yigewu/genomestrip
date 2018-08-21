#!/bin/bash

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
outDir=${runDir}
mx="-Xmx5g"

# tempory dir
SV_TMPDIR=${runDir}/tmpdir

# For SVAltAlign, you must use the version of bwa compatible with Genome STRiP.
export SV_DIR=/opt/svtoolkit
export PATH=${SV_DIR}/bwa:${PATH}
export LD_LIBRARY_PATH=${SV_DIR}/bwa:${LD_LIBRARY_PATH}

classpath="${SV_DIR}/lib/SVToolkit.jar:${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar:${SV_DIR}/lib/gatk/Queue.jar"

mkdir -p ${runDir}/logs || exit 1
mkdir -p ${runDir}/metadata || exit 1

cp $0 ${outDir}/

# Unzip the reference sequence and masks if necessary
if [ ! -e ${inputDir}/${refFile} -a -e ${inputDir}/${refFile}.gz ]; then
    gunzip ${inputDir}/${refFile}.gz
fi
if [ ! -e ${inputDir}/${genomeMaskFile} -a -e ${inputDir}/${genomeMaskFile}.gz ]; then
    gunzip ${inputDir}/${genomeMaskFile}.gz
fi
if [ ! -e ${inputDir}/${copyNumberMaskFile} -a -e ${inputDir}/${copyNumberMaskFile}.gz ]; then
    gunzip ${inputDir}/${copyNumberMaskFile}.gz
fi

# Display version information.
java -cp ${classpath} ${mx} -jar ${SV_DIR}/lib/SVToolkit.jar

# Run preprocessing.
# For large scale use, you should use -reduceInsertSizeDistributions, but this is too slow for the installation test.
# The method employed by -computeGCProfiles requires a GC mask and is currently only supported for human genomes.
java -cp ${classpath} ${mx} \
    org.broadinstitute.gatk.queue.QCommandLine \
    -S ${SV_DIR}/qscript/SVPreprocess.q \
    -S ${SV_DIR}/qscript/SVQScript.q \
    -gatk ${SV_DIR}/lib/gatk/GenomeAnalysisTK.jar \
    --disableJobReport \
    -jobRunner ParallelShell \
    --maximumNumberOfJobsToRunConcurrently 2 \
    -resMemLimit 5 \
    -cp ${classpath} \
    -configFile ${SV_DIR}/conf/genstrip_parameters.txt \
    -tempDir ${SV_TMPDIR} \
    -R ${inputDir}${refFile} \
    -genderMapFile ${inputDir}${genderMap} \
    -runDirectory ${runDir} \
    -md ${runDir}/metadata \
    -jobLogDir ${runDir}/logs \
    -I ${inputDir}${batchbamMapFile} \
    -run \
    || exit 1


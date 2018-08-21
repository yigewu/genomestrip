#!/bin/bash

## group names, t for tumor/normal, c for cancer type
t=$1
c=$2

## the path to master directory containing genomestrip scripts, input dependencies and output directories
mainRunDir=$3

# input BAM
inputDir=${mainRunDir}"inputs/"
batchbamMapFile=$4
bamMapFile=$7
bamType=$8

## input dependencies
genderMap=$5
clinFilesuffix=$9

## the dir name inside the input directory
refDir=Homo_sapiens_assembly19
refFile=${refDir}/Homo_sapiens_assembly19.fasta

# output
batchName=$6
runDir=${mainRunDir}"outputs/"${batchName}"/"${t}"_"${c}
outDir=${runDir}
mx="-Xmx5g"

cd ${inputDir}
caseFile=$(ls *${clinFilesuffix})
echo ${caseFile}
mkdir -p tmp

if [ -s ${inputDir}${bamMapFile}"_"${bamType}"_"${t}"_"${c}"_gender_map.txt" ]
then
	echo ${inputDir}${bamMapFile}"_"${bamType}"_"${t}"_"${c}"_gender_map.txt exist!"
else
	touch ${inputDir}${bamMapFile}"_"${bamType}"_"${t}"_"${c}"_gender_map.txt" > ${inputDir}${bamMapFile}"_"${bamType}"_"${t}"_"${c}"_gender_map.txt"
	while IFS= read -r var; do
	    samtools view -H ${var} | grep SM | awk -F '\t' '{print $3}' | uniq | awk -F 'SM:' '{print $2}' > tmp/tmp_specimen
	    cat tmp/tmp_specimen | grep -f - ${bamMapFile} | awk -F ' ' '{print $2}' | uniq > tmp/tmp_case
	    cat tmp/tmp_case | grep -f - ${caseFile} | awk -F '\t' '{print $18}' | uniq > tmp/tmp_gender
	    if [ "$(cat tmp/tmp_gender)" == "Male" ]; then
		cat tmp/tmp_specimen | awk '{print $1"\tM"}' >> ${inputDir}${bamMapFile}"_"${bamType}"_"${t}"_"${c}"_gender_map.txt"
	    fi
	    if [ "$(cat tmp/tmp_gender)" == "Female" ]; then
		cat tmp/tmp_specimen | awk '{print $1"\tF"}' >> ${inputDir}${bamMapFile}"_"${bamType}"_"${t}"_"${c}"_gender_map.txt"
	    fi
	    if [ "$(cat tmp/tmp_gender)" != "Female" ] && [ "$(cat tmp/tmp_gender)" != "Male" ]; then
		echo "grep the wrong column for gender"
		cat tmp/tmp_case
	    fi
	done < ${bamMapFile}"_"${bamType}"_"${t}"_"${c}".list"
fi

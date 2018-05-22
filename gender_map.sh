#!/bin/bash

mainRunDir=$1
inputDir=${mainRunDir}"inputs/"
bamMapFile=$2
bamType=$3
clinicalFile=$4

cd ${inputDir}
mkdir -p tmp
for i in tumor tissue_normal; do
    while read j
	do
	if [ -s ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}"_gender_map.txt" ]
	then
		echo ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}"_gender_map.txt exist!"
	else
		touch ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}"_gender_map.txt" > ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}"_gender_map.txt" 
		while IFS= read -r var; do
		    samtools view -H ${var} | grep SM | awk -F '\t' '{print $3}' | uniq | awk -F 'SM:' '{print $2}' > tmp/tmp_specimen
		    cat tmp/tmp_specimen | grep -f - ${bamMapFile} | awk -F '\\s' '{print $2}' | uniq > tmp/tmp_case 
		    cat tmp/tmp_case | grep -f - ${clinicalFile} | awk -F '\t' '{print $4}' > tmp/tmp_gender
		    if [ "$(cat tmp/tmp_gender)" == "male" ]; then
			cat tmp/tmp_specimen | awk '{print $1"\tM"}' >> ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}"_gender_map.txt" 
		    fi
		    if [ "$(cat tmp/tmp_gender)" == "female" ]; then
			cat tmp/tmp_specimen | awk '{print $1"\tF"}' >> ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}"_gender_map.txt" 
		    fi
		    if [ "$(cat tmp/tmp_gender)" != "female" ] && [ "$(cat tmp/tmp_gender)" != "male" ]; then
			echo "grep the wrong column for gender"
			cat tmp/tmp_case
		    fi
		done < ${bamMapFile}"_"${bamType}"_"${i}"_"${j}".list"
	fi 
	done<${cancerType}
done


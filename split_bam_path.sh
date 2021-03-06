#!/bin/bash

mainRunDir=$1
bamMapFile=$2
inputDir=${mainRunDir}"inputs/"
bamType=$3

cd ${inputDir}
for i in tumor normal; do
    for c in CCRC UCEC; do
	grep ${i} ${bamMapFile} | grep ${c} | grep ${bamType} |  awk -F '\\s' '{print $6}' | awk -F 'import' '{print $1"import"$2}' > ${bamMapFile}"_"${bamType}"_"${i}"_"${c}".list"
    done
done
cd ${mainRunDir}

#!/bin/bash

mainRunDir=$1
bamMapFile=$2
inputDir=${mainRunDir}"inputs/"
bamType=$3
cancerType=$4

for i in tumor tissue_normal; do
    while read j
        do
        grep ${i} ${inputDir}${bamMapFile} | grep ${j} | grep ${bamType} |  awk -F '\\s' '{print $6}' | awk -F 'import' '{print $1"import"$2}' > ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}".list"
        done<${cancerType}
done

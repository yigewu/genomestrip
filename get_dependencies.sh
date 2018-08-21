#!/bin/bash

mainRunDir=$1
inputDir=${mainRunDir}"inputs/"

bamMapDir=$2
bamMapFile=$3
clinicalDir=$4
clinicalFile=$5
refDir=$6
refFile=$7
refBundlegz=$8
refBundle=$9
clinDir=${10}
clinFilesuffix=${11}
cancerType=${12}

# docker pull broadinstitute/gatk-nightly

# check reference metadata bundle
if [ -s ${inputDir}${refBundlegz} ]
then
        echo "reference metadata bundle gzip file is available!"
else
        echo "reference metadata bundle gzip file is being copied!"
	cd ${inputDir}
	wget ftp://ftp.broadinstitute.org/pub/svtoolkit/reference_metadata_bundles/Homo_sapiens_assembly19_12May2015.tar.gz
fi

if [ -d ${inputDir}${refBundle} ]
then
	echo "reference metadata bundle already unzipped!"
else
	echo "reference metadata bundle is being unzipped!"
	cd ${inputDir}
	tar -zxvf ${refBundlegz}
fi

## copy BamMaps
if [ -s ${inputDir}${bamMapFile} ]
then
        echo "bamMap is available"
else
        echo "bamMap is being copied"
        cp ${bamMapDir}${bamMapFile} ${inputDir}${bamMapFile}
fi

## copy reference file
if [ -s ${inputDir}${refFile} ]
then
        echo "refFile is available"
else
        echo "refFile is being copied"
        cp ${refDir}${refFile} ${inputDir}${refFile}
fi

## copy clinical file
if [ -s ${inputDir}${clinicalFile} ]
then
        echo "clinical file is available"
else
        echo "clinical file is being copied"
        cp ${clinicalDir}${clinicalFile} ${inputDir}${clinicalFile}
fi

## extra file for gender information
#while read j
#do
#	genderDir=${clinDir}${j}"/"
#	cd ${genderDir}
#	caseFile=$(ls *${clinFilesuffix})
#	if [ -s ${inputDir}${caseFile} ]
#	then
#		echo "extra clinical file is available"
#	else
#		echo "extra clinical file is being copied"
#		cp ${genderDir}${caseFile} ${inputDir}${caseFile}
#	fi
#done<${cancerType}

#!/bin/bash

mainRunDir=$1
inputDir=${mainRunDir}"inputs/"

bamMapDir=$2
bamMapFile=$3
clinicalDir=$4
clinicalFile=$5
refDir=$6
refFile=$7

## download reference metadata bundle
#cd ${inputDir}
#wget ftp://ftp.broadinstitute.org/pub/svtoolkit/reference_metadata_bundles/Homo_sapiens_assembly19_12May2015.tar.gz
#tar -zxvf Homo_sapiens_assembly19_12May2015.tar.gz

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

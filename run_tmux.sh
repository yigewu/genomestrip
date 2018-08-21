#!/bin/bash

## Usage: bash run_tmux.sh {tumor/normal} {CCRC/UCEC} {script_name_to_run} 

## the path to master directory containing genomestrip scripts, input dependencies and output directories
mainRunDir=$1

## the name of the file containing BAM paths, patient ids, sample ids
bamMapFile=$2
bamType=$3

## the path to master directory containing input BAM files
bamDir=$4

## the name of the docker image
imageName=$5

## the path to the binary file for the language to run inside docker container
binaryFile=$6

## script name to run
scriptDir=$7
scriptName=$8

## batch identifiers, t for tumor/normal, c for cancer type
t=$9
c=${10}

## the path to the BAM file batch to be processed
batchbamMapFile=${bamMapFile}"_"${bamType}"_"${t}"_"${c}".list"

## the name of output directory for different batches
batchName=${11}

## identifier for the log file
id=${12}

## the name of github branch
toolDirName=${13}

## the suffix of clinical file
clinFilesuffix=${14}

## user ID with permission to the input files
uid=$(id -u)

## group ID with permission to the input files
gid="2001"

## the name of the file containing the gender map
genderFile=${bamMapFile}"_"${bamType}"_"${t}"_"${c}"_gender_map.txt"

mkdir -p ${mainRunDir}"logs/"
bashCMD="tmux new-session -d -s "${toolDirName}"_"${scriptName}"_"${t}"_"${c}"_"${id}" 'docker run -v "${mainRunDir}":"${mainRunDir}" -v "${bamDir}":"${bamDir}" "${imageName}" "${binaryFile}" "${scriptDir}${scriptName}" "${t}" "${c}" "${mainRunDir}" "${batchbamMapFile}" "${genderFile}" "${batchName}" "${bamMapFile}" "${bamType}" "${clinFilesuffix}" |& tee "${mainRunDir}"logs/"${toolDirName}"_"${scriptName}"_"${t}"_"${c}"_"${id}".log'"
#bashCMD="tmux new-session -d -s "${toolDirName}"_"${scriptName}"_"${t}"_"${c}" 'docker run --user "${uid}":"${gid}" -v "${mainRunDir}":"${mainRunDir}" -v "${bamDir}":"${bamDir}" "${imageName}" "${binaryFile}" "${scriptDir}${scriptName}" "${t}" "${c}" "${mainRunDir}" "${batchbamMapFile}" "${genderFile}" "${batchName}" "${bamMapFile}" ${bamType} |& tee "${mainRunDir}"logs/"${toolDirName}"_"${scriptName}"_"${t}"_"${c}"_"${id}".log'" 
echo ${bashCMD}
echo ""
#$bashCMD

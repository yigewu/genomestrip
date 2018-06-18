#!/bin/bash

## Usage: run genomestrip on CPTAC3 WGS BAMs

## name of the master running directory
toolName="genomestrip"

## type of the BAM to be processed
bamType="WGS"

## name of the output directory for different batches
batchName="CPTAC3.b4"

## the path to master directory containing "${toolName}" scripts, input dependencies and output directories
mainRunDir="/diskmnt/Projects/CPTAC3CNV/"${toolName}"/"
toolDirName=${toolName}"."${batchName}
mainScriptDir=${mainRunDir}${toolDirName}"/"
inputDir=${mainRunDir}"inputs/"

## the path to the file containing BAM paths, patient ids, sample ids
bamMapDir="/diskmnt/Projects/cptac/GDC_import/import.config/CPTAC3.b4.b/"

## the name of the file containing BAM paths, patient ids, sample ids
bamMapFile="CPTAC3.b4.b.BamMap.dat"

## the master directory holding the BAMs to be processed
bamDir="/diskmnt/Projects/cptac/GDC_import/data/"

## the name of the docker image
imageName="skashin/genome-strip:latest"
gatkImage="broadinstitute/gatk-nightly:latest"

## the path to the reference metadata bundle
refDir=${inputDir}
refFile="Homo_sapiens_assembly19.fasta"
refBundlegz="Homo_sapiens_assembly19_12May2015.tar.gz"
refBundle="Homo_sapiens_assembly19"

## path to the file with gender info for patients
clinicalDir=${inputDir}
clinicalFile="CPTAC3.b4.Demographics.dat"

## the file containing the cancer types to be processed
cancerType="cancer_types.txt"

## tag for log file
id=$1
if [ $# -eq 0 ]
  then
    echo "No date supplied!"
    exit 1
fi

## directory with extra clinical information
clinDir="/diskmnt/Datasets/CPTAC/PGDAC/CPTAC_Biospecimens_Clinical_Data/CPTAC3_Clinical_Data/"
clinFilesuffix="case.tsv"

## version name of pipeline
version="1.2"

## download/copy dependencies
cm="bash get_dependencies.sh ${mainRunDir} ${bamMapDir} ${bamMapFile} ${clinicalDir} ${clinicalFile} ${refDir} ${refFile} ${refBundlegz} ${refBundle} ${clinDir} ${clinFilesuffix} ${cancerType}"
${cm}

## split BAM path file into batchs
#cm="bash split_bam_path.sh ${mainRunDir} ${bamMapFile} ${bamType}"
for i in tumor normal; do
    while read j; do
        grep ${i} ${inputDir}${bamMapFile} | grep ${j} | grep ${bamType} |  awk -F '\\s' '{print $6}' | awk -F 'import' '{print $1"import"$2}' > ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}".list"
        done<${cancerType}
done
echo "split the BAMs map file!"

## generate gender map file
for t in tumor normal; do
	while read c; do
		if [ -s ${inputDir}${bamMapFile}"_"${bamType}"_"${t}"_"${c}"_gender_map.txt" ]
		then
			echo "gender map generated!"
		else
			echo "generating gender map!"
			bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "create_gender_map.sh" ${t} ${c} ${batchName} ${id} ${toolDirName} ${clinFilesuffix}
		fi
        done<${cancerType}
done

## run SVPreprocess pipeline
for t in tumor normal; do
        while read c
        do
		bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "preprocess.sh" ${t} ${c} ${batchName} ${id} ${toolDirName}
	done<${cancerType}
done

## wait until the last step is done
## run SVDiscovery pipeline
for t in tumor normal; do
        while read c; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "svDiscovery.sh" ${t} ${c} ${batchName} ${id} ${toolDirName}
        done<${cancerType}        
done

## wait until the last step is done
## run SVGenotype pipeline
for t in tumor normal; do
        while read c; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "delGenotype.sh" ${t} ${c} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done

## wait until the last step is done
## run CNVDiscovery pipeline
for t in tumor normal; do
        while read c; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "cnvDiscovery.sh" ${t} ${c} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done

## wait until the last step is done
for t in tumor normal; do
        while read c; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "cnvGenotype.sh" ${t} ${c} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done

## wait until the last step is done
## run GATK CombineVariants
for t in tumor normal; do
        while read c; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${gatkImage} "/bin/bash" ${mainScriptDir} "combine_vcfs.sh" ${t} ${c} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done

## wait until the last step is done
## run GATK SelectVariants
for t in tumor normal; do
        while read c; do
               bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "split_vcfs_by_sample.sh" ${t} ${c} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done

## create README file
cm="bash create_readme.sh ${batchName} ${bamType} ${version} ${mainScriptDir} ${toolName} ${mainRunDir}"
${cm}

## push scripts to github
cm="bash push_git.sh ${batchName} ${version}"
echo ${cm}

## clean up docker containers
cm="bash clean_docker_containers.sh"
echo $cm

#!/bin/bash

## Usage: run genomestrip on CPTAC3 WGS BAMs

## name of the master running directory
toolName="genomestrip"

## type of the BAM to be processed
bamType="WGS"

## name of the output directory for different batches
batchName="CPTAC3.CCRC.b5"

## the path to master directory containing "${toolName}" scripts, input dependencies and output directories
mainRunDir="/diskmnt/Projects/CPTAC3CNV/"${toolName}"/"
toolDirName=${toolName}"."${batchName}
mainScriptDir=${mainRunDir}${toolDirName}"/"
inputDir=${mainRunDir}"inputs/"

## the path to the file containing BAM paths, patient ids, sample ids
bamMapDir="/diskmnt/Projects/cptac/GDC_import/import.config/CPTAC3.CCRC.b5/"

## the name of the file containing BAM paths, patient ids, sample ids
bamMapFile="CPTAC3.CCRC.b5.BamMap.dat"

## the master directory holding the BAMs to be processed
bamDir="/diskmnt/Projects/cptac/GDC_import/data/"

## the name of the docker image
mainImage="skashin/genome-strip"
#mainImage="yigewu/genome-strip"
tag1="latest"
tag2="r1814"
tag3="globus"
tag4="jan2018"
imageName=${mainImage}":"${tag1}
gatkImage="broadinstitute/gatk-nightly:latest"


## the path to the reference metadata bundle
refDir=${inputDir}
refFile="Homo_sapiens_assembly19.fasta"
refBundlegz="Homo_sapiens_assembly19_12May2015.tar.gz"
refBundle="Homo_sapiens_assembly19"

## path to the file with gender info for patients
clinicalDir=${inputDir}
clinicalFile="CPTAC3.C325.Demographics.dat"

## the file containing the cancer types to be processed
cancerType="cancer_types.txt"
echo "CCRC" > ${cancerType}

## the key word to search for tumor and normal BAM files used for this analysis
sampleTypeFile="sample_types.txt"
echo "tumor" > ${sampleTypeFile}
echo "blood_normal" >> ${sampleTypeFile}
#echo "tissue_normal" >> ${sampleTypeFile}

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
while read sample_type; do
    while read cancer_type; do
        grep ${sample_type} ${inputDir}${bamMapFile} | grep ${cancer_type} | grep ${bamType} |  awk -F '\\s' '{print $6}' | awk -F 'import' '{print $1"import"$2}' > ${inputDir}${bamMapFile}"_"${bamType}"_"${sample_type}"_"${cancer_type}".list"
    done<${cancerType}
done<${sampleTypeFile}
echo "split the BAMs map file!"

## generate gender map file
while read sample_type; do
	while read cancer_type; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "create_gender_map.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName} ${clinFilesuffix}
        done<${cancerType}
done<${sampleTypeFile}

## run SVPreprocess pipeline
while read sample_type; do
        while read cancer_type; do
		bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "preprocess.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName}
	done<${cancerType}
done<${sampleTypeFile}

## wait until the last step is done
## run SVDiscovery pipeline
while read sample_type; do
        while read cancer_type; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "svDiscovery.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName}
        done<${cancerType}        
done<${sampleTypeFile}

## wait until the last step is done
## run SVGenotype pipeline
while read sample_type; do
        while read cancer_type; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "delGenotype.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done<${sampleTypeFile}

## wait until the last step is done
## run CNVDiscovery pipeline
while read sample_type; do
       while read cancer_type; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "cnvDiscovery.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done<${sampleTypeFile}

## wait until the last step is done
while read sample_type; do
        while read cancer_type; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "cnvGenotype.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done<${sampleTypeFile}

## wait until the last step is done
## filter out variants that do not pass Per-sample genotype filter (FT_
while read sample_type; do
        while read cancer_type; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "filter_variants.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName} ${clinFilesuffix}
        done<${cancerType}
done<${sampleTypeFile}

echo "wait until the last step is done and run the below tmux command ~"
## run GATK CombineVariants
while read sample_type; do
        while read cancer_type; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${gatkImage} "/bin/bash" ${mainScriptDir} "combine_vcfs.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName} ${clinFilesuffix}
        done<${cancerType}
done<${sampleTypeFile}

## wait until the last step is done
## run GATK SelectVariants
while read sample_type; do
        while read cancer_type; do
##               bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${gatkImage} "/bin/bash" ${mainScriptDir} "split_vcfs_by_sample.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName}
               bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "split_vcfs_by_sample.sh" ${sample_type} ${cancer_type} ${batchName} ${id} ${toolDirName}
        done<${cancerType}
done<${sampleTypeFile}

## push scripts to github
cm="bash push_git.sh ${batchName} ${version}"
echo ${cm}

## clean up docker containers
cm="bash clean_docker_containers.sh"
echo $cm

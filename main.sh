#!/bin/bash

## Usage: run genomestrip on CPTAC3 WGS BAMs

## name of the master running directory
toolName="genomestrip"

## type of the BAM to be processed
bamType="WGS"

## name of the output directory for different batches
batchName="LUAD.b1"

## the path to master directory containing "${toolName}" scripts, input dependencies and output directories
mainRunDir="/diskmnt/Projects/CPTAC3CNV/"${toolName}"/"
toolDirName=${toolName}"."${batchName}
mainScriptDir=${mainRunDir}${toolDirName}"/"
inputDir=${mainRunDir}"inputs/"

## the path to the file containing BAM paths, patient ids, sample ids
bamMapDir="/diskmnt/Projects/cptac_downloads/data/GDC_import/import.config/CPTAC3.b1.LUAD/"

## the name of the file containing BAM paths, patient ids, sample ids
bamMapFile="CPTAC3.b1.LUAD.BamMap.dat"

## the master directory holding the BAMs to be processed
bamDir="/diskmnt/Projects/cptac_downloads/data/GDC_import"

## the name of the docker image
imageName="skashin/genome-strip:latest"

## the path to the reference metadata bundle
refDir=" /diskmnt/Projects/Users/mwyczalk/data/docker/data/A_Reference/"
refFile="Homo_sapiens_assembly19.fasta"

## path to the file with gender info for patients
clinicalDir="/home/mwyczalk_test/Projects/CPTAC3/Discover/discover.CPTAC3.b15-LUAD/dat/"
clinicalFile="CPTAC3.LUAD.b1-5.Demographics.dat"

## the file containing the cancer types to be processed
cancerType="cancer_types.txt"

## tag for log file
id=$1

## download/copy dependencies
cm="bash get_dependencies.sh ${mainRunDir} ${bamMapDir} ${bamMapFile} ${clinicalDir} ${clinicalFile} ${refDir} ${refFile}"
if [ -s ${inputDir}${bamMapFile} ] && [ -s ${inputDir}${refFile} ] && [ -s ${inputDir}${clinicalFile} ]
then
	echo "dependencies were downloaded"
else
	echo ${cm}
	exit 1
fi

## split BAM path file into batchs
#cm="bash split_bam_path.sh ${mainRunDir} ${bamMapFile} ${bamType}"
for i in tumor normal; do
    while read j
        do
        grep ${i} ${inputDir}${bamMapFile} | grep ${j} | grep ${bamType} |  awk -F '\\s' '{print $6}' | awk -F 'import' '{print $1"import"$2}' > ${inputDir}${bamMapFile}"_"${bamType}"_"${i}"_"${j}".list"
        done<${cancerType}
done

## generate gender map file
cm="bash gender_map.sh ${mainRunDir} ${bamMapFile} ${bamType} ${clinicalFile}"
cd ${inputDir}
mkdir -p tmp
for i in tumor normal; do
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
        done<${mainScriptDir}${cancerType}
done
cd ${mainScriptDir}

## run SVPreprocess pipeline
for t in tumor normal; do
	for c in LUAD; do
		bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "preprocess.sh" ${t} ${c} ${batchName} ${id}
	done
done

## wait until the last step is done
## run SVDiscovery pipeline
for t in tumor normal; do
        for c in LUAD; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "svDiscovery.sh" ${t} ${c} ${batchName} ${id}
        done
done

## wait until the last step is done
## run SVGenotype pipeline
for t in tumor normal; do
        for c in LUAD; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "delGenotype.sh" ${t} ${c} ${batchName} ${id}
        done
done

## wait until the last step is done
## run CNVDiscovery pipeline
for t in tumor normal; do
        for c in LUAD; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "cnvDiscovery.sh" ${t} ${c} ${batchName} ${id} 
        done
done

## wait until the last step is done
for t in tumor normal; do
        for c in LUAD; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "cnvGenotype.sh" ${t} ${c} ${batchName} ${id} 
        done
done

## wait until the last step is done
## run GATK CombineVariants
for t in tumor normal; do
        for c in LUAD; do
                bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "combine_vcfs.sh" ${t} ${c} ${batchName} ${id}
        done
done

## wait until the last step is done
## run GATK SelectVariants
for t in tumor normal; do
        for c in LUAD; do
               bash run_tmux.sh ${mainRunDir} ${bamMapFile} ${bamType} ${bamDir} ${imageName} "/bin/bash" ${mainScriptDir} "split_vcfs_by_sample.sh" ${t} ${c} ${batchName} ${id}
        done
done

## clean up docker containers
cm="bash clean_docker_containers.sh"
echo $cm


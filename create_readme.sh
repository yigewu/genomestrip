#!/bin/bash

batchName=$1
bamType=$2
version=$3
mainScriptDir=$4
toolName=$5
mainRunDir=$6
readmeFile=${mainScriptDir}"README.md"
subdeliverDir=${mainRunDir}"deliverables/"${batchName}"/"

echo "${batchName} ${bamType} CNV pipeline v${version} overview:" > ${readmeFile}
echo "" >> ${readmeFile}
echo "${batchName} ${bamType} BAM files divided into groups by sample type (tumors sample or blood normal samples, each cancer type is also processed separately).  Genome STRiP deletion discovery pipeline and CNV discovery pipeline implemented on each group seperately." >> ${readmeFile}
echo "" >> ${readmeFile}
echo "Genome STRiP deletion discovery pipeline used Genome STRiP 2.0 SVPreprocess, SVDiscovery, SVGenotyper Queue scripts to generate deletion calls targeting 100 to 1M bps." >> ${readmeFile}
echo "" >> ${readmeFile}
echo "CNV discovery pipeline used CNVDiscoveryPipeline Queue script to discover copy number variants (including duplications and mCNV).
(This pipeline is complementary to the older deletion discovery pipeline, which seeds based on aberrantly spaced read pairs. Both pipelines will find large deletion sites, but the CNV pipeline will also find larger duplications and multi-allelic copy number variants. The deletion discovery pipeline will be more sensitive than the CNV pipeline for shorter deletions (at the same sequencing depth), but less sensitive for larger deletions where the breakpoints occur in more repetitive regions of the genome.)" >> ${readmeFile}
echo "" >> ${readmeFile}
echo "GATK CombineVariants was used to combine callsets from deletion discovery pipeline and CNV discovery pipeline (genoetypemergeoption=UNSORTED). GATK SelectVariants was used to extract sample specific callset." >> ${readmeFile}
echo "" >> ${readmeFile}
echo "Suggested downstream filtering:" >> ${readmeFile}
echo "RedundancyAnnotator(used to detect and filter redundant structural variation calls with similar coordinates in outputs from deletion discovery pipeline and CNV discovery pipeline)" >> ${readmeFile}
echo "" >> ${readmeFile}
echo "Processing scripts:" >> ${readmeFile}
echo "(@https://github.com/yigewu/${toolName}/tree/${batchName}):" >> ${readmeFile}
echo "refer to main.sh for coordination of specific scripts for each step" >> ${readmeFile}

cp ${readmeFile} ${subdeliverDir}

CPTAC3 WGS CNV Pipeline (v1.2) overview:

CPTAC3 batch#3 WGS BAM files were divided into 2 groups by tumor (18 LUAD tumors and 18 blood normal samples and by cancer types. Genome STRiP deletion discovery pipeline and CNV discovery pipeline implemented on 2 groups separately.

Genome STRiP deletion discovery pipeline used Genome STRiP 2.0 SVPreprocess, SVDiscovery, SVGenotyper Queue scripts to generate deletion calls targeting 100 to 1M bps.

CNV discovery pipeline used CNVDiscoveryPipeline Queue script to discover copy number variants (including duplications and mCNV).
(This pipeline is complementary to the older deletion discovery pipeline, which seeds based on aberrantly spaced read pairs. Both pipelines will find large deletion sites, but the CNV pipeline will also find larger duplications and multi-allelic copy number variants. The deletion discovery pipeline will be more sensitive than the CNV pipeline for shorter deletions (at the same sequencing depth), but less sensitive for larger deletions where the breakpoints occur in more repetitive regions of the genome.)

GATK CombineVariants was used to combine callsets from deletion discovery pipeline and CNV discovery pipeline (genoetypemergeoption=UNSORTED). GATK SelectVariants was used to extract sample specific callset.

Suggested downstream filtering:
RedundancyAnnotator(used to detect and filter redundant structural variation calls with similar coordinates in outputs from deletion discovery pipeline and CNV discovery pipeline) 

Processing scripts(@https://github.com/yigewu/genomestrip/tree/CPTAC3.LUAD.b3): 
refer to main.sh for coordination of specific scripts for each step

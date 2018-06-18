CPTAC3.b4 WGS CNV pipeline v1.2 overview:

CPTAC3.b4 WGS BAM files divided into groups by sample type (tumors sample or blood normal samples, each cancer type is also processed separately).  Genome STRiP deletion discovery pipeline and CNV discovery pipeline implemented on each group seperately.

Genome STRiP deletion discovery pipeline used Genome STRiP 2.0 SVPreprocess, SVDiscovery, SVGenotyper Queue scripts to generate deletion calls targeting 100 to 1M bps.

CNV discovery pipeline used CNVDiscoveryPipeline Queue script to discover copy number variants (including duplications and mCNV).
(This pipeline is complementary to the older deletion discovery pipeline, which seeds based on aberrantly spaced read pairs. Both pipelines will find large deletion sites, but the CNV pipeline will also find larger duplications and multi-allelic copy number variants. The deletion discovery pipeline will be more sensitive than the CNV pipeline for shorter deletions (at the same sequencing depth), but less sensitive for larger deletions where the breakpoints occur in more repetitive regions of the genome.)

GATK CombineVariants was used to combine callsets from deletion discovery pipeline and CNV discovery pipeline (genoetypemergeoption=UNSORTED). GATK SelectVariants was used to extract sample specific callset.

Suggested downstream filtering:
RedundancyAnnotator(used to detect and filter redundant structural variation calls with similar coordinates in outputs from deletion discovery pipeline and CNV discovery pipeline)

Processing scripts:
(@https://github.com/yigewu/genomestrip/tree/CPTAC3.b4):
refer to main.sh for coordination of specific scripts for each step

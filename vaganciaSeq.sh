#!/bin/bash
echo -e "#############################################################"
echo -e "###################	VAGANCIA SEQ	######################"
echo -e "#############################################################"
# Backbone file for the metagenomics project. Multiple other scripts
# will be called from this one. All scripts assume the following
# file structure:
#	ANALYSIS
#		SAMPLENAME
#			01.PREPROCESSING
#				SKEWER
#				TRIMMOMATIC
#			02.HOST
#			03.BACTERIA
#			04.VIRUS
#			05.ASSEMBLY
#				quast
#				spades
#	DOC
#	RAW
#		SAMPLENAME
#			xxxxxx_1.fasta
#			xxxxxx_2.fasta
#	REFERENCES
#		HUMAN_GENOME_REFERENCE
#		BACTERIA_16S_REFERENCE
#		VIRUS_GENOME_REFERENCE
#	RESULTS
#	TMP
# DEPENDENCIES:
# This program requires the following dependencies:
# - trimmommatic
# - bowtie2
# - spades
# The pipeline will do the following:
# 1. Quality control using trimmommatic.
# 2. Host removal mapping with bowtie2. 
# 3. Mapping against bacteria 16S reference.
# 4. Mapping against viral metagenome reference.
# 5. Assembly of bacteria and virus genomes separately with SPAdes.
# 6. Assembly of non-mapped reads
# 7. BLAST of the assemblies
# 8. Identification of hits
#######################################################################
#	GLOBAL VARIABLES
workingDir='/processing_Data/bioinformatics/research/20160530_METAGENOMICS_AR_IC_T/'
hostDB='${workingDir}REFERENCES/HUMAN_GENOME_REFERENCE/'
bacDB='${workingDir}REFERENCES/BACTERIA_16S_REFERENCE/'
virDB='${workingDir}REFERENCES/VIRUS_GENOME_REFERENCE/'

#	AWESOME SCRIPT
echo -e "Captain's log. Stelar date $(date)"
#	Get parameters:
sampleDir=''
while getopts "hs:" opt
do
	case "$opt" in
	h)	showHelp
		;;
	s)	sampleDir=$OPTARG
		;;
	esac
done
shift $((OPTIND-1))
#["$1"="--"] && shift

function showHelp {
	echo -e 'Usage: vagancia -s <path_to_samples>'
	echo -e 'vagancia -h: show this help'
	exit 0
}

#	VARIABLES
sampleName=$(basename "$sampleDir")
sampleAnalysisDir="${workingDir}ANALYSIS/${sampleName}"
rawDir="${workingDir}RAW/${sampleName}"
echo $sampleDir
#	TRIMMOMMATIC QUALITY CONTROL
#	Create sh file
echo -e "Command: python ${workingDir}ANALYSIS/SRC/Trimmomatic_new.py -i ${rawDir} -o ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/ -n $sampleName"
python ${workingDir}ANALYSIS/SRC/Trimmomatic_new.py -i ${rawDir} -o ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/ -n $sampleName
#	Execute sh file
if [ ! -x ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/* ]
then
	chmod +x ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/*
fi
$(${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh)

#	HOST REMOVAL
if [ ! -x ${workingDir}ANALYSIS/SRC/host_removal_new.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/host_removal_new.sh 
fi
#	execute host removal script
source ${workingDir}ANALYSIS/SRC/host_removal_new.sh
removeHost $hostDB $sampleAnalysisDir
echo -e "$(date)\t Finished filtering of host reads"


#	BACTERIA MAPPING
if [ ! -x ${workingDir}ANALYSIS/SRC/bac_mapper_new.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/bac_mapper_new.sh 
fi
#	execute bacteria mapping script
source ${workingDir}ANALYSIS/SRC/bac_mapper_new.sh
removeHost $bacDB $sampleAnalysisDir
echo -e "$(date)\t Finished mapping bacteria reads"

#	VIRUS MAPPING
if [ ! -x ${workingDir}ANALYSIS/SRC/vir_mapper_new.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/vir_mapper_new.sh 
fi
#	execute virus mapping script
source ${workingDir}ANALYSIS/SRC/vir_mapper_new.sh
removeHost $virDB $sampleAnalysisDir
echo -e "$(date)\t Finished mapping virus reads"








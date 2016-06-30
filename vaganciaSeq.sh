#!/bin/bash
set -e
echo -e "**********************************************************************************************"
echo -e "  __   __ _______ _______ _______ __   __ _______ _______ __   __ _______ _______ ___ _______  "
echo -e " |  |_|  |       |       |   _   |  | |  |       |       |  |_|  |   _   |       |   |       |"
echo -e " |       |    ___|_     _|  |_|  |  | |  |_     _|   _   |       |  |_|  |_     _|   |       |"
echo -e " |       |   |___  |   | |       |  |_|  | |   | |  | |  |       |       | |   | |   |       |"
echo -e " |       |    ___| |   | |       |       | |   | |  |_|  |       |       | |   | |   |      _|"
echo -e " | ||_|| |   |___  |   | |   _   |       | |   | |       | ||_|| |   _   | |   | |   |     |_ "
echo -e " |_|   |_|_______| |___| |__| |__|_______| |___| |_______|_|   |_|__| |__| |___| |___|_______|"
echo -e ""
echo -e "**********************************************************************************************"

# Backbone file for the metagenomics project. Multiple other scripts
# will be called from this one. All scripts assume the following
# file structure (and will create it if it doesn't exist):
#	ANALYSIS
#		SAMPLENAME
#			01.PREPROCESSING
#				SKEWER
#				TRIMMOMATIC
#			02.HOST
#			03.BACTERIA
#			04.VIRUS
#			05.ASSEMBLY
#				virus
#					spades
#					quast
#				bacteria
#					spades
#					quast
#			06. BLAST
#				virus
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
hostDB="${workingDir}REFERENCES/HUMAN_GENOME_REFERENCE/hg38.AnalysisSet"
bacDB="${workingDir}REFERENCES/BACTERIA_16S_REFERENCE/"
bac_bwt2_DB="${bacDB}bowtie2/16S"
virDB="${workingDir}REFERENCES/VIRUS_GENOME_REFERENCE/"
vir_bwt2_DB="${virDB}bowtie2/all.fna.tar.gz"
vir_BLASTn_DB="${virDB}blastn/viral_blastn"
vir_BLASTx_DB="${virDB}blastx/viral_blastx"

#	AWESOME SCRIPT
echo -e "PIPELINE START: $(date)"
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
bacteriaDir="${sampleAnalysisDir}/03.BACTERIA/"
virusDir="${sampleAnalysisDir}/04.VIRUS/"
sampleAnalysisLog="${sampleAnalysisDir}/${sampleName}_lablog.log"

if [ ! -d "${sampleAnalysisDir}" ]
then
	mkdir -p "$sampleAnalysisDir"
fi

#	TRIMMOMMATIC QUALITY CONTROL
#	Create sh file
echo -e "$(date): ********* Start quaility control **********" > "${sampleAnalysisLog}"
echo -e "************** First, let's do a bit of quality control *************"  
if [ ! -d "${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/" ]
then
	mkdir -p "$sampleAnalysisDir/01.PREPROCESSING/TRIMMOMATIC"
	echo -e "${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC created"
fi
echo -e "Command: python ${workingDir}ANALYSIS/SRC/Trimmomatic_new.py -i ${rawDir} -o ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/ -n $sampleName" >> "${sampleAnalysisLog}"
python ${workingDir}ANALYSIS/SRC/Trimmomatic_new.py -i ${rawDir} -o ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/ -n $sampleName
#	Execute sh file
if [ ! -x "${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh" ]
then
	chmod +x "${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh"
fi
echo -e "$(date): Execute ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh" >> "${sampleAnalysisLog}"
$(${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh) 
echo -e "$(date): Finished executing trimmommatic" >> "${sampleAnalysisLog}"
echo -e "$(date): ********* Finished quaility control **********" >> "${sampleAnalysisLog}"

#	HOST REMOVAL
echo -e "$(date): ************* Start host removal ***************" >> "${sampleAnalysisLog}"
echo -e "************** Now, we need to remove the host genome *************" 
if [ ! -x ${workingDir}ANALYSIS/SRC/host_removal_new.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/host_removal_new.sh   
fi
#	execute host removal script
source ${workingDir}ANALYSIS/SRC/host_removal_new.sh
echo -e " Execute removeHost $hostDB $sampleAnalysisDir" >> "${sampleAnalysisLog}"
removeHost $hostDB $sampleAnalysisDir 
echo -e "$(date): ************ Finished host removal ************" >> "${sampleAnalysisLog}"


#	BACTERIA MAPPING
#echo -e "$(date): ******** start mapping bacteria ***********" >> "${sampleAnalysisLog}"
#echo -e "******************* Great! Let's map some bacteria ****************"
#if [ ! -x ${workingDir}ANALYSIS/SRC/bac_mapper_new.sh ]
#then
#	chmod +x ${workingDir}ANALYSIS/SRC/bac_mapper_new.sh 
#fi
##	execute bacteria mapping script
#source ${workingDir}ANALYSIS/SRC/bac_mapper_new.sh
#echo -e " Execute map_bacteria $bac_bwt2_DB $sampleAnalysisDir" >> "${sampleAnalysisLog}"
#map_bacteria $bac_bwt2_DB $sampleAnalysisDir
#echo -e "$(date): ******** Finished mapping bacteria **********" >> "${sampleAnalysisLog}"

#	VIRUS MAPPING
echo -e "$(date): ******** start mapping virus ***********" >> "${sampleAnalysisLog}"
echo -e "******************* Great! Let's map some virus ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/vir_mapper_new.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/vir_mapper_new.sh 
fi
#	execute virus mapping script
source ${workingDir}ANALYSIS/SRC/vir_mapper_new.sh
echo -e " Execute map_virus $vir_bwt2_DB $sampleAnalysisDir" >> "${sampleAnalysisLog}"
map_virus $vir_bwt2_DB $sampleAnalysisDir
echo -e "$(date): ******** Finished mapping virus **********" >> "${sampleAnalysisLog}"

#	ASSEMBLY FOR BACTERIA
#echo -e "$(date): ******** start assemblying bacteria ***********" >> "${sampleAnalysisLog}"
#echo -e "******************* wohooo! Bacteria assembly party! ****************"
#if [ ! -x ${workingDir}ANALYSIS/SRC/SPAdes_assembly.sh ]
#then
#	chmod +x ${workingDir}ANALYSIS/SRC/SPAdes_assembly.sh 
#fi
##	execute assembly script
#source ${workingDir}ANALYSIS/SRC/SPAdes_assembly.sh
#echo -e " Execute assemble $bacteriaDir" >> "${sampleAnalysisLog}"
#assemble $bacteriaDir
#echo -e "$(date): ******** Finished assemblying bacteria ***********" >> "${sampleAnalysisLog}"

#	ASSEMBLY FOR VIRUS
echo -e "$(date): ******** Start assemblying virus ***********" >> "${sampleAnalysisLog}"
echo -e "******************* weeeeeeee! Virus assembly party! ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/SPAdes_assembly.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/SPAdes_assembly.sh 
fi
#	execute assembly script
source ${workingDir}ANALYSIS/SRC/SPAdes_assembly.sh
echo -e " Execute assemble $virusDir" >> "${sampleAnalysisLog}"
assemble $virusDir
echo -e "$(date): ******** Finished assemblying virus ***********" >> "${sampleAnalysisLog}"

#	BLAST 
echo -e "$(date): ******** Start running BLAST for virus ***********" >> "${sampleAnalysisLog}"
echo -e "******************* This is it! Let's see what hides in the deepness of the sample ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/blast.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/blast.sh 
fi
#	execute blast script
source ${workingDir}ANALYSIS/SRC/blast.sh 
echo -e " Execute assemble $virusDir" >> "${sampleAnalysisLog}"
blast $sampleAnalysisDir $virDB
echo -e "$(date): ******** Finished assemblying virus ***********" >> "${sampleAnalysisLog}"



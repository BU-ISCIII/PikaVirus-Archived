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

# Wrapper file for the metagenomics project. Multiple other scripts
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
#			05.FUNGI
#			06.PROTOZOA
#			07.INVERTEBRATE
#			08.ASSEMBLY
#				virus
#					spades
#					quast
#				bacteria
#					spades
#					quast
#			09.BLAST
#	DOC
#	RAW
#		SAMPLENAME
#			xxxxxx_1.fasta
#			xxxxxx_2.fasta
#	REFERENCES
#		HUMAN_GENOME_REFERENCE
#			BLAST
#				blastx
#				blastn
#			WG
#				bwt2
#		BACTERIA_GENOME_REFERENCE
#			BLAST
#				blastx
#				blastn
#			16S
#				bwt2
#			WG
#				bwt2
#		VIRUS_GENOME_REFERENCE
#			BLAST
#				blastx
#				blastn
#			WG
#				bwt2
#		FUNGI_GENOME_REFERENCE
#			BLAST
#				blastx
#				blastn
#			WG
#				bwt2
#			ITS
#				bwt2
#		INVERTEBRATE_GENOME_REFERENCE
#			BLAST
#				blastx
#				blastn
#			WG
#				bwt2
#		PROTOZOA_GENOME_REFERENCE
#			BLAST
#				blastx
#				blastn
#			WG
#				bwt2
#	RESULTS
#	TMP
# Notes: inside each bwt2 folder are the bowtie index files for that DB.
#	================================================
# DEPENDENCIES:
# This program requires the following dependencies:
# - trimmommatic
# - bowtie2
# - spades
# - BLAST
# - samtools
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
hostDB="${workingDir}REFERENCES/HUMAN_GENOME_REFERENCE/"
bacDB="${workingDir}REFERENCES/BACTERIA_GENOME_REFERENCE/"
virDB="${workingDir}REFERENCES/VIRUS_GENOME_REFERENCE/"
fungiDB="${workingDir}REFERENCES/FUNGI_GENOME_REFERENCE/"
parasiteDB="${workingDir}REFERENCES/"

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
fungiDir="${sampleAnalysisDir}/05.FUNGI/"
parasiteDir="${sampleAnalysisDir}/06.PARASITE/"

sampleAnalysisLog="${sampleAnalysisDir}/${sampleName}_lablog.log"

if [ ! -d "${sampleAnalysisDir}" ]
then
	mkdir -p "$sampleAnalysisDir"
fi

#                     _ _ _                           _             _ 
#    __ _ _   _  __ _| (_) |_ _   _    ___ ___  _ __ | |_ _ __ ___ | |
#   / _` | | | |/ _` | | | __| | | |  / __/ _ \| '_ \| __| '__/ _ \| |
#  | (_| | |_| | (_| | | | |_| |_| | | (_| (_) | | | | |_| | | (_) | |
#   \__, |\__,_|\__,_|_|_|\__|\__, |  \___\___/|_| |_|\__|_|  \___/|_|
#      |_|                    |___/                                   


#	TRIMMOMMATIC QUALITY CONTROL
#	Create sh file
echo -e "$(date): ********* Start quaility control **********" > "${sampleAnalysisLog}"
echo -e "************** First, let's do a bit of quality control *************"  
if [ ! -d "${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/" ]
then
	mkdir -p "$sampleAnalysisDir/01.PREPROCESSING/TRIMMOMATIC"
	echo -e "${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC created"
fi
echo -e "Command: python ${workingDir}ANALYSIS/SRC/trimmomatic.py -i ${rawDir} -o ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/ -n $sampleName" >> "${sampleAnalysisLog}"
python ${workingDir}ANALYSIS/SRC/trimmomatic.py -i ${rawDir} -o ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/ -n $sampleName
#	Execute sh file
if [ ! -x "${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh" ]
then
	chmod +x "${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh"
fi
echo -e "$(date): Execute ${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh" >> "${sampleAnalysisLog}"
$(${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/trimmomatic.sh) 
echo -e "$(date): Finished executing trimmommatic" >> "${sampleAnalysisLog}"
echo -e "$(date): ********* Finished quaility control **********" >> "${sampleAnalysisLog}"

#   _               _                                        _ 
#  | |__   ___  ___| |_   _ __ ___ _ __ ___   _____   ____ _| |
#  | '_ \ / _ \/ __| __| | '__/ _ \ '_ ` _ \ / _ \ \ / / _` | |
#  | | | | (_) \__ \ |_  | | |  __/ | | | | | (_) \ V / (_| | |
#  |_| |_|\___/|___/\__| |_|  \___|_| |_| |_|\___/ \_/ \__,_|_|
# 

#	HOST REMOVAL
echo -e "$(date): ************* Start host removal ***************" >> "${sampleAnalysisLog}"
echo -e "************** Now, we need to remove the host genome *************" 
if [ ! -x ${workingDir}ANALYSIS/SRC/host_removal.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/host_removal.sh   
fi
#	execute host removal script
source ${workingDir}ANALYSIS/SRC/host_removal.sh
echo -e " Execute removeHost $hostDB $sampleAnalysisDir" >> "${sampleAnalysisLog}"
removeHost $hostDB $sampleAnalysisDir 
echo -e "$(date): ************ Finished host removal ************" >> "${sampleAnalysisLog}"

#   _                _            _       
#  | |__   __ _  ___| |_ ___ _ __(_) __ _ 
#  | '_ \ / _` |/ __| __/ _ \ '__| |/ _` |
#  | |_) | (_| | (__| ||  __/ |  | | (_| |
#  |_.__/ \__,_|\___|\__\___|_|  |_|\__,_|
#   
#	BACTERIA MAPPING
echo -e "$(date): ******** start mapping bacteria ***********" >> "${sampleAnalysisLog}"
echo -e "******************* Great! Let's map some bacteria ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/mapper_bac.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/mapper_bac.sh 
fi
#	execute bacteria mapping script
source ${workingDir}ANALYSIS/SRC/mapper_bac.sh
echo -e " Execute map_bacteria $bacDB $sampleAnalysisDir" >> "${sampleAnalysisLog}"
map_bacteria $bacDB $sampleAnalysisDir
echo -e "$(date): ******** Finished mapping bacteria **********" >> "${sampleAnalysisLog}"

#	ASSEMBLY FOR BACTERIA
echo -e "$(date): ******** start assemblying bacteria ***********" >> "${sampleAnalysisLog}"
echo -e "******************* wohooo! Bacteria assembly party! ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/assembly.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/assembly.sh 
fi
#	execute assembly script
source ${workingDir}ANALYSIS/SRC/assembly.sh
echo -e " Execute assemble $bacteriaDir" >> "${sampleAnalysisLog}"
assemble $bacteriaDir
echo -e "$(date): ******** Finished assemblying bacteria ***********" >> "${sampleAnalysisLog}"

#	BLAST 
echo -e "$(date): ******** Start running BLAST for bacteria ***********" >> "${sampleAnalysisLog}"
echo -e "******************* Drums, drums in the deep (of the sample, of course)... ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/blast.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/blast.sh 
fi
#	execute blast script
source ${workingDir}ANALYSIS/SRC/blast.sh 
echo -e " Execute blast $sampleAnalysisDir $bacDB" >> "${sampleAnalysisLog}"
blast $sampleAnalysisDir $bacDB
echo -e "$(date): ******** Finished bacteria blast ***********" >> "${sampleAnalysisLog}"

#         _                
#  __   _(_)_ __ _   _ ___ 
#  \ \ / / | '__| | | / __|
#   \ V /| | |  | |_| \__ \
#    \_/ |_|_|   \__,_|___/
#                          

#	VIRUS MAPPING
echo -e "$(date): ******** start mapping virus ***********" >> "${sampleAnalysisLog}"
echo -e "******************* Great! Let's map some virus ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/mapper_virus.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/mapper_virus.sh 
fi
#	execute virus mapping script
source ${workingDir}ANALYSIS/SRC/mapper_virus.sh
echo -e " Execute map_virus $virDB $sampleAnalysisDir" >> "${sampleAnalysisLog}"
map_virus $virDB $sampleAnalysisDir
echo -e "$(date): ******** Finished mapping virus **********" >> "${sampleAnalysisLog}"

#	ASSEMBLY FOR VIRUS
echo -e "$(date): ******** Start assemblying virus ***********" >> "${sampleAnalysisLog}"
echo -e "******************* weeeeeeee! Virus assembly party! ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/assembly.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/assembly.sh 
fi
#	execute assembly script
source ${workingDir}ANALYSIS/SRC/assembly.sh
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
echo -e " Execute blast $sampleAnalysisDir $virDB" >> "${sampleAnalysisLog}"
blast $sampleAnalysisDir $virDB
echo -e "$(date): ******** Finished virus blast ***********" >> "${sampleAnalysisLog}"

#    __                   _ 
#   / _|_   _ _ __   __ _(_)
#  | |_| | | | '_ \ / _` | |
#  |  _| |_| | | | | (_| | |
#  |_|  \__,_|_| |_|\__, |_|
# 

#	FUNGI MAPPING
echo -e "$(date): ******** start mapping fungi ***********" >> "${sampleAnalysisLog}"
echo -e "******************* Mushroom hunting, yay! ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/mapper_fungi.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/mapper_fungi.sh 
fi
#	execute fungi mapping script
source ${workingDir}ANALYSIS/SRC/mapper_fungi.sh
echo -e " Execute map_fungi $fungiDB $sampleAnalysisDir" >> "${sampleAnalysisLog}"
map_fungi $fungiDB $sampleAnalysisDir
echo -e "$(date): ******** Finished mapping fungi **********" >> "${sampleAnalysisLog}"

#	ASSEMBLY FOR FUNGI
echo -e "$(date): ******** Start assemblying fungi ***********" >> "${sampleAnalysisLog}"
echo -e "******************* Assemblying is fun(gi)!! ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/assembly.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/assembly.sh 
fi
#	execute assembly script
source ${workingDir}ANALYSIS/SRC/assembly.sh
echo -e " Execute assemble $fungiDir" >> "${sampleAnalysisLog}"
assemble $fungiDir
echo -e "$(date): ******** Finished assemblying fungi ***********" >> "${sampleAnalysisLog}"

#	BLAST 
echo -e "$(date): ******** Start running BLAST for fungi ***********" >> "${sampleAnalysisLog}"
echo -e "******************* Can we eat the fungi we found? BLAST will say ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/blast.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/blast.sh 
fi
#	execute blast script
source ${workingDir}ANALYSIS/SRC/blast.sh 
echo -e " Execute blast $sampleAnalysisDir $fungiDB" >> "${sampleAnalysisLog}"
blast $sampleAnalysisDir $fungiDB
echo -e "$(date): ******** Finished fungi blast ***********" >> "${sampleAnalysisLog}"

#                             _ _       
#   _ __   __ _ _ __ __ _ ___(_) |_ ___ 
#  | '_ \ / _` | '__/ _` / __| | __/ _ \
#  | |_) | (_| | | | (_| \__ \ | ||  __/
#  | .__/ \__,_|_|  \__,_|___/_|\__\___|
#  |_| 

#	VIRUS MAPPING
echo -e "$(date): ******** start mapping parasite ***********" >> "${sampleAnalysisLog}"
echo -e "******************* parasites.... are you there? ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/mapper_parasite.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/mapper_parasite.sh 
fi
#	execute parasite mapping script
source ${workingDir}ANALYSIS/SRC/mapper_parasite.sh
echo -e " Execute map_parasite $parasiteDB $sampleAnalysisDir" >> "${sampleAnalysisLog}"
map_parasite $parasiteDB $sampleAnalysisDir
echo -e "$(date): ******** Finished mapping parasite **********" >> "${sampleAnalysisLog}"

#	ASSEMBLY FOR PARASITES	
echo -e "$(date): ******** Start assemblying parasites ***********" >> "${sampleAnalysisLog}"
echo -e "******************* If we assemble paras... do we get parasite? ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/assembly.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/assembly.sh 
fi
#	execute assembly script
source ${workingDir}ANALYSIS/SRC/assembly.sh
echo -e " Execute assemble $parasiteDir" >> "${sampleAnalysisLog}"
assemble $parasiteDir
echo -e "$(date): ******** Finished assemblying parasites ***********" >> "${sampleAnalysisLog}"

#	BLAST 
echo -e "$(date): ******** Start running BLAST for parasites ***********" >> "${sampleAnalysisLog}"
echo -e "******************* BLASTed parasites! ****************"
if [ ! -x ${workingDir}ANALYSIS/SRC/blast.sh ]
then
	chmod +x ${workingDir}ANALYSIS/SRC/blast.sh 
fi
#	execute blast script
source ${workingDir}ANALYSIS/SRC/blast.sh 
echo -e " Execute blast $sampleAnalysisDir $parasiteDB" >> "${sampleAnalysisLog}"
blast $sampleAnalysisDir $parasiteDB
echo -e "$(date): ******** Finished parasite blast ***********" >> "${sampleAnalysisLog}"

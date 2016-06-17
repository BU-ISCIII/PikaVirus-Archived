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
# 6. Identification of microbes present

echo -e "Captain's log. Stelar date $(date)"
#	Get parameters:
hostDB=''
sampleDir=''
while getopts "hr:s:" opt
do
	case "$opt" in
	h)	showHelp
		;;
	r)	hostDB=$OPTARG
		;;
	s)	sampleDir=$OPTARG
		;;
	esac
done
shift $((OPTIND-1))
["$1"="--"] && shift

function showHelp{
	echo -e "Usage: vagancia -r <path_to_reference> -s <path_to_samples>"
	echo "vagancia -h: show this help"
	exit 0
}

#	TRIMMOMMATIC QUALITY CONTROL
./Trimmomatic_new.py -i $sampleDir













#########################################################
#		  SCRIPT TO ASSEMBLE READS USING SPADES		 	#
#########################################################
# Arguments:
# $1 = Group Directory. Directory where the fastq to be assembled are located.
# $2 = sampleName. Name of the sample to be processed. Must match the name of the sample in the RAW directory.
# 1. Creates necessary directories. 
# 2. Assembles fastq files.
# 3. Runs quast to see quality
# Output files: (In ANALYSIS/sampleName/05.ASSEMBLY)
# sampleName_bacteria_mapped.sam: SAM file from mapping the processed files against the reference genome.
# sampleName_*_forward.fastq: .fastq file with forward reads that mapped the bacteria DB.
# sampleName_*_reverse.fastq: .fastq file with reverse reads that mapped the bacetria DB.
# sampleName_lablog.log: .log file with a log of the mapping.

function assemble {
#	GET ARGUMENTS
mappedDir=$1 # Directory where the mapped fastq are 
sampleAnalysisDir=$2
#	INITIALIZE VARIABLES
#		Organism
organism="${mappedDir##*.}" # gets whats is after the '.' and assumes is the organism
#		Directories
sampleName=$(basename "${sampleAnalysisDir}")
outputDir="${sampleAnalysisDir}05.ASSEMBLY/${organism}/"
#		Input Files
mappedForwardFastq="${mappedDir}${sampleName}_*_forward.fastq"
mappedReverseFastq="${mappedDir}${sampleName}_*_reverse.fastq"
#		Output Files
lablog="${outputDir}${sampleName}_lablog.log"


echo -e "$(date)" 
echo -e "*********** ASSEMBLY $sampleName ************"

#	CREATE DIRECTORY FOR THE SAMPLE IF NECESSARY
if [ ! -d ${outputDir} ]
then
	mkdir -p $outputDir
	echo -e "${outputDir} created"
fi
	
#	RUN SPADES	
echo -e "$(date)\t start running spades for ${sampleName} for ${organism}\n" > $lablog
echo -e "The command is: ### spades.py -1 $mappedForwardFastq -2 $mappedReverseFastq --meta -o $outputDir > $lablog"
spades.py -1 $mappedForwardFastq -2 $mappedReverseFastq --meta -o $outputDir > $lablog
echo -e "$(date)\t finished running spades for ${sampleName} for ${organism}\n" > $lablog

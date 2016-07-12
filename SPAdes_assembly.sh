set -e
#########################################################
#		  SCRIPT TO ASSEMBLE READS USING SPADES		 	#
#########################################################
# Arguments:
# $1 = (mappedDir) Group Directory. Directory where the fastq to be assembled are located.
# 1. Creates necessary directories. 
# 2. Assembles fastq files.
# 3. Runs quast to see quality
# Output files: (In ANALYSIS/sampleName/05.ASSEMBLY)
# sampleName_bacteria_mapped.sam: SAM file from mapping the processed files against the reference genome.
# sampleName_*_R1.fastq: .fastq file with R1 reads that mapped the DB.
# sampleName_*_R2.fastq: .fastq file with R2 reads that mapped the DB.
# sampleName_assembly.log: .log file with a log of the mapping.

function assemble {
#	GET ARGUMENTS
mappedDir=$1  
#	INITIALIZE VARIABLES
#		Organism
organism="${mappedDir##*.}" # gets what is after the '.' and assumes is the organism
sampleName=$(echo $mappedDir | rev | cut -d'/' -f3 | rev) # gets the sample name (3d column from the end of the mapped dir)
sampleAnalysisDir=$(echo $mappedDir | rev | cut -d'/' -f3- | rev) #gets the analysis directory of the sample (everything before the 3 column)
#		Directories
outputDir="${sampleAnalysisDir}/07.ASSEMBLY/${organism}/"
#		Input Files
mappedR1Fastq="${mappedDir}${sampleName}_WG*_R1.fastq"
mappedR2Fastq="${mappedDir}${sampleName}_WG*_R2.fastq"
#		Output Files
lablog="${outputDir}${sampleName}_assembly.log"


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
echo -e "The command is: ### spades.py --phred-offset 33 -1 $mappedR1Fastq -2 $mappedR2Fastq --meta -o $outputDir" >> $lablog
spades.py --phred-offset 33 -1 $mappedR1Fastq -2 $mappedR2Fastq --meta -o ${outputDir}spades 2>&1 | tee -a $lablog
echo -e "$(date)\t finished running spades for ${sampleName} for ${organism}\n" >> $lablog

#	RUN QUAST
echo -e "$(date)\t start running quast for ${sampleName} for ${organism}\n" >> $lablog
echo -e "The command is ###  metaquast.py -f ${outputDir}spades/contigs.fasta -o ${outputDir}quast/" >> $lablog
metaquast.py -f ${outputDir}spades/contigs.fasta -o ${outputDir}quast/ 2>&1 | tee -a $lablog
echo -e "$(date)\t finished running quast for ${sampleName} for ${organism}\n" >> $lablog


}

#assemble /processing_Data/bioinformatics/research/20160530_METAGENOMICS_AR_IC_T/ANALYSIS/MuestraPrueba/04.VIRUS/

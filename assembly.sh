#!/bin/bash
set -e
#########################################################
#		  SCRIPT TO ASSEMBLE READS USING SPADES		 	#
#########################################################
# 1. Creates necessary directories.
# 2. Assembles fastq files with spades.
# 3. Runs quast to check alignment quality
# Note: this script must be run only after mapping against a reference with the appropiate mapper_organism.sh script.

# Arguments:
# $1 (mappedDir) = Group Directory. Directory where the fastq to be assembled are located. (ANALYSIS/xx-organism/sampleName/reads)

# Input files: (In mappedDir)
# mappedR1Fastq = R1 alignment file.
# mappedR2Fastq = R2 alignment file.

# Output files: (In ANALYSIS/xx-organism/sampleName/contigs)
# spades output files (contigs.fasta, scaffolds.fasta...)
# sampleName_assembly.log: .log file with a log of the mapping.
# quast/: quast output files

source ./pikaVirus.config

#	GET ARGUMENTS
mappedDir=$1  # analysisDir/xx-organism/sampleName/reads/
#	INITIALIZE VARIABLES
#		Constants
sampleName=$(echo $mappedDir | rev | cut -d'/' -f3 | rev) # (sampleName)
organismDir=$(echo $mappedDir | rev | cut -d'/' -f4 | rev) # (xx-organism)
organism="${organismDir##*-}" # (organism)
#		Directories
outputDir="$(echo $mappedDir | rev | cut -d'/' -f3- | rev)/contigs/" # where the contigs will be saved (workingDir/ANALYSIS/xx-organism/sampleName/contigs)
#		Input Files
mappedR1Fastq="${mappedDir}${sampleName}*.fastq"
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

if [ ! -d "${outputDir}quast" ]
then
	mkdir -p "${outputDir}quast"
	echo -e "${outputDir}quast created"
fi

#	RUN SPADES
echo -e "$(date)\t start running spades for ${sampleName} for ${organism}\n" > $lablog
echo -e "The command is: ### spades.py --phred-offset 33 -s $mappedR1Fastq --meta -o $outputDir" >> $lablog
spades.py --phred-offset 33 -s $mappedR1Fastq --meta -o ${outputDir} 2>&1 | tee -a $lablog
echo -e "$(date)\t finished running spades for ${sampleName} for ${organism}\n" >> $lablog

#	RUN QUAST
echo -e "$(date)\t start running quast for ${sampleName} for ${organism}\n" >> $lablog
echo -e "The command is ###  metaquast.py -f ${outputDir}/contigs.fasta -o ${outputDir}quast/" >> $lablog
metaquast.py -f ${outputDir}/contigs.fasta -o ${outputDir}quast/ 2>&1 | tee -a $lablog
echo -e "$(date)\t finished running quast for ${sampleName} for ${organism}\n" >> $lablog




#!/bin/bash
set -e
#########################################################
#  SCRIPT TO RUN BLAST LOCALLY AGAINST NCBI VIRUS SEQ.	#
#########################################################
# 1. Creates necessary directories. 
# 2. Runs BLASTn against reference.
# 3. Runs BLASTx against reference.
# Note: This script must be run after assemblying the reads into contigs with assembly.sh.

# Arguments:
# $1 (sampleDir) = Directory with the sample analysis. (ANALYSIS/xx-organism/sampleName/)
# $2 (refDB) = Directory where the blast db is located (REFERENCES/ORGANISM_GENOME_REFERENCE/BLAST)

# Input files: (In ANALYSIS/xx-organism/sampleName/contigs/)
# sampleContig: fasta file with the contigs to be used as queries in blast.

# Output files: (In ANALYSIS/xx-organism/sampleName/blast/)
# sampleName_blast_log.log: log file for the blast run
# sampleName_BLASTn.blast: hit file of the blast
# sampleName_BLASTn_filtered.blast: hit file of the blast filtered by % id >90% and query sequence length > 100bp

source ./pikaVirus.config

function blast {
#	GET ARGUMENTS
sampleDir=$1  #analysisDir/xx-organism/sampleName/
refDB=$2
#	INITIALIZE VARIABLES
sampleName=$(basename $sampleDir) # (sampleName)
organismDir=$(echo $sampleDir | rev | cut -d'/' -f3 | rev) # (xx-organism)
organism="${organismDir##*-}" # (organism)
upOrganism=$(echo $organism | tr '[:lower:]' '[:upper:]') # (ORGANISM)
blastDB="${refDB}BLAST/"
BLASTn_DB="${blastDB}blastn/${upOrganism}_blastn"
BLASTx_DB="${blastDB}blastx/${upOrganism}_blastx"
#		Directories
outputDir="${sampleDir}/blast/"
#		Input Files
sampleContig="${sampleDir}/contigs/contigs.fasta"
#		Output Files
blastnResult="${outputDir}${sampleName}_BLASTn.blast"
blastnResultFiltered="${outputDir}${sampleName}_BLASTn_unsorted.blast"
blastnResultSorted="${outputDir}${sampleName}_BLASTn_filtered.blast"
blastxResult="${outputDir}${sampleName}_BLASTx.blast"
lablog="${outputDir}${sampleName}_blast_log.log"
contigFaa="${outputDir}${sampleName}_contig_aa.faa"
blastnHits="${outputDir}blastn_Hits.txt"

# load programs in module (comment for local runs) 
#module load ncbi_blast-2.2.30+

echo -e "$(date)" 
echo -e "*********** BLAST $sampleName ************"

#	CREATE DIRECTORY FOR THE SAMPLE IF NECESSARY
if [ ! -d ${outputDir} ]
then
	mkdir -p $outputDir
	echo -e "${outputDir} created"
fi
	
#	RUN BLASTn	
if [ ! -f $sampleContig ]; then
	echo "$sampleContig file not found!" > $lablog
else
	echo -e "$(date)\t start running BLASTn for ${sampleName}\n" > $lablog
	echo -e "$(date)\t start running BLASTn for ${sampleName}"
	echo -e "The command is: ### blastn -db $BLASTn_DB -query $sampleContig -outfmt '6 stitle staxids std qseq' > $blastResult ###" >> $lablog
	blastn -db $BLASTn_DB -query $sampleContig -outfmt '6 stitle std qseq' > $blastnResult 
	echo -e "$(date)\t finished running BLASTn for ${sampleName}\n" >> $lablog
	#	Filter blast results that pass min 100 length (col. 5) and 90% alignment (col. 4).
	awk -F "\t" '{if($4 >= 90 && $5>= 100) print $0}' $blastnResult > $blastnResultFiltered
	sort -k1 $blastnResultFiltered > $blastnResultSorted
	
	#	RUN BLASTx and RAPSearch2
	#echo -e "$(date)\t start running BLASTx for ${sampleName}\n" >> $lablog
	#echo -e "$(date)\t start running BLASTx for ${sampleName}" 
	#echo -e "The command is: ### blastx -db $BLASTx_DB -query $sampleContig -html > $blastResult ###" >> $lablog
	#blastx -db $BLASTx_DB -query $sampleContig -outfmt '6 stitle std' > $blastxResult 
	#echo -e "$(date)\t finished running BLASTx for ${sampleName}\n" >> $lablog
	
	#grep -A 5 -B 3 ">" $blastnResult > $blastnHits

fi
}


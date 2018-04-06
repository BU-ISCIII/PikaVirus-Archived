#!/bin/bash
set -e

#########################################################
#		  		LOAD SOFTWARE INTO PATH				 	#
#########################################################

# 1. Load the right version of the software needed to run pikaVirus.
# This script is designed to run in our cluster under Sun Grid Engine,
# so you will may have to adapt it before porting it to your own infrastrucutre.
# If all the software is already in your PATH, there is no need to execute this
# script.

module load FastQC-0.11.3
module load Trimmomatic-0.33
module load bowtie/bowtie2-2.2.4
module load samtools/samtools-1.2
module load spades/spades-3.8.0
module load quast/quast-4.1
module load ncbi-blast/ncbi_blast-2.2.30+
module load bedtools2/bedtools2-2.25.0
module load R/R-3.2.5


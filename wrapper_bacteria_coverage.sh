#!/bin/bash
set -e

#########################################################
#		  		BACTERIA COVERAGE WRAPPER				 	#
#########################################################

# 1. Runs coverage.sh* with every sample included in samples_id.txt**
# * Note: This script must only be used after running wrapper_virus_mapper.sh

#       CONSTANTS
source ./pikaVirus.config
samplesIdFile="${analysisDir}/samples_id.txt"

# Calculates coverage for each sample
if [ "${cluster}" == "yes" ] # qsub -V -j y -b y -cwd -t 1-number of samples -q all.q -N name command
then
	in=$(awk "NR==$SGE_TASK_ID" $samplesIdFile)
	sampleDir="${analysisDir}/05-bacteria/${in}/"
	bash ${analysisDir}/SRC/coverage.sh $sampleDir $bacDB
else
	cat ${analysisDir}/samples_id.txt | while read in
	do
		sampleDir="${analysisDir}/05-bacteria/${in}/"
		bash ${analysisDir}/SRC/coverage.sh $sampleDir $bacDB
	done
fi


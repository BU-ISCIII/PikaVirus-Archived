#!/bin/bash
set -e

#########################################################
#		  		HTML RESULTS GENERATOR				 	#
#########################################################
# 1. Copies web utilities into RESULTS/ (css, img, js...).
# 2. Generates info.html.
# 3. Generates quality reports of each sample. (with listFastQCReports.pl and createHTML.pl).
# 4. Generates quality.html.
# 5. Generates merged results table (with mergeResults.R).
# 6. Generates results web table for each sample and organism (with script createResultHtml.sh).
# 7. Generates samples.html.
# 8. Generates statistics of each sample and organism (with script statistics.sh).
# 9. Generates result summary.html.

source ./pikaVirus.config

#       CONSTANTS
PIKAVIRUSDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
lablog="${resultsDir}results_log.log"

############### COPY UTILITIES ################
#	CREATE DIRECTORies IF NECESSARY
if [ ! -d "${resultsDir}" ]
then
	mkdir -p "${resultsDir}"
	echo -e "$(date)\t Generate ${resultsDir}" > $lablog
	echo -e "${resultsDir} created"
fi
echo -e "$(date)\t start copying utilities (css, js, img...)\n" >> $lablog
echo -e "The commands are:\ncp -r ${PIKAVIRUSDIR}/html/css* ${resultsDir}\ncp -r ${PIKAVIRUSDIR}/html/img* ${resultsDir}\ncp -r ${PIKAVIRUSDIR}/html/js* ${resultsDir}" > $lablog

#	CREATE DIRECTORies IF NECESSARY
if [ ! -d "${resultsDir}css" ]
then
	mkdir -p "${resultsDir}css"
	echo -e "$(date)\t Generate ${resultsDir}css" >> $lablog
	echo -e "${resultsDir}css created"
fi

if [ ! -d "${resultsDir}js" ]
then
	mkdir -p "${resultsDir}js"
	echo -e "$(date)\t Generate ${resultsDir}js" >> $lablog
	echo -e "${resultsDir}js created"
fi

cp -r ${PIKAVIRUSDIR}/html/css/*.css "${resultsDir}css/"
cp -r ${PIKAVIRUSDIR}/html/img* ${resultsDir}
cp -r ${PIKAVIRUSDIR}/html/js/*.js "${resultsDir}js/"
echo -e "$(date)\t finished copying utilities into $resultsDir" >> $lablog

########## Copy template  #############
echo -e "$(date)\t start copying info.html into $resultsDir" >> $lablog
echo -e "The command is:\ncp ${PIKAVIRUSDIR}/html/info.html ${resultsDir}" >> $lablog
cp ${PIKAVIRUSDIR}/html/info.html ${resultsDir}

########## QUALITY REPORT #############
#	CREATE DIRECTORY FOR THE SAMPLE IF NECESSARY
if [ ! -d "${resultsDir}quality" ]
then
	mkdir -p "${resultsDir}quality"
	echo -e "$(date)\t Generate ${resultsDir}quality" >> $lablog
	echo -e "${resultsDir}quality created"
fi

# Copy quality utilities
echo -e "$(date)\t Start copying utilities for quality results:" >> $lablog
echo -e "cp -r ${PIKAVIRUSDIR}/html/quality/ ${resultsDir}" >> $lablog
cp -r ${PIKAVIRUSDIR}/html/quality/ ${resultsDir}
# Copy data
echo -e "cp -r ${workingDir}ANALYSIS/99-stats/data* ${resultsDir}quality" >> $lablog
cp -r ${analysisDir}/99-stats/data* ${resultsDir}quality

# Change to quality dir
#cd ${resultsDir}quality
#cd ${resultsDir}

# generate fastqc report:
echo -e "Generate fastq report:" >> $lablog
echo -e "perl ./listFastQCReports.pl ${resultsDir}quality/data/ > ${resultsDir}quality/table.html" >> $lablog
#perl ./listFastQCReports.pl ./quality/data/ > ./quality/table.html
perl ${PIKAVIRUSDIR}/html/quality/listFastQCReports.pl ${resultsDir}quality/data/ > ${resultsDir}quality/table.html
echo -e "perl ./createHTML.pl" >> $lablog
perl ${PIKAVIRUSDIR}/html/quality/createHTML.pl

echo -e "Removing template.html, table.html, listFastQCReports.pl and createHTML.pl" >> $lablog
# rm ./template.html
# rm ./table.html
# rm ./listFastQCReports.pl
# rm ./createHTML.pl

# Copy quality template html file
echo -e "$(date)\t Copy the quality template page:" >> $lablog
echo -e "cp ${PIKAVIRUSDIR}/html/quality.html ${resultsDir}" >> $lablog
cp ${PIKAVIRUSDIR}/html/quality.html ${resultsDir}

# cd ${analysisDir}

######### PER SAMPLE ########
#	CREATE DIRECTORY FOR THE SAMPLE IF NECESSARY
if [ ! -d "${resultsDir}data/persamples" ]
then
	mkdir -p "${resultsDir}data/persamples"
	echo -e "$(date)\t Generate ${resultsDir}data/persamples" >> $lablog
	echo -e "${resultsDir}data/persamples created"
fi

# Copy all the

# Generate by sample template html
echo -e "$(date)\t Run script to generate BySample template:" >> $lablog
echo -e "bash ${PIKAVIRUSDIR}/createSamplesHtml.sh" >> $lablog
bash ${PIKAVIRUSDIR}/createSamplesHtml.sh 2>&1 | tee -a $lablog

# Generate actual sample data html files
echo -e "$(date)\t Generate actual data sample html files" >> $lablog
organisms=()
for organism in "${analysisDir}/*"
do
	organism=$(echo $organism | rev | cut -d'/' -f1 | rev)
	if [[ $organism =~ ^[0]{1}[5-9] ]];
	then
		cat ${analysisDir}/samples_id.txt | while read sample
		do
			echo -e "$sample" >> $lablog
			# Create results table
			echo -e "\t$(date)\t Create results table (.txt)" >> $lablog
			echo -e "\t$(date)\t Rscript ${PIKAVIRUSDIR}/mergeResults.R $sample $organism $analysisDir $resultsDir" >> $lablog
			Rscript ${PIKAVIRUSDIR}/mergeResults.R $sample $organism $analysisDir $resultsDir 2>&1 | tee -a $lablog
			# Create results html
			#sampleDir=$1  #/analysisDir/xx-organism/sampleName/
			echo -e "\t$(date)\t Create results html file" >> $lablog
			echo -e "\t$(date)\t ${PIKAVIRUSDIR}/createResultHtml.sh ${analysisDir}/${organism}/${sample}/" >> $lablog
			bash ${PIKAVIRUSDIR}/createResultHtml.sh "${analysisDir}/${organism}/${sample}/" 2>&1 | tee -a $lablog
		done
	fi
done

######### SUMMARY ###########
# Create directory for the sample if necessary
if [ ! -d "${resultsDir}data/summary" ]
then
	mkdir -p "${resultsDir}data/summary/"
	echo -e "$(date)\t Generate ${resultsDir}data/summary" >> $lablog
	echo -e "${resultsDir}data/summary created"
fi

# Generate taxonomy statistics files
echo -e "$(date)\t Generate taxonomy statistics files" >> $lablog
organisms=()
for organism in ${analysisDir}/*
do
	organism=$(echo $organism | rev | cut -d'/' -f1 | rev)
	if [[ $organism =~ ^[0]{1}[5-9] ]];
	then
		echo -e "$organism" >> $lablog
		organism_stripped="${organism##*-}" # gets what is after the '-' and assumes is the organism
		cat ${analysisDir}/samples_id.txt | while read sample
		do
			echo -e "\t$sample" >> $lablog
			# Generate taxonomy statistics
			echo -e "\t\t$(date)\t Generate statistics" >> $lablog
			echo -e "\t\t${PIKAVIRUSDIR}/statistics.sh ${analysisDir}/${organism}/${sample}/blast" >> $lablog
			bash ${PIKAVIRUSDIR}/statistics.sh ${analysisDir}/${organism}/${sample}/blast/ 2>&1 | tee -a $lablog
			# Copy statistics files to RESULTS data folder
			cp "${analysisDir}/${organism}/${sample}/taxonomy/${sample}_${organism_stripped}_statistics.txt" "${resultsDir}/data/summary/" 2>&1 | tee -a $lablog
		done
	fi
done

# Generates the html file once the txt statistics are finished and copied.
echo -e "$(date)\t Create summary html file:" >> $lablog
echo -e "${PIKAVIRUSDIR}/createSummaryHtml.sh" >> $lablog
bash ${PIKAVIRUSDIR}/createSummaryHtml.sh 2>&1 | tee -a $lablog





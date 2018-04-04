
#!/bin/bash
set -e

#########################################################
#		  			PIKAVIRUS WRAPPER				 	#
#########################################################

# 1. Check that the folder structure is already created and as described in the documentation.
# 2. Check that a valid pikaVirus.config file exists.
# 3. Check that the input files are correctly located.
# 4. Check that the databases are in the right place.
# 5. Generate samples names list file.
# 6. Quality control.
# 7. Mapping.
# 8. Assembly.
# 9. Blast.
# 10. Coverage.
# 11. Results.

# USAGE
CONFIGFILE="$1"
if [ ! -f "$CONFIGFILE" ]
then
	echo "File not found!"
	echo "Please pass the absolute path to your pikaVirus.config file as argument:"
	echo "sh pikavirus.sh /path/to/file/pikaVirus.config"
	exit 1
else
	source "$CONFIGFILE"
fi

# CHECK FOLDER STRUCTURE
PIKAVIRUSDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d "$workingDir" ]
then
	echo "$workingDir \n defined in \n$CONFIGFILE not found. Attempting to create it now"
	mkdir "$workingDir"
fi

if [ ! -d "$analysisDir" ]
then
	echo "$analysisDir \n defined in \n$CONFIGFILE not found. Attempting to create it now"
	mkdir "$analysisDir"
fi

if [ ! -d "${analysisDir}/00-reads/" ]
then
	echo "${analysisDir}/00-reads/ \n defined in \n$CONFIGFILE not found. Attempting to create it now"
	mkdir "${analysisDir}/00-reads/"
	echo "Please, locate your input fastq files in ${analysisDir}/00-reads/"
	exit 1
fi

if [ ! -d "$resultsDir" ]
then
	echo "$resultsDir \n defined in \n$CONFIGFILE not found. Attempting to create it now"
	mkdir "$resultsDir"
fi

if [ ! -d "$virDB" ]
then
	echo "$virDB \n defined in \n$CONFIGFILE not found. Please make sure to prepare your data for the analysis before executing pikaVirus.sh"
	echo "$virDB must contain already processed databases for blast and bowtie mapping"
	exit 1
fi

if [ ! -d "$bacDB" ]
then
	echo "$bacDB \n defined in \n$CONFIGFILE not found. Please make sure to prepare your data for the analysis before executing pikaVirus.sh"
	echo "$bacDB must contain already processed databases for blast and bowtie mapping"
	exit 1
fi

if [ ! -d "$fungiDB" ]
then
	echo "$fungiDB \n defined in \n$CONFIGFILE not found. Please make sure to prepare your data for the analysis before executing pikaVirus.sh"
	echo "$fungiDB must contain already processed databases for blast and bowtie mapping"
	exit 1
fi

if [ ! -d "$protozoaDB" ]
then
	echo "$protozoaDB \n defined in \n$CONFIGFILE not found. Please make sure to prepare your data for the analysis before executing pikaVirus.sh"
	echo "$protozoaDB must contain already processed databases for blast and bowtie mapping"
	exit 1
fi

if [ ! -d "$invertebrateDB" ]
then
	echo "$invertebrateDB \n defined in \n$CONFIGFILE not found. Please make sure to prepare your data for the analysis before executing pikaVirus.sh"
	echo "$invertebrateDB must contain already processed databases for blast and bowtie mapping"
	exit 1
fi

if [ ! -d "$hostDB" ]
then
	echo "$hostDB \n defined in \n$CONFIGFILE not found. Please make sure to prepare your data for the analysis before executing pikaVirus.sh"
	echo "$hostDB must contain already processed databases for blast and bowtie mapping"
	exit 1
fi

# COPY CONFIGFILE TO ANALYSISDIR AND SET IT AS WORK DIRECTORY
/bin/cp -rf $CONFIGFILE ${analysisDir}/pikaVirus.config
cd $analysisDir

# GENERATE SAMPLE LIST
sh ${PIKAVIRUSDIR}/samplesID_gen.sh
awk 'a[$0]++{exit 1}' ${analysisDir}samples_id.txt ||
(echo "There are duplicated sample names in ${analysisDir}samples_id.txt" &&
echo "Please rename your files or modify the regular expression in ${PIKAVIRUSDIR}/samplesID_gen.sh to make it work with your samples" &&
exit 1)
samplesIdFile="${analysisDir}/samples_id.txt"

# QUALITY CONTROL
if [ $cluster == "yes" ]
then
	# TO-DO
	# in=$(awk "NR==$SGE_TASK_ID" $samplesIdFile)
	# bash ${PIKAVIRUSDIR}/preprocessing.sh -s $in
	echo "TO-DO: This option si not supported yet"
	exit 1
else
	cat ${analysisDir}/samples_id.txt | while read in
	do
		bash ${PIKAVIRUSDIR}/preprocessing.sh -s $in
	done
fi
#
/bin/cp -rf ${PIKAVIRUSDIR}/html/quality/template.html ${workingDir}ANALYSIS/99-stats/
perl ${PIKAVIRUSDIR}/html/quality/listFastQCReports.pl ${workingDir}ANALYSIS/99-stats/data/ > ${workingDir}ANALYSIS/99-stats/table.html
perl ${PIKAVIRUSDIR}/html/quality/createHTML.pl

# MAPPING
if [ $cluster == "yes" ]
then
	# TO-DO
	# in=$(awk "NR==$SGE_TASK_ID" $samplesIdFile)
	# bash ${PIKAVIRUSDIR}/host_removal.sh $in
	# bash ${PIKAVIRUSDIR}/mapper_bac.sh $in
	# bash ${PIKAVIRUSDIR}/mapper_virus.sh $in
	# bash ${PIKAVIRUSDIR}/mapper_fungi.sh $in
	# bash ${PIKAVIRUSDIR}/mapper_parasite.sh $in
	# bash ${PIKAVIRUSDIR}/mapper_unknown.sh $in
	echo "TO-DO: This option si not supported yet"
	exit 1
else
	cat ${analysisDir}/samples_id.txt | while read in
	do
		bash ${PIKAVIRUSDIR}/host_removal.sh $in
		bash ${PIKAVIRUSDIR}/mapper_bac.sh $in
		bash ${PIKAVIRUSDIR}/mapper_virus.sh $in
		bash ${PIKAVIRUSDIR}/mapper_fungi.sh $in
		bash ${PIKAVIRUSDIR}/mapper_parasite.sh $in
		bash ${PIKAVIRUSDIR}/mapper_unknown.sh $in
	done
fi

# ASSEMBLY
if [ $cluster == "yes" ]
then
	# TO-DO
	# in=$(awk "NR==$SGE_TASK_ID" $samplesIdFile)
	# bash ${PIKAVIRUSDIR}/assembly.sh $in
	echo "TO-DO: This option si not supported yet"
	exit 1
else
	cat ${analysisDir}/samples_id.txt | while read in
	do
		mappedDir="${analysisDir}/05-bacteria/${in}/reads/"
		bash ${PIKAVIRUSDIR}/assembly.sh $mappedDir
		mappedDir="${analysisDir}/06-virus/${in}/reads/"
		bash ${PIKAVIRUSDIR}/assembly.sh $mappedDir
		mappedDir="${analysisDir}/07-fungi/${in}/reads/"
		bash ${PIKAVIRUSDIR}/assembly.sh $mappedDir
		mappedDir="${analysisDir}/08-protozoa/${in}/reads/"
		bash ${PIKAVIRUSDIR}/assembly.sh $mappedDir
		mappedDir="${analysisDir}/09-invertebrate/${in}/reads/"
		bash ${PIKAVIRUSDIR}/assembly.sh $mappedDir
		mappedDir="${analysisDir}/10-unknown/${in}/reads/"
		bash ${PIKAVIRUSDIR}/assembly.sh $mappedDir
	done
fi

# BLAST
if [ $cluster == "yes" ]
then
	# TO-DO
	# in=$(awk "NR==$SGE_TASK_ID" $samplesIdFile)
	# bash ${PIKAVIRUSDIR}/blast.sh $in
	echo "TO-DO: This option si not supported yet"
	exit 1
else
	cat ${analysisDir}/samples_id.txt | while read in
	do
		sampleDir="${analysisDir}/05-bacteria/${in}/"
		bash ${PIKAVIRUSDIR}/blast.sh $sampleDir $bacDB
		sampleDir="${analysisDir}/06-virus/${in}/"
		bash ${PIKAVIRUSDIR}/blast.sh $sampleDir $virDB
		sampleDir="${analysisDir}/07-fungi/${in}/"
		bash ${PIKAVIRUSDIR}/blast.sh $sampleDir $fungiDB
		sampleDir="${analysisDir}/08-protozoa/${in}/"
		bash ${PIKAVIRUSDIR}/blast.sh $sampleDir $protozoaDB
		sampleDir="${analysisDir}/09-invertebrate/${in}/"
		bash ${PIKAVIRUSDIR}/blast.sh $sampleDir $invertebrateDB
		sampleDir="${analysisDir}/10-unknown/${in}/"
		bash ${PIKAVIRUSDIR}/blast.sh $sampleDir
	done
fi

# COVERAGE
if [ $cluster == "yes" ]
then
	# TO-DO
	# in=$(awk "NR==$SGE_TASK_ID" $samplesIdFile)
	# bash ${PIKAVIRUSDIR}/coverage.sh $in
	echo "TO-DO: This option si not supported yet"
	exit 1
else
	cat ${analysisDir}/samples_id.txt | while read in
	do
		sampleDir="${analysisDir}/05-bacteria/${in}/"
		sampleName=$(basename $sampleDir)
		bash ${PIKAVIRUSDIR}/coverage.sh $sampleDir $bacDB
		Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "${sampleDir}/coverage/" ${sampleName}
		sampleDir="${analysisDir}/06-virus/${in}/"
		sampleName=$(basename $sampleDir)
		bash ${PIKAVIRUSDIR}/coverage.sh $sampleDir $virDB
		Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "${sampleDir}/coverage/" ${sampleName}
		sampleDir="${analysisDir}/07-fungi/${in}/"
		sampleName=$(basename $sampleDir)
		bash ${PIKAVIRUSDIR}/coverage.sh $sampleDir $fungiDB
		Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "${sampleDir}/coverage/" ${sampleName}
		sampleDir="${analysisDir}/08-protozoa/${in}/"
		sampleName=$(basename $sampleDir)
		bash ${PIKAVIRUSDIR}/coverage.sh $sampleDir $protozoaDB
		Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "${sampleDir}/coverage/" ${sampleName}
		sampleDir="${analysisDir}/09-invertebrate/${in}/"
		sampleName=$(basename $sampleDir)
		bash ${PIKAVIRUSDIR}/coverage.sh $sampleDir $invertebrateDB
		Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "${sampleDir}/coverage/" ${sampleName}
	done
fi

# RESULTS
bash generate_results.sh


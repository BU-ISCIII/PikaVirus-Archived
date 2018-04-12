
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
sample_count="$( wc -l ${analysisDir}/samples_id.txt | cut -f1 -d' ')"

# QUALITY CONTROL
if [ $cluster == "yes" ]
then
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N preprocessing_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_preprocessing.txt" ]
	then
		echo "preprocessing_\$SGE_TASK_ID" > ${analysisDir}/jid_preprocessing.txt
	else
		echo ",preprocessing_\$SGE_TASK_ID" > ${analysisDir}/jid_preprocessing.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/preprocessing.sh -s \$INPUT
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
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
	while [ (! -f ${analysisDir}/jid_preprocessing.txt) || $( cat ${analysisDir}/jid_preprocessing.txt | sed -e 's/,/\n/g' | wc -l ) != $sample_count ]
	do
		sleep 1
	done
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N host_removal_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_mapping.txt" ]
	then
		echo "host_removal_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	else
		echo ",host_removal_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/host_removal.sh \$INPUT
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_preprocessing.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_bac_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_mapping.txt" ]
	then
		echo "mapper_bac_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	else
		echo ",mapper_bac_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_bac.sh \$INPUT
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_preprocessing.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_virus_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_mapping.txt" ]
	then
		echo "mapper_virus_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	else
		echo ",mapper_virus_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_virus.sh \$INPUT
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_preprocessing.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_fungi_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_mapping.txt" ]
	then
		echo "mapper_fungi_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	else
		echo ",mapper_fungi_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_fungi.sh \$INPUT
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_preprocessing.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_parasite_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_mapping.txt" ]
	then
		echo "mapper_parasite_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	else
		echo ",mapper_parasite_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_parasite.sh \$INPUT
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_preprocessing.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_unknown_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_mapping.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_mapping.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_unknown.sh \$INPUT
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_preprocessing.txt )  bash tmp.sh
	rm tmp.sh
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
	while [ (! -f ${analysisDir}/jid_mapping.txt) || $( cat ${analysisDir}/jid_mapping.txt | sed -e 's/,/\n/g' | wc -l ) != $sample_count*6 ]
	do
		sleep 1
	done
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_bac_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_assembly.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/05-bacteria/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_mapping.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_virus_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_assembly.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/06-virus/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_mapping.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_fungi_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_assembly.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/07-fungi/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_mapping.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_protozoa_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_assembly.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/08-protozoa/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_mapping.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_invertebrate_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_assembly.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/09-invertebrate/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_mapping.txt ) bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_unknown_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_assembly.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_assembly.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/10-unknown/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	$cluster_prefix -hold_jib $( cat ${analysisDir}/jid_mapping.txt ) bash tmp.sh
	rm tmp.sh
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
	while [ (! -f ${analysisDir}/jid_assembly.txt) || $( cat ${analysisDir}/jid_assembly.txt | sed -e 's/,/\n/g' | wc -l ) != $sample_count*6 ]
	do
		sleep 1
	done
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_bac_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_blast.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/05-bacteria/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $bacDB
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_virus_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_blast.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/06-virus/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $bacDB
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_fungi_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_blast.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/07-fungi/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $fungiDB
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_protozoa_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_blast.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/08-protozoa/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $protozoaDB
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_invertebrate_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_blast.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/09-invertebrate/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $invertebrateDB
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_unknown_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_blast.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_blast.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/10-unknown/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
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
	while [ (! -f ${analysisDir}/jid_blast.txt) || $( cat ${analysisDir}/jid_blast.txt | sed -e 's/,/\n/g' | wc -l ) != $sample_count*6 ]
	do
		sleep 1
	done
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_bac_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_coverage.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/05-bacteria/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $bacDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_virus_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_coverage.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/06-virus/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $bacDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_fungi_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_coverage.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/07-fungi/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $fungiDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_protozoa_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_coverage.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/08-protozoa/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $protozoaDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
	cat > tmp.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_invertebrate_\$SGE_TASK_ID
	#$ -t 1-$sample_count
	if [ ! -f "${analysisDir}/jid_coverage.txt" ]
	then
		echo "mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	else
		echo ",mapper_unknown_\$SGE_TASK_ID" > ${analysisDir}/jid_coverage.txt
	fi
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/09-invertebrate/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $invertebrateDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	$cluster_prefix bash tmp.sh
	rm tmp.sh
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
if [ $cluster == "yes" ]
then
	while [ (! -f ${analysisDir}/jid_coverage.txt) || $( cat ${analysisDir}/jid_coverage.txt | sed -e 's/,/\n/g' | wc -l ) != $sample_count*5 ]
	do
		sleep 1
	done
fi
bash generate_results.sh


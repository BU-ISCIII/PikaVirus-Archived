
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
	cat > cluster_preprocessing.sh <<- EndOfFile
	#!/bin/sh
	#$ -N preprocessing
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/preprocessing.sh \$INPUT
	EndOfFile
	output_qsub=$( $cluster_prefix bash cluster_preprocessing.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne "$jobid" > ${analysisDir}/jid_preprocessing.txt
	if [ ! -d "${workingDir}ANALYSIS/99-stats/data" ]
	then
		mkdir -p ${workingDir}ANALYSIS/99-stats/data
	fi
	cat > cluster_preprocessing_report.sh <<- EndOfFile
	#!/bin/sh
	#$ -N preprocessing_report
	/bin/cp -rf ${PIKAVIRUSDIR}/html/quality/template.html ${workingDir}ANALYSIS/99-stats/
	perl ${PIKAVIRUSDIR}/html/quality/listFastQCReports.pl ${workingDir}ANALYSIS/99-stats/data/ > ${workingDir}ANALYSIS/99-stats/table.html
	perl ${PIKAVIRUSDIR}/html/quality/createHTML.pl $workingDir stats
	EndOfFile
	$cluster_prefix hold_jid $( cat ${analysisDir}/jid_preprocessing.txt ) bash cluster_preprocessing_report.sh
else
	cat ${analysisDir}/samples_id.txt | while read in
	do
		bash ${PIKAVIRUSDIR}/preprocessing.sh $in
		if [ ! -d "${workingDir}ANALYSIS/99-stats/data" ]
		then
			mkdir -p ${workingDir}ANALYSIS/99-stats/data
		fi
		/bin/cp -rf ${PIKAVIRUSDIR}/html/quality/template.html ${workingDir}ANALYSIS/99-stats/
		perl ${PIKAVIRUSDIR}/html/quality/listFastQCReports.pl ${workingDir}ANALYSIS/99-stats/data/ > ${workingDir}ANALYSIS/99-stats/table.html
		perl ${PIKAVIRUSDIR}/html/quality/createHTML.pl $workingDir stats
	done
fi
#
# MAPPING
if [ $cluster == "yes" ]
then
	cat > cluster_host_removal.sh <<- EndOfFile
	#!/bin/sh
	#$ -N host_removal
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/host_removal.sh \$INPUT
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_preprocessing.txt ) bash cluster_host_removal.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne "$jobid" > ${analysisDir}/jid_host_removal.txt
	cat > cluster_mapper_bac.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_bac
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_bac.sh \$INPUT
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_host_removal.txt ) bash cluster_mapper_bac.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne "$jobid" > ${analysisDir}/jid_mapping.txt
	cat > cluster_mapper_virus.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_virus
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_virus.sh \$INPUT
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_host_removal.txt ) bash cluster_mapper_virus.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_mapping.txt
	cat > cluster_mapper_fungi.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_fungi
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_fungi.sh \$INPUT
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_host_removal.txt ) bash cluster_mapper_fungi.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_mapping.txt
	cat > cluster_mapper_parasite.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_parasite
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_parasite.sh \$INPUT
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_host_removal.txt ) bash cluster_mapper_parasite.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_mapping.txt
	cat > cluster_mapper_unknown.sh <<- EndOfFile
	#!/bin/sh
	#$ -N mapper_unknown
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	bash ${PIKAVIRUSDIR}/mapper_unknown.sh \$INPUT
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_mapping.txt ) bash cluster_mapper_unknown.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_mapping.txt
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
	cat > cluster_assembly_bac.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_bac
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/05-bacteria/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_mapping.txt ) bash cluster_assembly_bac.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne "$jobid" > ${analysisDir}/jid_assembly.txt
	cat > cluster_assembly_virus.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_virus
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/06-virus/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_mapping.txt ) bash cluster_assembly_virus.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_assembly.txt
	cat > cluster_assembly_fungi.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_fungi
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/07-fungi/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_mapping.txt ) bash cluster_assembly_fungi.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_assembly.txt
	cat > cluster_assembly_protozoa.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_protozoa
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/08-protozoa/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_mapping.txt ) bash cluster_assembly_protozoa.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_assembly.txt
	cat > cluster_assembly_invertebrate.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_invertebrate
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/09-invertebrate/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_mapping.txt ) bash cluster_assembly_invertebrate.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_assembly.txt
	cat > cluster_assembly_unknown.sh <<- EndOfFile
	#!/bin/sh
	#$ -N assembly_unknown
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	mappedDir="${analysisDir}/10-unknown/\${INPUT}/reads/"
	bash ${PIKAVIRUSDIR}/assembly.sh \$mappedDir
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_assembly.txt ) bash cluster_assembly_unknown.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_assembly.txt
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
	cat > cluster_blast_bac.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_bac
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/05-bacteria/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $bacDB
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_assembly.txt ) bash cluster_blast_bac.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne "$jobid" > ${analysisDir}/jid_blast.txt
	cat > cluster_blast_virus.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_virus
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/06-virus/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $bacDB
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_assembly.txt ) bash cluster_blast_virus.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_blast.txt
	cat > cluster_blast_fungi.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_fungi
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/07-fungi/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $fungiDB
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_assembly.txt ) bash cluster_blast_fungi.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_blast.txt
	cat > cluster_blast_protozoa.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_protozoa
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/08-protozoa/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $protozoaDB
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_assembly.txt ) bash cluster_blast_protozoa.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_blast.txt
	cat > cluster_blast_invertebrate.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_invertebrate
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/09-invertebrate/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir $invertebrateDB
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_assembly.txt ) bash cluster_blast_invertebrate.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_blast.txt
	cat > cluster_blast_unknown.sh <<- EndOfFile
	#!/bin/sh
	#$ -N blast_unknown
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/10-unknown/\${INPUT}/"
	bash ${PIKAVIRUSDIR}/blast.sh \$sampleDir
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_blast.txt ) bash cluster_blast_unknown.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_blast.txt
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
	cat > cluster_coverage_bac.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_bac
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/05-bacteria/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $bacDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_blast.txt ) bash cluster_coverage_bac.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne "$jobid" > ${analysisDir}/jid_coverage.txt
	cat > cluster_coverage_virus.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_virus
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/06-virus/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $bacDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_blast.txt ) bash cluster_coverage_virus.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_coverage.txt
	cat > cluster_coverage_fungi.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_fungi
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/07-fungi/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $fungiDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_blast.txt ) bash cluster_coverage_fungi.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_coverage.txt
	cat > cluster_coverage_protozoa.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_protozoa
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/08-protozoa/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $protozoaDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_blast.txt ) bash cluster_coverage_protozoa.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_coverage.txt
	cat > cluster_coverage_invertebrate.sh <<- EndOfFile
	#!/bin/sh
	#$ -N coverage_invertebrate
	#$ -t 1-$sample_count
	INPUTFILE=${analysisDir}/samples_id.txt
	INPUT=\$(awk "NR==\$SGE_TASK_ID" \$INPUTFILE)
	sampleDir="${analysisDir}/09-invertebrate/\${INPUT}/"
	sampleName=\$(basename \$sampleDir)
	bash ${PIKAVIRUSDIR}/coverage.sh \$sampleDir $invertebrateDB
	Rscript --vanilla "${PIKAVIRUSDIR}/graphs_coverage.R" "\${sampleDir}/coverage/" \${sampleName}
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_blast.txt ) bash cluster_coverage_invertebrate.sh )
	jobid=$( echo $output_qsub | cut -d ' ' -f3 | cut -d '.' -f1 )
	echo -ne ",$jobid" >> ${analysisDir}/jid_coverage.txt
	# Create summary tables
	cat > summary_tables.sh <<- EndOfFile
	#!/bin/sh
	#$ -N summary_tables
	for file in "$analysisDir/*/${in}/*_BLASTn_filtered.blast"
	do
		perl ${PIKAVIRUSDIR}/summary_tables.pl $file
	done
	EndOfFile
	output_qsub=$( $cluster_prefix -hold_jid $( cat ${analysisDir}/jid_coverage.txt ) bash summary_tables.sh )
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
		for file in "$analysisDir/*/${in}/blast/*_BLASTn_filtered.blast"
		do
			perl ${PIKAVIRUSDIR}/summary_tables.pl $file
		done
	done
fi

# RESULTS
if [ $cluster == "yes" ]
then
	$cluster_prefix -hold_jid $( cat ${analysisDir}/jid_coverage.txt ) bash ${PIKAVIRUSDIR}/generate_results.sh
else
	bash ${PIKAVIRUSDIR}/generate_results.sh
fi

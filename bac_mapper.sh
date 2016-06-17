echo -e "##################################################################"
echo -e "############################LOL-SEQ###############################"
echo -e "##################################################################"
echo -e "$(date)\t Begin filtering of bacteria reads"

#virus_seq_dir Directory to save virus related sequences to.
#noHostFilesDir is the directory where the host filtering files are saved (sam for mapping and fastq for host free samples)
#hostDB is the .fa file with the reference genome for the mapping. Must be adjacent to the bowtie index files. 

bacDB="REFERENCES/GreenGenes_16S/16S"
noHostFilesDir="ANALYSIS/HOST_REMOVAL/"
bacRelatedDir="ANALYSIS/BAC_RELATED/"

for sampleDir in $(ls -d ${noHostFilesDir}*/)
do  
	#VARIABLES
	sampleName=$(basename "$sampleDir")
	mappedSamFile="${noHostFilesDir}${sampleName}/${sampleName}_Mapped.sam"
	noHostFileFastq="${noHostFilesDir}${sampleName}/${sampleName}_NoHost.fastq"
    bowtie2logFile="${bacRelatedDir}${sampleName}/${sampleName}_log"
    bacRelatedFileSam="${bacRelatedDir}${sampleName}/${sampleName}_bac_Mapped.sam"
	bacFileFastq="${bacRelatedDir}${sampleName}/${sampleName}_bac.fastq"
	FilteredGI="${bacRelatedDir}${sampleName}/${sampleName}_bac_GI.fastq"
	#FilteredFasta="${bacRelatedDir}${sampleName}/${sampleName}_bac_mapped_seq.fasta"
	#FilteredFastq="${bacRelatedDir}${sampleName}/${sampleName}_bac_mapped_seq.fastq"

	echo -e "*********** PROCESSING $sampleName ************"

	#CREATE DIRECTORIES FOR EACH SAMPLE IF NECESSARY
	if [ ! -d "$bacRelatedDir$sampleName" ]
	then
		mkdir "$bacRelatedDir$sampleName"
		echo -e "$bacRelatedDir$sampleName created"
	fi
	
	#BOWTIE2 MAPPING AGAINST BACTERIA DB
	echo -e "--------Bowtie2 is mapping against the bacteria 16S references....------"
	echo -e "$(date) $sampleName" > $bowtie2logFile
	echo -e "The command is: ### bowtie2 -x $bacDB -r $noHostFileFastq -S $bacRelatedFileSam -q ###" >> $bowtie2logFile 
	bowtie2 -x $bacDB -r $noHostFileFastq -S $bacRelatedFileSam -q >> $bowtie2logFile 2>&1 | tee -a $bowtie2logFile
	echo -e "$(date) $sampleName" >> $bowtie2logFile
	
	#FILTERING BACTERIA READS
	echo -e "-----------------Mapping reads...---------------------"
	#	All reads mapping against reference
	egrep -v "^@" $bacRelatedFileSam | awk '{if($3 != "*") print}' > $bacFileFastq
	#	BacRelatedReads=`egrep -v "^@" $bacRelatedFileSam | awk '{if($3 != "*") print$1}' | uniq | wc -l | awk '{print$1}'` 
	#	Filtered GI of mapped reads
	#awk {'print $3'} ${bacFileFastq} | sort -u > $FilteredGI
    # Get ID of mapped read and retrieve its fastq entry
    #grep -F -f $FilteredGI $virusFileFastq > $FilteredFastq
    #	Generate fasta with mapped reads
	#awk {'printf ">%s\t%s\t%s\n%s\n", $1, $3, $2, $10'} ${bacFileFastq} > $FilteredFasta
done

echo -e "*********** FINISHED MAPPING ***********"
echo -e "$(date)"
echo -e "##################################################################"
echo -e "############################LOL-SEQ###############################"
echo -e "##################################################################"

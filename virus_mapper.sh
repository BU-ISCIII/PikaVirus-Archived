echo -e "##################################################################"
echo -e "############################LOL-SEQ###############################"
echo -e "##################################################################"
echo -e "********************** MAPPING VIRUS READS ***********************"

#virus_seq_dir Directory to save virus related sequences to.
#noHostFilesDir is the directory where the host filtering files are saved (sam for mapping and fastq for host free samples)
#hostDB is the .fa file with the reference genome for the mapping. Must be adjacent to the bowtie index files. 

virusDB="REFERENCES/Viral_2.1_Genomic/all.fna.tar.gz"
noHostFilesDir="ANALYSIS/HOST_REMOVAL/"
virusRelatedDir="ANALYSIS/VIRUS_RELATED/"

for sampleDir in $(ls -d ${noHostFilesDir}*/)
do  
	#VARIABLES
	sampleName=$(basename "$sampleDir")
	mappedSamFile="${noHostFilesDir}${sampleName}/${sampleName}_Mapped.sam"
	noHostFileFastq="${noHostFilesDir}${sampleName}/${sampleName}_NoHost.fastq"
    bowtie2logFile="${virusRelatedDir}${sampleName}/${sampleName}_log"
    virusRelatedFileSam="${virusRelatedDir}${sampleName}/${sampleName}_Virus_Mapped.sam"
	virusFileFastq="${virusRelatedDir}${sampleName}/${sampleName}_Virus.fastq"
	FilteredGI="${virusRelatedDir}${sampleName}/${sampleName}_vir_GI.fastq"
	#FilteredFasta="${virusRelatedDir}${sampleName}/${sampleName}_vir_mapped_seq.fasta"
	#FilteredFastq="${virusRelatedDir}${sampleName}/${sampleName}_vir_mapped_seq.fastq"
    

	echo -e "$(date)"
	echo -e "***********PROCESSING $sampleName ************"

	#CREATE DIRECTORIES FOR EACH SAMPLE IF NECESSARY
	if [ ! -d "$virusRelatedDir$sampleName" ]
	then
		mkdir "$virusRelatedDir$sampleName"
		echo -e "$virusRelatedDir$sampleName created"
	fi
	
	#BOWTIE2 MAPPING AGAINST VIRUS DB
	echo -e "--------Bowtie2 is mapping against the virus reference genomes....------"
	echo -e "$(date) $sampleName" > $bowtie2logFile
	echo -e "The command is: ### bowtie2 -x $virusDB -r $noHostFileFastq -S $virusRelatedFileSam -q ###" >> $bowtie2logFile 
	bowtie2 -x $virusDB -r $noHostFileFastq -S $virusRelatedFileSam -q >> $bowtie2logFile 2>&1 | tee -a $bowtie2logFile
	echo -e "$(date) $sampleName" >> $bowtie2logFile
	
	#FILTERING VIRUS READS
	echo -e "-----------------Mapping reads...---------------------"
	egrep -v "^@" $virusRelatedFileSam | awk '{if($3 != "*") print}' > $virusFileFastq
	#VirusRelatedReads=`egrep -v "^@" $virusRelatedFileSam | awk '{if($3 != "*") print$1}' | uniq | wc -l | awk '{print$1}'` 
	#	Filtered GI of mapped reads
	#awk {'print $3'} ${virusFileFastq} | sort -u > $FilteredGI
    # Get ID of mapped reads and retrieve its fastq entry
    #grep -F -f $FilteredGI $virusFileFastq > $FilteredFastq
    #	Generate fasta of mapped reads
	#awk {'printf ">%s\t%s\t%s\n%s\n", $1, $3, $2, $10'} ${virusFileFastq} > $FilteredFasta

done

echo -e "$(date)"
echo -e "***************** FINISHED MAPPING VIRUS READS *******************"
echo -e "##################################################################"
echo -e "############################LOL-SEQ###############################"
echo -e "##################################################################"

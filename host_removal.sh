echo -e "##################################################################"
echo -e "############################LOL-SEQ###############################"
echo -e "##################################################################"
echo -e "$(date)\t Begin filtering of host reads"

#All the fastq files for preprocessed forward and reverse strands must be inside a folder with the sample name.
#preprocessedFilesDir is the directory containing these folders.
#noHostFilesDir is the directory where the host filtering files will we saved (sam for mapping and fastq for host free samples)
#hostDB is the .fa file with the reference genome for the mapping. Must be adjacent to the bowtie index files. 

hostDB="REFERENCES/hg38.AnalysisSet/hg38.AnalysisSet"
preprocessedFilesDir="ANALYSIS/PREPROCESSING/TRIMMOMATIC/"
noHostFilesDir="ANALYSIS/HOST_REMOVAL/"

for sampleDir in $(ls -d ${preprocessedFilesDir}*/)
do  
	#VARIABLES
	sampleName=$(basename "$sampleDir")
	sampleForward="${sampleDir}${sampleName}_output_forward_paired.fastq"
	sampleReverse="${sampleDir}${sampleName}_output_reverse_paired.fastq"
	mappedSamFile="${noHostFilesDir}${sampleName}/${sampleName}_Mapped.sam"
	noHostFileFastq="${noHostFilesDir}${sampleName}/${sampleName}_NoHost.fastq"
    bowtie2logFile="${noHostFilesDir}${sampleName}/${sampleName}_log"

	echo -e "$(date)\t ***********PROCESSING $sampleName ************"

	#CREATE DIRECTORIES FOR EACH SAMPLE IF NECESSARY
	echo -e "----------------------Creating directory...----------------------"
	if (! ls -d "ANALYSIS/HOST_REMOVAL/$sampleName")
	then
		mkdir "ANALYSIS/HOST_REMOVAL/$sampleName"
		echo -e "ANALYSIS/HOST_REMOVAL/$sampleName created"
	fi
	
	#BOWTIE2 MAPPING AGAINST HUMAN
	echo -e "--------Bowtie2 is mapping against the reference genome....------"
	echo -e "$(date) $sampleName" > $bowtie2logFile
	echo -e "The command is: ###bowtie2 -fr -x "$hostDB" -q -1 $sampleForward -2 $sampleReverse -S $mappedSamFile###" >> $bowtie2logFile 
	bowtie2 -fr -x "$hostDB" -q -1 $sampleForward -2 $sampleReverse -S $mappedSamFile 2>&1 | tee -a $bowtie2logFile
	echo -e "$(date) $sampleName" >> $bowtie2logFile
	
	#FILTERING NON-HUMAN READS
	echo -e "-----------------Filtering non-host reads...---------------------"
	egrep -v "^@" $mappedSamFile | awk '{if($3 == "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $noHostFileFastq
	HostRelatedReads=`egrep -v "^@" $mappedSamFile | awk '{if($3 != "*") print$1}' | uniq | wc -l | awk '{print$1}'` 
done

echo -e "$(date)\t Finished filtering of host reads"
echo -e "##################################################################"
echo -e "############################LOL-SEQ###############################"
echo -e "##################################################################"

#########################################################
#	SCRIPT TO REMOVE HOST READS USING BOWTIE2 MAPPING	#
#########################################################
# Arguments:
# $1 = hostDB. File with the reference genome for the mapping. Must be adjacent to the bowtie index files.
# $2 = sampleName. Name of the sample to be processed. Must match the name of the sample in the RAW directory.
# 1. Creates necessary directories. 
# 2. Maps against host reference genome.
# 3. Creates a .fastq file using the sam file created by bowtie2 containing only those reads which don't match the host
# Output files: (In ANALYSIS/sampleName/02.HOST/)
# sampleName_Mapped.sam: SAM file from mapping the processed files against the reference genome.
# sampleName_NoHost.fastq: .fastq file created from the unmapped reads of the SAM file.
# sampleName_lablog.log: .log file with a log of the mapping.

function removeHost {
#	GET ARGUMENTS
hostDB=$1  
sampleAnalysisDir=$2
#	INITIALIZE VARIABLES
sampleName=$(basename "${sampleAnalysisDir}")
preprocessedFilesDir="${sampleAnalysisDir}/01.PREPROCESSING/TRIMMOMATIC/" # directory where the preprocessed files are.
noHostFilesDir="${sampleAnalysisDir}/02.HOST/" #directory where the host filtering files will we saved (sam for mapping and fastq for host free samples)
sampleForward="${preprocessedFilesDir}${sampleName}_output_forward_paired.fastq"
sampleReverse="${preprocessedFilesDir}${sampleName}_output_reverse_paired.fastq"
mappedSamFile="${noHostFilesDir}${sampleName}_Mapped.sam"
#noHostFileFastq="${noHostFilesDir}${sampleName}_NoHost.fastq"
bowtie2logFile="${noHostFilesDir}${sampleName}_lablog.log"
mappedForwardFastq="${noHostFilesDir}${sampleName}_noHost_forward.fastq"
mappedReverseFastq="${noHostFilesDir}${sampleName}_noHost_reverse.fastq"
echo -e "$(date)" 
echo -e "*********** REMOVING HOST FROM $sampleName ************"

#	CREATE DIRECTORY FOR THE SAMPLE IF NECESSARY
if [ ! -d ${noHostFilesDir} ]
then
	mkdir -p $noHostFilesDir
	echo -e "${noHostFilesDir} created"
fi
	
#	BOWTIE2 MAPPING AGAINST HUMAN
echo -e "--------Bowtie2 is mapping against the reference genome....------"
echo -e "$(date)\t Start mapping ${sampleName}\n" > $bowtie2logFile
echo -e "The command is: ### bowtie2 -fr -x "$hostDB" -q -1 $sampleForward -2 $sampleReverse -S $mappedSamFile ###\n" >> $bowtie2logFile 
bowtie2 -fr -x "$hostDB" -q -1 $sampleForward -2 $sampleReverse -S $mappedSamFile 2>&1 | tee -a $bowtie2logFile
echo -e "$(date)\t Finished mapping ${sampleName}\n" >> $bowtie2logFile

#	SEPARATE FORWARD AND REVERSE MAPPED READS AND FILTER HOST
echo -e "-----------------Filtering non-host reads...---------------------"
echo -e "$(date)\t Start filtering ${sampleName}\n" > $bowtie2logFile
echo -e "The command is: ###samtools view -F 0x40 $mappedSamFile | awk '{if($3 == '*') print '@'$1'\\n'$10'\\n''+'$1'\\n'$11}' > $mappedForwardFastq"
samtools view -F 0x40 $mappedSamFile | awk '{if($3 == "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $mappedForwardFastq
samtools view -f 0x40 $mappedSamFile | awk '{if($3 == "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $mappedReverseFastq
#	samtools separates forward (-F) or reverse (-f) reads using the mapped SAM file and awk filters those not mapped (="*") in fastq format
echo -e "$(date)\t Finished filtering ${sampleName}\n" > $bowtie2logFile

#	FILTERING NON-HUMAN READS
#egrep -v "^@" $mappedSamFile | awk '{if($3 == "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $noHostFileFastq
#HostRelatedReads=`egrep -v "^@" $mappedSamFile | awk '{if($3 != "*") print$1}' | uniq | wc -l | awk '{print$1}'` 
}

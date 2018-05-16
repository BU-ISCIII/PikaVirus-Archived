#!/bin/bash
set -e

source ./pikaVirus.config

#	GET ARGUMENTS
sampleDir=$1

#	INITIALIZE VARIABLES
#	VARIABLES
sampleName=$(basename "${sampleDir}")
sampleAnalysisDir="${analysisDir}/02-preprocessing/${sampleName}/"
sampleAnalysisLog="${sampleAnalysisDir}/${sampleName}_lablog.log"
#		Constants
unknownFilesDir="${analysisDir}/10-unknown/${sampleName}/reads/" #directory where the unknown reads will we saved.
virFilesDir="${analysisDir}/06-virus/${sampleName}/reads/" #directory where the mapped reads are.
bacWGDB="${bacDB}WG/bwt2/WG"
fungiWGDB="${fungiDB}WG/bwt2/fungi_all"
invertebrateWGDB="${invertebrateDB}/WG/bwt2/invertebrate_all"
protozoaWGDB="${protozoaDB}/WG/bwt2/protozoa_all"
threads=10
#		Input Files
virusBamFile="${virFilesDir}${sampleName}_virus_sorted.bam" #bowtie bam file with the reads that mapped against the WG reference
#		OutputFiles
unknownLogFile="${unknownFilesDir}${sampleName}_unknown_mapping.log"
notMappedR1Fastq="${unknownFilesDir}${sampleName}_unknown.fastq"
notMappedSamFile="${unknownFilesDir}${sampleName}_unknown_mapped.sam"
notMappedBamFile="${unknownFilesDir}${sampleName}_unknown_mapped.bam" #bowtie bam file with the reads that mapped against the WG reference
sortedBamFile="${unknownFilesDir}${sampleName}_unknown_sorted.bam" #bowtie bam file with the reads that mapped against the WG reference

#	MAPPING UNKNOWN
echo -e "$(date): ************* Start unknown mapping ***************" >> "${sampleAnalysisLog}"
echo -e " Execute mapper_unknown.sh $sampleDir" >> "${sampleAnalysisLog}"
echo -e "$(date)"
echo -e "*********** MAPPING UNKNOWN IN $sampleName ************"

#	CREATE DIRECTORY FOR THE SAMPLE IF NECESSARY
if [ ! -d ${unknownFilesDir} ]
then
	mkdir -p $unknownFilesDir
	echo -e "${unknownFilesDir} created"
fi

#	SEPARATE R1 AND R2 UNMAPPED VIRUS READS
echo -e "----------------- Filtering virus reads ...---------------------" > $unknownLogFile
echo -e "$(date)\t Start filtering ${sampleName}\n" >> $unknownLogFile
echo -e "The command is: ###samtools view -F 0x40 $virusBamFile | awk '{if($3 == '*'') print "@"$1"\n"$10"\n""+""\n"$11}' > $notMappedR1Fastq" >> $unknownLogFile
samtools view $virusBamFile | awk '{if($3 == "*") print "@" $1" \n" $10 "\n" "+" $1 "\n" $11}' > $notMappedR1Fastq
#	samtools separates R1 (-F) or R2 (-f) reads using the mapped BAM file and awk filters those that DIDN'T map (=="*") in fastq format
echo -e "$(date)\t Finished filtering virus ${sampleName}\n" >> $unknownLogFile
#--------------------------------------------------------------------------------------------------------------------------------------------
#	MAP UNKOWN READS WITH BACTERIA DB
echo -e "--------Bowtie2 is mapping against bacteria WG reference ....------" >> $unknownLogFile
echo -e "$(date)\t Start mapping ${sampleName} reads to bacteria WG reference \n" >> $unknownLogFile
echo -e "The command is: ### bowtie2 -p $threads -x $bacWGDB -q $notMappedR1Fastq -S $notMappedSamFile ###\n" >> $unknownLogFile
bowtie2 -p $threads -x $bacWGDB -q $notMappedR1Fastq -S $notMappedSamFile 2>&1 | tee -a $unknownLogFile
echo -e "$(date)\t Finished mapping ${sampleName} reads to bacteria WG reference \n" >> $unknownLogFile
echo -e "$(date)\t Converting reads not mapped to bacteria from SAM to BAM of ${sampleName} \n" >> $unknownLogFile
samtools view -Sb $notMappedSamFile > $notMappedBamFile
rm $notMappedSamFile
samtools sort -O bam -T temp -o $sortedBamFile $notMappedBamFile
samtools index -b $sortedBamFile
rm $notMappedBamFile
echo -e "$(date)\t Finished converting reads not mapped to bacteria from SAM to BAM of ${sampleName} \n" >> $unknownLogFile

#	SEPARATE AND EXTRACT R1 AND R2 READS NOT MAPPED TO BACTERIA
echo -e "----------------- Filtering bacteria reads that mapped to bacteria WG reference ...---------------------" >> $unknownLogFile
echo -e "$(date)\t Start filtering ${sampleName} reads that mapped to bacteria WG \n" >> $unknownLogFile
echo -e "The command is: ###samtools view -F 0x40 $sortedBamFile | awk '{if($3 == '*') print '@' $1 '\\n' $10 '\\n' '+' '\\n' $11}' > $notMappedR1Fastq" >> $unknownLogFile
samtools view $sortedBamFile | awk '{if($3 == "*") print "@" $1 "\n" $10 "\n" "+" $1 "\n" $11}' > $notMappedR1Fastq
#	samtools separates R1 (-F) or R2 (-f) reads using the mapped SAM file and awk filters those mapped (!="*") in fastq format
echo -e "$(date)\t Finished filtering ${sampleName} reads that mapped to bacteria WG reference \n" >> $unknownLogFile

#--------------------------------------------------------------------------------------------------------------------------------------------
#	MAP UNKOWN READS WITH FUNGI DB
echo -e "--------Bowtie2 is mapping against fungi WG reference ....------" >> $unknownLogFile
echo -e "$(date)\t Start mapping ${sampleName} reads to fungi WG reference \n" >> $unknownLogFile
echo -e "The command is: ### bowtie2 -p $threads -x $fungiWGDB -q $notMappedR1Fastq -S $notMappedSamFile ###\n" >> $unknownLogFile
bowtie2 -p $threads -x $fungiWGDB -q $notMappedR1Fastq -S $notMappedSamFile 2>&1 | tee -a $unknownLogFile
echo -e "$(date)\t Finished mapping ${sampleName} reads to fungi WG reference \n" >> $unknownLogFile
echo -e "$(date)\t Converting reads not mapped to fungi from SAM to BAM of ${sampleName} \n" >> $unknownLogFile
samtools view -Sb $notMappedSamFile > $notMappedBamFile
rm $notMappedSamFile
samtools sort -O bam -T temp -o $sortedBamFile $notMappedBamFile
samtools index -b $sortedBamFile
rm $notMappedBamFile
echo -e "$(date)\t Finished converting reads not mapped to fungi from SAM to BAM of ${sampleName} \n" >> $unknownLogFile

#	SEPARATE AND EXTRACT R1 AND R2 READS NOT MAPPED TO FUNGI
echo -e "----------------- Filtering fungi reads that mapped to fungi WG reference ...---------------------" >> $unknownLogFile
echo -e "$(date)\t Start filtering ${sampleName} reads that mapped to fungi WG \n" >> $unknownLogFile
echo -e "The command is: ###samtools view -F 0x40 $sortedBamFile | awk '{if($3 == '*') print '@' $1 '\\n' $10 '\\n' '+' '\\n' $11}' > $notMappedR1Fastq" >> $unknownLogFile
samtools view $sortedBamFile | awk '{if($3 == "*") print "@" $1 "\n" $10 "\n" "+" $1 "\n" $11}' > $notMappedR1Fastq
#	samtools separates R1 (-F) or R2 (-f) reads using the mapped SAM file and awk filters those mapped (!="*") in fastq format
echo -e "$(date)\t Finished filtering ${sampleName} reads that mapped to fungi WG reference \n" >> $unknownLogFile

#--------------------------------------------------------------------------------------------------------------------------------------------
#	MAP UNKOWN READS WITH PROTOZOA DB
echo -e "--------Bowtie2 is mapping against protozoa WG reference ....------" >> $unknownLogFile
echo -e "$(date)\t Start mapping ${sampleName} reads to protozoa WG reference \n" >> $unknownLogFile
echo -e "The command is: ### bowtie2 -p $threads -x $protozoaWGDB -q $notMappedR1Fastq -S $notMappedSamFile ###\n" >> $unknownLogFile
bowtie2 -p $threads -x $protozoaWGDB -q $notMappedR1Fastq -S $notMappedSamFile 2>&1 | tee -a $unknownLogFile
echo -e "$(date)\t Finished mapping ${sampleName} reads to protozoa WG reference \n" >> $unknownLogFile
echo -e "$(date)\t Converting reads not mapped to protozoa from SAM to BAM of ${sampleName} \n" >> $unknownLogFile
samtools view -Sb $notMappedSamFile > $notMappedBamFile
rm $notMappedSamFile
samtools sort -O bam -T temp -o $sortedBamFile $notMappedBamFile
samtools index -b $sortedBamFile
rm $notMappedBamFile
echo -e "$(date)\t Finished converting reads not mapped to protozoa from SAM to BAM of ${sampleName} \n" >> $unknownLogFile

#	SEPARATE AND EXTRACT R1 AND R2 READS NOT MAPPED TO FUNGI
echo -e "----------------- Filtering protozoa reads that mapped to protozoa WG reference ...---------------------" >> $unknownLogFile
echo -e "$(date)\t Start filtering ${sampleName} reads that mapped to protozoa WG \n" >> $unknownLogFile
echo -e "The command is: ###samtools view -F 0x40 $sortedBamFile | awk '{if($3 == '*') print '@' $1 '\\n' $10 '\\n' '+' '\\n' $11}' > $notMappedR1Fastq" >> $unknownLogFile
samtools view $sortedBamFile | awk '{if($3 == "*") print "@" $1 "\n" $10 "\n" "+" $1 "\n" $11}' > $notMappedR1Fastq
#	samtools separates R1 (-F) or R2 (-f) reads using the mapped SAM file and awk filters those mapped (!="*") in fastq format
echo -e "$(date)\t Finished filtering ${sampleName} reads that mapped to protozoa WG reference \n" >> $unknownLogFile

#--------------------------------------------------------------------------------------------------------------------------------------------
#	MAP UNKOWN READS WITH INVERTEBRATE DB
echo -e "--------Bowtie2 is mapping against invertebrate WG reference ....------" >> $unknownLogFile
echo -e "$(date)\t Start mapping ${sampleName} reads to invertebrate WG reference \n" >> $unknownLogFile
echo -e "The command is: ### bowtie2 -p $threads -x $invertebrateWGD -q -1 $notMappedR1Fastq -S $notMappedSamFile ###\n" >> $unknownLogFile
bowtie2 -p $threads -x $invertebrateWGDB -q $notMappedR1Fastq -S $notMappedSamFile 2>&1 | tee -a $unknownLogFile
echo -e "$(date)\t Finished mapping ${sampleName} reads to invertebrate WG reference \n" >> $unknownLogFile
echo -e "$(date)\t Converting reads not mapped to invertebrate from SAM to BAM of ${sampleName} \n" >> $unknownLogFile
samtools view -Sb $notMappedSamFile > $notMappedBamFile
rm $notMappedSamFile
samtools sort -O bam -T temp -o $sortedBamFile $notMappedBamFile
samtools index -b $sortedBamFile
rm $notMappedBamFile
echo -e "$(date)\t Finished converting reads not mapped to invertebrate from SAM to BAM of ${sampleName} \n" >> $unknownLogFile

#	SEPARATE AND EXTRACT R1 AND R2 READS NOT MAPPED
echo -e "----------------- Filtering invertebrate reads that mapped to invertebrate WG reference ...---------------------" >> $unknownLogFile
echo -e "$(date)\t Start filtering ${sampleName} reads that mapped to invertebrate WG \n" >> $unknownLogFile
echo -e "The command is: ###samtools view -F 0x40 $sortedBamFile | awk '{if($3 == '*') print '@' $1 '\\n' $10 '\\n' '+' '\\n' $11}' > $notMappedR1Fastq" >> $unknownLogFile
samtools view $sortedBamFile | awk '{if($3 == "*") print "@" $1 "\n" $10 "\n" "+" $1 "\n" $11}' > $notMappedR1Fastq
#	samtools separates R1 (-F) or R2 (-f) reads using the mapped SAM file and awk filters those mapped (!="*") in fastq format
echo -e "$(date)\t Finished filtering ${sampleName} reads that mapped to invertebrate WG reference \n" >> $unknownLogFile


echo -e "$(date): ************ Finished unknown mapping ************" >> "${sampleAnalysisLog}"

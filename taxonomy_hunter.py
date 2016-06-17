# First all mapped gi are captured and filtered so there are no duplicates.


DirToFilter='ANALYSIS/VIRUS_RELATED/'
for sampleDir in $(ls -d ${DirToFilter}*/)
do  	
	#VARIABLES
  	sampleName=$(basename "$sampleDir")
  	XRelatedFastq="${DirToFilter}${sampleName}/${sampleName}_*.fastq"
  	SampleGi="${DirToFilter}${sampleName}/${sampleName}_GI.gi"

  	echo -e "$(date)" 
  	echo -e "***********PROCESSING $sampleName ************"

	#FILTER FASTQ FILES
	echo -e "----------------------Filtering ${XRelatedFastq}...----------------------"
	awk {'print $3'} ${XRelatedFastq} | sort -u > SampleGi
done  	

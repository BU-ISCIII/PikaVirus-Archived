#!/bin/bash
set -e

#########################################################
#	SCRIPT TO CREATE HTML REPORT OF THE SAMPLE RESULTS	#
#########################################################
# 1. Creates necessary directories. 
# 2. Generates html with the merged table.
# Note: This script should only be run after running mergeResults.R. 

# Arguments:
# $1 (sampleDir) = Directory of the organism analysis of the sample. (ANALYSIS/xx-organism/sampleName/)

# Input Files: (In RESULTS/data/)
# sampleName_organism_results.txt: File generated with mergeResults.R

# Output files: (In RESULTS/data/)
# sampleName_organism_results.html: html file of the merged results table.

source ./pikaVirus.config
# - resultsDir

#	GET PARAMETERS
sampleDir=$1  #/analysisDir/xx-organism/sampleName/

#	INITIALIZE VARIABLES
genomeId=""
coverageFile=""
#		CONSTANTS
sampleName=$(basename $sampleDir) # (sampleName)
workingDir="$(echo $sampleDir | rev | cut -d'/' -f5- | rev)/" # (workingDir) 
organismDir=$(echo $sampleDir | rev | cut -d'/' -f3 | rev) # (xx-organism)
organism="${organismDir##*-}" # (organism)
#		INPUT FILES
sampleResult="${resultsDir}/data/persamples/${sampleName}_${organism}_results.txt"
#		OUTPUT FILES
result_page="${resultsDir}/data/persamples/${sampleName}_${organism}_results.html"

if [ -e $sampleResult ]
then
	echo "
	<html>
		<head>
	   		<title>" > $result_page
	   		 echo "$sampleName ${organism} results" >> $result_page
	   		 echo "
	   		</title>
	   		<link rel='stylesheet' type='text/css' href='../../css/table.css'>
	   	 	<meta content=''>
		</head>
		<body>
			<table>
				<thead>
			   		<tr>
			   		    <th>" >> $result_page
					    echo "${sampleName} ${organism} result" >> $result_page
					    echo "</th>
					    <!--<th>Subject Title</th>-->
						<th>Reference Id</th>
						<th>Reference name</th>
						<th>Contig Id</th>
						<th>% of identical matches</th>
						<th>Alignment length</th>
						<th>Number of mismatches</th>
						<th>Number of gap openings</th>
						<th>Start of alignment in query</th>
						<th>End of alignment in query</th>
						<th>Start of alignment in subject</th>
						<th>End of alignment in subject</th>
						<th>Expect value</th>
						<th>Bit score</th>
						<th>Coverage mean</th>
						<th>Minimum coverage</th>
						<th>Coverage SD</th>
						<th>Coverage median</th>
						<th>x1-x4 depth</th>
						<th>x5-x9 depth</th>
						<th>x10-x19 depth</th>
						<th>=>20 depth</th>
						<th>Total coverage</th>
						<th>Coverage graph</th>
					</tr>
				</thead>
				<tbody>" >> $result_page
					#	Start formatting data 
					while IFS='' read -r line || [[ -n $line ]]
					do
						echo "
					<tr>" >> $result_page
						IFS='	' read -r -a array <<< "$line"
						#organism="${organismDir##*-}" # (organism)
						echo "<th>"$(echo ${array[1]//\"/} | cut -f1 -d',')"</th>">> $result_page
						#for value in "${array[@]:1:12}"
						for (( i = 0; i < ${#array[@]}; i++))
						do
							echo "<td>${array[$i]//\"/}</td>" >> $result_page
						done
						# conseguir el genome id
						genomeId=${array[0]//\"/}
						coverageFile="${sampleDir}coverage/${genomeId}_coverage_graph.pdf"
						echo "<td><a target='_blank' href='$coverageFile'>${genomeId}</a></td>" >> $result_page
						echo "</tr>" >> $result_page
				done < ${sampleResult}
			echo "</tbody>
			</table>
			<script src='http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js'></script>
			<script src='http://cdnjs.cloudflare.com/ajax/libs/jquery-throttle-debounce/1.1/jquery.ba-throttle-debounce.min.js'></script>
			<script src='../../js/jquery.stickyheader.js'></script>
		</body>
	</html>" >> $result_page
else
    echo "
    <html>
    	<head>
    		<title>"${sampleName}" "${organism}" results</title>
    	   		<link rel='stylesheet' type='text/css' href='../../css/table.css'>
    	   		<meta content=''>
    	</head>
    	<body>
    	   	<p>Sorry, we couldn't identify "${organism}" in the sample "${sampleName}".</p>
    	</body>
    </html>" > $result_page
fi 










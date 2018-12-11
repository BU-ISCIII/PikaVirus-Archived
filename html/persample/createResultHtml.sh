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

# - resultsDir

#	GET PARAMETERS
sampleName=$1
organism=$2
#	INITIALIZE VARIABLES
genomeId=""
coverageFile=""
org="$( echo $organism | cut -c1-3 )"
#		INPUT FILES
sampleResult="${resultsDir}/results/data/persamples/${sampleName}_${organism}_results.txt"
#		OUTPUT FILES
result_page="${resultsDir}/results/data/persamples/${sampleName}_${organism}_results.html"

if [[ -s $sampleResult ]]
then
	echo "
	<div id=\"${sampleName}-${org}-div\" class=\"col-md-11 targetdivs\" style=\"display: none\">
	  <div class=\"table-responsive\">
			<table class=\"table table-hover\">
				<thead>
			   		<tr>
			   		    <th>" > $result_page
					    echo "${sampleName} ${organism} result" >> $result_page
					    echo "</th>
					    <!--<th>Subject Title</th>-->
						<th>Reference Id</th>
						<th>Reference name</th>
						<th>Covered genome fraction</th>
						<th>Genome length</th>
						<th>Frequency</th>
						<th>Contig length mean</th>
						<th>Contig length min</th>
						<th>Contig length median</th>
						<th>Contig length max</th>
						<th>Coverage mean</th>
						<th>Coverage SD</th>
						<th>x1-x4 depth</th>
						<th>x5-x9 depth</th>
						<th>x10-x19 depth</th>
						<th>=>20 depth</th>
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
						coverageFile="${resultsDir}/results/coverage_graphs/${sampleName}_${organism}_${genomeId}_coverage_graph.pdf"
						if [[ -s $coverageFile ]]
						then
							echo "<td><a target='_blank' href='$coverageFile'>${genomeId}</a></td>" >> $result_page
						else
							echo "<td>-</td>" >> $result_page
						fi
						echo "</tr>" >> $result_page
				done < ${sampleResult}
			echo "</tbody>
			</table>
		 </div>
	</div>
		" >> $result_page
else
    echo "
    <div id=\"${sampleName}-${org}-div\" class=\"col-md-11 targetdivs\" style=\"display: none\">
	   	<p>Sorry, we couldn't identify "${organism}" in the sample "${sampleName}".</p>
    </div>
	" > $result_page
fi 










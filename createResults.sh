set -e
#	GET PARAMETERS
sampleDir=$1

#	INITIALIZE VARIABLES
sampleName=$(basename $sampleDir)
rootDir=$(dirname $(dirname $sampleDir))
blastnResult="${sampleDir}08.BLAST/VIRUS/${sampleName}_BLASTn.blast"
blastxResult="${sampleDir}08.BLAST/VIRUS/${sampleName}_BLASTx.blast"
resultPage="${rootDir}/RESULTS/${sampleName}/blast.html"

echo "
<html>
	<head>
   		<title>" > $resultPage
   		 echo "$sampleName blast" >> $resultPage
   		 echo "
   		</title>
   		<link rel='stylesheet' type='text/css' href='style.css'>
   	 	<meta content=''>
	</head>
	<body>
		<table class='flatTable'>
	   		<tr class='titleTr'>
				<td class='titleTd'> " >> $resultPage
				echo "${sampleName} blast result" >> $resultPage
				echo "				
				</td>
				<td colspan='4'></td>
				<td class='plusTd button'></td>
			</tr>
			<!-- <tr class='headingTr'> -->
			<thead class='headingTr'>
				<td>Subject Title</td>
				<td>Query Seq-id</td>
				<td>Reference Id</td>
				<td>Percentage of identical matches</td>
				<td>Alignment length</td>
				<td>Number of mismatches</td>
				<td>Number of gap openings</td>
				<td>Start of alignment in query</td>
				<td>End of alignment in query</td>
				<td>Start of alignment in subject</td>
				<td>End of alignment in subject</td>
				<td>Expect value</td>
				<td>Bit score</td>
				<td></td>
			</thead>" >> $resultPage
			#	Start formatting data from blast
			while IFS='' read -r line || [[ -n $line ]]
			do
				echo "
			<tr>" >> $resultPage
				IFS='	' read -r -a array <<< "$line"
				for value in "${array[@]}"
				do
					echo "<td>${value}</td>" >> $resultPage
				done
				echo "
      		</tr>
      		<!--
				<td class='controlTd'>
	  				<div class='settingsIcons'>
	    				<span class='settingsIcon'><img src='http://i.imgur.com/nnzONel.png' alt='X' /></span>
	    				<span class='settingsIcon'><img src='http://i.imgur.com/UAdSFIg.png' alt='placeholder icon' /></span>
	    				<div class='settingsIcon'><img src='http://i.imgur.com/UAdSFIg.png' alt='placeholder icon' /></div>
	  				</div>  
				</td>
			-->
      		</tr>" >> $resultPage
		done < ${blastnResult}
			echo "
		</table>
	</body>
</html>" >> $resultPage

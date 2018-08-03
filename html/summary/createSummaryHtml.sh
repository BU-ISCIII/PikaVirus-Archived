#!/bin/bash
set -e

#########################################################
#	SCRIPT TO CREATE HTML PAGE WITH THE SAMPLE LIST		#
#########################################################
# 1. Gets the list of samples
# 2. Creates the sample list
# Note: This script should only be run after the analysis is finished.

# Arguments:
# $1 (workingDir) = Directory of the analysis.

# Input Files: (In workingDir)
# samples_id.txt: File generated with samplesID_gen.sh

# Output files: (In RESULTS/)
# results.html: html file of with the sample list.

# - analysisDir
# - resultsDir

#	GET PARAMETERS
summaryDir="${resultsDir}/results/data/summary/"
#		INPUT FILES
samplesId="${resultsDir}/samples_id.txt"
#		OUTPUT FILES
result_page="${resultsDir}/results/summary.html"

#	CONSTANTS
organisms=("bacteria" "virus" "fungi")

cat ${PIKAVIRUSDIR}/html/header.html > $result_page

echo "
<nav class=\"navbar navbar-inverse\" data-spy=\"affix\" data-offset-top=\"137\">
  <ul class=\"nav navbar-nav\">
    <li class=\"active\"><a href=\"summary.html\"><img class=\"icon-bar\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/clipboard.png' img> Summary</a></li>
    <li><a href=\"samples.html\"><img class=\"icon-bar\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/test-tube.png' img> Results per sample</a></li>
    <li><a href=\"quality.html\"><img class=\"icon-bar\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/dna-structure.png' img> Quality Analysis</a></li>
    <li><a href=\"info.html\"><img class=\"icon-bar\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/book.png' img> What is this?</a></li>
  </ul>
</nav>

<div class=\"container-fluid\">
  <br>
  <div class=\"col-md-1 panel panel-default\">
    <nav id=\"samples\" class=\"nav nav-pills\">
" >> $result_page

cat $samplesId | while read in
do
    echo "<li id=\"${in}\" data-target=\"${in}\"><a href=\"#\">${in}</a></li>" >> $result_page
done

echo "
    </nav>
  </div>
  <script type=\"text/javascript\">
    window.onload = function() {
" >> $result_page

fields=""
while read in
do
	fields="$fields #${in}-bac, #${in}-vir, #${in}-fun,"
done < <( cat $samplesId )
fields=${fields%,}

for file in $summaryDir/*_statistics.txt
do
	analysis=$( basename "$file" )
    analysis=${analysis%_statistics.txt}
    organism=${analysis#*_}
    name=$organism
    name="$(tr '[:lower:]' '[:upper:]' <<< ${name:0:1})${name:1}"
    organism=$( echo $organism | cut -c1-3 )
    sample=${analysis%_*}

    if [[ ! -s $file ]]
    then
        echo "
          var ${sample}${organism} = {
          exportEnabled: true,
          animationEnabled: true,
          title:{
            text: \"$name\"
          },
          subtitles:[
          {
            text : \"No Data available\",
            verticalAlign : \"center\"
          }
          ],
      data: [
      {
       type: \"pie\",
       dataPoints: null
       }
      ]
        };
        \$(\"#${sample}-${organism}\").CanvasJSChart(${sample}${organism});
        " >> $result_page
    else
        echo "
          var ${sample}${organism} = {
          exportEnabled: true,
          animationEnabled: true,
          title:{
            text: \"$name\"
          },
          data: [{
            type: \"pie\",
            toolTipContent: \"<b>{name}</b>: {y} (#percent%)\",
            indexLabel: \"#percent%\",
            legendText: \"{name} (#percent%)\",
            indexLabelPlacement: \"inside\",
            dataPoints: [
        " >> $result_page
        cat $file | perl -pe 's/^\ +//' | perl -pe 's/\ +$//' | perl -pe 's/\ \ +/\ /g' | perl -pe 's/^(\d+)\ (.*)$/\{ y: $1, name: \"$2\" \},/' | sed '$ s/.$//' >> $result_page
        echo "
                ]
          }]
        };
        \$(\"#${sample}-${organism}\").CanvasJSChart(${sample}${organism});
        " >> $result_page
    fi
done

echo "
    }
  </script>
" >> $result_page

cat $samplesId | while read in
do
    echo "
  <div id=\"${in}-div\" class=\"col-md-11 targetdivs\" style=\"display: none\">
    <div class=\"row\" style=\"height: 450px\">
      <div class=\"col-md-4 panel panel-default\" style=\"height: 450px\">
        <br>
        <div id=\"${in}-bac\" style=\"height: 100%; width: 100%;\"></div>
      </div>
      <div class=\"col-md-4 panel panel-default\" style=\"height: 450px\">
        <br>
        <div id=\"${in}-vir\" style=\"height: 100%; width: 100%;\"></div>
      </div>
      <div class=\"col-md-4 panel panel-default\" style=\"height: 450px\">
        <br>
        <div id=\"${in}-fun\" style=\"height: 100%; width: 100%;\"></div>
      </div>
    </div>
  </div>
    " >> $result_page
done

fields=""
while read in
do
	fields="$fields #${in},"
done < <( cat $samplesId )
fields=${fields%,}

echo "
  <script>
  \$(\"$fields\").on(\"click\", function(e){
    e.preventDefault();
    var target = \$(this).data(\"target\");
    \$(\".targetdivs\").css(\"display\", \"none\");
    \$(\"#\"+target+\"-div\").css(\"display\", \"block\");
    \$(\"$fields\").removeClass(\"active\");
    \$(this).addClass(\"active\");
  });//click
  </script>
</div>
" >> $result_page

cat ${PIKAVIRUSDIR}/html/footer.html >> $result_page

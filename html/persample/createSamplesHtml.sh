#!/bin/bash
set -e

#########################################################
#	SCRIPT TO CREATE HTML PAGE WITH THE SAMPLE LIST		#
#########################################################
#	GET PARAMETERS
#		INPUT FILES
samplesId="${resultsDir}/samples_id.txt"
#		OUTPUT FILES
result_page="${resultsDir}/results/samples.html"


cat ${PIKAVIRUSDIR}/html/header.html > $result_page

echo "
<nav class=\"navbar navbar-inverse\" data-spy=\"affix\" data-offset-top=\"137\">
  <ul class=\"nav navbar-nav\">
    <li><a href=\"summary.html\"><img class=\"icon-bar\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/clipboard.png' img> Summary</a></li>
    <li class=\"active\"><a href=\"samples.html\"><img class=\"icon-bar\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/test-tube.png' img> Results per sample</a></li>
    <li><a href=\"quality.html\"><img class=\"icon-bar\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/dna-structure.png' img> Quality Analysis</a></li>
    <li><a href=\"info.html\"><img class=\"icon-bar\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/book.png' img> What is this?</a></li>
  </ul>
</nav>

<div class=\"container-fluid\">
  <br>
  <div class=\"col-md-1 panel panel-default\">
    <nav class=\"nav nav-pills\">
" >> $result_page

cat $samplesId | while read in
do
	echo "
	<li id=\"$in\" class=\"dropdown\"><a class=\"dropdown-toggle\" data-toggle=\"dropdown\" href=\"#\">$in</a>
        <ul class=\"dropdown-menu\">
          <li id=\"${in}-bac\" data-target=\"${in}-bac\"><a href=\"#\"><img class=\"icon\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/bacteria.png' img>  Bacteria</a></li>
          <li id=\"${in}-vir\" data-target=\"${in}-vir\"><a href=\"#\"><img class=\"icon\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/virus1.png' img>  Virus</a></li>
          <li id=\"${in}-fun\" data-target=\"${in}-fun\"><a href=\"#\"><img class=\"icon\" src='https://raw.githubusercontent.com/BU-ISCIII/PikaVirus/feature/nextflow/html/img/fungi.png' img>  Fungi</a></li>
        </ul>
      </li>
	" >> $result_page
done

echo "
    </nav>
  </div>
" >> $result_page

for table in ${resultsDir}/results/data/persamples/*_results.html
do
	cat $table >> $result_page
done

fields=""
while read in
do
	fields="$fields #${in}-bac, #${in}-vir, #${in}-fun,"
done < <( cat $samplesId )
fields=${fields%,}

echo "
  <script>
  \$(\"$fields\").on(\"click\", function(e){
    e.preventDefault();
    var target = \$(this).data(\"target\");
    \$(\".targetdivs\").css(\"display\", \"none\");
    \$(\"#\"+target+\"-div\").css(\"display\", \"block\");
    \$(\"$fields\").parent().parent().removeClass(\"active\");
    \$(\"#\"+target).parent().parent().addClass(\"active\");
  });//click
  </script>
</div>
" >> $result_page

cat ${PIKAVIRUSDIR}/html/footer.html >> $result_page

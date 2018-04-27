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

source ./pikaVirus.config
# - analysisDir
# - resultsDir

#	GET PARAMETERS
#		INPUT FILES
samplesId="${analysisDir}/samples_id.txt"
#		OUTPUT FILES
result_page="${resultsDir}/samples.html"


echo "
<!DOCTYPE html>
<html lang='en' class='no-js'>
	<head>
		<meta charset='UTF-8' />
		<meta http-equiv='X-UA-Compatible' content='IE=edge'>
		<meta name='viewport' content='width=device-width, initial-scale=1'>
		<title>Metagenomic Analysis</title>
		<meta name='description' content='Metagenomic Analysis: Results report' />
		<meta name='keywords' content='metagenetics, metagenomics, ISCIII, bioinformatics' />
		<meta name='author' content='ISCIII Bioinformatics unit' />
		<link rel='stylesheet' type='text/css' href='css/shared.css' />
		<link rel='stylesheet' type='text/css' href='css/normalize.css' />
		<link rel='stylesheet' type='text/css' href='css/samples.css' />
		<!-- JQuery -->
		<script src='js/jquery-3.1.0.js'></script>
		<!--Thrid party-->
		<script type='text/javascript' src='js/google-loader.js'></script>
		<!--custom-->
		<script src='js/main-nav.js'></script>
		<script src='js/samples.js'></script>
	</head>
	<body>
		<div class='container'>
			<!-- Top Navigation -->
			<header class='report-header'>
				<div>
					<h1>Metagenomic Analysis
					<span>Results report</span>
					<p class='support'>This browser doen't support<strong>flexbox</strong>! <br />To correctly view this report, please use an <strong>updated browser</strong>.</p>
				</div>
				<div class='socialMedia'>
					<!--<span>Find us at: </span>//-->
					<a href='https://www.facebook.com/pages/Escuela-Nacional-de-Sanidad-Isciii/203300096355772?fref=ts' target='_blank'><img class = 'social' src='img/facebook.png' alt='Facebook'></a>
 					<!--<a href='https://es.linkedin.com/' target='_blank'><img class = 'social' src='img/linkedin.png' alt='Linkedin'></a>//-->
					<a href='https://twitter.com/BUISCIII' target='_blank'><img class = 'social' src='img/twitter.png' alt='Twitter'></a>
					<a href='https://github.com/BU-ISCIII/PikaVirus' target='_blank'><img class = 'social' src='img/github.png' alt='GitHub'></a>
 					<!--<a href='https://bitbucket.org/bioinfo_isciii/' target='_blank'><img class = 'social' src='img/bitbucket.png' alt='BitBucket'></a>//-->
				</div>
				</h1>
			</header>
			<div id='contenido'>
				<div class='tabs tabs-style-bar'>
					<nav>
						<ul id = 'horizontal-nav'>
							<li><a href='summary.html' class='icon icon-home'><span>Summary</span></a></li>
							<li class='tab-current'><a href='samples.html' class='icon icon-display'><span>Per Sample</span></a></li>
							<li><a href='quality.html' class='icon icon-upload'><span>Quality analysis</span></a></li>
							<li><a href='info.html' class='icon icon-book'><span>What is this?</span></a></li>
						</ul>
					</nav>
				</div><!-- /tabs -->

				<div id = 'pagina' class='content-wrap'>
					<div class='items vertical-nav'>
					<nav>
						<ul>" > $result_page

#	Start formatting data
cat $samplesId | while read in
do
	#  awk -v sample=${in} 'BEGIN {printf "%-9s\n",
	#  "<li><a class='\''icon menu'\'' href='\''#sample'\''><span>'${in}'</span></a>",
	#  	"<ul class='\''submenu'\''>",
	#  		"<li><a href='\''#sample'\''><span>Bacteria</span></a></li>",
	#  		"<li><a href='\''#sample'\''><span>Virus</span></a></li>",
	#  		"<li><a href='\''#sample'\''><span>Fungi</span></a></li>",
	#  		"<li><a href='\''#sample'\''><span>Protozoa</span></a></li>",
	#  		"<li><a href='\''#sample'\''><span>Invertebrate</span></a></li>",
	#  	"</ul>",
	#  "</li>"}' >> $result_page

	echo "
	<li><a class='icon menu' href='#""" >> $result_page
	echo $in >> $result_page
	echo "'><span>">> $result_page
	echo $in >> $result_page
	echo "</span></a>
	<ul class='submenu'>
	<li><a class='icon-bacteria' href='#${in}'><span>Bacteria</span></a></li>
	<li><a class='icon-virus' href='#${in}'><span>Virus</span></a></li>
	<li><a class='icon-fungi' href='#${in}'><span>Fungi</span></a></li>
	<li><a class='icon-protozoo' href='#${in}'><span>Protozoa</span></a></li>
	<li><a class='icon-invertebrate' href='#${in}'><span>Invertebrate</span></a></li>
	</ul>
	</li>" >> $result_page
done

echo "					</ul>
					</nav>
					</div>
					<object class='results' type='text/html' data=''></object>
					</div>
				</div><!-- /tabs -->
			<footer class='web-footer'>
				<div>
				<span>
					This report is for reference Use Only. It has not been approved, cleared, or licensed by any regulatory authority.
					The user acknowledges no intended medical purpose or objective such as clinical
					diagnosis, patient management, or human clinical trials.
				</span>
			</div>
		</footer>
		</div>
	</body>
</html>" >> $result_page

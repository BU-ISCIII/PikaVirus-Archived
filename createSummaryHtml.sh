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
#workingDir=$1  #
summaryDir="${resultsDir}data/summary/"
#		INPUT FILES
samplesId="${analysisDir}samples_id.txt"
#		OUTPUT FILES
result_page="${resultsDir}summary.html"

#	CONSTANTS
organisms=("bacteria" "virus" "fungi" "protozoa" "invertebrate")

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
		<link rel='stylesheet' type='text/css' href='css/summary.css' />
		<!-- JQuery -->
		<script src='js/jquery-3.1.0.js'></script>
		<!--Thrid party-->
	    <script type='text/javascript' src='js/google-loader.js'></script>
		<!--custom-->
		<script src='js/main-nav.js'></script>
		<script src='js/summary.js'></script>

	</head>
	<body>
		<div class='container'>
			<!-- Top Navigation -->
			<header class='report-header'>
				<div>
					<h1>Metagenomic Analysis
					<span>Results report</span>
					<p class='support'>This browser doesn't support<strong>flexbox</strong>! <br />To correctly view this report, please use an <strong>updated browser</strong>.</p>
				</div>
				<div class='socialMedia'>
					<!--<span>Find us at: </span>-->				
					<a href='https://www.facebook.com/pages/Escuela-Nacional-de-Sanidad-Isciii/203300096355772?fref=ts' target='_blank'><img class = 'social' src='img/facebook.png' alt='Facebook'></a>				
					<a href='https://es.linkedin.com/in/andrea-rubio-ponce-55a34562' target='_blank'><img class = 'social' src='img/linkedin.png' alt='Linkedin'></a>
					<a href='https://twitter.com/isciii_es' target='_blank'><img class = 'social' src='img/twitter.png' alt='Twitter'></a>
					<a href='https://github.com/AndreaRP/METAGENOMICS' target='_blank'><img class = 'social' src='img/github.png' alt='GitHub'></a>
					<a href='https://bitbucket.org/bioinfo_isciii/' target='_blank'><img class = 'social' src='img/bitbucket.png' alt='BitBucket'></a>
				</div>
				</h1>
			</header>
			<div id='contenido'>
				<div class='tabs tabs-style-bar'>
					<nav>
						<ul id = 'horizontal-nav'>
							<li class='tab-current'><a href='summary.html' class='icon icon-home'><span>Summary</span></a></li>
							<li><a href='samples.html' class='icon icon-display'><span>Per Sample</span></a></li>
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
					 echo "
					 <li><a class='icon menu' href='#""" >> $result_page
					 echo $in >> $result_page
					 echo "'><span onclick='load_summary(this.innerText)'>">> $result_page
					 echo $in >> $result_page
					 echo "</span></a>    
					 </li>" >> $result_page
				done
				echo "</ul>
					</nav>
					</div>
						<div style='display:none' class='results'>">> $result_page							         
							cat $samplesId | while read line
							do 
                            # read summary files 
                            	echo "<div class='" >> $result_page 
								echo $line >> $result_page
								echo "'>" >> $result_page
								for organism in "${organisms[@]}"
								do
									
                            		echo "<div class='${organism}'><span>" >> $result_page
                                		cat "${summaryDir}${line}_${organism}_statistics.txt">> $result_page
                            		echo "</span></div>" >> $result_page
                            	done
                            	echo "</div>" >> $result_page
                            done
                            echo "
						</div>
						<div class='charts'>" >> $result_page
						for organism in "${organisms[@]}"
						do
                    		echo "<div id='${organism}'></div>" >> $result_page
                        done
						echo "</div>
					</div>
				</div><!-- /tabs -->
			<footer class='web-footer'>
				<div>
				<span>
					Icons made by
					<a href='http://www.flaticon.com/authors/freepik' title='Freepik'>Freepik</a>, <a href='http://www.flaticon.com/authors/pixel-buddha' title='Pixel Buddha'>Pixel Buddha</a> and <a href='http://www.flaticon.com/authors/dave-gandy' title='Dave Gandy'>Dave Gandy</a> 
					from <a href='http://www.flaticon.com' title='Flaticon'>www.flaticon.com</a>. Licensed by <a href='http://creativecommons.org/licenses/by/3.0/' title='Creative Commons BY 3.0' target='_blank'>CC 3.0 BY</a>
				</span>
			</div>
		</footer>
		</div>
	</body>
</html>" >> $result_page

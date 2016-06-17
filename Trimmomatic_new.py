#!/bin/bash
# -*- coding: utf-8 -*-
#This code generates the necessary script to run trimmomatic automatically on several fastq files for several samples.
#The samples must follow the following directory structure:
#Data/Sample1/File1.fastq is the forward file for sample 1
#Data/Sample1/File2.fastq is the reverse file for sample 1
#Data/Sample2/File1.fastq is the forward file for sample 2
#Data/Sample2/File2.fastq is the reverse file for sample 2
#...
#and so on. The path the script uses as dataPath would be the path to 'Data' in the above example.
#Future modifications: get variables (outputDir and dataPath) and options for trimmomatic from config file. Decide where to save script. 

import sys, getopt
import re
import os

def main(argv):
	inputDir =''
	try:
		opts, args = getopt.getopt(argv,"hi:",["help", "ifile="])
	except getopt.GetoptError:
		print 'Trimmomatic.py -i <inputDirectory>'
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print 'Trimmomatic.py -i <inputDirectory>'
			sys.exit()
		elif opt in ("-i", "--ifile"):
			inputDir = arg
    	else:
    		print 'holi'
    #	Nombre del Dataset:
	dataSet = os.path.basename(inputDir)    
    #	Lugar donde se genera el output (output de trimmomatic y donde se guarda el script)
	outputDir ='./ANALYSIS/' + dataSet + '/01.PREPROCESSING/TRIMMOMATIC/'
	#	si no existe el direcorio, se crea
	if ! os.path.exists(outputDir):
		os.mkdirs(outputDir)
    #	Lugar donde se genera el script
	script = open(outputDir + 'trimmomatic.sh','w')
	input_forward = ''
	input_reverse = ''
	#	cambiamos al directorio de las muestras
	os.chdir(inputDir)
	#	Sacar archivo forward y archivo reverse
	for files in os.listdir('.'):
		if files.endswith('_1.fastq'):
			input_forward = dataSet + '_' + files
		if files.endswith('_2.fastq'):
			input_reverse = dataSet + '_' + files
    #	generar el script con las rutas correctas
	script.write('java -jar /opt/Trimmomatic/trimmomatic-0.33.jar PE ' + input_forward + ' ' + input_reverse + ' ' +
	outputDir + '_' + sample + '_output_forward_paired.fastq ' + 
	outputDir + '_' + sample + '_output_forward_unpaired.fastq ' + 
	outputDir + '_' + sample + '_output_reverse_paired.fastq ' + 
	outputDir + '_' + sample + '_output_reverse_unpaired.fastq ' +
	'ILLUMINACLIP:/opt/Trimmomatic/adapters/TruSeq3-PE.fa:2:30:10 SLIDINGWINDOW:4:20 MINLEN:70 \n')
	script.close()

if __name__== "__main__":
	main(sys.argv[1:])


#!/usr/bin/python
# -*- coding: utf-8 -*-
#This code generates the necessary script to run trimmomatic automatically on several fastq files for several dataSets.
#The dataSets must follow the following directory structure:
#Data/dataSet1/File1.fastq is the R1 file for dataSet 1
#Data/dataSet1/File2.fastq is the R2 file for dataSet 1
#Data/dataSet2/File1.fastq is the R1 file for dataSet 2
#Data/dataSet2/File2.fastq is the R2 file for dataSet 2
#...
#and so on. The path the script uses as dataPath would be the path to 'Data' in the above example.
#Future modifications: get variables (outputDir and dataPath) and options for trimmomatic from config file. Decide where to save script. 

import sys, getopt
import re
import os
import commands

def main(argv):
	inputDir =''
	outputDir = ''
	dataSet= ''
	try:
		opts, args = getopt.getopt(argv,"hi:o:n:",["help", "ifile=", "ofile=","sname="])
	except getopt.GetoptError:
		print 'Trimmomatic.py -i <inputDirectory> -o <outputDirectory> -n <sampleName>'
		sys.exc_info()[0]
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print 'Trimmomatic.py -i <inputDirectory> -o <outputDirectory> -n <sampleName>'
			sys.exit()
		elif opt in ("-i", "--ifile"):
			inputDir = arg
		elif opt in ("-o", "--ofile"):
			outputDir = arg
		elif opt in ("-n", "--sname"):
			dataSet = arg
    	else:
    		print 'Done'
    #	Nombre del Dataset:
   	# dataSet = os.system("basename "+ inputDir)
   	#dataSet = commands.getstatusoutput("basename" + inputDir)
	#print 'dataSet '+ dataSet
    #	Lugar donde se genera el output (output de trimmomatic y donde se guarda el script)
	#	si no existe el direcorio, se crea
	if not os.path.exists(outputDir):
		os.makedirs(outputDir)
    #	Lugar donde se genera el script
	script = open(outputDir + 'trimmomatic.sh','w')
	input_R1 = ''
	input_R2 = ''
	#	cambiamos al directorio de las muestras
	os.chdir(inputDir)
	#	Sacar archivo R1 y archivo R2
	for files in os.listdir('.'):
		if files.endswith('_1.fastq'):
			#input_R1 = dataSet + '/' + files
			input_R1 =  os.path.abspath(files)
		if files.endswith('_2.fastq'):
			#input_R2 = dataSet + '/' + files
			input_R2 =  os.path.abspath(files)
    #	generar el script con las rutas correctas
	script.write('java -jar /opt/Trimmomatic/trimmomatic-0.33.jar PE ' + input_R1 + ' ' + input_R2 + ' ' +
	outputDir + dataSet + '_output_R1_paired.fastq ' + 
	outputDir + dataSet + '_output_R1_unpaired.fastq ' + 
	outputDir + dataSet + '_output_R2_paired.fastq ' + 
	outputDir + dataSet + '_output_R2_unpaired.fastq ' +
	'ILLUMINACLIP:/opt/Trimmomatic/adapters/TruSeq3-PE.fa:2:30:10 SLIDINGWINDOW:4:20 MINLEN:70 \n')
	script.close()

if __name__== "__main__":
	main(sys.argv[1:])


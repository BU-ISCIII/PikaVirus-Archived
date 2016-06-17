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
#Future modifications: get variables (savePath and dataPath) and options for trimmomatic from config file. Decide where to save script. 

import re
import os
savePath = '/home/arubio/Documents/20160530_METAGENOMICS_AR_IC_T/ANALYSIS/PREPROCESSING/TRIMMOMATIC/' 
dataPath = '/home/arubio/Documents/20160530_METAGENOMICS_AR_IC_T/RAW'
script = open('./trimmomatic.sh','w')
input_forward = ''
input_reverse = ''
os.chdir(dataPath)
for r,d,f in os.walk('.'):
    for dirs in d:
	for files in os.listdir(dirs):	  	  
	  if files.endswith('1.fastq'):
	    input_forward = dirs +'/'+ files
	  if files.endswith('2.fastq'):
	    input_reverse = dirs +'/'+ files
	script.write('java -jar /opt/Trimmomatic/trimmomatic-0.33.jar PE ' + input_forward + ' ' + input_reverse + ' ' +
	savePath + dirs + '_output_forward_paired.fastq ' + 
	savePath + dirs + '_output_forward_unpaired.fastq ' + 
	savePath + dirs + '_output_reverse_paired.fastq ' + 
	savePath + dirs + '_output_reverse_unpaired.fastq ' +
	'ILLUMINACLIP:/opt/Trimmomatic/adapters/TruSeq3-PE.fa:2:30:10 SLIDINGWINDOW:4:20 MINLEN:70 \n')
script.close()	        

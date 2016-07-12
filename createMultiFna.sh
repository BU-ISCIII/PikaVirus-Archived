set -e

file_patern="/processing_Data/bioinformatics/research/20160530_METAGENOMICS_AR_IC_T/REFERENCES/FUNGI_GENOME_REFERENCE/ensembl/*/dna/*dna.toplevel.fa.gz"
multifasta="/processing_Data/bioinformatics/research/20160530_METAGENOMICS_AR_IC_T/REFERENCES/FUNGI_GENOME_REFERENCE/WG/fungi_all.fna"


#hopt -s globstar

#echo $file_patern
for f in $file_patern
do 
	#get sp name
	spName=$(echo $f | rev | cut -d'/' -f3 | rev) # gets the species name (3d column from the end of the mapped dir)	
	zcat "$f" | sed "s/>/>$spName|/g"
done > $multifasta

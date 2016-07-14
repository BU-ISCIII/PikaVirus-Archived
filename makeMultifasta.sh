set -e

#	ARGUMENTS:
#	$1 = regular expression of file
#	$2 = destination file

for file in $1
do 
   zcat $file >> $2
done

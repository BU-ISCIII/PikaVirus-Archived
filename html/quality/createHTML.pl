#!/usr/bin/perl -w

$workingDir=$ARGV[0];

open (TABLE,"$workingDir/RESULTS/quality/table.html") or die "$!";

while(<TABLE>){
	$line=$_;
	chomp($line);
	$table.=$line;
}

close TABLE;

# open (TABLE2,"table2.html") or die "$!";
#
# while(<TABLE2>) {
# 	$line=$_;
# 	chomp($line);
# 	$table2.=$line;
# }
#
# close TABLE2;

open (IN,"$workingDir/RESULTS/quality/template.html") or die "$!";
open (OUT,">$workingDir/RESULTS/quality/report.html") or die "$!";

while(<IN>){
	$line=$_;
	$line=~s/##FILTER##/$table/;
# 	$line=~s/##ALIGN##/$table2/;
	print OUT $line;
}

close IN;
close OUT;

exit;

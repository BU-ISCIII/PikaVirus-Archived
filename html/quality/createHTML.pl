#!/usr/bin/perl -w

$Dir=$ARGV[0];

if ($ARGV[1] eq "stats"){
	$Dir.="/ANALYSIS/99-stats/"
} else {
	$Dir.="/RESULTS/quality/"
}

open (TABLE,"$Dir/table.html") or die "$!";

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

open (IN,"$Dir/template.html") or die "$!";
open (OUT,">$Dir/report.html") or die "$!";

while(<IN>){
	$line=$_;
	$line=~s/##FILTER##/$table/;
# 	$line=~s/##ALIGN##/$table2/;
	print OUT $line;
}

close IN;
close OUT;

exit;

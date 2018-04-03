#!/usr/bin/perl -w 

open (TABLE,"table.html");

while(<TABLE>){
	$line=$_;
	chomp($line);
	$table.=$line;
}

close TABLE;

open (TABLE2,"table2.html");

while(<TABLE2>) {
	$line=$_;
	chomp($line);
	$table2.=$line;
}

close TABLE2;

open (IN,"template.html");
open (OUT,">report.html");

while(<IN>){
	$line=$_;
	$line=~s/##FILTER##/$table/;
	$line=~s/##ALIGN##/$table2/;
	print OUT $line;
}

close IN;
close OUT;

exit;

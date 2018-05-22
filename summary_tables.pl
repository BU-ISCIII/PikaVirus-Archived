#!/usr/bin/perl -w
use strict;

## Take blasn_filtered output and transform it into a table showing name, score, length of contig and percentage of contig mapped, keeping only score and percentaje of mapping > 90%

if(scalar @ARGV < 1){die "We need at least 1 file as argument\n";}

    foreach my $file (@ARGV){

	my $coveragefile = $file;
	$coveragefile =~ s/_BLASTn_filtered.blast/_coverageTable.txt/;
	$coveragefile =~ s/blast/coverage/;

    my $outfile = $file;
    $outfile =~ s/_filtered.blast/_summary.tsv/;
    $outfile =~ s/ANALYSIS\/0\d-(\w+)\/.*\/blast\//RESULTS\/summary_tables\/$1-/;

	#Get the path portion only, without the filename.
	my $outfile_path = $outfile;
	if ($outfile_path =~ /^(.*)\/[\w|\d|\-]+_summary.tsv$/){
	    if (-e $1) {
	    	print "Directory exists.\n";
		} else {
	    	mkdir $1 or die "Error creating directory: $1";
	    }
	} else {
		die "Invalid path name: $outfile_path";
	}

    open(INFILE, $file) or die "$!";
    open(COVERAGE, $coveragefile) or die "$!";
    open(OUTFILE, ">$outfile") or die "$!";

    print OUTFILE "Genome\tBlastScore\tContigLength\tContig%Mapped\tContigName\tcovMean\tcovMin\tcovSD\tcovMedian\tx1-x4\tx5-x9\tx10-x19\t>x20\ttotal\n";

	my %coverage;
	while (my $line = <COVERAGE>){
		chomp $line;
		$line =~ s/"//g;
		my @items = split("\t", $line);

		$coverage{$items[0]} = $line;
	}

    while (my $line = <INFILE>){
        chomp $line;
        my @items = split("\t", $line);

        my $genome = $items[0];
        my $contig = $items[2];
        my $blast_score = $items[3];
        my $contig_length = $items[1];
        $contig_length =~ s/.*_length_(\d+)_cov_.*/$1/;
        my $contig_percentage = $items[4];
        $contig_percentage = $contig_percentage / $contig_length * 10000;
        $contig_percentage = int($contig_percentage) / 100;

        if($contig_percentage > 90){
            print OUTFILE "$genome\t$blast_score\t$contig_length\t$contig_percentage\t$coverage{$contig}\n";
        }
    }

    close(INFILE);
    close(COVERAGE);
    close(OUTFILE);
}

exit;

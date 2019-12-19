#!/usr/bin/perl -w
use strict;

## Take blasn_filtered and coverage_table and transform it into a table showing name, score, length of contig and percentage of contig mapped, keeping only score and percentaje of mapping > 90%

if(scalar @ARGV != 2){die "We need 2 files as argument, blasn_filtered and coverage_table\n";}

	my $blastfile = $ARGV[0];
    my $coveragefile = $ARGV[1];

    my $outfile = $ARGV[0];
    $outfile =~ s/_filtered.blast/_summary.tsv/;

    open(INFILE, $blastfile) or die "$!";
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
				$contig =~ s/^ref\|//;
				$contig =~ s/\|//;
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

exit;

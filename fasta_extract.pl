#!/usr/bin/perl -w
use strict;

## This scrtipt reads a multifasta and extract only sequences whose IDs contain a string included in the IDs list file (non case-sensitive). 

if(scalar @ARGV != 2){die "This scrtipt reads a multifasta and extract only sequences whose IDs contain a string included in the IDs list file (non case-sensitive).\nThis script needs 2 arguments, first the multifasta file and second the list of IDs to find.\n\nUSAGE: perl fasta_extract.pl multifasta.fasta IDs.txt > output.fasta\n\n";}

my $multifasta = $ARGV[0];
my $id_list = $ARGV[1];

# Check input files exist
open (MULTIFASTA, $multifasta) or die "$!";
open (ID_LIST, $id_list) or die "$!";

# Load IDs
my %ids;
while (my $line = <ID_LIST>){
    chomp $line;
    $ids{$line} = 1;
}

# Extract
my $mode = "read";
while (my $line = <MULTIFASTA>){
    if ($line =~ /^>/){
        foreach my $id (keys %ids){
            if (index (lc($line) ,lc($id)) != -1){
                $mode = "extract";
                last;
            } else {
                $mode = "read";
            }
        }
    }
    print $line if ($mode eq "extract");
}

close MULTIFASTA;
close ID_LIST;

exit;
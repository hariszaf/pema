#!/usr/bin/perl -w                                                              

# Aim    : Extract filtered fasta sequences used by the main script.
# 
# Usage  : This script is invoked by PEMA each time that the vsearch algorithm
#          has been selected for the OTU clustering step; see module step, clusteringVsearch() function
# 
# Author : Torbjørn Rognes, see at https://github.com/torognes/vsearch/wiki/VSEARCH-pipeline#example-scripts

use warnings;
use strict;

die "Three arguments needed: fasta1, uc, and fasta2\n" unless scalar @ARGV > 2;

my ($fasta1, $uc, $fasta2) = @ARGV;

# read fasta2 file with accepted sequences                                      

my %accepted = ();

open(F2, $fasta2);
while (<F2>)
{
    if (/^>([^ ;]+)/)
    {
     	$accepted{$1} = 1;
    }
}
close F2;

# read uc file with mapping                                                     

open(UC, $uc);
while (<UC>)
{
    chomp;
    my @col = split /\t/;

    my $a;
    if ($col[8] =~ /^([^ ;*]+)/)
    {
     	$a = $1;
    }

    my $b;
    if ($col[9] =~ /^([^ ;*]+)/)
    {
     	$b = $1;
    }

    if ((defined $b) && ($accepted{$b}) && (defined $a))
    {
        $accepted{$a} = 1;
    }
}
close UC;

# read original fasta1 file                                                     

my $ok = 0;
open(F1, $fasta1);
while (<F1>)
{
    if (/^>([^ ;]+)/)
    {
     	$ok = $accepted{$1};
    }
    print if $ok;
}
close F1;
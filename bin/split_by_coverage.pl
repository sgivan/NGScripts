#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  split_by_coverage.pl
#
#        USAGE:  ./split_by_coverage.pl  
#
#  DESCRIPTION:  Script to segregate sequences in a fasta file by their read coverage.
#                Initially developed for output of the SPAdes assembler.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  09/16/14 08:56:59
#     REVISION:  ---
#===============================================================================

use 5.010;       # use at least perl version 5.10
use strict;
use warnings;
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use Bio::Seq;
use Bio::SeqIO;
use Statistics::Descriptive;
use Statistics::TTest;

my ($debug,$verbose,$help,$infile,$outfile,$coverage);

my $result = GetOptions(
    "debug"         =>  \$debug,
    "verbose"       =>  \$verbose,
    "help"          =>  \$help,
    "infile:s"      =>  \$infile,
    "outfile:s"     =>  \$outfile,
    "coverage:i"    =>  \$coverage,
);

if ($help) {
    help();
    exit(0);
}

sub help {

    say <<HELP;

    Command-line options

    --debug
    --verbose
    --help
    --infile
    --outfile
    --coverage


HELP

}

$verbose = 1 if ($debug);
$infile ||= 'infile';
$outfile ||= 'outfile';
$coverage ||= 200;


if ($debug) {
    say "infile: '$infile'";
    say "outfile: '$outfile'";
    say "coverage: '$coverage'";
}

my $inseqs = Bio::SeqIO->new(
    -file   =>  $infile,
    -format =>  'fasta',
);

my ($outfile1,$outfile2) = ($outfile . "_le$coverage", $outfile . "_gt$coverage");

my $outseqs1 = Bio::SeqIO->new(
    -file   =>  ">$outfile1",
    -format =>  'fasta',
);
my $outseqs2 = Bio::SeqIO->new(
    -file   =>  ">$outfile2",
    -format =>  'fasta',
);

open(STATS1,">",$outfile1 . ".stats");
open(STATS2,">",$outfile2 . ".stats");

my ($stats1,$stats2,@stats1vals,@stats2vals) = (Statistics::Descriptive::Sparse->new(),Statistics::Descriptive::Sparse->new());

if ($debug) {
    say "\$inseqs isa '" . ref($inseqs) . "'";
    say "\$outseqs1 isa '" . ref($outseqs1) . "'";
}

while (my $seq = $inseqs->next_seq()) {
    say $seq->id() if ($verbose);
    # fasta headers look like:
    # NODE_49_length_21441_cov_309.893_ID_97

    my ($seqlength,$seqcoverage) = ();

    if ($seq->id() =~ /NODE_\d+_length_(\d+)_cov_([\d.]+)_ID_\d+/) {
        $seqlength = $1;
        $seqcoverage = $2;
        say "\tlength: '$seqlength'\n\tcoverage: '$seqcoverage'" if ($verbose);

        if ($seqcoverage <= $coverage) {
            $outseqs1->write_seq($seq);
            push(@stats1vals,$seqcoverage);
            $stats1->add_data($seqcoverage);
            say STATS1 $seq->id() . "\t$seqcoverage\t$seqlength";
        } else {
            $outseqs2->write_seq($seq);
            push(@stats2vals,$seqcoverage);
            $stats2->add_data($seqcoverage);
            say STATS2 $seq->id() . "\t$seqcoverage\t$seqlength";
        }
    }

}
close(STATS1);
close(STATS2);

say "Summary Statistics";
say "Sequence coverage le $coverage";
say "\tn: " . $stats1->count();
say "\tMean coverage: " . $stats1->mean();
say "\tVariance of coverage: " . $stats1->variance();
say "\tSD: " . $stats1->standard_deviation();
say "\tmin: " . $stats1->min() . ", max: " . $stats1->max();

say "Sequence coverage gt $coverage";
say "\tn: " . $stats2->count();
say "\tMean coverage: " . $stats2->mean();
say "\tVariance of coverage: " . $stats2->variance();
say "\tSD: " . $stats2->standard_deviation();
say "\tmin: " . $stats2->min() . ", max: " . $stats2->max();

my $ttest = Statistics::TTest->new();
$ttest->set_significance(90);
$ttest->load_data(\@stats1vals,\@stats2vals);
$ttest->output_t_test();


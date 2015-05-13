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

my ($debug,$verbose,$help,$infile,$outfile,$coverage,$spades,$soapdenovo,$stats,$justsummary,$ttest,$nosummary);

my $result = GetOptions(
    "debug"         =>  \$debug,
    "verbose"       =>  \$verbose,
    "help"          =>  \$help,
    "infile:s"      =>  \$infile,
    "outfile:s"     =>  \$outfile,
    "coverage:i"    =>  \$coverage,
    "spades"        =>  \$spades,
    "soapdenovo"    =>  \$soapdenovo,
    "stats"         =>  \$stats,
    "justsummary"   =>  \$justsummary,
    "nosummary"     =>  \$nosummary,
    "ttest"         =>  \$ttest,
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
    --spades
    --soapdenovo
    --stats
    --justsummary
    --nosummary
    --ttest

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

my ($outfile1,$outfile2,$outseqs1,$outseqs2) = ($outfile . "_le$coverage", $outfile . "_gt$coverage");

unless ($justsummary) {
    $outseqs1 = Bio::SeqIO->new(
        -file   =>  ">$outfile1",
        -format =>  'fasta',
    );
    $outseqs2 = Bio::SeqIO->new(
        -file   =>  ">$outfile2",
        -format =>  'fasta',
    );
}

if ($stats) {
    open(STATS1,">",$outfile1 . ".stats");
    open(STATS2,">",$outfile2 . ".stats");
}

my ($stats1,$stats2,$lengthstats1,$lengthstats2,@stats1vals,@stats2vals,@lengthstats1vals,@lengthstats2vals) = 
(Statistics::Descriptive::Sparse->new(),Statistics::Descriptive::Sparse->new(),Statistics::Descriptive::Sparse->new(),Statistics::Descriptive::Sparse->new());

if ($debug) {
    say "\$inseqs isa '" . ref($inseqs) . "'";
    say "\$outseqs1 isa '" . ref($outseqs1) . "'";
}

while (my $seq = $inseqs->next_seq()) {
    say $seq->id() if ($verbose);
    # SPAdes fasta headers look like:
    # NODE_49_length_21441_cov_309.893_ID_97

    my ($seqlength,$seqcoverage) = ();
    if ($spades) {
        if ($seq->id() =~ /NODE_\d+_length_(\d+)_cov_([\d.]+)_ID_\d+/) {
            $seqlength = $1;
            $seqcoverage = $2;
            say "\tlength: '$seqlength'\n\tcoverage: '$seqcoverage'" if ($verbose);

        }
    } elsif ($soapdenovo) {
        $seqlength = $seq->length();
        $seqcoverage = $seq->description();
        $coverage = 0 unless ($coverage);
    }

    if ($seqcoverage <= $coverage) {
        $outseqs1->write_seq($seq) unless ($justsummary);
        # coverage stats
        push(@stats1vals,$seqcoverage);
        $stats1->add_data($seqcoverage);
        # sequence length stats
        push(@lengthstats1vals,$seqlength);
        $lengthstats1->add_data($seqlength);
        say STATS1 $seq->id() . "\t$seqcoverage\t$seqlength" if ($stats);
    } else {
        $outseqs2->write_seq($seq) unless ($justsummary);
        # coverage stats
        push(@stats2vals,$seqcoverage);
        $stats2->add_data($seqcoverage);
        # sequence length stats
        push(@lengthstats2vals,$seqlength);
        $lengthstats2->add_data($seqlength);
        say STATS2 $seq->id() . "\t$seqcoverage\t$seqlength" if ($stats);
    }
}

if ($stats) {
    close(STATS1);
    close(STATS2);
}

unless ($nosummary) {
    say "Summary Statistics of Coverage";
    say "Sequence coverage le $coverage";
    say "\tn: " . $stats1->count();
    say "\tMean: " . $stats1->mean() . "\tmin: " . $stats1->min() . "\tmax:" . $stats1->max();
    say "\tVariance: " . $stats1->variance() . "\tSD: " . $stats1->standard_deviation();

    say "Sequence coverage gt $coverage";
    say "\tn: " . $stats2->count();
    say "\tMean: " . $stats2->mean() . "\tmin: " . $stats2->min() . "\tmax:" . $stats2->max();
    say "\tVariance: " . $stats2->variance() . "\tSD: " . $stats2->standard_deviation();


    say "\nSummary Statistics of Sequence Length";
    say "Sequence coverage le $coverage";
    say "\tn: " . $lengthstats1->count();
    say "\tMean: " . $lengthstats1->mean() . "\tmin: " . $lengthstats1->min() . "\tmax:" . $lengthstats1->max();
    say "\tVariance: " . $lengthstats1->variance() . "\tSD: " . $lengthstats1->standard_deviation();

    say "Sequence coverage gt $coverage";
    say "\tn: " . $lengthstats2->count();
    say "\tMean: " . $lengthstats2->mean() . "\tmin: " . $lengthstats2->min() . "\tmax:" . $lengthstats2->max();
    say "\tVariance: " . $lengthstats2->variance() . "\tSD: " . $lengthstats2->standard_deviation();
}

if ($ttest) {
    say "\nTTest Analysis";
    say "T-test of Coverage Distributions";
    my $cttest = Statistics::TTest->new();
    $cttest->set_significance(90);
    $cttest->load_data(\@stats1vals,\@stats2vals);
    $cttest->output_t_test();

    say "\nT-test of Length Distributions";
    my $lttest = Statistics::TTest->new();
    $lttest->set_significance(90);
    $lttest->load_data(\@lengthstats1vals,\@lengthstats2vals);
    $lttest->output_t_test();
}


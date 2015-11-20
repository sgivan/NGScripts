#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  calc_total_span.pl
#
#        USAGE:  ./calc_total_span.pl  
#
#  DESCRIPTION:  Calculates the total span of coverage of contigs mapped to
#                a reference genome sequence. Desiged to take output of
#                nucmer | delta-filter -q <delta file> | show-coords -rclT 
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  11/19/15 21:10:21
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;

my ($debug,$verbose,$help,$infile);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile:s"  =>  \$infile,
);

$infile = 'infile' unless ($infile);

if ($help) {
    help();
    exit(0);
}

open(my $IN,"<",$infile);

my ($global_start,$global_stop,$global_gap_sum,$global_align_sum) = (0,0,0,0);
my ($last_start,$last_stop,$reference_length) = (0,0,0);
my ($contained) = (0);

my $cnt = 0;
while (<$IN>) {
    next unless (++$cnt > 4);
    my ($local_start,$local_stop,@vals) = split /\t/, $_;
    $reference_length = $vals[5] unless ($reference_length);
    say "local_start = '$local_start', local_stop = '$local_stop'" if ($verbose);

    if ($local_start < $global_stop && $local_stop < $global_stop) {
        say "whoa! There is a fully contained fragment from $local_start to $local_stop" if ($verbose);
        ++$contained;
        next;
    }

    if ($local_stop < $local_start) {
        say "whoa! stop = $local_stop, which is < start = $local_start" if ($verbose);
        exit;
    }

    if ($local_start > $global_stop) {
        say "gap: $local_start > $global_stop" if ($verbose);
        $global_align_sum += ($local_stop - $local_start);
        $global_gap_sum += ($local_start - $last_stop);
    } else {
        say "no gap: $local_start < $global_stop" if ($verbose);
        $global_align_sum += ($local_stop - $local_start) - ($last_stop - $local_start);
    }


    $global_start = $local_start if ($local_start < $global_start || !$global_start);
    $global_stop = $local_stop if ($local_stop > $global_stop);
    $last_start = $local_start;
    $last_stop = $local_stop;
}

if (1) {
    say "global_start = '$global_start', global_stop = '$global_stop', reference length = '$reference_length'";
    say "global alignment sum = $global_align_sum";
    say "global gap sum = $global_gap_sum";
    printf "total %% of reference sequence covered: %2.2f\n", $global_align_sum/$reference_length * 100;
    say "fully contained fragments: $contained";
}

sub help {

    say <<HELP;
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile:s"  =>  \$infile,


HELP

}




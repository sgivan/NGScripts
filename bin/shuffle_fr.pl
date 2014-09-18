#!/usr/bin/env perl

# script to take an fastq file created with sff_extract
# and create files of paired and unpaired reads

use 5.010;      # Require at least Perl version 5.8
use autodie;
use Getopt::Long; # use GetOptions function to for CL args

my ($debug,$verbose,$help);

my $result = GetOptions(
    "infile=s"  =>  \$infile,
    "outfile=s" =>  \$outfile,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

if ($help) {
    _help();
    exit();
}

my $unpaired_file = "$outfile" . "u";
my %seq = ();

# build %seq keyed on sequence id root
# value will be array
# if array length = 2 print as paired
# if array length = 1 print as unpaired

open($IN,"<",$infile);
open($OUT,">",$outfile . ".paired");
open($UNP,">",$outfile . ".unpaired");
open($UNK,">",$outfile . ".unknown");

while (<$IN>) {
    my $seqid = "";
    if ($_ =~ /^@(.+?)\s/) {
        $seqid = $1;
    }
    chomp(my $sequence = <$IN>);
    chomp(my $qaulID = <$IN>);
    chomp(my $qualstring = <$IN>);

    my $seqroot = $seqid;
    $seqroot =~ s/.[fr]//;

    print "\nseqid: '$seqid'\nsequence: '$sequence'\nqualid: '$qualID'\nqualstring: '$qualstring'\nseqroot: '$seqroot'\n" if ($debug);

    my $seqvals = [ $seqid, $sequence, $qualstring ];
    push(@{$seq{$seqroot}},$seqvals);
    print "number of sequences for seqroot '$seqroot': '", scalar(@{$seq{$seqroot}}), "'\n" if ($debug);
}

for my $key (keys(%seq)) {
    if (scalar(@{$seq{$key}}) == 2) {
        for my $vals (values(@{$seq{$key}})) {
            print $OUT "\@" . $vals->[0] . "\n" . $vals->[1] . "\n+\n" . $vals->[2] . "\n";
        }
    } elsif (scalar(@{$seq{$key}}) == 1) {
        my $s = $seq{$key}->[0];
        print $UNP "\@" . $s->[0] . "\n" . $s->[1] . "\n+\n" . $s->[2] . "\n";
    } else {
        my $s = $seq{$key}->[0];
        print $UNK "\@" . $s->[0] . "\n" . $s->[1] . "\n+\n" . $s->[2] . "\n";
    }
}

if ($help) {
    help();
    exit(0);
}

sub _help {

say <<HELP;

    "infile=s"  =>  \$infile,
    "outfile=s" =>  \$outfile,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,

HELP

}


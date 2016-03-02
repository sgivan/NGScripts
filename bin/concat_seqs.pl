#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: concat_seqs.pl
#
#        USAGE: ./concat_seqs.pl  
#
#  DESCRIPTION: Will concatenate a set of sequences with multiple N's separating them
#
#      OPTIONS: ---
# REQUIREMENTS: autodie, Getopt::Long, Bio::SeqIO, Bio::Seq::SeqFactory, Bio::SeqFeature::Lite, Bio::Tools::GFF
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Scott A. Givan
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/10/2013 10:43:45 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;


use 5.010;      # Require at least Perl version 5.8
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use Bio::SeqIO;
use Bio::Seq::SeqFactory;
use Bio::SeqFeature::Lite;
use Bio::Tools::GFF;

my ($debug,$verbose,$help);
my ($infile,$outfile,$Ns,$fileformat,$gff,$gtf,$gffversion);

my $result = GetOptions(
    "infile:s"  =>  \$infile,
    "outfile:s" =>  \$outfile,
    "N:i"       =>  \$Ns,
    "format:s"  =>  \$fileformat,
    "gff"       =>  \$gff,
    "gtf"       =>  \$gtf,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

$Ns ||= 10;
$infile ||= 'infile';
$fileformat ||= 'fasta';

$gffversion = $gff ? 3 : 2.5;# GFF version 2.5 is GTF

if ($help) {
    help();
    exit(0);
}

sub help {

say <<HELP;

    "infile:s"  =>  \$infile,
    "outfile:s" =>  \$outfile,
    "N:i"       =>  \$Ns,
    "format:s"  =>  \$fileformat,
    "gff"       =>  \$gff,
    "gtf"       =>  \$gtf,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,

HELP

}

#$fileformat = 'fasta';
my $seqio = Bio::SeqIO->new(
                            -file       =>  $infile,
                            -format     =>  $fileformat,
);

my $seqout = Bio::SeqIO->new(
                            -file       =>  ">$infile" . ".out",
                            -format     =>  $fileformat,
);

my $featureIO = Bio::Tools::GFF->new(
                                        -file   =>  $gff ? ">$infile" . ".out.gff" : ">$infile" . ".out.gtf",
#                                        -gff_version    =>  '2.5',
                                        -gff_version    =>  $gffversion,
);

#say "GFF version: " . $featureIO->gff_version();

my $Nstring = "N" x $Ns;
say "Nstring: '$Nstring'" if ($debug);

my ($newseqstring,$running) = ("",1);

while (my $seq = $seqio->next_seq()) {
#    say "seqid: ", $seq->id();

#    $seq->seq($seq->seq() . "$Nstring");
    $newseqstring .= $seq->seq() . "$Nstring";
#    $seqout->write_seq($seq);
    my %attributes = (
                        length          =>  $seq->length(),
                        transcript_id   =>  $seq->id(),
                        gene_id           =>  $seq->id(),
    );
    my $stop = $running + $seq->length() - 1;

    my $seqfeature = Bio::SeqFeature::Lite->new(
                                                    -start  =>  $running,
                                                    -stop   =>  $stop,
                                                    -strand =>  1,
                                                    -type   =>  'CDS',
                                                    -name   =>  $seq->id(),
                                                    -desc   =>  'na',
                                                    -seq_id =>  'concatseq',
                                                    -source =>  'concat_seqs',
                                                    -score  =>  '.',
                                                    -phase  =>  '0',
                                                    -attributes =>  \%attributes,
    );
    $featureIO->write_feature($seqfeature);

    #$running += ($seq->length() + $Ns - 1);# I think this will be the last N of the string
    $running += ($seq->length() + $Ns);
}

my $newseq = Bio::Seq::SeqFactory->new()->create(
                                            -seq    =>  $newseqstring,
                                            -id     =>  'concatseq',
);

$seqout->write_seq($newseq);


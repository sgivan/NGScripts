#!/usr/bin/env perl
#
# copyright 2010
# Scott A. Givan
# University of Missouri
#
# script to generate a random sampling of an input biological sequence file
#
use strict;
use Getopt::Long;
use Bio::SeqIO;

my ($infile,$outfile,$numoutseqs,$format,$idlist,$idfile) = ('infile','outfile',1000,'fasta',0,0);
my ($debug,$help);

GetOptions(
  'infile=s'  =>  \$infile,
  'outfile=s' =>  \$outfile,
  'outseqs=i' =>  \$numoutseqs,
  'format=s'  =>  \$format,
  'idlist=s'    =>  \$idlist,# output array ID's to a file
  'idfile=s'    =>  \$idfile,# read array ID's from a file
  'debug'     =>  \$debug,
  'help'      =>  \$help,
);

if ($help) {
  _help();
  exit();
}

#if ($outfile =~ /OUT/) {
# $outfile = \*STDOUT;
#} else {
# $outfile = ">$outfile";
#}

if ($debug) {
  print "\$infile = '$infile'\n\$outfile = '$outfile'\n\$outseqs = '$numoutseqs'\n";
}

my $seqio = Bio::SeqIO->new(
        -file   =>  $infile,
        -format   =>  $format,
);
my $seqout = Bio::SeqIO->new(
        -file   =>  ">$outfile",
        -format   =>  $format,
);

my (@ids) = ();
if ($idlist) {
  #open(ID,">idfile") or die "can't open idlist file: $!";
  open(ID,">",$idlist) or die "can't open idlist file: $!";
} elsif ($idfile) {
  #open(IDS,'idfile') or die "can't open idfile: $!";
  open(IDS,"<",$idfile) or die "can't open idfile: $!";
  @ids = <IDS>;
  close(IDS) or warn "can't close idfile properly: $!";
  print "\@ids: ", scalar(@ids), "\n" if ($debug);
}

my (@seqs) = ();
while (my $seq = $seqio->next_seq()) {
  push(@seqs,$seq);
}

print "# of seqs: ", scalar(@seqs), "\n" if ($debug);

if (!$idfile) {
  for (my $i = 0; $i < $numoutseqs; ++$i) {
    # pick random element from array of Bio::Seq objects
    my $index = int(rand(@seqs));
    # the following redo removes potential redundancy
    # in the output files
    redo unless $seqs[$index];
    print ID "$index\n" if ($idlist);
    print "index: $index\n" if ($debug);
    $seqout->write_seq($seqs[$index]);
    # set this element to undef to keep
    # it from being used again (see redo step, above)
    $seqs[$index] = undef;
  }
} else {
  print "retrieving arrays index values from 'idfile'\n" if ($debug);
  foreach my $index (@ids) {
    chomp($index);
    print "index: $index\n" if ($debug);
    $seqout->write_seq($seqs[$index]);
  }
}

if ($idlist) {
  close(ID) or warn "can't close idlist file: $!";
}

sub _help {

print <<HELP;

  This script generates a file containing sequences sampled from a larger file.
  
  Command line options:
  
  
  --infile      name of large input file
  --outfile     name of output file
  --outseqs     number of sequences to sample from larger file
  --format      file format of sequence files
  --idlist      generate a list of array ID's in this file
  --idfile      read this file to determine which sequences to output*
  --debug       debugging mode
  --help        print this help menu


  * These options are primarily useful when you have 2 large files of paired-end sequences,
  where file 1 has read 1 and file 2 has read 2, and the files are sorted to contain the exact
  same order of sequences. You can use the --idlist option to generate a file containing the
  array indices used to generate a sample of file 1 and then use the --idfile option to generate
  file 2 using the second read for each file 1 read.
  
HELP

}

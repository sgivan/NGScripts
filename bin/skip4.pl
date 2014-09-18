#!/usr/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use autodie;
use Getopt::Long; # use GetOptions function to for CL args

my ($debug,$verbose,$help);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

if ($help) {
    help();
    exit(0);
}

my $lncnt = 0;
while (<>) {

    if (++$lncnt <= 4) {
        print $_;
    } else {
        $lncnt = 0;
    }
}

sub help {

say <<HELP;


HELP

}


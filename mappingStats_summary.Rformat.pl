#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;

my @script_info = "
##########################################################################################
#
#	Script goes through a directory containing the output from get_RNAseq_mapped_unmapped_stats.pl
#    and combines the output into one file, in long Rformat.
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -d\tDirectory path
    -f\tFilename wildcard to identify files of interest
    -o\toutput file\n\n";

my (%opt, $directory, $filename, $outfile);
getopts('d:f:o:', \%opt);
&var_check();








sub var_check {
	if ($opt{'d'}) {
		$directory = $opt{'d'};
	} else {
		&var_error();
	}
	if ($opt{'f'}) {
		$filename = $opt{'f'};
	} else {
		&var_error();
	}
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		&var_error();
	}
}

sub var_error {
	print "@script_info";
	exit 0;
}

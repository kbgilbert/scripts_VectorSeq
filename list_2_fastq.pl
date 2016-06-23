#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes a list of read IDs and a corresponding fastq file and outputs only those
#	reads in the list.
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -l\tList filename
    -f\tFastq filename [assumes fastq.gz]
    -o\tOutput file name
    OPTIONAL:
    -z\tUse if .fastq is not gzipped\n\n";

my (%opt, $outfile, $list_file, $fastq_file);

getopts('o:l:f:z', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";
open (IN, $list_file) or die " Cannot open $list_file: $!\n\n";

my %hash;

while (my $line = <IN>) {
	chomp $line;
	my $name = $line;
	$hash{$name} = 1;
}
close IN;

if ($opt{'z'}) {
	open (FASTQ, $fastq_file) || die "Cannot open $fastq_file: $!\n\n";
} else {
	open (FASTQ, "zcat $fastq_file |");
}

while (my $line = <FASTQ>) {
	chomp $line;
	my @split = split(/\s/, $line);
	my $header = $split[0];
	next if (!exists($hash{$header}));
	
	my $seq = <FASTQ>;
	my $next = <FASTQ>;
	my $qual = <FASTQ>;
	
	print OUT "$line\n$seq$next$qual";
}
close FASTQ;
close OUT;
exit;

#########################################################
# Start of Varriable Check Subroutine "var_check"       #
#########################################################

sub var_check {
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		var_error();
	}
	if ($opt{'l'}) {
		$list_file = $opt{'l'};
	} else {
		var_error();
	}
	if ($opt{'f'}) {
		$fastq_file = $opt{'f'};
	} else {
		var_error();
	}
}

#########################################################
# Start of Varriable error Subroutine "var_error"       #
#########################################################

sub var_error {
	print "@script_info";
	exit 1;
}


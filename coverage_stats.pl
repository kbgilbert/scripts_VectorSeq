#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Runs genomeCoverageBed on output from gatk variant finding and outputs the average
#	coverage per base pair.
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -b\tbam file for genomeCoverageBed
    -f\tfasta file for genomeCoverageBed
    -o\tOutput file name\n\n";

my (%opt, $outfile, $bam_file, $fasta_file);

getopts('o:f:b:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";

open COV, "genomeCoverageBed -ibam $bam_file -g $fasta_file -d |";
my $total = 0;
my $line_count = 0;

while (my $line = <COV>) {
	chomp $line;
	
	my @split = split(/\t/, $line);
	my $coverage = $split[2];
	$total += $coverage;
	$line_count += 1;
}
close COV;

print OUT "Avg coverage\t";
my $avg_cov = sprintf("%.2f", ($total / $line_count));
print OUT "$avg_cov\n";
close OUT;
exit;

#########################################################
# Variable Check Subroutine "var_check"       
#########################################################

sub var_check {
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		var_error();
	}
	if ($opt{'f'}) {
		$fasta_file = $opt{'f'};
	} else {
		var_error();
	}
	if ($opt{'b'}) {
		$bam_file = $opt{'b'};
	} else {
		var_error();
	}
}

#########################################################
# Variable error Subroutine "var_error"
#########################################################

sub var_error {
	print "@script_info";
	exit 1;
}


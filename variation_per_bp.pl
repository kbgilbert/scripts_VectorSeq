#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes a sorted, indexed bam file and an region of interest and outputs the
#	observed bp frequency / position.
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -b\t.bam file
    -n\tName of scaffold/contig/etc
    -r\tRegion coordinates
    -o\tOutfile name\n\n";

my (%opt, $outfile, $bam_file, $contig, @coords);

getopts('o:b:n:r:', \%opt);
var_check();

my $pair1_out = $outfile . "_pair1.fastq";
my $pair2_out = $outfile . "_pair2.fastq";

open (P1, ">$pair1_out") or die "Cannot open $pair1_out\n\n";
open (P2, ">$pair2_out") or die "Cannot open $pair2_out\n\n";

my (%hash);

my %flags;
$flags{'77'} = 1;
$flags{'141'} = 1;

open SAM, "samtools view -f 4 $bam_file |";
while (my $line = <SAM>) {
	chomp $line;
	
	my @split = split(/\t/, $line);
	my $flag = $split[1];
	next if (!exists($flags{$flag}));
	
	my $readID = $split[0];
	my $seq = $split[9];
	my $qual = $split[10];
	
	if (exists($hash{$readID})) {
		print P2 "@" . $readID . "\n";
		print P2 $seq . "\n";
		print P2 "+\n";
		print P2 $qual . "\n";
	} else {
		print P1 "@" . $readID . "\n";
		print P1 $seq . "\n";
		print P1 "+\n";
		print P1 $qual . "\n";
		$hash{$readID} = 1;
	}
}
close P1;
close P2;
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
	if ($opt{'b'}) {
		$bam_file = $opt{'b'};
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


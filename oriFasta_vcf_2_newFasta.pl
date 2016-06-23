#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Scripts takes original fasta file used for reference based assembly and a vcf output from
#	variant calling using GATK and creates a new fasta file.
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -f\tFasta file used for reference based assembly
    -v\tvcf file from GATK pipeline
    -o\tOutput file name\n\n";

my (%opt, $outfile, $oriFasta, $gatk_vcf);

getopts('o:v:f:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";
open (IN, $oriFasta) || die "Cannot open $oriFasta: $!\n\n";

my @seq_array;
my ($header, $tmp_seq);

while (my $line = <IN>) {
	chomp $line;
	if ($line =~ /\>/) {
		$header = $line;
		next;
	}
	$tmp_seq .= $line;
}
close IN;

@seq_array = split(//, $tmp_seq);

my $count = scalar(@seq_array);

open (IN, $gatk_vcf) || die "Cannot open $gatk_vcf: $!\n\n";
my @check = <IN>;
my $vars = 0;
foreach my $line (@check) {
	if ($line !~ /^#/) {
		$vars++;
	}
}
close IN;

open (IN, $gatk_vcf) || die "Cannot open $gatk_vcf: $!\n\n";
while (my $line = <IN>) {
	chomp $line;
	if ($vars == 0) {
		last;
	}
	next if ($line =~ /^\#/);
	
	my @split = split(/\t/, $line);
	my $refPos = $split[1];
	my $refNT = $split[3];
 	my $ref_len = length($refNT);
	
	my $newNT = $split[4];
	my $new_len = length($newNT);
	$refPos -= 1;
	
	if ($new_len == $ref_len || $new_len > $ref_len) {
		$seq_array[$refPos] = $newNT;		
	} else {
		for (my $i = 0; $i < scalar(@seq_array); $i++) {
			if ($i < $refPos) {
				next;
			} elsif ($i == $refPos) {
				$seq_array[$i] = $newNT;
			} elsif ($i > $refPos && $i <= ($refPos + $ref_len - 1)) {
				$seq_array[$i] = "delete";
			}
		}
	}
}
close IN;

my $ending = $outfile;
$ending =~ s/\.fasta//;
my @tmp_split = split(/\_/, $ending);
$header =~ s/ref//;

print OUT "$header" . "$tmp_split[-1]\n";
for (my $i = 0; $i < scalar(@seq_array); $i++) {
	my $nt = $seq_array[$i];
	if ($nt =~ /delete/) {
		next;
	} else {
		$nt =~ tr/acgt/ACGT/;
		print OUT "$nt";
	}
}
print OUT "\n";
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
	if ($opt{'v'}) {
		$gatk_vcf = $opt{'v'};
	} else {
		var_error();
	}
	if ($opt{'f'}) {
		$oriFasta = $opt{'f'};
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


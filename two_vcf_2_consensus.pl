#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Scripts takes two different vcf files and creates a consensus sequence output
#
#	vcf 1: Output from samtools mpileup-->bcftools [contains entire sequence]
#	vcf 2: Output from GenomeAnalysisTK.jar of GATK pipeline [contains the differences]
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -v\tvcf file 1 from samtools
    -V\tvcf file 2 from GATK pipeline
    -o\tOutput file name\n\n";

my (%opt, $outfile, $samtools_vcf, $gatk_vcf);

getopts('o:v:V:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";

print STDERR " Going through $samtools_vcf... ";
open (IN, $samtools_vcf) || die "Cannot open $samtools_vcf: $!\n\n";

my $header;

my (%hash, @pos);
while (my $line = <IN>) {
	chomp $line;
	next if ($line =~ /^#/);
	
	my @split = split(/\t/, $line);
	$header = $split[0];
	my $pos = $split[1];
	my $ref_nt = $split[3];
	
	$hash{$pos} = $ref_nt;
	push (@pos, $pos);
}
close IN;
print STDERR "done.\n";

print STDERR " Going through $gatk_vcf... ";
open (IN, $gatk_vcf) || die "Cannot open $gatk_vcf: $!\n\n";

while (my $line = <IN>) {
	chomp $line;
	next if ($line =~ /^#/);
	
	my @split = split(/\t/, $line);
	my $pos = $split[1];
	my $variant_nt = $split[4];
	my $variant_len = length($variant_nt);
	
	my $ref_nt = $split[3];
	my $ref_len = length($ref_nt);
	
	if ($ref_len > $variant_len) {
		for (my $i = $pos; $i < ($pos+$ref_len); $i++) {
			delete $hash{$i};
		}
	}
	
	$hash{$pos} = $variant_nt;
}
close IN;
print STDERR "done.\n";

print OUT ">$header\n";
foreach my $pos (sort {$a <=> $b} keys %hash) {
	my $seq = $hash{$pos};
	print OUT "$seq";
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
		$samtools_vcf = $opt{'v'};
	} else {
		var_error();
	}
	if ($opt{'V'}) {
		$gatk_vcf = $opt{'V'};
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


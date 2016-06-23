#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Scripts takes a genbank file (like output from Serial Cloner) and creates a gff3
#	formatted output file. Also requires a fasta file for the sequence (to ensure that
#	the contig/chrom/etc name matches between the gff3 and fasta files.)
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -i\tInput file (genbank file)
    -f\tFasta file (that corresponds to genbank file)
    -o\tOutput file name
    OPTIONAL:
    -s\tSource info [default = '.']\n\n";

my (%opt, $infile, $outfile, $fasta_file, $source);

getopts('i:o:f:s:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";
print OUT "##gff-version 3\n";

open (FA, $fasta_file) || die "Cannot open $fasta_file: $!\n\n";
my ($header);

while (my $line = <FA>) {
	chomp $line;
	$header = $line;
	$header =~ s/>//;
	last;
}
close FA;

open (IN, $infile) || die "Cannot open $infile: $!\n\n";
my $ok = 2;
my $ID = 1;
my ($type, $start, $end, $strand, $name);


while (my $line = <IN>) {
	chomp $line;
	
	if ($line =~ /^LOCUS/) {
		my @split = split(/\s+/, $line);
		my $len = $split[2];
		print OUT "##sequence-region\t$header\t1\t$len\n";
		next;
	}
	
	if ($line =~ /FEATURES/) {
		$ok = 1;
		next;
	}
	
	last if ($line =~ /ORIGIN/);
	next if ($line =~ /SerialCloner/);
	next if ($line =~ /source/);
	next if ($line =~ /organism/);
	next if ($line =~ /mol_type/);
	
	if ($line =~ /\d\.\.\d/) {
		my @split = split(/\s+/, $line);
		$type = $split[1];
		if ($type =~ /CDS/) {
			$type = "gene";
		}
		my @tmp_coords = split(/\.\./, $split[2]);
		$start = $tmp_coords[0];
		$end = $tmp_coords[1];
		if ($start =~ /complement/) {
			$strand = "-";
			$start =~ s/complement\(//;
			$end =~ s/\)//;
		} else {
			$strand = "+";
		}
		
		$line = <IN>;
		chomp $line;
		
		if ($line =~ /direction/ || $line =~ /codon_start/ || $line =~ /product/) {
			$line = <IN>;
			chomp $line;
			if ($line =~ /note/) {
				@split = split(/\=/, $line);
				$name = $split[1];
			}
			print OUT "$header\t$source\t$type\t$start\t$end\t.\t$strand\t.\tID=$ID;Name=$name\n";
		}
		if ($line =~ /direction/ || $line =~ /codon_start/ || $line =~ /product/) {
			$line = <IN>;
			chomp $line;
			if ($line =~ /note/) {
				@split = split(/\=/, $line);
				$name = $split[1];
			}
			print OUT "$header\t$source\t$type\t$start\t$end\t.\t$strand\t.\tID=$ID;Name=$name\n";
		}
		
		#if ($line =~ /note/) {
		#	@split = split(/\=/, $line);
		#	$name = $split[1];
		#}
		#print OUT "$header\t$source\t$type\t$start\t$end\t.\t$strand\t.\tID=$ID;Name=$name\n";
		$ID++;
		next;
	} elsif ($ok > 1) {
		next;
	}
	
	#print OUT "$header\t$source\t$type\t$start\t$end\t.\t$strand\t.\tID=$ID;Name=$name\n";
	#$ID++;
}

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
	if ($opt{'i'}) {
		$infile = $opt{'i'};
	} else {
		var_error();
	}
	if ($opt{'f'}) {
		$fasta_file = $opt{'f'};
	} else {
		var_error();
	}
	if ($opt{'s'}) {
		$source = $opt{'s'};
	} else {
		$source = ".";
	}
}

#########################################################
# Start of Varriable error Subroutine "var_error"       #
#########################################################

sub var_error {
	print "@script_info";
	exit 1;
}


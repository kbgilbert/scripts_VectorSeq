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

opendir (DIR, $directory) or die "Could not open Dir $directory: $!\n";
my @dir_files = readdir DIR;
closedir DIR;

open (OUT, ">$outfile") || die "Cannot open $outfile: $!\n\n";

my (%hash);

foreach my $in_file (@dir_files) {
     chomp $in_file;
     next if ($in_file !~ /$filename/);
     
     open (IN, "$directory/$in_file") || die "Cannot open $in_file: $!\n\n";
     while (my $line = <IN>) {
          chomp $line;
          next if ($line =~ /^File/);
          
          my @split = split(/\t/, $line);
          my $name = $split[0];
          $name =~ s/\.sam//;
          
          my $parsed = $split[1];
          my $mapped = $split[3];
          
          $hash{$name}{'parsed'} = $parsed;
          $hash{$name}{'mapped'} = $mapped;
     }
     close IN;
}

my @types = qw (parsed mapped);

print OUT "File\tData\tType\n";
foreach my $file (sort {$a cmp $b} keys %hash) {
     foreach my $type (@types) {
          print OUT "$file\t$hash{$file}{$type}\t$type\n";
     }
}
close OUT;
exit;

########################################################
##                var_check Subroutine               ##
########################################################
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

########################################################
##                var_error Subroutine               ##
########################################################
sub var_error {
	print "@script_info";
	exit 0;
}

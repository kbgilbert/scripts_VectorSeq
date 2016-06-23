use strict;
use warnings;
use Getopt::Std;

my @script_info = "
##########################################################################################
#
#	Script takes the .vcf output from GATK pipeline and creates an Rformat data file
#	for plotting the SNP, insertion, deletion data.
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -i\tInput file (.vcf file from GATK)
    -o\tOutput file for any matches
    -n\tName of vector\n\n";

my (%opt, $infile, $outfile, $name);

getopts('i:o:n:', \%opt);
var_check();

my @name = split(/_/, $name);
$name = join(" ", @name);

open (OUT, ">$outfile") || die "Cannot open $outfile: $!\n\n";
print OUT "Vector\tSize\tCount\tType\n";

open (IN, $infile) || die "Cannot open $infile: $!\n\n";

my %hash;
my @types = qw (snp ins del);

while (my $line = <IN>) {
	next if ($line =~ /^#/);
	chomp $line;
	my @split = split(/\t/, $line);
	
	my $ref_nt = $split[3];
	my $ref_len = length($ref_nt);
	
	my $new_nt = $split[4];
	my $new_len = length($new_nt);
	
	if ($ref_len == 1 && $new_len == 1) {
		$hash{'snp'}{'0'} += 1;
	}
	
	if ($ref_len > $new_len) {
		my $del = $ref_len - $new_len;
		if ($del > 5) {
			$del = 5;
		}
		
		$hash{'del'}{$del} += 1;
	}
	
	if ($ref_len < $new_len) {
		my $ins = $new_len - $ref_len;
		if ($ins > 5) {
			$ins = 5;
		}
		
		$hash{'ins'}{$ins} += 1;
	}
}
close IN;

foreach my $type (@types) {
	if ($type =~ /snp/) {
		my $size = 0;
		my $count = 0;
		if (exists($hash{$type}{'0'})) {
			$count = $hash{$type}{'0'};
		}
		print OUT "$name\t$size\t$count\tSNP\n";
	} else {
		for (my $size = 1; $size <= 5; $size++) {
			my $count = 0;
			
			if (exists($hash{$type}{$size})) {
				$count = $hash{$type}{$size};
			}
			
			print OUT "$name\t$size\t$count\t$type\n";
		}
	}
}
close OUT;
exit;

sub var_check {
	if ($opt{'i'}) {
		$infile = $opt{'i'};
	} else {
		&var_error();
	}
     if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		&var_error();
	}
     if ($opt{'n'}) {
		$name = $opt{'n'};
	} else {
		&var_error();
	}
}

sub var_error {
	print "@script_info";
	exit 1;
}

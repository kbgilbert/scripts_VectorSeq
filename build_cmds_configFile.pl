#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use POSIX qw( ceil floor);
use Config::Tiny;
use Env qw(HOME);
use lib "$HOME/lib/perl";
use CommonFunctions qw(parseListToArray parseFileList);

#########################################################
# Start Variable declarations                           #
#########################################################

my @script_info = "
##########################################################################################
#
#	Script takes a config file with sample info and builds the commands.
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -c\tPath to Config file
    -o\tOutput filename suffix [will be appended onto ID info in config file]\n\n";

my (%opt, $configFile, $outfile);

getopts('c:o:h', \%opt);
var_check();

# Get configuration settings
my $Conf = Config::Tiny->read($configFile);
my (%conf_details, @IDs);

foreach my $section (keys %{$Conf}) {
	foreach my $parameter (keys %{$Conf->{$section}}) {		
		my $ID = $Conf->{$section}->{'ID'};
		my $reads = $Conf->{$section}->{'Reads'};
		my $refSeq = $Conf->{$section}->{'Reference'};
		my $refFasta = $refSeq . ".fasta";
		my $refGB = $refSeq . ".gb";
		my $outname = $ID . "_pair1.bwa_vs_$refSeq";
		
		$conf_details{$ID}{'reads'} = $reads;
		$conf_details{$ID}{'name'} = $refSeq;
		$conf_details{$ID}{'fasta'} = $refFasta;
		$conf_details{$ID}{'GB'} = $refGB;
		$conf_details{$ID}{'outname'} = $outname;
		
		my $outfile_ID = $ID . $outfile;
		$conf_details{$ID}{'output'} = $outfile_ID;
		push(@IDs, $ID);
	 }
}

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

foreach my $ID (@IDs) {
	foreach my $key (keys %{$conf_details{$ID}}) {
		my $reads = $conf_details{$ID}{'reads'};
		my $refSeq = $conf_details{$ID}{'name'};
		my $refFasta = $conf_details{$ID}{'fasta'};
		my $refGB = $conf_details{$ID}{'GB'};
		my $outname = $conf_details{$ID}{'outname'};
		
		my $printOut = $conf_details{$ID}{'output'};
		open (OUT, ">$printOut") || die "Cannot open $printOut: $!\n\n";
		
		
		print OUT "#!/bin/sh\n";
		print OUT "bowtie2-build -f $refFasta $refFasta\n";
		print OUT "samtools faidx $refFasta\n";
		print OUT "java -jar /nfs4shares/bioinfosw/installs_current/picard/dist/picard.jar CreateSequenceDictionary REFERENCE=$refFasta OUTPUT=$refSeq" . ".dict\n";
		print OUT "bwa index -a is $refFasta\n";
		
		print OUT "perl ~/scripts/replace\^MwithNewLine.pl $refFasta\n";
		print OUT "perl ~/scripts/replace\^MwithNewLine.pl $refGB\n";
		print OUT "perl ~/scripts/vector_seq/genbank_2_gff3.pl -i $refGB -f $refFasta -s AC -o $refSeq" . ".gff3\n";
		
		print OUT "mkdir 1variant_calling\n";
		
		print OUT "bwa mem -M -R '\@RG\\tID:$ID\\tSM:$refSeq\\tPL:illumina\\tLB:$ID\\tPU:pair1' $refFasta $reads > 1variant_calling/$outname" . ".sam\n";
		print OUT "cd 1variant_calling\n";
		
		print OUT "java -jar /nfs4shares/bioinfosw/installs_current/picard/dist/picard.jar SortSam INPUT=$outname" . ".sam OUTPUT=$outname" . ".bam SORT_ORDER=coordinate\n";
		print OUT "java -jar /nfs4shares/bioinfosw/installs_current/picard/dist/picard.jar MarkDuplicates INPUT=$outname" . ".bam OUTPUT=$outname" . ".dedup.bam METRICS_FILE=metrics.dedup.txt\n";
		print OUT "java -jar /nfs4shares/bioinfosw/installs_current/picard/dist/picard.jar BuildBamIndex INPUT=$outname" . ".dedup.bam\n";
		print OUT "java -jar /nfs4shares/bioinfosw/installs_current/gatk-protected/target/GenomeAnalysisTK.jar --analysis_type HaplotypeCaller --genotyping_mode DISCOVERY -R ../$refFasta -I $outname" . ".dedup.bam -o $outname" . ".raw_variants.vcf\n";
		
		close OUT;
	}
}

exit;

#########################################################
# Start Subroutines                                     #
#########################################################

#########################################################
# Start of Varriable Check Subroutine "var_check"       #
#########################################################

sub var_check {
	if ($opt{'h'}) {
		var_error();
	}
	if ($opt{'c'}) {
		$configFile = $opt{'c'};
	} else {
		var_error();
	}
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		var_error();
	}
}

#########################################################
# End of Varriable Check Subroutine "var_check"         #
#########################################################

#########################################################
# Start of Varriable error Subroutine "var_error"       #
#########################################################

sub var_error {
	print "@script_info";
	exit 1;
}

#########################################################
# End of Varriable error Subroutine "var_error"         #
#########################################################

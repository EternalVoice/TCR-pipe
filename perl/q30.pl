#!/usr/bin/perl
# use strict;
use warnings;

die "Usage : perl $0 <sampleID.list> <batch>\n" unless scalar(@ARGV) == 2;

my $sampleIDlist = $ARGV[0];
my $batch = $ARGV[1];

## raw data ##
print join ("\t", "sampleID", "Raw_reads", "Clean_reads", "Clean_q20", "Clean_q30","Raw_Yield(Gb)"); print "\n";
open ID,$sampleIDlist or die "cannt open the sampleID.list\n";
while (my $id =<ID>){
	chomp $id;
	$id =~ s/\/$batch//g;
	my @filelist= `find /home/tongqiang/test/$batch/2.clean/QC/ -name "*.json"`;
	my ($raw_reads,$clean_reads,$fq1_20,$fq1_30,$fq1,$fq2_20,$fq2_30,$fq2,$q20,$q30,$R1_q20, $R2_q20, $R1_q30, $R2_q30,$Yield);
	
## get sampleID yield{Mb}
	open Data_stats,"/home/tongqiang/test/$batch/1.raw/statistics/data_stats.xls" || die "$!\n";
	while (<Data_stats>){
		chomp;
		my @mem = split;
		if (/$id/){
			$mem[8] =~ s/,//g;
			$Yield += $mem[8];
		}
	}
	close Data_stats;
	$Yield = sprintf "%.1f", $Yield/1000;
	
	foreach my $fh(@filelist){
	chomp $fh;  	
	open IN,$fh or die $!;

  	while (<IN>){
    		if (/\"before_filtering\"/){
			my $a = <IN>;
			$a =~ /\"total_reads\":(\d+),/;
			$raw_reads=$1;
    		}
  		if(/\"after_filtering\"/){
      			my $a2 = <IN>;
			$a2 =~ /\"total_reads\":(\d+),/;
			$clean_reads=$1;
			<IN>;<IN>;<IN>;
			my $b = <IN>;
			$b =~ /\"q20_rate\":(.+),/;
			$q20=$1;
			my $c = <IN>;
			$c =~ /\"q30_rate\":(.+),/;
			$q30=$1;
    			last;
		}
  	}
	close IN;

	}
	
printf "%s\t%d\t%d\t%.4f\t%.4f\t%.1f\n", $id, $raw_reads, $clean_reads,$q20, $q30, $Yield ;
}
close ID;

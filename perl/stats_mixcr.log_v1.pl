#!/usr/bin/perl -w
use strict;

die "Usage: perl $0 <mixcr.log> <sampleID> 
for IMGT lib(merge.log) $!\n" unless @ARGV == 2;

my $log = $ARGV[0];
my $sampleID = $ARGV[1];

print "SampleID\t$sampleID\n";
open LOG ,"$log" || die $!;
my $flag = 0;
while (<LOG>){
	chomp;
	if (/^TRB chains/){
		$flag ++;
	}
	if ($flag <= 1){
		next if (/^Analysis/ || /Input file/  || /Output file/ || /Version/ || /Command line arguments/ || /^==/ );
		my @mem = split /:/,$_;
		print "$mem[0]\t$mem[1]\n";
	}else{
		last;
	}
}
close LOG;

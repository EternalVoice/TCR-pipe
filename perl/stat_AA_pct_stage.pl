#!/usr/bin/perl -w
use strict;
die "Usage : perl $0 <all_CDR3_AA.counts.percent.txt> <sampleID>" unless @ARGV ==2;

my $expanded = 0;
my $medium = 0;
my $small = 0;  
 # expanded: > 0.1%; medium clone:>0.01% & <=0.1%; small clone: < 0.01%);
my ( %hash_V , %hash_J , %hash_nucl, %hash_AA );
my $sampleID = $ARGV[1];
open IN,$ARGV[0] || die $!;
while (<IN>){
	chomp;
	next if /^clone/;
	my @mem = split /\t/;
	if ($mem[3]> 0.001){ $expanded += $mem[3]; }
	if ($mem[3]<= 0.001 && $mem[3]> 0.0001){ $medium += $mem[3];}
	if ($mem[3]<= 0.0001){ $small += $mem[3]; }
}
close IN;

print "expanded\t$expanded\t$sampleID\nmedium\t$medium\t$sampleID\nsmall\t$small\t$sampleID\n";

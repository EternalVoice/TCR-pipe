#!/usr/bin/perl -w
use strict;

my %hash;
open IN , $ARGV[0] || die;
while (<IN>){
	chomp;
	if (/^clone/){print "V_gene\tJ_gene\tcounts\n"; next; }
	my @mem = split;
	my $key = $mem[2]."\t".$mem[3] ;
	$hash{$key} += $mem[1];	
}

foreach my $key(sort keys %hash){
	print "$key\t$hash{$key}\n";
}

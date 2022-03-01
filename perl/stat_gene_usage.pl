#!/usr/bin/perl -w
use strict;
die "Usage : perl $0 <trb.txt> <sampleID>" unless @ARGV ==2;

my ($sum,$nu, $sampleID );
my ( %hash_V , %hash_J , %hash_nucl, %hash_AA );
$sampleID = $ARGV[1];

## get all clonecount ##
open IN,$ARGV[0] || die $!;
<IN>;
while (<IN>){
	my @mem = split /\t/;
	$sum += $mem[1];
}
close IN;

###################### print sampleID.xls ###################	
open IN,$ARGV[0] || die $!;
open OUT_out,"> $sampleID.xls" || die $!;
while (<IN>){
	chomp;
	if (/^clone/){print OUT_out "cloneId\tcloneCount\tfreq\tallVHits\tallDHits\tallJHits\tnSeqCDR3\taaSeqCDR3\n" ; next; }
	my @mem = split /\t/;
	
	my $v_tmp = (split ",", $mem[2])[0];
	my $v ;	
	if ($v_tmp =~ /\//){
		$v_tmp =~ /^(TRBV[\w-]+)\//; $v = $1;	## TRBV20/OR9-2*01(446.8),
	}else{
		$v_tmp=~ /^(TRBV[\w-]+)\*0/; $v = $1;
	}
	#$mem[2] =~ /^(TRBV[\w-]+)\*0/;
	#my $v = $1;
	
	$mem[4] =~ /^(TRBJ[\w-]+)\*0/;
	my $j = $1;
	$hash_V{$v} += $mem[1];
	$hash_J{$j} += $mem[1];
	#$sum += $mem[1];
	my $len = length ($mem[6]);
	$hash_nucl{$len} ++;
	$nu ++;
	$hash_AA{$mem[7]} += $mem[1];	
	
	my $d;
	if( $mem[3]){
		$mem[3] =~ /^(TRBD[\w-]+)\*0/;
		$d = $1;
	} else {
		$d = "";
	}
	my $per = $mem[1]/$sum ;
print OUT_out "$nu\t$mem[1]\t$per\t$v\t$d\t$j\t$mem[6]\t$mem[7]\n";
}
close IN;
close OUT_out;

################## print out V,J usage #######################
open OUT_V,"> $sampleID.V_count.hist.percent" || die $!;
print OUT_V "V_gene\tcounts\tfrequency\tsampleID\n";
foreach my $key( sort keys %hash_V){
	my $percent = $hash_V{$key}/$sum;
	print OUT_V "$key\t$hash_V{$key}\t$percent\t$sampleID\n";
}
close OUT_V;

open OUT_J,"> $sampleID.J_count.hist.percent" || die $!;
print OUT_J "J_gene\tcounts\tfrequency\tsampleID\n";
foreach my $key( sort keys %hash_J){
        my $percent = $hash_J{$key}/$sum;
	print OUT_J "$key\t$hash_J{$key}\t$percent\t$sampleID\n";
}
 close OUT_J;

################ print out AA clonetype frequency #####################
open OUT_AA_10,"> $sampleID.top10_CDR3_AA.percent.txt" || die $!;
open OUT_AA_50,"> $sampleID.top50_CDR3_AA.percent.txt" || die $!;
open OUT_AA_ALL,"> $sampleID.all_CDR3_AA.counts.percent.txt" || die $!;
print OUT_AA_10 "cloneNumber\tAA\tcloneCounts\tfrequency\n";
print OUT_AA_50 "cloneNumber\tAA\tcloneCounts\tfrequency\n";
print OUT_AA_ALL "cloneNumber\tAA\tcloneCounts\tfrequency\n";
my @key = sort{ $hash_AA{$b} <=> $hash_AA{$a} } keys %hash_AA;
my $n;
foreach my $key (@key){
	$n ++;
	my $percent = $hash_AA{$key}/$sum;	
	if ($n <=10 ){ print OUT_AA_10 "$n\t$key\t$hash_AA{$key}\t$percent\n"; }
	if ($n <=50 ){ print OUT_AA_50 "$n\t$key\t$hash_AA{$key}\t$percent\n"; }
	print OUT_AA_ALL "$n\t$key\t$hash_AA{$key}\t$percent\n";
}
close OUT_AA_10;
close OUT_AA_50;
close OUT_AA_ALL;

################ print out nucl length frequency ####################
open OUT_nucl,"> $sampleID.CDR3.length_percent.txt" || die $!;
print OUT_nucl "CDR3_nu_len\tfrequency\n";
foreach my $key(sort keys %hash_nucl){
	my $percent = $hash_nucl{$key}/$nu;
	print OUT_nucl "$key\t$percent\n";
}
close OUT_nucl;

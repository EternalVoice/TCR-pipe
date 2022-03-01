#!/usr/bin/perl -w
use strict;
#die "Usage : perl $0 <batch> <sampleID...>  $!\n" unless @ARGV == 4;
die "Usage : perl $0 <batch>  $!\n" unless @ARGV == 1;

my %VCF_h;
my @VCF;
my @sampleID;
my %key;

my @ar = ( 'Total sequencing reads','Successfully aligned reads','Paired-end alignment conflicts eliminated','Alignment failed, no hits (not TCR/IG?)','Alignment failed because of absence of V hits','Alignment failed because of absence of J hits','No target with both V and J alignments','Alignment failed because of low total score','Overlapped','Overlapped and aligned','Alignment-aided overlaps','Overlapped and not aligned','V gene chimeras','J gene chimeras','TRA chains','TRB chains','Final clonotype count','Average number of reads per clonotype','Reads used in clonotypes, percent of total','Reads used in clonotypes before clustering, percent of total','Number of reads used as a core, percent of used','Mapped low quality reads, percent of used','Reads clustered in PCR error correction, percent of used','Reads pre-clustered due to the similar VJC-lists, percent of used','Reads dropped due to the lack of a clone sequence','Reads dropped due to low quality','Reads dropped due to failed mapping','Reads dropped with low quality clones','Clonotypes eliminated by PCR error correction','Clonotypes dropped as low quality','Clonotypes pre-clustered due to the similar VJC-lists' );

# my $id = $ARGV[0]; 	## chomp( ..) return 0 or 1
my $batch = $ARGV[0];
# @sampleID = ($ARGV[1],$ARGV[2],$ARGV[3]);
@VCF = glob "/home/tongqiang/test/${batch}/TCR_MiCXR_stats.report";

foreach my $in (@VCF) {
	chomp $in;
	open IN, $in or die "Cannt open the file $!\n";
	my $flag = 0;
	while(<IN>){
	chomp;
	my @mem = split /\t/,$_;
	if (/^SampleID/){push @sampleID,$mem[1] ; next;};
	my $value = $mem[1];
	$value =~ s/ //g;
	my $key = $mem[0];
	if ($key =~ /TRB chains/){$flag ++;}
	if ($flag < 2){
		$VCF_h{$key}{$in} = $value;
	}
	}
	close IN;
}

my $name;
for (my $i = 0; $i <= $#sampleID; $i ++ ){
	$name .= $sampleID[$i].".";
}
#my $out = $batch."/"."report.TCR-0.".$name."xls";
my $out = "/home/tongqiang/test/${batch}/TCR-seqeucncing.report.xls";

open OUT, "> $out" or die "Cannt write the file $!\n";
print OUT "#####TCR-sequence QC Report#####\nSampelID";
for (my $i = 0; $i <= $#sampleID; $i ++ ){
print OUT "\t$sampleID[$i]";
}
print OUT "\n";

foreach my $title (@ar){
	printf OUT "%s",$title ;
 	foreach my $sampleID(@VCF){
		if ( exists $VCF_h{$title}{$sampleID}){
		printf OUT "\t%s", $VCF_h{$title}{$sampleID};
		}else {
		print OUT "\t";
		}
	}
	print OUT "\n";
}

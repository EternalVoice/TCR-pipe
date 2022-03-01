
my $report=$ARGV[0];
# my $lane;
# if ($report=~/\/(\d+.*?)\//){
#	$lane=$1;
# }
# my $lane=(split /\//,$report)[3];
my $list=(split /_/,$report)[3];
$list=~s/^[A|B|H]//;
open IN,"./Reports/html/$list/all/all/all/lane.html" || die $!;
while(<IN>){
	chomp;
	$_ eq "<th>Mean Quality<br>Score</th>" && last;
}
$/="tr";
print "Lane\tPF Clusters\t%of_lane\t%Perfect_Barcode\t%One_mismatch_barcode\tYield_(Mbase)\t%PF_Clusters\t%Q30_base\tMean_Quality\n";
while(<IN>){
	/<td>/ || next;
	my $line=$_;
	my $print;
	my @a;
	while($line=~/\<td\>(\S+?)\<\/td\>/g){
	push @a,$1
	}
	print join "\t",@a;
	print "\n";
}



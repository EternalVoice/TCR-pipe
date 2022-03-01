
# pwd=/ngs_process/XTEN1-4/181020_E00485_0074_AHNVN5CCXY

# my $report=$ARGV[0];
my $lane=$ARGV[0];
# if ($report=~/\/(\d+.*?)\//){
#	$lane=$1;
# }
# my $lane=(split /\//,$report)[3];
my $list=(split /_/,$lane)[3];
$list=~s/^[A|B]//;
# Reports/html/HNVNGCCXY/all/all/all
open IN,"./Reports/html/$list/all/all/all/laneBarcode.html" || die $!;
while(<IN>){
	chomp;
	$_ eq "<th>Mean Quality<br>Score</th>" && last;
}
$/="tr";
print "Lane\tProject\tSample\tBarcode\tPF_Clusters\t%of_lane\t%Perfect_Barcode\t%One_mismatch_barcode\tYield_(Mbase)\t%PF_Clusters\t%Q30_base\tMean_Quality\n";
while(<IN>){
	/<\/table>/ && last;
	/<td>/ || next;
	my $line=$_;
	my $print;
	my @a;
	while($line=~/\<td\>(\S+?)\<\/td\>/g){
	my $t=$1;
	$t=~s/Undetermined/Undetermined\tNA/;
	push @a,$t;
	}
	print join "\t",@a;
	print "\n";
}



use strict;
use warnings;

my $sampleID=$ARGV[1];
open IN,$ARGV[0] || die;
my $title = <IN>;
chomp $title;
my @title = split /\t/,$title;
my %index_id;
foreach my $id (0..$#title){
	$index_id{$title[$id]} = $id;
	# if ($title[$id] eq "V3Deletion"){
		# $index_id{"V3Deletion"}=$id;
	# }
	# if ($title[$id] eq "VEnd"){
		# $index_id{"VEnd"}=$id;
	# }
	# if ($title[$id] eq "DBegin"){
		# $index_id{"DBegin"}=$id;
	# }
	# if ($title[$id] eq "D5Deletion"){
		# $index_id{"D5Deletion"}=$id;
	# }
	# if ($title[$id] eq "D3Deletion"){
		# $index_id{"D3Deletion"}=$id;
	# }
	# if ($title[$id] eq "DEnd"){
		# $index_id{"DEnd"}=$id;
	# }
	# if ($title[$id] eq "JBegin"){
		# $index_id{"JBegin"}=$id;
	# }
	# if ($title[$id] eq "J5Deletion"){
		# $index_id{"J5Deletion"}=$id;
	# }
	# if ($title[$id] eq "CDR3End"){
		# $index_id{"CDR3End"}=$id;
	# }
	# if ($title[$id] eq "CDR3Begin"){
		# $index_id{"CDR3Begin"}=$id;
	# }
}

my %hash;
my %hash2;
my %hash3;
my %hash4;
while (<IN>){
	s/\r|\n//;
	my @array = split /\t/;
	my $v3del = $array[$index_id{"V3Deletion"}];
	my $d5del = $array[$index_id{"D5Deletion"}];
	my $d3del = $array[$index_id{"D3Deletion"}];
	my $j5del = $array[$index_id{"J5Deletion"}];
	my $vlen = $array[$index_id{"VEnd"}] - $array[$index_id{"CDR3Begin"}];
	my $jlen = $array[$index_id{"CDR3End"}] - $array[$index_id{"JBegin"}];
	
	$hash3{"Vgene"}{$vlen}++;
	$hash3{"Jgene"}{$jlen}++;
	$hash2{"Vgene"}++;
	$hash2{"Jgene"}++;
	if ($array[$index_id{"DEnd"}]){
		my $dlen = $array[$index_id{"DEnd"}]-$array[$index_id{"DBegin"}];
		my $vd_junction = $array[$index_id{"DBegin"}] - $array[$index_id{"VEnd"}];
		my $dj_junction = $array[$index_id{"JBegin"}] - $array[$index_id{"DEnd"}];
		$hash4{"vd_junction"}{$vd_junction}++;
		$hash4{"dj_junction"}{$dj_junction}++;
		$hash3{"Dgene"}{$dlen}++;
		$hash2{"Dgene"}++;
		$hash2{"vd_junction"}++;
		$hash2{"dj_junction"}++;
	}else{
		my $vj_junction = $array[$index_id{"JBegin"}] - $array[$index_id{"VEnd"}];
		$hash4{"vj_junction"}{$vj_junction}++;
		$hash2{"vj_junction"}++;
	}
	$hash{"V3Deletion"}{$v3del}++;
	$hash2{"V3Deletion"}++;
	if ($d5del){
		$hash{"D5Deletion"}{$d5del}++;
		$hash2{"D5Deletion"}++;
	}
	if ($d3del){
		$hash{"D3Deletion"}{$d3del}++;
		$hash2{"D3Deletion"}++;
	}
	
	$hash{"J5Deletion"}{$j5del}++;
	$hash2{"J5Deletion"}++;
#	print "$v3del\t$d5del\t$d3del\t$j5del\n";
}
close IN;
open OUT,"> 6.vdj/$sampleID.vdj_del.txt" || die;
# open (OUT, ">vdj_deletion.txt") or die $!;
print OUT "deletion\tlength\tnum_del\tpercentage\n";
foreach my $key (sort keys %hash){
	foreach my $key2 (sort keys %{$hash{$key}}){
		my $percent = 100*($hash{$key}{$key2})/($hash2{$key});
		print OUT "$key\t$key2\t$hash{$key}{$key2}\t$percent\n";
	}
}
close OUT;
open OUT,"> 6.vdj/$sampleID.vdj_len.txt" || die;
# open (OUT, ">vdj_length.txt") or die $!;
print OUT "gene\tlength\tnum_gene\tpercentage\n";

foreach my $key (sort keys %hash3){
	foreach my $key2 (sort keys %{$hash3{$key}}){
		my $percent = 100*($hash3{$key}{$key2})/($hash2{$key});
		print OUT "$key\t$key2\t$hash3{$key}{$key2}\t$percent\n";
	}
}
close OUT;

open OUT,"> 6.vdj/$sampleID.vdj_junc.txt" || die;
# open (OUT, ">vdj_junction.txt") or die $!;
print OUT "gene\tlength\tnum_gene\tpercentage\n";

foreach my $key (sort keys %hash4){
	foreach my $key2 (sort keys %{$hash4{$key}}){
		my $percent = 100*($hash4{$key}{$key2})/($hash2{$key});
		print OUT "$key\t$key2\t$hash4{$key}{$key2}\t$percent\n";
	}
}
close OUT;

#!/usr/bin/perl
use strict;
use warnings;
use lib qw(/OLD_LIB/home/cxxie/perl_lib/ /OLD_LIB/home/cxxie/perl_lib/Parallel-ForkManager-0.7.5/share/perl5 /OLD_LIB/home/cxxie/perl_lib/Parallel-ForkManager-0.7.5/share/perl5/Parallel);
use Parallel::ForkManager;
use Cwd qw(getcwd); 
use File::Find;
use Getopt::Long;
my ($indir,$infile,$outdir,$threads,$phred,$adapter_sequence,$adapter_sequence_r2,$cut_mean_quality,$cut_window_size,$qualified_quality_phred,$unqualified_percent_limit,$n_base_limit,$length_required,$json,$html);
my $help;
GetOptions(
	'indir|d=s'=>\$indir,
	'infile|f=s'=>\$infile,
	'outdir|o=s'=>\$outdir,
	'phred|ph=s'=>\$phred,
	'adapter_sequence|as=s'=>\$adapter_sequence,
	'adapter_sequence_r2|ar=s'=>\$adapter_sequence_r2,
	'cut_mean_quality|cm=i'=>\$cut_mean_quality,
	'cut_window_size|cw=i'=>\$cut_window_size,
	'qualified_quality_phred|qqp=i'=>\$qualified_quality_phred,
	'unqualified_percent_limit|upl=i'=>\$unqualified_percent_limit,
	'n_base_limit|nbl=i'=>\$n_base_limit,
	'length_required|lr=i'=>\$length_required,
	'threads|t=i'=>\$threads,
	'help|h=s'=>\$help   
);
my $usage=qq^
    Usage:   perl $0 -f infile.txt 
	--indir|-d <string>: input directory, default is current working dircetory
	--infile|-f <string>: the input file with the pathways of sequencing files (e.g. rawdata_list.txt)
	--outdir|-o <string>: output directory, default is QC_result in current working dircetory
	--phred|-ph <string>: phred33
	--adapter_sequence|-as <string>: the adapter for read1.For SE data, if not specified, the adapter will be auto-detected. For PE data, this is used if R1/R2 are found not overlapped
	--adapter_sequence_r2|-ar <string>: the adapter for read2.This is used if R1/R2 are found not overlapped
	--cut_mean_quality|-cm <int>: the bases in the sliding window with mean quality below cutting_quality will be cut, default is 20 (Q20)
	--cut_window_size|-cw <int>: the window size option shared by cut_front, cut_tail or cut_sliding. Range: 1~1000, default: 4
	--qualified_quality_phred|-qqp <int>: the quality value that a base is qualified. Default 15 means phred quality >=Q15 is qualified
	--unqualified_percent_limit|-upl <int>: how many percents of bases are allowed to be unqualified (0~100). Default 40 means 40%
	--n_base_limit|nbl <int>: if one read's number of N base is >n_base_limit, then this read/pair is discarded. Default is 5
	--length_required|-lr <int>: reads shorter than length_required will be discarded, default is 36
	--threads|-t <int>: default is 8
	--help|-h: print this usage message
^
;

my $qcparameter;
if ($help) { die "$usage";}
unless ($infile) {die "erro: please check input file!"}
unless ($indir) {$indir=getcwd;}
unless ($outdir) {$outdir= "$indir/QC";} mkdir $outdir;
print STDOUT "output directory : $outdir\n";
unless ($threads) {$threads= 8;}
if ($phred) {$qcparameter.=" --phred64"; print STDOUT "WARNING : You specified phred64!";}
if ($adapter_sequence) {$qcparameter.=" --adapter_sequence $adapter_sequence";}
if ($adapter_sequence_r2) {$qcparameter.=" --adapter_sequence_r2 $adapter_sequence_r2";}
if ($cut_mean_quality) {$qcparameter.=" -M $cut_mean_quality";} 
if ($cut_window_size) {$qcparameter.=" -W $cut_window_size";} 
if ($qualified_quality_phred) {$qcparameter.=" -q $qualified_quality_phred";} else{$qcparameter.=" -q 15";}
if ($unqualified_percent_limit) {$qcparameter.=" -u $unqualified_percent_limit";} else{$qcparameter.=" -u 40";}
if ($n_base_limit) {$qcparameter.=" -n $n_base_limit";} else{$qcparameter.=" -n 5";}
if ($length_required) {$qcparameter.=" -l $length_required";} else{$qcparameter.=" -l 36";}

open STDERR,">$outdir/QC_erro.txt";
open STDOUT,">$outdir/QC_log.txt";

open IN,$infile or die "cannot open infile!";
open OUT,">$outdir/clean_data_list.txt";

my @seqfile = <IN>;my $one;my $two;my $subproce;
my $MAX_PROCESSES = $threads;
if (@seqfile > $threads ) {$MAX_PROCESSES=@seqfile;$subproce = 1;}
else {$subproce = int($MAX_PROCESSES/@seqfile);}
$qcparameter.= " -w $subproce";

my $pm = Parallel::ForkManager->new($MAX_PROCESSES);my $cmd;my $cleanfile;
foreach my $seqfile (@seqfile) {
	my $pid = $pm->start and next;

	chomp $seqfile;($one,$two)=split/\s+/,$seqfile; 
	my @onepath=split/\//,$one; (my $onename,undef) = split/\./,$onepath[-1];
	my @twopath=split/\//,$two; (my $twoname,undef) = split/\./,$twopath[-1];

	my $cleanone=$onename."_clean_1.fastq.gz";my $cleantwo=$twoname."_clean_2.fastq.gz";$json="$outdir/$onename.json";$html="$outdir/$onename.html";
	if ($two) {
		$cmd="/OLD_LIB/home/xjiao/software/fastp -i $one -o $outdir/$cleanone -I $two -O $outdir/$cleantwo $qcparameter -j $json -h $html";
		$cleanfile= "$outdir/$cleanone  $outdir/$cleantwo";
	}
	else {$cmd="/OLD_LIB/home/xjiao/software/fastp -i $one -o $outdir/$cleanone $qcparameter -j $json -h $html"; $cleanfile= "$outdir/$cleanone";}

		print "runing QC for $onename\n commandline:$cmd\n\n";`$cmd`;sleep(5);
		print OUT "$cleanfile\n";

		
	$pm->finish;
}
$pm->wait_all_children;
print "\n\n\n all QC are finish !\n";

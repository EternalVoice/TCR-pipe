#!/usr/bin/bash

#$ -V
#$ -cwd
#$ -N TCR
#$ -o log_TCR
#$ -j y
#$ -S /bin/bash
#$ -pe smp 8
# set -e

source /home/tongqiang/.bashrc

batch=$1
sampleID=$2
# TYPE=$3
raw=/home/tongqiang/test/$batch/1.raw
# cd & mkdir -p .mixcr/libraries
# cp /OLD_LIB/home/wylou/soft/mixcr-3.0.5/libraries/imgt.202011-3.sv6.json .mixcr/libraries
python=/ngs_share/bioinformatics/projects/scSeq/dependency/conda_packages/bin/python
java=/ngs_share/bioinformatics/software/jdk1.8.0_202/bin/java
mixcr=/OLD_LIB/home/wylou/soft/mixcr-3.0.5/mixcr.jar
vdjtools=/OLD_LIB/home/wylou/soft/vdjtools-1.2.1/vdjtools-1.2.1.jar
Rscript=/ngs_share/bioinformatics/projects/scSeq/dependency/conda_packages/bin/Rscript
Perl_script=/home/tongqiang/pipeline/TCR/perl
R_script=/home/tongqiang/pipeline/TCR/R
python_script=/home/tongqiang/pipeline/TCR/python

if [ "$#" != 2 ];then
    echo "Usage:$0 <batch> <sampleID>"
    exit 1
fi

echo "================= FASTQ cleaning ===================="
time_start=`date "+%Y-%m-%d %H:%M:%S"`
time_start_s=`date +%s`

mkdir -p /home/tongqiang/test/$batch/2.clean
cd /home/tongqiang/test/$batch/2.clean

if [ -f ${sampleID}_clean_1.fastq.gz ];then
    echo "The file $sampleID.clean.fastq.gz has already exists !!!"
else
    cp $raw/${sampleID}*R1*.fastq.gz $sampleID.R1.fastq.gz
    cp $raw/${sampleID}*R2*.fastq.gz $sampleID.R2.fastq.gz
    # ls $raw/${sampleID}*R1*.fastq.gz | tr "\n" " " | xargs -t -I $ batch -c " cat $ > $raw/${sampleID}.R1.fastq.gz"
    # ls $raw/${sampleID}*R2*.fastq.gz | tr "\n" " " | xargs -t -I $ batch -c " cat $ > $raw/${sampleID}.R2.fastq.gz"

    ls ${sampleID}.R{1,2}.fastq.gz |tr "\n" "\t" > inFile.txt
    echo "<<================= Raw Reads Cleaning  ====================>>"
    perl $Perl_script/fastp.jx.pl --cut_window_size 36 --cut_mean_quality 1 --n_base_limit 5 --qualified_quality_phred 15 --unqualified_percent_limit 40 --length_required 36 --infile inFile.txt
    mv QC/*_clean_1.fastq.gz .
    mv QC/*_clean_2.fastq.gz .
    # rm *R1*.fastq.gz *R2*.fastq.gz
fi

time_end=`date "+%Y-%m-%d %H:%M:%S"`
time_end_s=`date +%s`
sumTime=$[ $time_end_s - $time_start_s ]
echo "$time_start ---> $time_end" "Total time consumption: $sumTime seconds"

echo "<<================= MiXCR  ====================>>"
time_start=`date "+%Y-%m-%d %H:%M:%S"`
time_start_s=`date +%s`

mkdir -p /home/tongqiang/test/$batch/{3.align,4.assemble,5.clones,6.vdj,7.geneUsage,8.diversity,9.visualization,vdjtools_fmt,tmp}
cd /home/tongqiang/test/$batch

echo "<====Step1. Align the original sequence to the VDJ gene sequence fragment of the IGH gene====>"
if [ -f 3.align/$sampleID.align.report ];then
    echo "Step1 has already been performed !!!"
else
    $java -Xmx4G -jar $mixcr align -f -s hs -OvParameters.geneFeatureToAlign=VTranscript -t 8 -b imgt.202011-3.sv6 -r 3.align/$sampleID.align.report 2.clean/${sampleID}_clean_1.fastq.gz 2.clean/${sampleID}_clean_2.fastq.gz 3.align/$sampleID.align.vdjca
fi

echo "<<====Step 2. Assemble clonotypes====>>"
$java -Xmx4G -jar $mixcr assemble -f -t 8 -r 4.assemble/$sampleID.assemble.report 3.align/$sampleID.align.vdjca 4.assemble/$sampleID.clones.clns
echo "<<====Step 3. Export clones (human readable)====>>"
echo "all clones contain: TRA, TRB, TRD, TRG, IGH, IGK, IGL"

$java -Xmx4G -jar $mixcr exportClones -f 4.assemble/$sampleID.clones.clns 5.clones/$sampleID.ALL.clones.txt

array=(TRA TRB TRD TRG IGH IGK IGL)
for chain in ${array[@]};
do
{
    echo "export clones for "$chain
    $java -Xmx4G -jar $mixcr exportClones --chains $chain -f 4.assemble/$sampleID.clones.clns 5.clones/$sampleID.$chain.clonotypes.txt
    # OR
    # awk '{if($6 ~/^${chain}/) print}' clones/${sampleID}.clones.txt > clones/${sampleID}.$chain.clonotypes.txt
    echo "success for "$chain
}&
done
wait

time_end=`date "+%Y-%m-%d %H:%M:%S"`
time_end_s=`date +%s`
sumTime=$[ $time_end_s - $time_start_s ]
echo "$time_start ---> $time_end" "Total time consumption: $sumTime seconds"

echo "<<====combine align and assemble reports====>>"
cat 3.align/$sampleID.align.report 4.assemble/$sampleID.assemble.report > $sampleID.MiCXR.report
perl $Perl_script/stats_mixcr.log_v1.pl $sampleID.MiCXR.report $sampleID > TCR_MiCXR_stats.report

echo "<<====filtering VDJ chains====>>"
for chain in ${array[@]};
do
{
    echo "filtering "$chain
    perl $Perl_script/filter.pl 5.clones/$sampleID.$chain.clonotypes.txt > 5.clones/$sampleID.$chain.clonotypes.filt.txt
    echo "Success for "$chain
}&
done
wait

cd /home/tongqiang/test/$batch
echo "<<====Parse CDR3 deletion====>>"
for chain in ${array[@]};
do
{
    echo "Parse CD3R deletion for "$chain
    $python $python_script/parse.cdr3.del.py 5.clones/$sampleID.$chain.clonotypes.filt.txt 5.clones/$sampleID.$chain.cdr3.del.parsed.txt
    echo "success for "$chain
}&
done
wait

echo "<<====extarct VDJ====>>"
for chain in ${arr[@]};
do
{
    echo "extract VDJ for "$chain
    perl $Perl_script/extract_vdj.pl 5.clones/$sampleID.$chain.cdr3.del.parsed.txt $sampleID.$chain
    echo "success for "$chain
}&
done
wait

echo "<<================= Calculate VDJ  ====================>>"
time_start=`date "+%Y-%m-%d %H:%M:%S"`
time_start_s=`date +%s`

for chain in ${arr[@]};
do
{
    echo "Calculate V J gene for "$chain
    cut -f 1,2,6-9,24,33 5.clones/$sampleID.$chain.clonotypes.filt.txt > tmp/$sampleID.$chain.txt
    cut -f 1,2,3 tmp/$sampleID.$chain.txt | cut -d "*" -f 1 > tmp/$sampleID.$chain.tmp
    cut -f 5 tmp/$sampleID.$chain.txt | cut -d "*" -f 1 > tmp/$sampleID.$chain.J_gene.hist
    paste tmp/$sampleID.$chain.tmp tmp/$sampleID.$chain.J_gene.hist >tmp/$sampleID.$chain.V_J_hist
    echo "merge same for "$chain
    perl $Perl_script/merge_same.pl tmp/$sampleID.$chain.V_J_hist > 6.vdj/$sampleID.$chain.V_J_count_3D
    echo "success for "$chain
}&
done
wait

time_end=`date "+%Y-%m-%d %H:%M:%S"`
time_end_s=`date +%s`
sumTime=$[ $time_end_s - $time_start_s ]
echo "$time_start ---> $time_end" "Total time consumption: $sumTime seconds"

echo "<<================= Gene Usage  ====================>>"
time_start=`date "+%Y-%m-%d %H:%M:%S"`
time_start_s=`date +%s`

cd 7.geneUsage/
for chain in ${array[@]};
do
{
    echo "Stat gene usage for "$chain
    perl $Perl_script/stat_gene_usage.pl ../tmp/$sampleID.$chain.txt $sampleID.$chain
    echo "success for "$chain
}&
done
wait

cd ../

time_end=`date "+%Y-%m-%d %H:%M:%S"`
time_end_s=`date +%s`
sumTime=$[ $time_end_s - $time_start_s ]
echo "$time_start ---> $time_end" "Total time consumption: $sumTime seconds"

echo "<<================= Visualization  ====================>>"
time_start=`date "+%Y-%m-%d %H:%M:%S"`
time_start_s=`date +%s`

source activate R3.6.3
for chain in ${array[@]};
do
{
    echo "visualization for "$chain
    $Rscript $R_script/picture.r $sampleID.$chain
    echo "success for "$chain
}&
done
wait

time_end=`date "+%Y-%m-%d %H:%M:%S"`
time_end_s=`date +%s`
sumTime=$[ $time_end_s - $time_start_s ]
echo "$time_start ---> $time_end" "Total time consumption: $sumTime seconds"


time_start=`date "+%Y-%m-%d %H:%M:%S"`
time_start_s=`date +%s`

for chain in ${array[@]};
do
{
    echo "Run step for "$chain
    echo "===>>> Stage expand medium small AA clonotypes <<<=== "
    perl $Perl_script/stat_AA_pct_stage.pl 7.geneUsage/$sampleID.$chain.all_CDR3_AA.counts.percent.txt $sampleID > 5.clones/$sampleID.$chain.stage_expand_medium_small.pct.txt
    echo "===>>> Convert file format to vdjtools <<<==="
    $java -Xmx4G -jar $vdjtools Convert -S mixcr 5.clones/$sampleID.$chain.cdr3.del.parsed.txt vdjtools_fmt/vdjtools_fmt
    echo "===>>> change percentage after filter clonotypes without functions <<<==="
    $java -Xmx4G -jar $vdjtools FilterNonFunctional vdjtools_fmt/vdjtools_fmt.$sampleID.$chain.cdr3.del.parsed.txt vdjtools_fmt/ChangePct
    echo "===>>> Diversity Estimation <<<===" 
    $Rscript $R_script/diversity.r $sampleID.$chain

    echo "====>>>> Data visualization <<<<===="
    echo "===>> clonotype population structure <<==="
    $java -Xmx4G -jar $vdjtools PlotQuantileStats -t 5 vdjtools_fmt/ChangePct.vdjtools_fmt.$sampleID.$chain.cdr3.del.parsed.txt  9.visualization/$sampleID.$chain.QuantileStats.clonetypes
    echo "<<===== Top10 CDR3aa on CDR3aa length <<===="
    $java -Xmx4G -jar $vdjtools PlotFancySpectratype -t 10 vdjtools_fmt/ChangePct.vdjtools_fmt.$sampleID.$chain.cdr3.del.parsed.txt 9.visualization/$sampleID.$chain.FancySpectra_CDR3aa
    echo "=====>> Top12 V genes on CDR3aa length <<===="
    $java -Xmx4G -jar $vdjtools PlotSpectratypeV -t 12 vdjtools_fmt/ChangePct.vdjtools_fmt.$sampleID.$chain.cdr3.del.parsed.txt 9.visualization/$sampleID.$chain.Spectra_typeV
    echo "=====>> circos plot for VJ usage <<===="
    $java -Xmx4G -jar $vdjtools PlotFancyVJUsage --unweighted vdjtools_fmt/vdjtools_fmt.$sampleID.$chain.cdr3.del.parsed.txt 9.visualization/$sampleID.$chain.FrancyUsage_VJCircle
    echo "success for  "$chain
}&
done
wait

time_end=`date "+%Y-%m-%d %H:%M:%S"`
time_end_s=`date +%s`
sumTime=$[ $time_end_s - $time_start_s ]
echo "$time_start ---> $time_end" "Total Time Consumption:$sumTime seconds"


echo "<<====================================== EXTENSION ====================================>>"

echo "============================ alignment ======================"
echo "keep orignal reads in clonesAndAlignment.vdjca during alignment step"
$java -jar $mixcr align --species hs -OmaxHits=3 -OsaveOriginalReads=true 2.clean/${sampleID}_clean_1.fastq.gz 2.clean/${sampleID}_clean_2.fastq.gz 3.align/$sampleID.clonesAndAlignments.vdjca

echo "============================ assemble ========================"
$java -jar $mixcr assemble --write-alignments -a 3.align/$sampleID.clonesAndAlignments.vdjca 4.assemble/$sampleID.clonesAndAlignment_assembled.clna
echo "============================ extarct clones1.fq ========================"
$java -jar $mixcr exportReadsForClones --id 1 4.assemble/$sampleID.clonesAndAlignment_assembled.clna 2.clean/$sampleID.ReadsForClone1.fastq.gz

echo "========= Obtain paired-end reads aligment results and annotation information ========="
## alignment pair-reads to VDJC (两种形式) --skip 1000 略过比对上的前1000个 --limit 10 只输出10个
$java -jar $mixcr exportAlignmentsPretty 3.align/$sampleID.clonesAndAlignments.vdjca 3.align/$sampleID.aligned.txt
$java -jar $mixcr exportAlignmentsPretty --verbose 3.align/$sampleID.clonesAndAlignments.vdjca 3.align/$sampleID.aligned_verbose.txt

echo "========= Obtain full-length VDJ sequences of TCR and BCR (3 CDR + 4 FR (framework region)) ========="
echo "---Assemble complete clonotypes (complement sqeuences that are not aligned in other regions)---"
$java -jar $mixcr assembleContigs -t 8 -r 4.assemble/$sampleID.full_len_assembled_contigs.report 5.clones/$sampleID.clonesAndAlignment_assembled.clna 5.clones/$sampleID.full_len_clones.clns
$java -jar $mixcr exportClones -c TRB -p fullImputed -f 5.clones/$sampleID.full_len_clones.clns 5.clones/$sampleID.full_len_clones.txt

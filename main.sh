#!/usr/bin/bash

#$ -V
#$ -cwd
#$ -N bcl_tcr
#$ -o log_bcl.tcr
#$ -j y
#$ -S /bin/bash
#$ -pe smp 8
# # set -e

source ~/.bashrc
samplesheet=$1
batch=`echo $samplesheet | awk -F "/" '{print $NF}' | awk -F ".csv" '{print $1}'`

Perl_script=/home/tongqiang/pipeline/TCR/perl
shell=/home/tongqiang/pipeline/TCR/shell

echo "-------- Run Step1 ---------------"
bash $shell/auto_out_tcr.sh $samplesheet

echo "-------- Run Step2 ---------------"
cat $samplesheet | sed -n '/Lane,Sample_ID,Sample_Name/,+1000p' | sed 1d | cut -d ',' -f2 | sed 's/-1//g' | while read id;
do
{
    sleep 1     # 模仿执行一条命令需要花费的时间
    bash $shell/TCR.dna_rna.v1.sh $batch $id
    echo "success "$id;
}&

# 用{}包循环体括起来，后加一个&符号，代表每次循环都把命令放入后台运行，
# 一旦放入后台，就意味着里面的命令交给操作系统的一个线程处理了
# 循环1000次，就有1000个&将任务放入后台，操作系统会并发1000个线程来处理


done
wait        #wait命令表示等待上面的命令(放入后台的任务)都执行完毕了再往下执行


echo "================= Q30 ===================="
perl $Perl_script/q30.pl $/home/tongqiang/test/$batch/1.raw/statistics/all_ID.list $batch > /home/tongqiang/test/$batch/2.clean/q30.xls

echo "-------- Run Step3 ---------------"
perl $Perl_script/merge.mixcr.TCR_report.pl $batch

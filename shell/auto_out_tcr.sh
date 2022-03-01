#!/usr/bin/bash

time_start=`date "+%Y-%m-%d %H:%M:%S"`
time_start_s=`date +%s`

## For samplesheet.csv change Sample_ID and Sample_Name
# perl -ne 'if (^[0-9],/){@ar=split/,/; $str=$ar[2]; $ar[2]=$ar[1]; $ar[1]=$str; for(@ar) {if(/\n/) {print $_} else {print"$_,"}}}else{print $_}' file.csv
## For sampleID need numbered
# perl -ne 'if (/^[0-9],/){@ar=split/,/; $n++;$ar[1].= "_$n";for(@ar){if(/\n/){print $_}else{print"$_,"}}}else{print $_}' file.csv

Perl_script=/home/tongqiang/pipeline/TCR/perl
bcl2fastq=/soft/bcl2fastq2-v2.17.1.14/bin/bcl2fastq
if [ "$#" != 1 ];then
    echo "Usage:$0 <samplesheet.csv>"
    exit 1
else
    samplesheet=$1
    ss=`echo $samplesheet | awk -F "/" '{print $NF}' | awk -F ".csv" '{print $1}'`
    bcl=/ngs_raw/*/$ss
    mkdir -p /home/tongqiang/test/$ss/1.raw/statistics
    wkd=/home/tongqiang/test/$ss/1.raw
    cd $wkd
    if [ -f $ss.new ];then
        echo "modified samplesheet has already been created !!!"
    else
        sed 's#|#,#g' $samplesheet | sed  's#index,#index,index2,#g'| perl -ne 'my @a = split /,/,$_; if (/^\d,/){$a[1] =~ s/\-\d//g ; my @b = join",",@a ; print @b }else{print}' | perl -ne 'if (/^[0-9],/){@ar=split/,/;$str=$ar[2];$ar[2]=$ar[1];$ar[1]=$str;for(@ar){if(/\n/){print $_}else{print"$_,"}}}else{print $_}' -  > $ss.new
    fi


if [ ! -f ${bcl}/RTAComplete.txt ];then
    echo "BCL file is not ready yet !!!"
else
    if [ -f bcl2fastqComplete ];then
        echo "bcltofastq has already been performed !!!"
    else
        $bcl2fastq --barcode-mismatches 1 --mask-short-adapter-reads 22 -R $bcl --sample-sheet $ss.new -o ./
        ls *.fastq.gz | xargs -P 5 -I % bash -c "md5sum % >> md5.txt" bash
        perl $Perl_script/stat_lane.pl $ss > statistics/lane.xls
        perl $Perl_script/stat_barcode.pl $ss > statistics/barcode.xls
        ls -lh *.gz | grep -v "Undetermined" | awk '{print $9"\t"$5}' > statistics/s_size.txt
        grep -v 'Undetermined' md5.txt |sort -k2 > statistics/md5.0.txt
        grep -v 'Undetermined' statistics/barcode.xls > statistics/data_stats.xls
        touch bcl2fastqComplete
    fi
fi

fi

grep -P -e "^\d," $samplesheet | cut -d "," -f 2 | perl -pe 's/[-_]\d+$//g' | sort | uniq > statistics/all_ID.list

time_end=`date "+%Y-%m-%d %H:%M:%S"`
time_end_s=`date +%s`
sumTime=$[ $time_end_s - $time_start_s ]
echo "$time_start ---> $time_end" "Total time consumption: $sumTime seconds"
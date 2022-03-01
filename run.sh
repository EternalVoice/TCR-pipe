#!/bin/bash

batchlist=/home/tongqiang/test/*.csv
main=/home/tongqiang/pipeline/TCR/main.sh
ls $batchlist | while read id;
do
    bash $main $id
done

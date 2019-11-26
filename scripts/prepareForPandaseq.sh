#!/bin/bash

read_1=${1}
read_2=${2}


gunzip $read_1 $read_2

sample=${read_1::-40}
sample_name="${sample##*_}"

echo "my sample is:	" $sample
echo "my sample_name is:	" $sample_name


sample_file_1=${read_1::-3}
sample_file_2=${read_2::-3}
echo "my sample_file_1 is called:	" $sample_file_1



sed -i "s/$sample_name/ERR101/g"  "$sample_file_1"
sed -i "s/$sample_name/ERR101/g"  "$sample_file_2" 



gzip $sample_file_1 $sample_file_2

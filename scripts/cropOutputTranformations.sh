#!/bin/bash

mkdir abundances

cp CROP_output.cluster.list abundances

path=$(pwd)

cd $path/abundances/

sed -i 's/\t/,/g' CROP_output.cluster.list
split -l 1 CROP_output.cluster.list

rm CROP_output.cluster.list

for filename in $path/abundances/x*; do echo $COUNTER ; sed 's/,/\n/g' $filename | sed  's/.*=//g' > $filename.abundances ; awk '{s+=$1} END {print s}' $filename.abundances > $filename.size; rm $filename.abundances $filename ; COUNTER=$[$COUNTER +1]; done

cat x* > abundances.txt
rm x*
mv abundances.txt ../
cd ..
rm -r abundances


tail -n +2 CROP_output.cluster > CROP_output.cluster_2


paste CROP_output.cluster_2 abundances.txt > test

rm CROP_output.cluster_2


awk '{print $2 "\t" $NF "\t" $1}' test | sed 's/;size=/\t/g' > SWARM.stats

rm test


cp CROP_output.cluster.list SWARM.swarms
sed -i 's/\t/ /g; s/;size=/_/g; s/,/ /g' SWARM.swarms

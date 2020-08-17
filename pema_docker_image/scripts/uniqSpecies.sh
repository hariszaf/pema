#!/bin/bash

sed 's/1\./10/g; s/0\.//g' tax_assign_swarm_COI.txt > temp.txt

#awk '{for(i = 1 ; i <= NF ; i++) {if ($i ~ /^[0-9]+$/ && $i <= 97) { next }}} 1'  < temp.txt > lesna.txt

awk '{for(i = 1 ; i <= NF ; i++) {
if ($i ~ /^[0-9]+$/ && $i < 97) { next };
     }
} 1'  < temp.txt > lesna.txt


awk '{n = 4; for (--n; n >= 0; n--){ printf "%s\t",$(NF-n)} print ""}' lesna.txt > almost.txt

awk '{NF-=2}1' almost.txt > species.txt

cat species.txt | sort | uniq | sort > uniq_species.txt

rm temp.txt lesna.txt almost.txt species.txt

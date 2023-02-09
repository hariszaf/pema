#!/usr/bin/env python
import sys
otu_table_file = sys.argv[1]
otu_table      = open(otu_table_file, "r")
new_otu_table  = open("no_oligotons.tsv", "w")
threshold      = int(sys.argv[2])


asvs = otu_table.readlines()

def pairwise(iterable):
    a = iter(iterable)
    return zip(a, a)

for x, y in pairwise(asvs):

    if x[0] == ">":
        abundance = int(x.split("_")[1])
        if abundance > threshold:
            new_otu_table.write(x)
            new_otu_table.write(y)



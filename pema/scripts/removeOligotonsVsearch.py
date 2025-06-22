#!/usr/bin/env python
import sys
otu_table_file   = sys.argv[1]
otu_table           = open(otu_table_file, "r")
new_otu_table = open("no-singl-allTab.tsv", "w")
fasta_file           = sys.argv[2]
fasta_file           = open(fasta_file, "r")
new_fasta_file = open("no-singl-allSquences.fa", "w")
threshold           = int(sys.argv[3])

otus_to_remove = []
counter = 0 
for line in otu_table: 
    counter += 1
    if counter == 1:
        new_otu_table.write(line)
        continue
    otu_id             = line.split("\t")[0]

    abundances = line.split("\t")[1:]
    otu_total = 0
    for case in abundances:
        otu_total += int(case)
    if otu_total < threshold: 
        otus_to_remove.append(otu_id)
    else:
        new_otu_table.write(line)

fasta = fasta_file.readlines()
for otu, sequence in zip(fasta[::2], fasta[1::2]):
    otu_id = otu[1:-1]
    if  otu_id not in otus_to_remove:
        new_fasta_file.write(otu)
        new_fasta_file.write(sequence)

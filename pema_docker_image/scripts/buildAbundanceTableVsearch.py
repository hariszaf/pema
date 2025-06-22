import sys
import json
import pandas as pd

all_samples      = sys.argv[1]   # all_samples.fasta
all_otus         = sys.argv[2]  # all.otus.fasta
contigency_table = sys.argv[3]  # amplicon_contingency_table.tsv


with open(all_samples, 'r') as f:
    lines = f.readlines()

map = {}
for i in range(0, len(lines), 2):
    line1 = lines[i].strip()
    line2 = lines[i + 1].strip() if i + 1 < len(lines) else ''
    id = line1.split(";")[0].split(">")[-1]
    map[id] = line2

reverse_map = {v: k for k, v in map.items()}
to_keep = set()

with open(all_otus, 'r') as f:
    lines = f.readlines()
random2seqId = {}
for i in range(0, len(lines), 2):
    seq_id = lines[i].strip().split(">")[-1]
    seq    = lines[i + 1].strip() if i + 1 < len(lines) else ''
    if seq in reverse_map:
        to_keep.add(reverse_map[seq])
        random2seqId[reverse_map[seq]] = seq_id


df = pd.read_csv(contigency_table, sep="\t", index_col=0)
df.columns = df.columns.str.replace('.merged.linearized.dereplicated.fa', '', regex=False)
df = df.drop(columns=['total'])

filtered_df = df.loc[df.index.isin(to_keep)]
filtered_df.to_csv("all.otutab_sha.txt", sep="\t")

filtered_df.index = filtered_df.index.map(random2seqId)
filtered_df.to_csv("all.otutab.txt", sep="\t")

with open("map.json", "w") as f:
    json.dump(random2seqId, f)

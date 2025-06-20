# Builds an abundance table with a Taxonomy column based on Crest4 findinigs

import os
import sys
import pandas as pd

abd_table         = sys.argv[1]
crest_assignments = sys.argv[2]

df = pd.read_csv(abd_table, sep="\t")
columns = df.columns
columns = [x.split(".")[0] for x in columns]
df.columns = columns

tax = pd.read_csv(crest_assignments, header=None, sep="\t")
tax.columns = ["ASV", "Taxonomy"]

df = df.merge(tax[["ASV", "Taxonomy"]], on="ASV", how="left")

# crest_search      = sys.argv[3]
# hits = pd.read_csv(crest_search, sep="\t", header=None)
# hits = hits.iloc[:, :3]
# hits.columns = ["ASV", "ID", "Value"]

outfile = os.path.dirname(crest_assignments)
outfile += "/finalTable.tsv"
df.to_csv(outfile, sep="\t", index=False)

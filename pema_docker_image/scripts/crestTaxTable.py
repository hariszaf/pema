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

# Based on wheather Swarm or VSEARCH was used, we may have ASV or OTUs
id_col = "ASV" if "ASV" in df.columns else "#OTU ID" if "#OTU ID" in df.columns else None

if id_col is None:
    raise ValueError("Neither 'ASV' nor '#OTU ID' found in df.columns")

# Rename the column to 'ASV' temporarily for the merge
df = df.rename(columns={id_col: "ASV"})

# Load taxonomy table
tax = pd.read_csv(crest_assignments, header=None, sep="\t")
tax.columns = ["ASV", "Taxonomy"]

# Merge
df = df.merge(tax[["ASV", "Taxonomy"]], on="ASV", how="left")

# Rename back to original
df = df.rename(columns={"ASV": id_col})

# Save outfile
outfile = os.path.dirname(crest_assignments)
outfile += "/finalTable.tsv"
df.to_csv(outfile, sep="\t", index=False)

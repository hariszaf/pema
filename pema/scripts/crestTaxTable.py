#!/usr/bin/env python3

# Builds an abundance table with a Taxonomy column based on Crest4 findinigs

import os
import sys
import pandas as pd
from pathlib import Path

input_file        = sys.argv[1]  # Abundance table (allTab.tsv) or (asvs_contingency_hash.tsv)
crest_assignments = sys.argv[2]  # Taxonomy assignments from CREST (assignments.txt)
clustering_algo   = sys.argv[3]  # "swarm" or "vsearch"

main_dir        = Path(input_file).parent.absolute()
assignments_dir = Path(crest_assignments).parent.absolute()


# input_file is the abd_table in the vsearch case, and the asvs_contingency_hash in the swarm case
df = pd.read_csv(input_file, sep="\t")


columns    = df.columns
columns    = [x.split(".")[0] for x in columns]
df.columns = columns

# Based on wheather Swarm (ASC) or VSEARCH ("#OTU ID") was used, we may have ASV or OTUs
id_col = "ASV" if "ASV" in df.columns else "amplicon" if "amplicon" in df.columns else None

if id_col is None:
    raise ValueError("Neither 'ASV' nor '#OTU ID' found in df.columns")

# Load taxonomy table
tax = pd.read_csv(crest_assignments, header=None, sep="\t")

if clustering_algo == "swarm":

    # Fix column names as in the hash table
    tax.columns = ["Seed", "Taxonomy"]

    # Merge
    df = df.merge(tax[["Seed", "Taxonomy"]], on="Seed", how="left")

    # Drop seed column
    df = df.drop(columns=["Seed"])

else:

    # Fix column names as in the allTab table
    tax.columns = ["amplicon", "Taxonomy"]

    # Merge
    df = df.merge(tax[["amplicon", "Taxonomy"]], on="amplicon", how="left")

    # Renaame
    df = df.rename(columns={"amplicon": "OTU"})

# Save outfile
outfile = assignments_dir / "finalTable.tsv"
df.to_csv(outfile, sep="\t", index=False)

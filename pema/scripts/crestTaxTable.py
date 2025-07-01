# Builds an abundance table with a Taxonomy column based on Crest4 findinigs

import os
import sys
import pandas as pd
from pathlib import Path

abd_table         = sys.argv[1]
crest_assignments = sys.argv[2]

main_dir        = Path(abd_table).parent.absolute()
assignments_dir = Path(crest_assignments).parent.absolute()

hash_table = main_dir / "asvs_contingency_hash.tsv"
# Abunddance table with both ASV id and hash
df         = pd.read_csv(hash_table, sep="\t")


#     # Hash abundance table
#     df         = pd.read_csv(abd_table, sep="\t")

columns    = df.columns
columns    = [x.split(".")[0] for x in columns]
df.columns = columns

# Based on wheather Swarm (ASC) or VSEARCH ("#OTU ID") was used, we may have ASV or OTUs
id_col = "ASV" if "ASV" in df.columns else "amplicon" if "amplicon" in df.columns else None

if id_col is None:
    raise ValueError("Neither 'ASV' nor '#OTU ID' found in df.columns")

# Rename the column to 'ASV' temporarily for the merge
df = df.rename(columns={id_col: "ASV"})

# Load taxonomy table
tax         = pd.read_csv(crest_assignments, header=None, sep="\t")
tax.columns = ["Seed", "Taxonomy"]

# Merge
df = df.merge(tax[["Seed", "Taxonomy"]], on="Seed", how="left")

# Rename back to original
df = df.rename(columns={"ASV": id_col})

# Drop seed column
df = df.drop(columns=["Seed"])

# Save outfile
outfile = assignments_dir / "finalTable.tsv"
df.to_csv(outfile, sep="\t", index=False)

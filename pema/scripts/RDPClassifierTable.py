import sys
import json
import pandas as pd
from pathlib import Path

# contingency_table = sys.argv[1]  # contingency_table = "asvs_contingency_hash.tsv"
clustering_algo   = sys.argv[1]

tax_assignments = "tax_assignments.tsv"
assignments_dir = Path(tax_assignments).parent.absolute()

tax_df      = pd.read_csv(tax_assignments, sep="\t", header=None)
tax_columns = [x for x in tax_df.columns[1::3]]
tax_df      = tax_df[[0] + tax_columns]
tax_df      = tax_df.copy()

tax_df['merged'] = tax_df.iloc[:, 1:].agg(';'.join, axis=1)
tax_df.drop(tax_df.columns[1:-1], axis=1, inplace=True)

# TODO (Haris Zafeiropoulos, 2025-07-02):  Filter based on confidence score
if clustering_algo == "vsearch":

    # Vsearch case of the taxonomy file
    tax_df.columns = ["OTU", "Taxonomy"]

    # Filename of the contigency table on the vsearch case
    contingency_table = "all.otutab_sha.txt"

    # Abundance data
    abd_df         = pd.read_csv(contingency_table, sep="\t")
    abd_df         = abd_df.rename(columns={"amplicon":"Seed"})
    abd_df.columns = [x.replace(".derep.fa", "") for x in abd_df.columns]

    # In the vsearch case, we keep the mapping of each hash to their corresponding otu
    # in a json file
    otu_hash = "map.json"
    with open(otu_hash, "r") as f:
        otu_hash_dict = json.load(f)

    abd_df.insert(0, 'OTU', abd_df['Seed'].map(otu_hash_dict))

    print(abd_df.head())

    print(tax_df.head())

    # Merge
    abd_df = abd_df.merge(tax_df[["OTU", "Taxonomy"]], on="OTU", how="left")
    abd_df = abd_df.drop(columns=["Seed"])


elif clustering_algo == "swarm":

    tax_df.columns = ["Seed", "Taxonomy"]

    contingency_table = "asvs_contingency_hash.tsv"

    # Abundance data
    abd_df         = pd.read_csv(contingency_table, sep="\t")
    abd_df.columns = [x.replace(".derep.fa", "") for x in abd_df.columns]

    # Merge
    abd_df = abd_df.merge(tax_df[["Seed", "Taxonomy"]], on="Seed", how="left")
    abd_df = abd_df.drop(columns=["Seed"])


# Save outfile
outfile = assignments_dir / "finalTable.tsv"
abd_df.to_csv(outfile, sep="\t", index=False)

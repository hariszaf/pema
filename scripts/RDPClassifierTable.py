import sys
# import json
import pandas as pd
from pathlib import Path
from utilsForTables import load_vseach_hash, load_swarm_hash


# contingency_table = sys.argv[1]  # contingency_table = "asvs_contingency_hash.tsv"
clustering_algo   = sys.argv[1]

tax_assignments = "tax_assignments.tsv"
tax_df      = pd.read_csv(tax_assignments, sep="\t", header=None)
tax_columns = [x for x in tax_df.columns[1::3]]
tax_df      = tax_df[[0] + tax_columns]
tax_df      = tax_df.copy()

# TODO (Haris Zafeiropoulos, 2025-07-02):  Filter based on confidence score
tax_df['merged'] = tax_df.iloc[:, 1:].apply(
    lambda row: ';'.join([str(x) if pd.notna(x) else '' for x in row]).rstrip(';'),
    axis=1
)  # There is the case where a column would be NaN, so we do this so it does not fail
# This for example would build 'Eukaryota;Myzostomida;Myzostoma;Myzostoma seymourcollegiorum'

# Drop float columns
tax_df.drop(tax_df.columns[1:-1], axis=1, inplace=True)

# Get working dir
assignments_dir = Path(tax_assignments).parent.absolute()

if clustering_algo == "vsearch":

    abd_df = load_vseach_hash(tax_df, assignments_dir)

elif clustering_algo == "swarm":

    abd_df = load_swarm_hash(tax_df, assignments_dir)

# Save outfile
outfile = assignments_dir / "tax_assigned_table.tsv"
abd_df.to_csv(outfile, sep="\t", index=False)

#!/usr/bin/env python3
"""
Assign taxonomy from CREST to OTU/ASV abundance tables.
"""

import argparse
from pathlib import Path
import pandas as pd

def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--otu-abundance-table", type=Path, help="Abundance table (e.g., allTab.tsv)")
    parser.add_argument("--asvs-hash", type=Path, help="ASV contingency hash table (asvs_contingency_hash.tsv)")
    parser.add_argument(
        "--crest-assignments",
        type=Path, required=True, help="Taxonomy assignments from CREST (assignments.txt)")
    parser.add_argument(
        "--clustering-algo", type=str, choices=["swarm", "vsearch"],
        required=True, help="Clustering algorithm used: 'swarm' or 'vsearch'"
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output")
    return parser.parse_args()

def find_id_column(df):
    return next((col for col in ["ASV", "amplicon", "#OTU ID"] if col in df.columns), None)

def load_and_merge(input_file, crest_file, clustering_algo):
    df     = pd.read_csv(input_file, sep="\t")
    id_col = find_id_column(df)
    if id_col is None:
        raise ValueError("Neither 'ASV', 'amplicon', nor '#OTU ID' found in input columns.")

    tax = pd.read_csv(crest_file, header=None, sep="\t")

    if clustering_algo == "swarm":
        tax.columns = ["Seed", "Taxonomy"]
        df = df.merge(tax[["Seed", "Taxonomy"]], on="Seed", how="left")
        df = df.drop(columns=["Seed"])

    else:
        tax.columns = ["amplicon", "Taxonomy"]
        df = df.merge(
            tax,
            left_on="amplicon",
            right_on="amplicon",
            how="left"
        ).rename(columns={"amplicon": "OTU"})

    return df


def main():

    args       = parse_args()
    input_file = (args.otu_abundance_table or args.asvs_hash)

    if input_file is None:
        raise ValueError("You must provide either --otu-abundance-table or --asvs-hash")

    input_file        = input_file.resolve()
    crest_assignments = args.crest_assignments.resolve()

    if args.verbose:
        print(f"Input file: {input_file}")
        print(f"CREST assignments: {crest_assignments}")
        print(f"Clustering algorithm: {args.clustering_algo}")

    df = load_and_merge(input_file, crest_assignments, args.clustering_algo)

    outfile = "tax_assigned_table.tsv"
    df.to_csv(outfile, sep="\t", index=False)

    if args.verbose:
        print(f"Taxonomy assigned table saved to: {outfile}")

if __name__ == "__main__":
    main()

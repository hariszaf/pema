#!/usr/bin/env python3
"""
Build the ASV taxonomy table from RDPClassifier assignments.

RDPClassifier (default output format) writes one line per sequence:
    <id> TAB <strand> TAB <name> TAB <rank> TAB <confidence> TAB <name> TAB <rank> TAB <confidence> ...
starting from the root. Ranks are kept from the top down while their confidence is at least
the threshold; sequences with no rank above it get the taxonomy "Unassigned".

Output: tax_assigned_table.tsv with the ASV, its abundance in each sample and its taxonomy,
in the same format as the CREST taxonomy table.
"""

import argparse
import re
from pathlib import Path

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--asvs-hash", type=Path, required=True,
                        help="ASV contingency hash table (asvs_contingency_hash.tsv)")
    parser.add_argument("--rdp-assignments", type=Path, required=True,
                        help="RDPClassifier output (default format)")
    parser.add_argument("--confidence", type=float, default=0.8,
                        help="Minimum confidence for a rank to be kept (0 keeps all ranks; default: 0.8)")
    parser.add_argument("--output", type=Path, default=Path("tax_assigned_table.tsv"))
    return parser.parse_args()


def clean_name(name):
    """Drop a rank prefix such as 'sk__' or 'g__', and use spaces instead of underscores
    (e.g. 's__Navicula_minima' -> 'Navicula minima'), as in NCBI Taxonomy names."""
    return re.sub(r"^[a-z]{1,3}__", "", name).replace("_", " ")


def rdp_taxonomy(fields, confidence):
    """Lineage from the (name, rank, confidence) triples of an RDP output line.

    The first triple is the root of the database (e.g. Root, r__cellularOrganisms) and is skipped,
    as are placeholder ranks (e.g. k__undef_Eukaryota), whose confidence still counts.
    """
    names = []
    for i in range(3, len(fields) - 2, 3):
        name, conf = clean_name(fields[i]), float(fields[i + 2])
        if conf < confidence:
            break
        if not name.startswith("undef "):
            names.append(name)
    return "; ".join(names) if names else "Unassigned"


def load_assignments(path, confidence):
    rows = []
    with open(path) as f:
        for line in f:
            fields = line.rstrip("\n").split("\t")
            if len(fields) < 5:
                continue
            # fields[1] is the strand ("-" when the sequence was reversed)
            rows.append((fields[0], rdp_taxonomy(fields[2:], confidence)))
    return pd.DataFrame(rows, columns=["Seed", "Taxonomy"])


def main():
    args = parse_args()

    asvs = pd.read_csv(args.asvs_hash, sep="\t")
    tax  = load_assignments(args.rdp_assignments, args.confidence)

    table = asvs.merge(tax, on="Seed", how="left").drop(columns=["Seed"])
    table["Taxonomy"] = table["Taxonomy"].fillna("Unassigned")
    table.to_csv(args.output, sep="\t", index=False)


if __name__ == "__main__":
    main()

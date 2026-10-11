#!/usr/bin/env python3
"""
Build the OTU contingency tables from the VSEARCH clustering.

Each amplicon is assigned to the OTU of its centroid, using the .uc file of the clustering
(S records: centroids, H records: amplicon -> centroid), and its abundance in each sample
(from the amplicon contingency table) is added to the OTU. OTUs are named OTU_1, OTU_2, ...
by decreasing total abundance.

Outputs, in the same format as for the Swarm ASVs:
    otus_contingency_hash.tsv    OTU, Seed (hash of the centroid), abundance per sample
    otus_contingency_table.tsv   OTU, abundance per sample
    otus_representatives.fa      centroid sequence of each OTU, named by its hash
"""

import argparse

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--uc", required=True, help="VSEARCH .uc file of the OTU clustering")
    parser.add_argument("--centroids", required=True, help="Centroids fasta of the OTU clustering")
    parser.add_argument("--amplicon-table", required=True, help="Amplicon contingency table (amplicon_contingency_table.tsv)")
    return parser.parse_args()


def label(field):
    """Amplicon hash from a VSEARCH label such as 'hash;size=12'."""
    return field.split(";")[0]


def read_uc(path):
    """amplicon hash -> centroid hash"""
    centroid_of = {}
    with open(path) as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 10:
                continue
            if cols[0] == "S":
                centroid_of[label(cols[8])] = label(cols[8])
            elif cols[0] == "H":
                centroid_of[label(cols[8])] = label(cols[9])
    return centroid_of


def read_fasta(path):
    seqs, name, chunks = {}, None, []
    with open(path) as f:
        for line in f:
            line = line.rstrip()
            if line.startswith(">"):
                if name is not None:
                    seqs[name] = "".join(chunks)
                name, chunks = label(line[1:]), []
            elif line:
                chunks.append(line)
    if name is not None:
        seqs[name] = "".join(chunks)
    return seqs


def main():
    args = parse_args()

    centroid_of = read_uc(args.uc)
    centroids   = read_fasta(args.centroids)

    amplicons = pd.read_csv(args.amplicon_table, sep="\t", index_col=0)
    amplicons = amplicons.drop(columns=["total"], errors="ignore")

    # Amplicons not in the clustering (oligotons, chimeras) are left out
    kept = amplicons.loc[amplicons.index.isin(centroid_of.keys())]
    otus = kept.groupby(kept.index.map(centroid_of)).sum()

    missing = set(otus.index) - set(centroids)
    if missing:
        raise SystemExit(f"{len(missing)} OTU centroids are missing from {args.centroids}")

    # Name the OTUs by decreasing total abundance
    otus = otus.loc[otus.sum(axis=1).sort_values(ascending=False, kind="stable").index]
    otus.index.name = "Seed"
    otus = otus.reset_index()
    otus.insert(0, "OTU", [f"OTU_{i}" for i in range(1, len(otus) + 1)])

    otus.to_csv("otus_contingency_hash.tsv", sep="\t", index=False)
    otus.drop(columns=["Seed"]).to_csv("otus_contingency_table.tsv", sep="\t", index=False)

    with open("otus_representatives.fa", "w") as out:
        for seed in otus["Seed"]:
            out.write(f">{seed}\n{centroids[seed]}\n")


if __name__ == "__main__":
    main()

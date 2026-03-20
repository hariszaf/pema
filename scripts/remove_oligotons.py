#!/usr/bin/env python3

import argparse
from pathlib import Path
import pandas as pd
import shutil


# --------------------------------------------------
# CLI
# --------------------------------------------------
def parse_args():
    parser = argparse.ArgumentParser(
        description="Filter clusters based on abundance threshold"
    )
    parser.add_argument("--stats", type=Path,
                        help="stats file (swarm)")
    parser.add_argument("--swarms", type=Path,
                        help="swarms file (swarm)")

    parser.add_argument("--otu-table", type=Path,
                        help="OTU table (vsearch)")

    parser.add_argument("--otu-fasta", type=Path,
                        help="fasta file (vsearch)")

    parser.add_argument("--hash-fasta", type=Path,
                        nargs="?",
                        help="fasta file (only for swarm)")
    parser.add_argument("--threshold", type=int)
    parser.add_argument("--clustering-algo",
                        choices=["swarm", "vsearch"],
                        required=True)
    parser.add_argument("--suffix", default="filtered_")
    return parser.parse_args()


# --------------------------------------------------
# Common utils
# --------------------------------------------------
def new_filename(path: Path, suffix: str) -> Path:
    new = path.with_name(suffix + path.stem + path.suffix)
    return new

def fasta_iter(path: Path):
    header = None
    seq_chunks = []

    with open(path) as f:
        for line in f:
            line = line.rstrip()
            if line.startswith(">"):
                if header:
                    yield header, "".join(seq_chunks)
                header = line
                seq_chunks = []
            else:
                seq_chunks.append(line)
        if header:
            yield header, "".join(seq_chunks)


# --------------------------------------------------
# SWARM LOGIC
# --------------------------------------------------
def run_swarm(stats_file, swarms_file, fasta_file, threshold, suffix):
    new_stats  = new_filename(stats_file, suffix)
    new_swarms = new_filename(swarms_file, suffix)
    new_fasta  = new_filename(fasta_file, suffix)

    cols = [
        "unique_amplicons",
        "total_abundance",
        "initial_seed",
        "initial_seed_abundance",
        "number_of_singletons_in_the_cluster",
        "max_iterations",
        "number_of_steps"
    ]

    stats = pd.read_csv(stats_file, sep="\t", header=None, names=cols)

    kept_stats = stats[stats["total_abundance"] >= threshold]
    kept_seeds = set(kept_stats["initial_seed"])

    kept_stats.to_csv(new_stats, sep="\t", header=False, index=False)

    # Filter swarms
    with open(swarms_file) as inp, open(new_swarms, "w") as out:
        for line in inp:
            seed = line.strip().split()[0].split("_")[0]
            if seed in kept_seeds:
                out.write(line)

    # Filter FASTA
    with open(new_fasta, "w") as out:
        for header, seq in fasta_iter(fasta_file):
            seed = header[1:].split("_")[0]
            if seed in kept_seeds:
                out.write(f"{header}\n{seq}\n")


# --------------------------------------------------
# VSEARCH LOGIC
# --------------------------------------------------
def run_vsearch(otu_table_file, fasta_file, threshold, suffix):
    new_otu   = new_filename(otu_table_file, suffix)
    new_fasta = new_filename(fasta_file, suffix)

    otus_to_remove = set()

    with open(otu_table_file) as inp, open(new_otu, "w") as out:
        for i, line in enumerate(inp):
            if i == 0:
                out.write(line)
                continue

            parts      = line.rstrip().split("\t")
            otu_id     = parts[0]
            abundances = map(int, parts[1:])
            otu_total  = sum(abundances)

            if otu_total < threshold:
                otus_to_remove.add(otu_id)
            else:
                out.write(line)

    # Filter FASTA (robust, not assuming 2-line format)
    with open(new_fasta, "w") as out:
        for header, seq in fasta_iter(fasta_file):
            otu_id = header[1:].strip()
            if otu_id not in otus_to_remove:
                out.write(f"{header}\n{seq}\n")


# --------------------------------------------------
# MAIN
# --------------------------------------------------
def main():
    args = parse_args()

    if args.clustering_algo == "swarm":
        if args.hash_fasta is None:
            raise ValueError("Swarm mode requires 3 input files")
        run_swarm(
            stats_file  = args.stats,
            swarms_file = args.swarms,
            fasta_file  = args.hash_fasta,
            threshold   = args.threshold,
            suffix      = args.suffix
        )

    elif args.clustering_algo == "vsearch":
        run_vsearch(
            otu_table_file = args.otu_table,
            fasta_file     = args.ptu_fasta,
            threshold      = args.threshold,
            suffix         = args.suffix
        )


if __name__ == "__main__":
    main()

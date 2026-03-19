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
    parser.add_argument("--suffix", default="_original")
    return parser.parse_args()


# --------------------------------------------------
# Common utils
# --------------------------------------------------
def backup_file(path: Path, suffix: str) -> Path:
    backup = path.with_name(path.stem + suffix + path.suffix)
    if backup.exists():
        raise FileExistsError(f"Backup already exists: {backup}")
    shutil.move(path, backup)
    return backup


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
    stats_backup  = backup_file(stats_file, suffix)
    swarms_backup = backup_file(swarms_file, suffix)
    fasta_backup  = backup_file(fasta_file, suffix)

    cols = [
        "unique_amplicons",
        "total_abundance",
        "initial_seed",
        "initial_seed_abundance",
        "number_of_singletons_in_the_cluster",
        "max_iterations",
        "number_of_steps"
    ]

    stats = pd.read_csv(stats_backup, sep="\t", header=None, names=cols)

    kept_stats = stats[stats["total_abundance"] >= threshold]
    kept_seeds = set(kept_stats["initial_seed"])

    kept_stats.to_csv(stats_file, sep="\t", header=False, index=False)

    # Filter swarms
    with open(swarms_backup) as inp, open(swarms_file, "w") as out:
        for line in inp:
            seed = line.strip().split()[0].split("_")[0]
            if seed in kept_seeds:
                out.write(line)

    # Filter FASTA
    with open(fasta_file, "w") as out:
        for header, seq in fasta_iter(fasta_backup):
            seed = header[1:].split("_")[0]
            if seed in kept_seeds:
                out.write(f"{header}\n{seq}\n")


# --------------------------------------------------
# VSEARCH LOGIC
# --------------------------------------------------
def run_vsearch(otu_table_file, fasta_file, threshold, suffix):
    otu_backup   = backup_file(otu_table_file, suffix)
    fasta_backup = backup_file(fasta_file, suffix)

    otus_to_remove = set()

    with open(otu_backup) as inp, open(otu_table_file, "w") as out:
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
    with open(fasta_file, "w") as out:
        for header, seq in fasta_iter(fasta_backup):
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

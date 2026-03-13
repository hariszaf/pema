#!/usr/bin/env python

# # NOTE (Haris Zafeiropoulos, 2025-07-01):
# # should we remove clusters where all amplicons had a single copy ?
# # for example, i have an asv that comes from 10 amplcions, that all had an abundance of 1

# import sys
# from pathlib import Path
# import pandas as pd

# asvs_stats  = sys.argv[1]
# asvs_swarms = sys.argv[2]
# threshold   = int(sys.argv[3])

# stats = pd.read_csv(asvs_stats, sep="\t", header=None)
# stats.columns = [
#     "unique_amplicons",
#     "total_abundance",
#     "initial_seed",
#     "initial_seed_abundance",
#     "number_of_singletons_in_the_cluster",
#     "max_iterations",
#     "number_of_steps"
# ]

# # NOTE (Haris Zafeiropoulos, 2025-07-01):
# # stats carry information only about the seeds !
# # We will remove seeds that have not reached the threshold, not amplicons!
# updated_stats     = stats[stats['total_abundance'] >= threshold]
# removed_stats     = stats[stats['total_abundance'] < threshold]

# amplicons_to_skip = removed_stats["initial_seed"].to_list()

# outdir = Path(asvs_stats).parent.absolute()

# # Remove them also from the astv.swarms
# with open(outdir / "updated_asvs.swarms", "w") as f:
#     with open(asvs_swarms) as file:
#         for line in file:
#             # Get first amplicon - which is the seed of the asv cluster -
#             # and remove its abuundance part
#             seed = line.split(" ")[0].split("_")[0]
#             if seed not in amplicons_to_skip:
#                 f.write(line)

# updated_stats.to_csv(outdir / "updated_asvs.stats", sep="\t", header=None)


import sys
from pathlib import Path
import pandas as pd
import shutil

stats_file  = Path(sys.argv[1])
swarms_file = Path(sys.argv[2])
hash_file   = Path(sys.argv[3])  # asvs_representatives_hash.fa
threshold   = int(sys.argv[4])

suffix = "_oligotonots_in"

outdir = stats_file.parent

# --------------------------------------------------
# Rename original files (archive)
# --------------------------------------------------
stats_backup  = stats_file.with_name(stats_file.stem  + suffix + stats_file.suffix)
swarms_backup = swarms_file.with_name(swarms_file.stem + suffix + swarms_file.suffix)
fasta_backup  = hash_file.with_name(hash_file.stem  + suffix + hash_file.suffix)

shutil.move(stats_file, stats_backup)
shutil.move(swarms_file, swarms_backup)
shutil.move(hash_file, fasta_backup)

# --------------------------------------------------
# Load stats (seeds only)
# --------------------------------------------------
stats = pd.read_csv(stats_backup, sep="\t", header=None)
stats.columns = [
    "unique_amplicons",
    "total_abundance",
    "initial_seed",
    "initial_seed_abundance",
    "number_of_singletons_in_the_cluster",
    "max_iterations",
    "number_of_steps"
]

kept_stats = stats[stats["total_abundance"] >= threshold]
kept_seeds = set(kept_stats["initial_seed"])

# --------------------------------------------------
# Write filtered stats (original name)
# --------------------------------------------------
kept_stats.to_csv(stats_file, sep="\t", header=False, index=False)

# --------------------------------------------------
# Filter swarms
# --------------------------------------------------
with open(swarms_backup) as inp, open(swarms_file, "w") as out:
    for line in inp:
        seed = line.split()[0].split("_")[0]
        if seed in kept_seeds:
            out.write(line)

# --------------------------------------------------
# Filter representative FASTA
# --------------------------------------------------
def fasta_iter(path):
    header = None
    seq = []
    with open(path) as f:
        for line in f:
            line = line.rstrip()
            if line.startswith(">"):
                if header:
                    yield header, "".join(seq)
                header = line
                seq = []
            else:
                seq.append(line)
        if header:
            yield header, "".join(seq)

with open(hash_file, "w") as out:
    for header, seq in fasta_iter(fasta_backup):
        seed = header[1:].split("_")[0]
        if seed in kept_seeds:
            out.write(f"{header}\n{seq}\n")

#!/usr/bin/env python

# NOTE (Haris Zafeiropoulos, 2025-07-01):
# should we remove clusters where all amplicons had a single copy ?
# for example, i have an asv that comes from 10 amplcions, that all had an abundance of 1

import sys
from pathlib import Path
import pandas as pd

asvs_stats  = sys.argv[1]
asvs_swarms = sys.argv[2]
threshold   = int(sys.argv[3])

stats = pd.read_csv(asvs_stats, sep="\t", header=None)
stats.columns = [
    "unique_amplicons",
    "total_abundance",
    "initial_seed",
    "initial_seed_abundance",
    "number_of_singletons_in_the_cluster",
    "max_iterations",
    "number_of_steps"
]

# NOTE (Haris Zafeiropoulos, 2025-07-01):
# stats carry information only about the seeds !
# We will remove seeds that have not reached the threshold, not amplicons!
updated_stats     = stats[stats['total_abundance'] >= threshold]
removed_stats     = stats[stats['total_abundance'] < threshold]

amplicons_to_skip = removed_stats["initial_seed"].to_list()

outdir = Path(asvs_stats).parent.absolute()

# Remove them also from the astv.swarms
with open(outdir / "updated_asvs.swarms", "w") as f:
    with open(asvs_swarms) as file:
        for line in file:
            # Get first amplicon - which is the seed of the asv cluster -
            # and remove its abuundance part
            seed = line.split(" ")[0].split("_")[0]
            if seed not in amplicons_to_skip:
                f.write(line)

updated_stats.to_csv(outdir / "updated_asvs.stats", sep="\t", header=None)

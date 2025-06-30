#!/bin/bash

# Aim: The "stats" table obtained once Swarm v2 was complteted
#      gives for each ASV:
#        1. the total abundance, 
#        2. the number of unique amplicons in the OTU, 
#        3. the name and the abundance of the most abundant amplicon in the OTU (i.e. the seed), and 
#        4. the number of low abundant amplicons (abundance = 1) in the ASV.

#       The sorted ASVs, can be used along with the amplicon
#       contingency table to produce a new ASV contingency table.
#       That table will indicate for each ASV the number of time
#       elements of that ASV (i.e. amplicons) have been seen in 
#       each sample (columns).
#
# Usage: PEMA invokes this script every time Swarm v2 has been asked for by the user,
#        once Swarm has been completed, in the clusteringSwarm function of the clustering module.
# 
# Authors: Frédéric Mahé, edited by Haris Zafeiropoulos
#           initial script available at: 
#           https://github.com/torognes/swarm/wiki/Working-with-several-samples#produce-a-contingency-table-for-otus
# 
# Note: 
# In the asvs.swarms file, each line has a cluster where the first element is the seed, and the others are the amplicons 
# that were cluster to that. There is a "_xx" part with the abundance of each amplicon


         STATS="asvs.stats"
        SWARMS="asvs.swarms"
AMPLICON_TABLE="amplicon_contingency_table.tsv"
     ASV_TABLE="asvs_contingency_table.tsv"

# Header
# echo -e "ASV\t$(head -n 1 "${AMPLICON_TABLE}")" > "${ASV_TABLE}"
echo -e "$(head -n 1 "${AMPLICON_TABLE}" | \
    awk -F'\t' '{for (i=2; i<NF; i++) printf "%s%s", $i, (i<NF-1 ? "\t" : "")}')"


# # Compute "per sample abundance" for each ASV
awk -v SWARM="${SWARMS}" -v TABLE="${AMPLICON_TABLE}" '
BEGIN {
    FS = "\t"

    # Load swarms: map each ASV to its seed
    while ((getline < SWARM) > 0) {
        n = split($0, ids, " ")
        split(ids[1], seed_parts, "_")
        seed = seed_parts[1]
        for (i = 1; i <= n; i++) {
            split(ids[i], parts, "_")
            id = parts[1]
            swarms[id] = seed
        }
    }

    # Load and group table data by seed (only if ASV is in swarms)
    while ((getline < TABLE) > 0) {
        line = $0
        split(line, fields, FS)
        asv = fields[1]
        if (!(asv in swarms)) {
            continue  # Use 'continue' instead of 'next' inside BEGIN
        }
        seed = swarms[asv]

        for (i = 2; i <= length(fields); i++) {
            grouped[seed][i] += fields[i]
        }
    }

    # Print the grouped table (headerless)
    for (seed in grouped) {
        printf "%s", seed
        for (i = 2; i <= length(grouped[seed]); i++) {
            printf "\t%d", grouped[seed][i]
        }
        printf "\n"
    }
}
' >> "${ASV_TABLE}"

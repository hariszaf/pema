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

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --stats) STATS="$2"; shift ;;
        --swarms) SWARMS="$2"; shift ;;
        --hash-fasta) HASH_FASTA="$2"; shift ;;
        --amplicon-table) AMPLICON_TABLE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# OUTPUT FILENAMES
REPRESENTATIVE_ASVS="asvs_representatives.fa"
     ASV_TABLE_HASH="asvs_contingency_hash.tsv"
          ASV_TABLE="asvs_contingency_table.tsv"

# Step 1

{
    # Extract header and write it, skipping first column (ASV) only
    head -n 1 "${AMPLICON_TABLE}" | \
    awk -F'\t' 'BEGIN {OFS="\t"} {
        printf "ASV\tSeed"
        for (i = 2; i < NF; i++) {
            printf "\t%s", $i
        }
        printf "\n"
    }'

    # Now run the AWK logic for the grouped data
    awk -v SWARM="${SWARMS}" -v TABLE="${AMPLICON_TABLE}" '
    BEGIN {
        FS = "\t"
        swarm_line = 0
    }

    FILENAME == SWARM {
        swarm_line++
        n = split($0, ids, " ")
        split(ids[1], seed_parts, "_")
        seed = seed_parts[1]

        if (!(seed in seed_line)) {
            seed_line[seed] = swarm_line
        }

        for (i = 1; i <= n; i++) {
            split(ids[i], parts, "_")
            id = parts[1]
            swarms[id] = seed
        }
        next
    }

    FILENAME == TABLE {
        split($0, fields, FS)
        asv = fields[1]
        if (!(asv in swarms)) next

        seed = swarms[asv]
        used_seeds[seed] = 1

        for (i = 2; i <= length(fields); i++) {
            grouped[seed][i] += fields[i]
        }
        next
    }

    END {
        for (seed in used_seeds) {
            printf "ASV_%d\t%s", seed_line[seed], seed
            for (i = 2; i <= length(grouped[seed]); i++) {
                printf "\t%d", grouped[seed][i]
            }
            printf "\n"
        }
    }
    ' "${SWARMS}" "${AMPLICON_TABLE}"
} > "${ASV_TABLE_HASH}"


# -------------------

# Step 2


awk -F'\t' '
BEGIN { OFS = "\t" }
NR == 1 {
  for (i = 1; i <= NF; i++) gsub(/\.derep\.fa/, "", $i)
}
NR == 1 || NF > 1 {
  $2 = ""                     # remove 2nd column (Seed)
  sub(/\t\t/, "\t")           # collapse the empty column
  print
}
' ${ASV_TABLE_HASH} > ${ASV_TABLE}



awk -F'\t' '
  FNR == NR {
    if (FNR == 1) next                    # skip header of table
    hash_to_asv[$2] = $1                  # map hash to ASV ID
    next
  }
  /^>/ {
    if (match($0, /^>([^;]+);size=([0-9]+)/, arr)) {
      hash = arr[1]
      size = arr[2]
      if (hash in hash_to_asv)
        print ">" hash_to_asv[hash] ";size=" size
      else
        print $0                          # leave unchanged if not found
    } else {
      print $0                            # malformed header? print as-is
    }
    next
  }
  { print }                               # sequence lines
' ${ASV_TABLE_HASH} ${HASH_FASTA} > ${REPRESENTATIVE_ASVS}

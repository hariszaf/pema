STATS="SWARM.stats"
SWARMS="SWARM.swarms"
AMPLICON_TABLE="amplicon_contingency_table.csv"
OTU_TABLE="SWARM_OTU_table.tsv"

# Header
echo -e "OTU\t$(head -n 1 "${AMPLICON_TABLE}")" > "${OTU_TABLE}"

# Compute "per sample abundance" for each OTU
awk -v SWARM="${SWARMS}" \
    -v TABLE="${AMPLICON_TABLE}" \
    'BEGIN {FS = " "
            while ((getline < SWARM) > 0) {
                swarms[$1] = $0
            }
            FS = "\t"
            while ((getline < TABLE) > 0) {
                table[$1] = $0
            }
           }

     {# Parse the stat file (OTUs sorted by decreasing abundance)
      seed = $3 "_" $4
      n = split(swarms[seed], OTU, "[ _]")
      for (i = 1; i < n; i = i + 2) {
          s = split(table[OTU[i]], abundances, "\t")
          for (j = 1; j < s; j++) {
              samples[j] += abundances[j+1]
          }
      }
      printf "%s\t%s", NR, $3
      for (j = 1; j < s; j++) {
          printf "\t%s", samples[j]
      }
     printf "\n"
     delete samples
     }' "${STATS}" >> "${OTU_TABLE}"

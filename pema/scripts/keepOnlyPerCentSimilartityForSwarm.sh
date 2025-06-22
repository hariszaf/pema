#!/bin/bash

## make stats for swarm output
awk '{if($NF >= 97) {print $0}}' tax_assign_swarm_COI.txt > assignment_97.txt

#### kratao se ena neo arxeio ta monadika eidi pou iparxoun stin analisi mas
awk '{print $(NF-3)" "$(NF-2)}' assignment_97.txt | sort | uniq | sort > unique_species_list.txt

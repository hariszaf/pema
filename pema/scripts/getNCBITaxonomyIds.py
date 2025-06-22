#!/usr/bin/python3

"""
This script makes use of the ncbi-taxonomist tool to get the NCBI Taxonomy id of the 
lowest possible taxon level in each taxonomic assignment mentioned in the finalTable.tsv
"""

import subprocess
import time

final_table         = open("finalTable.tsv", "r")
final_table_ncbiIds = open("extenedFinalTable.tsv", "w")

taxa_ncbiIds = {}

for line in final_table:

    line_tabs = line.split("\t")

    if line_tabs[-1][:-1] == "Taxonomy":
        final_table_ncbiIds.write(line[:-1] + "\t" + "TAXON:NCBI_TAX_ID" + "\n")
        continue

    else:
        taxa_levels = line_tabs[-1].split(";")
        taxa_levels = [x.strip() for x in taxa_levels]
        # taxa_levels[-1] = taxa_levels[-1][:-1]
        counter = 1

        print(">>", taxa_levels)

        # Start a loop from the end of the taxonomy to the root
        for entry in range(len(taxa_levels) - 1, 0, -1):

            level = taxa_levels[entry]

            if "__" in level:
                level = level.split("__")[-1]

            if level == "root":
                continue

            level = level.replace("_", " ")

            if not level[0].isupper():
                print("Taxon name does not have an uppercase as a first letter.")
                continue

            else:

                if level in taxa_ncbiIds:
                    print("Match from the dictionary!")
                    match = taxa_ncbiIds[level]

                    if match != "":
                        ncbi_id = match
                        final_table_ncbiIds.write(line[:-1] + "\t" + level + ":" + ncbi_id + "\n")
                        break

                else:
                    ps = subprocess.Popen(('ncbi-taxonomist', 'resolve', '-n', level), stdout=subprocess.PIPE)
                    output = subprocess.check_output(("jq", ".taxon.taxid"), stdin=ps.stdout, stderr=subprocess.STDOUT)
                    ps.wait()

                    time.sleep(1)

                    output = str(output)
                    output = output[2:]
                    output = output[:-1]

                    if output != "":

                        output = output[:-2]

                        if " " not in output:

                            ncbi_id = output
                            final_table_ncbiIds.write(line[:-1] + "\t" + level + ":" + ncbi_id + "\n")

                            taxa_ncbiIds[level] = ncbi_id
                            break

                    else:
                        taxa_ncbiIds[level] = ""
                        continue

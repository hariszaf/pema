#!/usr/bin/python 

import subprocess, time

final_table         = open("finalTable.tsv", "r")
final_table_ncbiIds = open("extenedFinalTable.tsv", "w")

taxa_ncbiIds = {}

for line in final_table:

    line_tabs = line.split("\t")

    if line_tabs[-1][:-1] == "Classification": 
        print("This is first line")
        final_table_ncbiIds.write(line[:-1] + "\t" + "TAXON:NCBI_TAX_ID" + "\n")
        continue

    else:

        taxa_levels = line_tabs[-1].split(";")
        taxa_levels[-1] = taxa_levels[-1][:-1]
        counter = 1

        # Start a loop from the end of the taxonomy to the root 
        for entry in range(len(taxa_levels)-1, 0, -1): 

            level = taxa_levels[entry]

            print("this is my level:\t" + level)

            if level[0].isupper() == False:
                print("This taxon name does not has an uppercase as a first letter")
                continue

            else:

                if level in taxa_ncbiIds: 
                    print("Match from the dictionary!")
                    match = taxa_ncbiIds[level]

                    if match != "":
                        ncbi_id = match
                        final_table_ncbiIds.write(line[:-1] + "\t" + level + ":" + ncbi_id)
                        break

                else:
                    ps = subprocess.Popen(('ncbi-taxonomist', 'resolve', '-n', level), stdout=subprocess.PIPE)
                    output = subprocess.check_output(("jq", ".taxon.taxid"), stdin=ps.stdout, stderr=subprocess.STDOUT)
                    ps.wait()

                    time.sleep(1)

                    if output != "":

                        if " " not in output:

                            ncbi_id = output 
                            final_table_ncbiIds.write(line[:-1] + "\t" + level + ":" + ncbi_id)

                            taxa_ncbiIds[level] = ncbi_id
                            break

                    else:
                        taxa_ncbiIds[level] = ""
                        continue


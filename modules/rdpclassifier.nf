#!/usr/bin/env nextflow

/* Nextflow processes to run the RDP Classifier (https://github.com/rdpstaff/classifier)
   with an RDP-trained database, and build the taxonomy table.

   A database is a folder with an rRNAClassifier.properties file and the files it lists, e.g.

       12S_v2.0.0/
       ├── bergeyTrainingTree.xml
       ├── genus_wordConditionalProbList.txt
       ├── logWordPrior.txt
       ├── rRNAClassifier.properties
       └── wordConditionalProbIndexArr.txt
*/

process RDP_CLASSIFY {

    tag "Taxonomy assignment using RDPClassifier."

    publishDir { "${params.outdir}/rdp_assignment" }, mode: 'copy'

    container "quay.io/biocontainers/rdp_classifier:2.13--hdfd78af_1"

    memory { rdp_params.memory }

    input:
        path fasta
        path database
        val rdp_params

    output:
        path "rdp_assignments.txt", emit: assignments

    script:
        // Leave some of the task memory to the JVM itself
        def heap_mb = Math.max((task.memory.toMega() * 0.9) as long, 512)
        """
        if [[ ! -f "${database}/rRNAClassifier.properties" ]]; then
            echo "No rRNAClassifier.properties in the RDP database folder '${database}'." >&2
            exit 1
        fi

        rdp_classifier -Xmx${heap_mb}m classify \\
            -t ${database}/rRNAClassifier.properties \\
            -o rdp_assignments.txt \\
            ${fasta}
        """
}


process BUILD_RDP_TAXONOMY_TABLE {

    tag "Building taxonomy table from RDPClassifier assignments."

    publishDir { "${params.outdir}/rdp_assignment" }, mode: 'copy'

    container "hariszaf/pema-nf:0.2.2"

    input:
        path asvs_contingency_hash_table
        path rdp_assignments
        val rdp_params

    output:
        path "tax_assigned_table.tsv", emit: tax_assigned_table

    script:
        """
        python3 /opt/pema/scripts/rdp_tax_table.py \\
            --asvs-hash ${asvs_contingency_hash_table} \\
            --rdp-assignments ${rdp_assignments} \\
            --confidence ${rdp_params.confidence}
        """
}

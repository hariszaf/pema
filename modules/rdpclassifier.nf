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

// Download a PEMA-trained database from Zenodo: <download_url>/<database>.tar.gz, or, if that file
// is not there, the database's folder from <download_url>/rdp_dbs_v220.tar.gz (all databases, ~1.2 GB).
process DOWNLOAD_RDP_DB {

    tag "Download the RDPClassifier database ${rdp_params.database}."

    // Saved in databases_dir; pema.nf finds it there in the next runs and does not download it again
    publishDir { rdp_params.databases_dir }, mode: 'copy'

    container "hariszaf/pema-nf:0.2.2"

    input:
        val rdp_params

    output:
        path "${rdp_params.database}", emit: database

    script:
        def db  = rdp_params.database
        def url = rdp_params.download_url.toString().replaceAll('/+$', '')
        """
        download() {
            wget --quiet --tries 10 --waitretry 10 --continue --output-document "\$2" "\$1"
        }

        if download "${url}/${db}.tar.gz" ${db}.tar.gz; then
            tar -xzf ${db}.tar.gz
        else
            rm -f ${db}.tar.gz
            echo "${url}/${db}.tar.gz not available; extracting ${db} from ${url}/rdp_dbs_v220.tar.gz" >&2
            download "${url}/rdp_dbs_v220.tar.gz" rdp_dbs_v220.tar.gz
            tar -xzf rdp_dbs_v220.tar.gz --wildcards "*${db}/*"
        fi

        # Move the database folder (wherever it is in the archive) to ./${db}
        properties=\$(find . -path "*${db}/rRNAClassifier.properties" -not -path "./${db}/*" | head -n 1)
        if [[ -n "\$properties" ]]; then
            mv "\$(dirname "\$properties")" ${db}_tmp && rm -rf ${db} && mv ${db}_tmp ${db}
        fi
        if [[ ! -f ${db}/rRNAClassifier.properties ]]; then
            echo "The downloaded archive has no ${db}/rRNAClassifier.properties." >&2
            exit 1
        fi
        rm -f ${db}.tar.gz rdp_dbs_v220.tar.gz
        """
}


// Training a custom database (https://hariszaf.github.io/pema_documentation/training_rdpclassifier/):
// the user provides a taxonomy file (tsv: id, then one column per rank, with a header line)
// and a sequence file (fasta, ids as in the taxonomy file).

process PREPARE_RDP_TRAINING {

    tag "Prepare the RDP training files for ${rdp_params.database}."

    container "hariszaf/pema-nf:0.2.2"

    input:
        path taxonomy
        path sequences
        val rdp_params

    output:
        path "ready4train_taxonomy.txt", emit: taxonomy
        path "ready4train_seqs.fasta", emit: sequences

    script:
        """
        python3 /opt/pema/scripts/rdp_training_files.py \\
            --taxonomy ${taxonomy} \\
            --sequences ${sequences} \\
            ${rdp_params.train.rename_duplicates ? '--rename-duplicates' : ''}
        """
}


process TRAIN_RDP_DB {

    tag "Train the RDPClassifier database ${rdp_params.database}."

    // Saved in databases_dir; pema.nf finds it there in the next runs and does not train it again
    publishDir { rdp_params.databases_dir }, mode: 'copy'

    container "quay.io/biocontainers/rdp_classifier:2.13--hdfd78af_1"

    memory { rdp_params.train.memory }

    input:
        path taxonomy
        path sequences
        val rdp_params

    output:
        path "${rdp_params.database}", emit: database

    script:
        def heap_mb = Math.max((task.memory.toMega() * 0.9) as long, 512)
        """
        rdp_classifier -Xmx${heap_mb}m train \\
            -o ${rdp_params.database} \\
            -s ${sequences} \\
            -t ${taxonomy}

        # The classifier finds the trained files through this file
        cat > ${rdp_params.database}/rRNAClassifier.properties <<'EOF'
        # Sample ResourceBundle properties file
        bergeyTree=bergeyTrainingTree.xml

        probabilityList=genus_wordConditionalProbList.txt

        probabilityIndex=wordConditionalProbIndexArr.txt

        wordPrior=logWordPrior.txt

        classifierVersion=RDP Naive Bayesian rRNA Classifier Version 2.13
        EOF
        """
}


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

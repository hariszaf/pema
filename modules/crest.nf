#!/usr/bin/env nextflow

/* Nextflow script to run crest4 (https://github.com/xapple/crest4)

Usage:

    nextflow run modules/crest.nf --params-file tests/configs/crest.yaml -c nextflow.config
*/
include { loadYamlParams; valueOr } from './utils.nf'

// Defaults for standalone use; when included from pema.nf these are already set.
params.outdir          = params.outdir ?: (params.paramsFile ? loadYamlParams(params.paramsFile, 'outdir') : null) ?: "results"
params.clustering_algo = params.clustering_algo ?: (params.paramsFile ? loadYamlParams(params.paramsFile, 'clustering_algo') : null) ?: 'swarm'

// Download one of PEMA's crest4 databases: <download_url>/<archive>.tar.gz, with the database folder in it.
// crest4 needs the files of a database to be named after its folder (<db>/<db>.fasta, .map, .names, .tre),
// so they are renamed; a tree whose root (node 0) is not named, as written by older versions of
// make_new_crest_db.py, gets its root named, otherwise crest4 fails on it.
process DOWNLOAD_CREST_DB {

    tag "Download the crest4 database ${crest_params.database_name}."

    // Saved in mount_crest_dbs; pema.nf finds it there in the next runs and does not download it again
    publishDir { crest_params.mount_crest_dbs }, mode: 'copy'

    container "hariszaf/pema-nf:0.2.2"

    input:
        val crest_params

    output:
        path "${crest_params.database_name}", emit: database

    script:
        def db      = crest_params.database_name
        def archive = crest_params.download_archive
        def url     = crest_params.download_url.toString().replaceAll('/+$', '')
        """
        wget --quiet --tries 10 --waitretry 10 --continue --output-document ${archive}.tar.gz "${url}/${archive}.tar.gz"
        mkdir -p extracted && tar -xzf ${archive}.tar.gz -C extracted

        # The database folder is the one with the .names file, wherever it is in the archive
        names=\$(find extracted -name "*.names" | head -n 1)
        if [[ -z "\$names" ]]; then
            echo "${url}/${archive}.tar.gz has no .names file: not a crest4 database." >&2
            exit 1
        fi
        mv "\$(dirname "\$names")" ${db}
        rm -rf extracted ${archive}.tar.gz

        # Name the files after the folder
        cd ${db}
        for ext in fasta map names tre tsv; do
            found=\$(ls *.\$ext 2>/dev/null | head -n 1)
            if [[ -n "\$found" && "\$found" != "${db}.\$ext" ]]; then
                mv "\$found" "${db}.\$ext"
            fi
        done
        for ext in fasta map names tre; do
            [[ -f "${db}.\$ext" ]] || { echo "The crest4 database ${db} has no .\$ext file." >&2; exit 1; }
        done

        # A root numbered 0 must be named in the tree too
        if head -n 1 ${db}.names | grep -q '^0,' && grep -q ')\\s*;\\s*\$' ${db}.tre; then
            sed -i 's/)\\s*;\\s*\$/)0;/' ${db}.tre
        fi
        """
}


// Building a custom crest4 database: the user provides a taxonomy file (tsv: accession, lineage
// separated by '/' or ';', optionally a name) and a sequence file (fasta, named by accession).

process PREPARE_CREST_TRAINING {

    tag "Prepare the CREST training files for ${crest_params.database_name}."

    container "hariszaf/pema-nf:0.2.2"

    input:
        path taxonomy
        path sequences
        val crest_params

    output:
        path "${crest_params.database_name}", emit: database

    script:
        """
        python3 /opt/pema/scripts/crest_training_files.py \\
            --taxonomy ${taxonomy} \\
            --sequences ${sequences} \\
            --name ${crest_params.database_name}
        """
}


process TRAIN_CREST_DB {

    tag "Build the crest4 database ${crest_params.database_name}."

    // Saved in mount_crest_dbs; pema.nf finds it there in the next runs and does not build it again
    publishDir { crest_params.mount_crest_dbs }, mode: 'copy'

    container "hariszaf/crest4:4.3.8"

    input:
        path prepared, stageAs: 'prepared_db'
        path make_new_crest_db
        val crest_params

    output:
        path "${crest_params.database_name}", emit: database

    script:
        def db = crest_params.database_name
        """
        # Work on a copy, so the prepared folder (a link to the previous task) is not modified
        cp -rL ${prepared} ${db}

        # The .tre, .map and .names files, from the .tsv
        python3 ${make_new_crest_db} ${db}/${db}.tsv

        # Build the search index now, so the classification does not have to
        python3 - <<'EOF'
        from crest4.databases import CrestDatabase
        db = CrestDatabase(custom_path="${db}")
        db.${crest_params.search_algo == 'vsearch' ? 'vsearch_db' : 'blast_db'}
        EOF

        # The container runs as root; let the database be read (and published) by the user
        chmod -R a+rX ${db}
        """
}


process CREST_TAXONOMY_ASSIGNMENT {

    tag "Taxonomy assignment using crest4."

    publishDir { "${params.outdir}" }, mode: 'copy'

    container "hariszaf/crest4:4.3.8"

    cpus { crest_params.threads }
    // Mount the local CREST databases folder only when one is given
    containerOptions { crest_params.mount_crest_dbs ? "-v ${crest_params.mount_crest_dbs}:/crest4/.crest4:rw" : '' }

    input:

        path fasta
        val crest_params
        // A database built in this run (TRAIN_CREST_DB); [] to use crest_params.database
        path built_db

    output:

        path "crest_assignment/assignments.txt", emit: assignments
        path "crest_assignment/search.hits", emit: search_hits

    script:

        def search_db = built_db ? built_db.toString() : crest_params.database
        """
        if [[ -e "${search_db}" ]]; then
            # Treat as input directory
            echo "Using a custom database"
        else
            # Treat as database name / keyword / identifier
            echo "Using a predefined database part of Crest4."
        fi

        # Use the Python API: the crest4 CLI passes numbers and booleans as strings (crest4 4.3.8)
        python - <<'EOF'
        from crest4 import Classify
        Classify(
            fasta       = "${fasta}",
            search_algo = "${crest_params.search_algo}",
            num_threads = ${task.cpus},
            search_db   = "${search_db}",
            output_dir  = "crest_assignment",
            min_score   = ${crest_params.min_score as double},
            score_drop  = ${crest_params.score_drop as double},
            min_smlrty  = ${crest_params.min_smlrty ? 'True' : 'False'},
        )()
        EOF
        """
}


process BUILD_TAXONOMY_TABLE {

    tag "Building taxonomy table from CREST assignments."

    publishDir { "${params.outdir}/crest_assignment" }, mode: 'copy'

    container "hariszaf/pema-nf:0.2.2"

    input:

        path asvs_contingency_hash_table
        path crest_assignments

    output:

        path "tax_assigned_table.tsv", emit: tax_assigned_table

    script:

        """
        /opt/pema/scripts/crest_tax_table.py \
            --asvs-hash ${asvs_contingency_hash_table} \
            --crest-assignments ${crest_assignments} \
            --clustering-algo ${params.clustering_algo == 'vsearch' ? 'vsearch' : 'swarm'}
        """
}

// Workflow for running the Crest4 taxonomy assignment and building the taxonomy table.
workflow {

    // Get YAML parameters file
    params.yaml = params.paramsFile ?: error(
        "Please provide YAML file with fastp parameters (--params-file)."
    )

    // Crest params
    def crest_params = loadYamlParams(params.yaml, 'crest') ?: [:]
    def crest_supported_DBs = ['ssuome', 'silvamod138pr2', 'mitofish', 'midori253darn']

    // Load the input fasta file containing the sequences to be classified.
    def fasta_file  = crest_params.fasta ?: error(
        "Please provide a fasta file to be classified (--fasta)."
    ) // asvs_representatives.fa
    def fasta   = channel.fromPath(fasta_file)

    // Load the ASV contingency table from the provided path. This table is needed to build the taxonomy table after the CREST assignments.
    def cont_file = loadYamlParams(params.yaml, 'asvs_contingency_table') ?: error(
        "Please provide the path to the ASV contingency table (--asvs_contingency_table)."
    )
    def cont_table = channel.fromPath(cont_file)

    // Load the database parameter, which can be either a predefined database name 
    // or a custom path to a directory containing the database files. 
    // If it's a custom path, make sure to prepend the mount point for the CREST databases.

    def db = crest_params.database ?: error(
        """
        The database used for the sequence similarity search.
        Either `ssuome`, `silvamod138pr2`, `mitofish`, or `midori253darn`. 
        By default, `ssuome`.
        In case of a custom database, please specify the full path to a directory containing 
        all required files, making sure that is under the `mount_crest_dbs`.
        """
    )
    if( !crest_supported_DBs.contains(db) ) {
        crest_params.database = "/crest4/.crest4/${db}"
        crest_params.mount_crest_dbs = crest_params.mount_crest_dbs ?: error(
        """
        Since you are using a custom database, you need to specify the mount point for the CREST databases.
        Please provide the path to the directory containing the CREST databases on your system (--mount_crest_dbs).
        This should be a directory that is mounted to the CREST container and contains folders with all required files for each database you may want to use.

        For example:
        ls ~/.crest4/
        18S_curated_141222_GenBank  bacteria_in_greece  fish16sDez2023  midori253darn  silvamod128  silvamod138pr2  unite_19_02_2025  unite2025_old

        ls ~/.crest4/unite_19_02_2025/
        unite_19_02_2025.fasta
        unite_19_02_2025.map
        unite_19_02_2025.names
        unite_19_02_2025.tre
        unite_19_02_2025.tsv
        """
        )
    } else {
        crest_params.database = db
    }

    crest_params.threads     = valueOr(crest_params.threads, valueOr(loadYamlParams(params.yaml, 'threads'), 4))

    crest_params.search_algo = crest_params.search_algo ?: 'blast'                                       // 'blast' or 'vsearch'
    crest_params.min_score   = valueOr(crest_params.min_score, crest_params.search_algo == 'blast' ? 155.0 : 0.75)
    crest_params.min_smlrty  = valueOr(crest_params.min_smlrty, true)
    crest_params.score_drop  = valueOr(crest_params.score_drop, 2.0)

    // Run the CREST taxonomy assignment.
    def crest_taxonomy_assignment = CREST_TAXONOMY_ASSIGNMENT(
        fasta,
        crest_params,
        []
    )

    // Build the taxonomy table by combining the ASV contingency table and the CREST taxonomy assignments.
    BUILD_TAXONOMY_TABLE(cont_table, crest_taxonomy_assignment.assignments)

}

#!/usr/bin/env nextflow

/* Nextflow script to run crest4 (https://github.com/xapple/crest4)

Usage:

    nextflow run modules/crest.nf --params-file config_files/crest.yaml
*/
include { loadYamlParams; valueOr } from './utils.nf'

// Defaults for standalone use; when included from pema.nf these are already set.
params.outdir          = params.outdir ?: (params.paramsFile ? loadYamlParams(params.paramsFile, 'outdir') : null) ?: "results"
params.clustering_algo = params.clustering_algo ?: (params.paramsFile ? loadYamlParams(params.paramsFile, 'clustering_algo') : null) ?: 'swarm'

process TRAIN_CREST_DB {

    tag "Training CREST database."

    publishDir { "${params.outdir}/crest_database_training" }, mode: 'copy'

    container "hariszaf/crest4:4.4.2"

    input:

        path database_fasta
        path database_taxonomy

    output:

        path "trained_database", emit: trained_db

    script:

        """
        crest4 --train_db \
            --db_fasta ${database_fasta} \
            --db_taxonomy ${database_taxonomy} \
            --output_dir trained_database
        """
}


process CREST_TAXONOMY_ASSIGNMENT {

    tag "Taxonomy assignment using crest4."

    publishDir { "${params.outdir}" }, mode: 'copy'

    container "hariszaf/crest4:4.4.5"
    // Mount the local CREST databases folder only when one is given
    containerOptions { crest_params.mount_crest_dbs ? "-v ${crest_params.mount_crest_dbs}:/crest4/.crest4:rw" : '' }

    input:

        path fasta
        val crest_params

    output:

        path "crest_assignment/assignments.txt", emit: assignments
        path "crest_assignment/search.hits", emit: search_hits

    script:

        """
        if [[ -e "${crest_params.database}" ]]; then
            # Treat as input directory
            echo "Using a custom database"
        else
            # Treat as database name / keyword / identifier
            echo "Using a predefined database part of Crest4."
        fi

        crest4 --fasta ${fasta} \
            --search_algo ${crest_params.search_algo} \
            --num_threads ${crest_params.threads} \
            --min_score ${crest_params.min_score} \
            --score_drop ${crest_params.score_drop} \
            --min_smlrty ${crest_params.min_smlrty} \
            --search_db ${crest_params.database} \
            --output_dir crest_assignment
        """
}


process BUILD_TAXONOMY_TABLE {

    tag "Building taxonomy table from CREST assignments."

    publishDir { "${params.outdir}/crest_assignment" }, mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

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
            --clustering-algo ${params.clustering_algo}
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
        Either `ssuome`, `silvamod138pr2`, `mitofish`, or `midori253darn`. By default, `ssuome`.
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
        crest_params
    )

    // Build the taxonomy table by combining the ASV contingency table and the CREST taxonomy assignments.
    BUILD_TAXONOMY_TABLE(cont_table, crest_taxonomy_assignment.assignments)

}

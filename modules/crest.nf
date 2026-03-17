#!/usr/bin/env nextflow

/* Nextflow script to run crest4 (https://github.com/xapple/crest4)

Usage:

    nextflow run modules/crest.nf --params-file config_files/crest.yaml
*/
include { paramsToCliArgs; loadYamlParams } from './utils.nf'

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
    containerOptions "-v ${params.mount_crest_dbs}:/crest4/.crest4:rw"

    input:
    path fasta
    val database

    output:
    path "crest_assignment/assignments.txt", emit: assignments
    path "crest_assignment/search.hits", emit: search_hits

    script:

    """
    if [[ -e "$database" ]]; then
        # Treat as input directory
        echo "Using a custom database"
    else
        # Treat as database name / keyword / identifier
        echo "Using a predefined database part of Crest4."
    fi

    crest4 --fasta ${fasta} \
        --search_algo ${params.search_algo ?: 'vsearch'} \
        --num_threads ${task.cpus} \
        --min_score ${params.min_score} \
        --score_drop ${params.score_drop} \
        --min_smlrty ${params.min_smlrty} \
        --search_db $database \
        --output_dir crest_assignment || true
    """
}


process BUILD_TAXONOMY_TABLE {

    tag "Building taxonomy table from CREST assignments."

    publishDir { "${params.outdir}/taxonomy_assignment" }, mode: 'copy'
    container "hariszaf/pema-nf:0.0.1"

    input:
    path asvs_contingency_table  // asvs_contingency_table.tsv
    path assignments

    output:
    // path "taxonomy_assigned_abd_table.tsv", emit: tax_table
    path "tax_assigned_table.tsv", emit: tax_assigned_table

    script:
    """
    crestTaxTable.py $asvs_contingency_table $assignments ${params.clustering_algo}
    """
}

// Workflow for running the Crest4 taxonomy assignment and building the taxonomy table.
workflow {

    // Get YAML parameters file
    params.yaml = params.paramsFile ?: error(
        "Please provide YAML file with fastp parameters (--params-file)."
    )

    // Crest params
    def crest_params = loadYamlParams(params.yaml, 'crest')
    def crest_supported_DBs = ['ssuome', 'silavamod138pr2', 'mitofish', 'midori253darn']

    // Load the input fasta file containing the sequences to be classified.
    def fasta_file  = crest_params.fasta ?: error(
        "Please provide a fasta file to be classified (--fasta)."
    ) // asvs_representatives.fa
    def fasta   = Channel.fromPath(fasta_file)

    // Load the ASV contingency table from the provided path. This table is needed to build the taxonomy table after the CREST assignments.
    def cont_file = loadYamlParams(params.yaml, 'asvs_contingency_table') ?: error(
        "Please provide the path to the ASV contingency table (--asvs_contingency_table)."
    )
    def cont_table = Channel.fromPath(cont_file)

    // Load the database parameter, which can be either a predefined database name 
    // or a custom path to a directory containing the database files. 
    // If it's a custom path, make sure to prepend the mount point for the CREST databases.
    def db = crest_params.database ?: error(
        """
        The database used for the sequence similarity search.
        Either `ssuome`, `silavamod138pr2`, `mitofish`, or `midori253darn`. By default, `ssuome`.
        In case of a custom database, please specify the full path to a directory containing 
        all required files, making sure that is under the `mount_crest_dbs`.
        """
    )
    if( !crest_supported_DBs.contains(db) ) {
        params.database = "/crest4/.crest4/${db}"
        params.mount_crest_dbs = crest_params.mount_crest_dbs ?: error(
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
        params.database = db
    }

    params.search_algo = crest_params.search_algo ?: 'blast' // 'blast' or 'vsearch'
    params.min_score   = crest_params.min_score ?: (params.search_algo == 'blast' ? 155.0 : 0.75)
    params.min_smlrty  = crest_params.min_smlrty ?: true
    params.score_drop  = crest_params.score_drop ?: 2.0

    // General parameters
    params.outdir          = loadYamlParams(params.yaml, 'outdir') ?: "results"
    params.threads         = loadYamlParams(params.yaml, 'threads') ?: 4
    params.clustering_algo = loadYamlParams(params.yaml, 'clustering_algo') ?: 'swarm' // 'vsearch' or 'swarm'

    // Run the CREST taxonomy assignment.
    def crest_taxonomy_assignment = CREST_TAXONOMY_ASSIGNMENT(
        fasta,
        params.database
    )

    // Build the taxonomy table by combining the ASV contingency table and the CREST taxonomy assignments.
    def tax_table = BUILD_TAXONOMY_TABLE(cont_table, crest_taxonomy_assignment.assignments)

}

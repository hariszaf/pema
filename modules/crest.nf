#!/usr/bin/env nextflow

// Usage:
// nextflow run modules/crest.nf \
// --fasta ~/all_sequences_grouped.fa \
// --mount_crest_dbs /home/luna.kuleuven.be/u0156635/.crest4 \
// --database /home/luna.kuleuven.be/u0156635/.crest4/unite_19_02_2025/ \
// --asvs_contingency_table ~/asvs_contingency_hash.tsv \
// --search_algo vsearch \
// --outdir MORELES

process TRAIN_CREST_DB {

    tag "Training CREST database."

    publishDir { "${params.outdir}/crest_database_training" }, mode: 'copy'
    container "hariszaf/crest4:latest"

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

    container "hariszaf/crest4:4.4.2"
    // containerOptions '-v /home/luna.kuleuven.be/u0156635/.crest4:/crest4/.crest4:rw'
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


process BUILD_TAX_TABLE {

    tag "Building taxonomy table from CREST assignments."

    publishDir { "${params.outdir}/taxonomy_assignment" }, mode: 'copy'
    container "hariszaf/pema-nf:0.1.0"

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



workflow {

    params.fasta           = params.fasta ?: error("Please provide a fasta file to be classified (--fasta).")                   // asvs_representatives.fa
    params.mount_crest_dbs = params.mount_crest_dbs ?: error(
        "Please provide the path to the directory containing the CREST databases on your system (--mount_crest_dbs). 
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
        "
    )
    params.database        = params.database ?: error(
        "The database used for the sequence similarity search.
        Either `ssuome`, `silvamod138pr2`, 'mitofish', or `midori253darn`. By default, `ssuome`.
        In case of a custom database, please specify the full path to a directory containing all required files, making sure that is under the `mount_crest_dbs`."
    )
    params.threads         = params.threads ?: 4
    params.clustering_algo = params.clustering_algo ?: 'swarm'                                                                  // 'vsearch' or 'swarm'

    // search_algo: The algorithm used for the sequence similarity search
    // that will be run to match the sequences against the database chosen. Either `blast` or `vsearch`. By default, `blast`.
    params.search_algo     = params.search_algo ?: 'blast'                                                                      // 'blast' or 'vsearch'

    // The minimum bit-score for a search hit to be considered when using BLAST as the search algorithm. 
    // All hits below this score are ignored. When using VSEARCH, this value instead indicates the minimum identity between two sequences for the hit to be considered.
    // The default is `155` for BLAST and `0.75` for VSEARCH.
    params.min_score = params.min_score ?: (params.search_algo == 'blast' ? 155.0 : 0.75)

    // Boolean: Determines if the minimum similarity filter is turned on or off. 
    // The minimum similarity filter prevents classification to higher ranks when a minimum rank-identity is not met.
    params.min_smlrty = params.min_smlrty ?: true

    // Determines the range of hits to retain and the range to discard based on a drop in percentage from the score of the best hit. 
    // Any hit below the following value: "(100 - score_drop)/100 * best_hit_score" is ignored.
    params.score_drop = params.score_drop ?: 2.0


    def fasta = Channel.fromPath(params.fasta)

    def crest_taxonomy_assignment = CREST_TAXONOMY_ASSIGNMENT(
        fasta,
        params.database
    )

    def cont_table = Channel.fromPath("${params.asvs_contingency_table}")

    // Build the taxonomy table by combining the ASV contingency table and the CREST taxonomy assignments.
    def tax_table = BUILD_TAX_TABLE(cont_table, crest_taxonomy_assignment.assignments)


}

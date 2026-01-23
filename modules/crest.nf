#!/usr/bin/env nextflow


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

    publishDir { "${params.outdir}/taxonomy_assignment}" }, mode: 'copy'

    container "hariszaf/crest4:4.3.8"
    containerOptions '-v /home/luna.kuleuven.be/u0156635/.crest4:/crest4/.crest4:rw'

    input:
    path fasta
    val database

    output:
    path "taxonomy_assignment/assignments.txt", emit: assignments
    path "taxonomy_assignment/search.hits", emit: search_hits

    script:
    """
    crest4 --fasta ${fasta} \
            --search_algo ${params.search_algo} \
            --num_threads ${params.threads} \
            --search_db $database \
            --output_dir taxonomy_assignment
            --min_score ${params.min_score} \
            --min_smlrty ${params.min_smlrty} \
            --score_drop ${params.score_drop}
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
    path "tmp.txt", emit: tmp_file

    script:
    """
    #python /pema/scripts/crestTaxTable.py $asvs_contingency_table $assignments ${params.clustering_algo}
    crestTaxTable.py $asvs_contingency_table $assignments ${params.clustering_algo}
    """
}



workflow {

    // ASSIGN: nextflow run modules/crest.nf --fasta testingNfModules/asvs_representatives.fa  --database silvamod128

    params.fasta           = params.fasta ?: error("Please provide a fasta file to be classified (--fasta).")                   // asvs_representatives.fa
    params.database        = params.database ?: error("Please provide a database for CREST taxonomy assignment, from: midori253darn, silvamod128, silvamod138pr2, silvamod138pr2, unite2025 (--database).")
    params.threads         = params.threads ?: 4

    params.clustering_algo = params.clustering_algo ?: 'swarm'                                                                  // 'vsearch' or 'swarm'

    // search_algo: The algorithm used for the sequence similarity search
    // that will be run to match the sequences against the database chosen. Either `blast` or `vsearch`. By default, `blast`.
    params.search_algo     = params.search_algo ?: 'blast'                                                                      // 'blast' or 'vsearch'

    // The minimum bit-score for a search hit to be considered when using BLAST as the search algorithm. 
    // All hits below this score are ignored. When using VSEARCH, this value instead indicates the minimum identity between two sequences for the hit to be considered.
    // The default is `155` for BLAST and `0.75` for VSEARCH.
    params.min_score = params.min_score ?: (params.search_algo == 'blast' ? 155 : 0.75)

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





    // // TABLE: nextflow run modules/crest.nf  --asvs_contingency_table testingNfModules/asvs_contingency_table.tsv --assignments_txt testingNfModules/taxonomy_assignment/assignments.txt

    // def cont_table = Channel.fromPath("${params.asvs_contingency_table}")
    // def crest_taxonomy_assignment = Channel.fromPath("${params.assignments_txt}")

    // def tax_table = BUILD_TAX_TABLE(
    //     cont_table, crest_taxonomy_assignment
    // )


}




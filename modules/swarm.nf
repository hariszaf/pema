#!/usr/bin/env nextflow

/* Nextflow script to run Swarm v3

Usage: 

nextflow run modules/swarm.nf --input_fasta path/to/amplicons.fasta --case fastidious --threads 3 --outdir results/swarm_results 

(optional )
--boundary 2    (only for fastidious case) 
                By default, an ASV with a mass of 3 or more is considered large. Conversely, an ASV is small if it has a mass of less than 3, 
                meaning that it is composed of either one amplicon of abundance 2, or two amplicons of abundance 1. Any positive value greater than 1 can be specified.
                Using higher boundary values will speed up the second pass, but also reduce the taxonomical resolution of swarm results.  

--differences 7 (only for non-fastidious case) 
                Maximum number of differences allowed between two amplicons so they would be groouped together,  
                i.e. two amplicons will be grouped together if they have d (or less) differences.

*/


process SWARM {

    tag "Cluster sets of amplicons based on a local clustering threshold"

    publishDir { "${params.outdir}/swarm" }, mode: 'copy'

    container "quay.io/biocontainers/swarm:3.1.6--h9948957_0"

    input:
    path(input_fasta)

    output:
    path("asvs_representatives_hash.fa")
    path("asvs.stats")
    path("asvs.swarms")

    script:
    """
    if [[ "${params.case}" == "fastidious" ]]; then

        swarm \
            --differences 1 \
            --fastidious \
            --boundary ${params.boundary} \
            --threads ${params.threads} \
            --statistics-file asvs.stats \
            --seeds asvs_representatives_hash.fa \
            < ${input_fasta} > asvs.swarms

    else

        swarm \
            --differences ${params.differences} \
            --threads ${params.threads} \
            --statistics-file asvs.stats \
            --seeds asvs_representatives_hash.fa \
            < ${input_fasta} > asvs.swarms
    fi
    """
}


workflow {

    // -------------------- PARAMETERS --------------------
    params.input_fasta = params.input_fasta ?: error(
        "Please provide a fasta file with the amplicons to be clustered (--input_fasta)."
    )
    params.threads     = params.threads ?: 3
    params.outdir      = params.outdir ?: "results"
    params.differences = params.differences ?: 1
    params.boundary    = params.boundary ?: 2
    params.case        = params.case ?: "fastidious"

    def input_seq = Channel.fromPath(params.input_fasta)

    // Run process 
    SWARM(input_seq)

}

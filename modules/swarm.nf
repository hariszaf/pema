#!/usr/bin/env nextflow

/* Nextflow script to run Swarm v3

Usage: 

nextflow run modules/swarm.nf --input_fasta path/to/amplicons.fasta --case fastidious --threads 3 --outdir results/swarm_results 

nextflow run modules/swarm.nf --params-file config_files/swarm.yaml


(optional )
--boundary 2    (only for fastidious case) 
                By default, an ASV with a mass of 3 or more is considered large. Conversely, an ASV is small if it has a mass of less than 3, 
                meaning that it is composed of either one amplicon of abundance 2, or two amplicons of abundance 1. Any positive value greater than 1 can be specified.
                Using higher boundary values will speed up the second pass, but also reduce the taxonomical resolution of swarm results.  

--differences 7 (only for non-fastidious case) 
                Maximum number of differences allowed between two amplicons so they would be groouped together,  
                i.e. two amplicons will be grouped together if they have d (or less) differences.

*/

include { loadYamlParams; paramsToCliArgs } from './utils.nf'

process SWARM {

    tag "Cluster sets of amplicons based on a local clustering threshold"

    publishDir { "${params.outdir}/swarm" }, mode: 'copy'

    container "quay.io/biocontainers/swarm:3.1.6--h9948957_0"

    input:
    path(input_fasta)
    val swarm_params

    output:
    path("asvs_representatives_hash.fa")
    path("asvs.stats")
    path("asvs.swarms")

    script:
    def swarm_params_str =  paramsToCliArgs(swarm_params)
    """
    swarm \
        --threads ${params.threads} \
        --statistics-file asvs.stats \
        --seeds asvs_representatives_hash.fa \
        $swarm_params_str < ${input_fasta} > asvs.swarms
    """
}
    // if [[ "${params.case}" == "fastidious" ]]; then

    //     swarm \
    //         --differences 1 \
    //         --fastidious \
    //         --boundary ${params.boundary} \
    //         --threads ${params.threads} \
    //         --statistics-file asvs.stats \
    //         --seeds asvs_representatives_hash.fa \
    //         < ${input_fasta} > asvs.swarms

    // else

    //     swarm \
    //         --differences ${params.differences} \
    //         --threads ${params.threads} \
    //         --statistics-file asvs.stats \
    //         --seeds asvs_representatives_hash.fa \
    //         < ${input_fasta} > asvs.swarms
    // fi

workflow {

    params.yaml = params.paramsFile ?: error(
        "No parameters file"
    )

    // -------------------- PARAMETERS --------------------
    params.input_fasta = loadYamlParams(params.yaml, 'input_fasta') ?: error(
        "Please provide a fasta file with the amplicons to be clustered (--input_fasta)."
    )
    params.threads     = loadYamlParams(params.yaml, 'threads') ?: 3
    params.outdir      = loadYamlParams(params.yaml, 'outdir') ?: "results"

    def swarm_params = loadYamlParams(params.yaml, 'swarm') ?: error(
        """Please make sure you have a parameter called 'swarm' into your YAML file, 
        with the parameter values for how to run swarm."""
    )

    def input_seq = Channel.fromPath(params.input_fasta)

    // Run process 
    // SWARM(input_seq)
    SWARM(input_seq, swarm_params)

}

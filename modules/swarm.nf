#!/usr/bin/env nextflow

/* Nextflow script to run Swarm v3

Usage: 

    nextflow run modules/swarm.nf --params-file config_files/swarm.yaml

*/

include { loadYamlParams; paramsToCliArgs } from './utils.nf'

process SWARM {

    tag "Cluster sets of amplicons based on a local clustering threshold"

    publishDir { "${params.outdir}/swarm" }, mode: 'copy'

    container "quay.io/biocontainers/swarm:3.1.6--h9948957_0"

    input:

        path input_fasta
        val swarm_params

    output:

        path("asvs.stats"), emit: swarm_stats
        path("asvs.swarms"), emit: swarm_swarms
        path("asvs_representatives_hash.fa"), emit: hash_fasta

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


workflow {

    params.yaml = params.paramsFile ?: error("No parameters file")

    // -------------------- PARAMETERS --------------------
    params.input_fasta = loadYamlParams(params.yaml, 'input_fasta') ?: error(
        "Please provide a fasta file with the amplicons to be clustered (--input_fasta).")
    params.threads     = loadYamlParams(params.yaml, 'threads') ?: 3
    params.outdir      = loadYamlParams(params.yaml, 'outdir') ?: "results"

    def swarm_params = loadYamlParams(params.yaml, 'swarm') ?: error(
        """Please make sure you have a parameter called 'swarm' into your YAML file, 
        with the parameter values for how to run swarm."""
    )

    def input_seq = Channel.fromPath(params.input_fasta)

    println(swarm_params)

    // Run process 
    SWARM(input_seq, swarm_params)

}

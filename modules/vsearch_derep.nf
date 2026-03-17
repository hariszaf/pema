#!/usr/bin/env nextflow

/* Nextflow script to run VSEARCH tasks

Usage: 

nextflow run modules/vsearch.nf --params-file config_files/vsearch_derep.yaml 

*/

include { paramsToCliArgs; loadYamlParams } from './utils.nf'

process VSEARCH_DEREP {

    tag "Dereplicate fastq files using VSEARCH.."

    publishDir { "${params.outdir}/derep_samples" }, mode: 'copy'

    container "quay.io/biocontainers/vsearch:2.30.4--hd6d6fdc_0"

    input:
    path underep_fastq

    output:
    path "*.fasta", emit: derep_fasta

    script:
    """
    SAMPLE_NAME=\$(basename $underep_fastq .fastq.gz)

    vsearch --fastx_uniques ${underep_fastq} \
            --fastaout derep_\$SAMPLE_NAME.fasta \
            --sizeout
    """
}


workflow {

    // -------------------- PARAMETERS --------------------
    params.yaml = params.paramsFile ?: error(
        "Please provide YAML file with fastp parameters (--params-file)."
    )
    //  Loading parameters from YAML file. 
    params.input_files  = loadYamlParams(params.yaml, 'files_to_dereplicate') ?: error(
        "Please provide folder with raw reads (--files_to_dereplicate)"
    )
    params.threads    = loadYamlParams(params.yaml, 'threads') ?: 3
    params.outdir     = loadYamlParams(params.yaml, 'outdir') ?: "results"

    // -------------------- CHANNELS --------------------
    def underep = Channel.fromPath("${params.input_files}/*.fastq.gz")

    // -------------------- DEREPLICATION --------------------
    VSEARCH_DEREP(underep)
}



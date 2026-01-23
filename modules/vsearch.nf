#!/usr/bin/env nextflow

/* Nextflow script to run VSEARCH tasks

Usage: 

nextflow run modules/vsearch.nf -

*/



process VSEARCH {

    tag "VSEARCH task.. "

    publishDir { "${params.outdir}/vsearch" }, mode: 'copy'

    container "quay.io/biocontainers/vsearch:2.30.4--hd6d6fdc_0"

    input:
    path(input_fasta)

    output:


    script:
    """
    """
}


workflow {
    
}



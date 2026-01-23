#!/usr/bin/env nextflow

/* Nextflow script to run fastp (https://github.com/OpenGene/fastp)

Usage: 

nextflow run modules/fastp.nf -params-file modules/faprotax/faprotax.yaml 

*/

process CUTADAPT {

    tag "Sequencing quality control and merging per paired read sample."

    publishDir "${params.outdir}/fastp", mode: 'copy'
    container "quay.io/biocontainers/1.0.1--heae3180_0"

    input:
    tuple val(sampleName), path(readF), path(readR)

    output:
    // QC files into qc subfolder
    path("qc/${sampleName}.html"), emit: qc_html
    path("qc/${sampleName}.json"), emit: qc_json

    // Merged reads into merged subfolder
    path("merged/${sampleName}.fastq.gz"), emit: merged_reads

    script:
    """
    Rscript cutadaptITS.R $readF $readR $forwardITSPrimer $reverseITSPrimer $params{'dataPath'}
    """
}

workflow{

    // Pattern 1: _1/_2
    def paired1 = Channel.fromFilePairs("${params.raw_reads}/*_{1,2}.fastq.gz", flat: true)

    // Pattern 2: _R1_/_R2_
    def paired2 = Channel.fromFilePairs("${params.raw_reads}/*_R{1,2}_*.fastq.gz", flat: true)

    // Merge channels; only if not empty
    def paired_raw_reads = Channel.empty()
        .mix(paired1)
        .mix(paired2)

    // Run process 
    CUTADAPT(paired_raw_reads)
}


#!/usr/bin/env nextflow

/* Nextflow script to run fastp (https://github.com/OpenGene/fastp)

Usage: 

    nextflow run modules/fastp.nf --params-file modules/fastp.yaml

*/

include { paramsToCliArgs; loadYamlParams } from './utils.nf'

process FASTP {

    tag "FASTP QC and merging"

    publishDir { "${params.outdir}/fastp" }, mode: 'copy'

    container "quay.io/biocontainers/fastp:1.0.1--heae3180_0"

    input:

        tuple val(sampleName), path(readF), path(readR)
        val fastpArgs

    output:

        path("qc/${sampleName}.html"), emit: qc_html
        path("qc/${sampleName}.json"), emit: qc_json
        path("merged/${sampleName}.fastq.gz"), emit: merged_reads

    script:

        // -------------------- BUILD FASTP ARGS --------------------
        def fastpParamsStr = paramsToCliArgs(fastpArgs)

        """
        mkdir -p qc merged

        fastp \
            --in1 $readF \
            --in2 $readR \
            --out1 ${sampleName}_proc_R1.fastq.gz \
            --out2 ${sampleName}_proc_R2.fastq.gz \
            --merge \
            --merged_out merged/${sampleName}.fastq.gz \
            --thread ${params.threads} \
            --html qc/${sampleName}.html \
            --json qc/${sampleName}.json \
            $fastpParamsStr
        """
}


// Workflow for running fastp on paired-end reads. 
workflow {

    // -------------------- PARAMETERS --------------------
    params.yaml = params['params-file'] ?: error(
        "Please provide YAML file with fastp parameters (--params-file)."
    )
    //  Loading parameters from YAML file. 
    // If a parameter is not provided in the YAML, it will be set to a default value 
    // or an error will be thrown if it's required.
    def fastpParams   = loadYamlParams(params.yaml, 'fastp')
    params.raw_reads  = loadYamlParams(params.yaml, 'raw_reads') ?: error(
        "Please provide folder with raw reads (--raw_reads)"
    )
    params.threads    = loadYamlParams(params.yaml, 'threads') ?: 3
    params.outdir     = loadYamlParams(params.yaml, 'outdir') ?: "results"

    // -------------------- CHANNELS --------------------
    def paired1 = Channel.fromFilePairs("${params.raw_reads}/*_{1,2}.fastq.gz", flat: true)
    def paired2 = Channel.fromFilePairs("${params.raw_reads}/*_R{1,2}_*.fastq.gz", flat: true)

    def paired_raw_reads = Channel.empty().mix(paired1).mix(paired2)

    // -------------------- RUN FASTP --------------------
    FASTP(paired_raw_reads, fastpParams)
}

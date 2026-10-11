#!/usr/bin/env nextflow

/* Nextflow script to run fastp (https://github.com/OpenGene/fastp)

Usage: 

    nextflow run modules/fastp.nf --params-file tests/configs/fastp.yaml -c nextflow.config

*/

include { paramsToCliArgs; loadYamlParams; findReadPairs } from './utils.nf'

// Quality control of each read pair, and merging of the pairs; with merge = false (for DADA2,
// which denoises the forward and reverse reads separately and merges them afterwards) the
// filtered read pairs are returned instead of merged reads
process FASTP {

    tag "${sampleName}"

    publishDir { "${params.outdir}/fastp" }, mode: 'copy', pattern: "{qc,merged,filtered}/*"

    container "quay.io/biocontainers/fastp:1.0.1--heae3180_0"

    cpus params.threads

    input:

        tuple val(sampleName), path(readF), path(readR)
        val fastpArgs
        val merge

    output:

        path("qc/${sampleName}.html"), emit: qc_html
        path("qc/${sampleName}.json"), emit: qc_json
        path("merged/${sampleName}.fastq.gz"), emit: merged_reads, optional: true
        tuple val(sampleName), path("filtered/${sampleName}_1.fastq.gz"), path("filtered/${sampleName}_2.fastq.gz"),
            emit: filtered_reads, optional: true

    script:

        // -------------------- BUILD FASTP ARGS --------------------
        def fastpParamsStr = paramsToCliArgs(fastpArgs)
        def outputs = merge
            ? "--out1 ${sampleName}_proc_R1.fastq.gz --out2 ${sampleName}_proc_R2.fastq.gz --merge --merged_out merged/${sampleName}.fastq.gz"
            : "--out1 filtered/${sampleName}_1.fastq.gz --out2 filtered/${sampleName}_2.fastq.gz"

        """
        mkdir -p qc merged filtered

        fastp \\
            --in1 $readF \\
            --in2 $readR \\
            ${outputs} \\
            --thread ${task.cpus} \\
            --html qc/${sampleName}.html \\
            --json qc/${sampleName}.json \\
            $fastpParamsStr
        """
}


// Workflow for running fastp on paired-end reads. 
workflow {

    // -------------------- PARAMETERS --------------------
    params.yaml = params.paramsFile ?: error(
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
    def paired_raw_reads = channel.fromList(findReadPairs(params.raw_reads.toString()))

    // -------------------- RUN FASTP --------------------
    FASTP(paired_raw_reads, fastpParams, true)
}

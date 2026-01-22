#!/usr/bin/env nextflow

/* Nextflow script to run fastp (https://github.com/OpenGene/fastp)

Usage: 

nextflow run modules/fastp.nf --raw_reads sanity_check/16S/mydata16s  --threads 3 --outdir testingNfModules --params-file modules/fastp.yaml 

*/

@Grab('org.yaml:snakeyaml:1.33')
import org.yaml.snakeyaml.Yaml

// Convert loaded arguments from the YAML file to CLI arguments, 
// e.g. --adapter_sequence AGATCGGAAGAGCACACGTCTGAACTCCAGTCA 
// Attention! We assume whole parameter names and tools that expet two `-` for them
def paramsToCliArgs(Map p) {
    if( !p ) return ""

    return p.collect { k, v ->
        if (v == null)
            return null

        if (v instanceof Boolean)
            return v ? "--$k" : null

        return "--$k $v"
    }.findAll { it }.join(' ')
}

// The `section` corresponds to the nested nature of the YAML file, so you load the part of it you wish.
def loadYamlParams( String yamlFilePath, String section ) {
    def yamlText = new File(yamlFilePath).text
    def yaml     = new Yaml()
    def params   = yaml.load(yamlText)
    return params[section] ?: [:]
}


process FASTP {

    tag "FASTP QC and merging"

    publishDir { "${params.outdir}/fastp" }, mode: 'copy'
    container "quay.io/biocontainers/1.0.1--heae3180_0"

    input:
    tuple val(sampleName), path(readF), path(readR)
    val fastpArgs

    output:
    // QC files into qc subfolder
    path("qc/${sampleName}.html"), emit: qc_html
    path("qc/${sampleName}.json"), emit: qc_json

    // Merged reads into merged subfolder
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


workflow {

    // -------------------- PARAMETERS --------------------
    params.fastp_yaml = params.paramsFile ?: error("Please provide YAML file with fastp parameters (--params-file).")
    params.raw_reads  = params.raw_reads ?: error("Please provide folder with raw reads (--raw_reads)")
    params.threads    = params.threads ?: 3
    params.outdir     = params.outdir ?: "results"

    // -------------------- LOAD FASTP YAML --------------------
    def fastpParams = loadYamlParams(params.fastp_yaml, 'fastp')

    // -------------------- CHANNELS --------------------
    def paired1 = Channel.fromFilePairs("${params.raw_reads}/*_{1,2}.fastq.gz", flat: true)
    def paired2 = Channel.fromFilePairs("${params.raw_reads}/*_R{1,2}_*.fastq.gz", flat: true)

    def paired_raw_reads = Channel.empty().mix(paired1).mix(paired2)

    // -------------------- RUN FASTP --------------------
    FASTP(paired_raw_reads, fastpParams)
}

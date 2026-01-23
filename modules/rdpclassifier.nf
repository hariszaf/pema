#!/usr/bin/env nextflow

/* Nextflow script to run rdpclassifier.jar ()

Usage: 

nextflow run modules/rdpclassifier.nf -params-file modules/faprotax/faprotax.yaml 

*/

process RDPCLASSIFY {

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
    java -Xmx64g \
        -jar /opt/rdp_classifier_2.14/dist/classifier.jar classify \
        -t $globalVars{'tools'}/rdp_classifier_2.14/TRAIN/$params{'referenceDb'}/rRNAClassifier.properties \
        -o tax_assign_temp.txt all_sequences_grouped.fa
    """
}


workflow{

    // Pattern 1: _1/_2
    def paired1 = Channel.fromFilePairs("${params.raw_reads}/*_{1,2}.fastq.gz", flat: true)

    // Run process 
    RDPCLASSIFY(paired_raw_reads)
}


#!/usr/bin/env nextflow

/* Nextflow process to remove the primers of ITS amplicons with cutadapt (https://cutadapt.readthedocs.io)

   ITS amplicons vary in length; when one is shorter than the reads, the reads run into the opposite primer.
   So, on the raw read pairs (before fastp), as in the DADA2 ITS workflow:
     read 1: the forward primer (5', -g) and the reverse complement of the reverse primer (3', -a)
     read 2: the reverse primer (5', -G) and the reverse complement of the forward primer (3', -A)
*/

include { paramsToCliArgs } from './utils.nf'

// Reverse complement of a primer, with IUPAC ambiguity codes
def reverseComplement(String seq) {
    def complement = [
        A: 'T', T: 'A', U: 'A', G: 'C', C: 'G',
        R: 'Y', Y: 'R', S: 'S', W: 'W', K: 'M', M: 'K',
        B: 'V', V: 'B', D: 'H', H: 'D', N: 'N', I: 'I'
    ]
    return seq.toUpperCase().reverse().collect { base ->
        complement[base] ?: error("Primer '${seq}': '${base}' is not a nucleotide (IUPAC) code.")
    }.join('')
}


process CUTADAPT {

    tag "${sampleName}"

    publishDir { "${params.outdir}/cutadapt" }, mode: 'copy', pattern: "*.cutadapt.json"

    container "quay.io/biocontainers/cutadapt:5.2--py312hfabe715_2"

    cpus params.threads

    input:
        tuple val(sampleName), path(readF), path(readR)
        val cutadapt_params

    output:
        tuple val(sampleName), path("${sampleName}_1.trimmed.fastq.gz"), path("${sampleName}_2.trimmed.fastq.gz"), emit: trimmed_reads
        path "${sampleName}.cutadapt.json", emit: report

    script:
        def fwd   = cutadapt_params.forward_primer.toString().trim().toUpperCase()
        def rev   = cutadapt_params.reverse_primer.toString().trim().toUpperCase()
        // Any other option of the cutadapt section is passed as it is, e.g. minimum-length: 50
        def extra = paramsToCliArgs(cutadapt_params.findAll { k, _v -> !(k in ['forward_primer', 'reverse_primer']) })
        """
        cutadapt \\
            -g ${fwd} -a ${reverseComplement(rev)} \\
            -G ${rev} -A ${reverseComplement(fwd)} \\
            -n 2 \\
            --cores ${task.cpus} \\
            ${extra} \\
            --json ${sampleName}.cutadapt.json \\
            -o ${sampleName}_1.trimmed.fastq.gz \\
            -p ${sampleName}_2.trimmed.fastq.gz \\
            ${readF} ${readR}
        """
}

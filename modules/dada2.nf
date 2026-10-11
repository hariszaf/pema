#!/usr/bin/env nextflow

/* ASV inference with DADA2 (https://benjjneb.github.io/dada2/).

   DADA2 takes the filtered read pairs of all samples (fastp without merging): it learns the error rates and denoises
   the forward and the reverse reads separately, merges the denoised pairs (mergePairs) and removes the chimeras.
   Its outputs have the same format as those of Swarm (asvs_contingency_hash.tsv, asvs_representatives.fa, ...),
   so the taxonomy assignment works the same way.
*/

process DADA2 {

    tag "ASV inference with DADA2."

    publishDir { "${params.outdir}/dada2" }, mode: 'copy', pattern: "dada2_*"
    publishDir { "${params.outdir}" }, mode: 'copy', pattern: "asvs_*"

    container "quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0"

    cpus params.threads

    input:
        path forward_reads, stageAs: 'reads/*'
        path reverse_reads, stageAs: 'reads/*'
        path dada2_script
        val dada2_params
        val min_oligotons

    output:
        path "asvs_contingency_hash.tsv", emit: asvs_contingency_hash
        path "asvs_contingency_table.tsv", emit: asvs_contingency_table
        path "asvs_representatives.fa", emit: asvs_to_tax_assign
        path "dada2_seqtab.tsv", emit: seqtab
        path "dada2_read_tracking.tsv", emit: read_tracking
        path "dada2_errors.pdf", emit: error_plots

    script:
        """
        # Denoising, merging and chimera removal (writes dada2_seqtab.tsv: sequence, abundance per sample)
        cd reads
        Rscript ../${dada2_script} \\
            ${task.cpus} \\
            ${dada2_params.pool} \\
            ${dada2_params.min_overlap} \\
            ${dada2_params.max_mismatch} \\
            ${dada2_params.chimera_method} \\
            ${dada2_params.nbases} \\
            ${min_oligotons}
        mv dada2_* ..
        cd ..

        # The ASV tables of PEMA: ASV_1, ASV_2, ... by decreasing total abundance, linked to their
        # representative sequence by its SHA1 hash (Seed)
        samples=\$(head -n 1 dada2_seqtab.tsv | cut -f 2-)
        printf 'ASV\\tSeed\\t%s\\n' "\$samples" > asvs_contingency_hash.tsv
        printf 'ASV\\t%s\\n' "\$samples" > asvs_contingency_table.tsv
        : > asvs_representatives.fa
        n=0
        tail -n +2 dada2_seqtab.tsv | while IFS=\$'\\t' read -r sequence counts; do
            n=\$((n + 1))
            hash=\$(printf '%s' "\$sequence" | sha1sum | cut -d ' ' -f 1)
            printf 'ASV_%d\\t%s\\t%s\\n' "\$n" "\$hash" "\$counts" >> asvs_contingency_hash.tsv
            printf 'ASV_%d\\t%s\\n' "\$n" "\$counts" >> asvs_contingency_table.tsv
            printf '>%s\\n%s\\n' "\$hash" "\$sequence" >> asvs_representatives.fa
        done
        """
}

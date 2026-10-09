#!/usr/bin/env nextflow

/* Nextflow processes for OTU clustering with VSEARCH, following the VSEARCH pipeline of T. Rognes
   (https://github.com/torognes/vsearch/wiki/VSEARCH-pipeline):

   1. dereplicate the amplicons of all samples, dropping those with a total abundance below min_oligotons
   2. precluster at the clustering threshold (denoising)
   3. remove chimeras de novo
   4. map the non-chimeric preclusters back to the dereplicated amplicons, and these back to all amplicons
   5. cluster the non-chimeric amplicons into OTUs
   6. build the OTU contingency tables

   The input is hash_all_samples.fa: one sequence per unique amplicon, named <sha1>_<total abundance>.
   About the .uc files: https://www.drive5.com/usearch/manual/opt_uc.html
*/

include {
    VSEARCH_MAP_BACK as VSEARCH_MAP_BACK_DEREP;
    VSEARCH_MAP_BACK as VSEARCH_MAP_BACK_ALL
} from './utils.nf'

process VSEARCH_DEREP_ALL {

    tag "Dereplicate all amplicons and remove oligotons."

    publishDir { "${params.outdir}/vsearch" }, mode: 'copy'

    container "quay.io/biocontainers/vsearch:2.30.4--hd6d6fdc_0"

    input:
        path all_samples_fasta
        val min_oligotons

    output:
        path "all_samples.fasta", emit: all_fasta
        path "derep.uc", emit: uc
        path "derep.fasta", emit: fasta

    script:
        """
        # VSEARCH expects the abundance as ;size=
        sed 's/_/;size=/' ${all_samples_fasta} > all_samples.fasta

        vsearch \\
            --derep_fulllength all_samples.fasta \\
            --minuniquesize ${Math.max(min_oligotons as int, 1)} \\
            --sizein \\
            --sizeout \\
            --fasta_width 0 \\
            --uc derep.uc \\
            --output derep.fasta
        """
}


process VSEARCH_PRECLUSTER {

    tag "Precluster (denoise) the dereplicated amplicons."

    publishDir { "${params.outdir}/vsearch" }, mode: 'copy'

    container "quay.io/biocontainers/vsearch:2.30.4--hd6d6fdc_0"

    cpus params.threads

    input:
        path derep_fasta
        val threshold

    output:
        path "preclustered.uc", emit: uc
        path "preclustered.fasta", emit: fasta

    script:
        """
        vsearch \\
            --threads ${task.cpus} \\
            --cluster_size ${derep_fasta} \\
            --id ${threshold} \\
            --strand both \\
            --sizein \\
            --sizeout \\
            --fasta_width 0 \\
            --uc preclustered.uc \\
            --centroids preclustered.fasta
        """
}


process VSEARCH_CHIMERAS {

    tag "De novo chimera removal."

    publishDir { "${params.outdir}/vsearch" }, mode: 'copy'

    container "quay.io/biocontainers/vsearch:2.30.4--hd6d6fdc_0"

    input:
        path preclustered_fasta

    output:
        path "nonchimeras_preclustered.fasta", emit: fasta

    script:
        """
        vsearch \\
            --uchime_denovo ${preclustered_fasta} \\
            --sizein \\
            --sizeout \\
            --fasta_width 0 \\
            --nonchimeras nonchimeras_preclustered.fasta
        """
}


process VSEARCH_CLUSTER_OTUS {

    tag "OTU clustering."

    publishDir { "${params.outdir}/vsearch" }, mode: 'copy'

    container "quay.io/biocontainers/vsearch:2.30.4--hd6d6fdc_0"

    cpus params.threads

    input:
        path nonchimeras_fasta
        val threshold

    output:
        path "otus.uc", emit: uc
        path "otus.fasta", emit: fasta

    script:
        """
        vsearch \\
            --threads ${task.cpus} \\
            --cluster_size ${nonchimeras_fasta} \\
            --id ${threshold} \\
            --strand both \\
            --sizein \\
            --sizeout \\
            --fasta_width 0 \\
            --uc otus.uc \\
            --centroids otus.fasta
        """
}


process OTUS_CONTINGENCY_TABLE {

    tag "Build contingency table using the OTUs returned"

    publishDir "${params.outdir}", mode: 'copy'

    container "hariszaf/pema-nf:0.2.2"

    input:
        path otus_uc
        path otus_fasta
        path amplicon_contingency_table

    output:
        path "otus_contingency_hash.tsv", emit: contingency_hash
        path "otus_contingency_table.tsv", emit: contingency_table
        path "otus_representatives.fa", emit: representatives

    script:
        """
        python3 /opt/pema/scripts/otu_contingency_table.py \\
            --uc ${otus_uc} \\
            --centroids ${otus_fasta} \\
            --amplicon-table ${amplicon_contingency_table}
        """
}


// OTU clustering, from all unique amplicons to the OTU tables and representative sequences
workflow VSEARCH_OTUS {

    take:
        all_samples_fasta
        amplicon_contingency_table
        threshold
        min_oligotons

    main:
        derep       = VSEARCH_DEREP_ALL(all_samples_fasta, min_oligotons)
        precluster  = VSEARCH_PRECLUSTER(derep.fasta, threshold)
        nonchimeras = VSEARCH_CHIMERAS(precluster.fasta)

        // Non-chimeric preclusters -> dereplicated amplicons -> all amplicons
        nonchimeras_derep = VSEARCH_MAP_BACK_DEREP(
            derep.fasta, precluster.uc, nonchimeras.fasta, "nonchimeras_derep.fasta"
        )
        nonchimeras_all = VSEARCH_MAP_BACK_ALL(
            derep.all_fasta, derep.uc, nonchimeras_derep.fasta, "nonchimeras.fasta"
        )

        otus  = VSEARCH_CLUSTER_OTUS(nonchimeras_all.fasta, threshold)
        table = OTUS_CONTINGENCY_TABLE(otus.uc, otus.fasta, amplicon_contingency_table)

    emit:
        contingency_hash = table.contingency_hash
        representatives  = table.representatives
}

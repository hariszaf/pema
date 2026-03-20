#!/usr/bin/env nextflow


include { paramsToCliArgs; loadYamlParams } from './utils.nf'


process REMOVE_OLIGOS_SWARM {

    tag "Removing oligotons from ASVs data files."

    publishDir { "${params.outdir}/oligos" }, mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:

        path stats
        path swarms
        path hash_fasta
        val threshold
        
    output:

        path("filtered_asvs.stats"), emit: swarm_stats_filtered
        path("filtered_asvs.swarms"), emit: swarm_swarms_filtered
        path("filtered_asvs_representatives_hash.fa"), emit: hash_fasta_filtered

    script:

        """
        python /opt/pema/scripts/remove_oligotons.py \
        --clustering-algo swarm \
        --stats $stats \
        --swarms  $swarms \
        --hash-fasta $hash_fasta \
        --threshold $threshold
        """
}


process REMOVE_OLIGOS_VSEARCH {

    tag "Removing oligotons from ASVs data files."

    publishDir { "${params.outdir}/oligos" }, mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:

        path(otu_table) 
        path(otu_fasta)
        val(threshold)
        
    output:

        path(""), emit: otu_table_filtered
        path(""), emit: otu_fasta_filtered


    script:

        """
        python /opt/pema/scripts/remove_oligotons.py \
        --clustering-algo vsearch \
        --otu-table $otu_table \
        --otu-fasta $otu_fasta \
        --threshold $threshold
        """
}


workflow {




}


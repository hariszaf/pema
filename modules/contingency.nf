
process CONTINGENCY_TABLE {

    tag "Dereplication at the study level (contingency table)"

    publishDir "${params.outdir}", mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:
    path derep_files

    output:
    path "amplicon_contingency_table.tsv", emit: contingency_table

    script:
    """
    bash /opt/pema/scripts/contingency_table.sh ${derep_files}
    """
}


process OLIGOTONS_FROM_SWARM {
    tag "Remove oligotons from Swarm findings."

    publishDir "${params.outdir}"
    // container

    input:
    path swarm_stats
    path swarm_swarms
    path asvs_repr_hash
    val threshold
    path pyscript

    output:
    path "asvs.stats", emit: swarm_stats
    path "asvs.swarms", emit: swarm_seeds
    path "asvs_representatives_hash.fa", emit: asvs_hash

    script:
    """
    python $pyscript $swarm_stats $swarm_swarms $asvs_repr_hash $threshold
    """
}


process ASVS_CONTINGENCY_TABLE {

    tag "Build contingency table using the ASVs returned"

    publishDir "${params.outdir}", mode: 'copy'
    // container ""

    // Usage:
    // nextflow run modules/utils.nf --asvs_stats testingNfModules/swarm/asvs.stats 
    // --asvs_swarms testingNfModules/swarm/asvs.swarms 
    // --contingency_table work/b9/7f599549bf8533ae56bab818bbf702/amplicon_contingency_table.tsv 
    // --script pema/scripts/createASVsContingencyTable.sh  
    // --asvs_repr_hash testingNfModules/swarm/asvs_representatives_hash.fa 

    input:
    path asvs_stats
    path asvs_swarms
    path asvs_repr_hash
    path contingency_table
    path build_sh

    output:
    path "asvs_contingency_hash.tsv", emit: asvs_contingency_hash
    path "asvs_contingency_table.tsv", emit: asvs_contingency_table
    path "asvs_representatives.fa", emit: asvs_to_tax_assign

    script:
    """
    bash $build_sh
    sed -i 's/_[0-9]*//' asvs_representatives.fa
    """
}

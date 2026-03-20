#!/usr/bin/env nextflow

/* Nextflow processes to query NCBI API for a list of taxonomies as returned by a pema classifier

Usage:

    nextflow run modules/ncbi.nf --params-file config_files/ncbi.yaml
*/

include { paramsToCliArgs; loadYamlParams } from './utils.nf'


params.max_parallel = params.max_parallel ?: 1
params.ncbi_api_key = params.ncbi_api_key ?: null
params.sleep        = params.sleep ?: 0.4


workflow {

    strings_ch = Channel.fromPath(params.strings_file)
    unique_ch  = UNIQUE_TAXA(strings_ch)

    // -------------------------------
    // Load strings from file
    // -------------------------------
    taxa_ch = unique_ch
        .map { file -> file.text }
        .splitText()
        .map { it.trim() }
        .filter { it }

    // -------------------------------
    // Run API query for each taxon
    // -------------------------------
    ncbi_taxonomies_ch = NCBI_TAXONOMY_QUERY(taxa_ch)

    // -------------------------------
    // Merge all results
    // -------------------------------
    MERGE_NCBI_TAXONOMIES(ncbi_taxonomies_ch.taxon_file.collect(), ncbi_taxonomies_ch.error_file.collect())

}

// ===============================
// Process: NCBI_TAXONOMY_QUERY
// ===============================
process NCBI_TAXONOMY_QUERY {

    tag {"Get NCBI Taxonomy metadata for" }

    container "biocontainers/ncbi-datasets-cli:16.22.1_cv1"

    // Limit parallelism
    maxForks params.max_parallel

    input:
        val taxon

    output:
        path "ncbi_ids/*.tsv", emit: taxon_file
        path "ncbi_ids/*.err", emit: error_file

    script:
    """
    mkdir -p ncbi_ids

    taxon_clean=\$(echo "${taxon}" | tr -d '()' | tr '/:' '_')

    # Export API key to be visible to datasets CLI if provided
    if [ -n "${params.ncbi_api_key}" ]; then
        export NCBI_API_KEY="${params.ncbi_api_key}"
    fi

    output_filename="\${taxon_clean// /_}"

    # Run the NCBI API CLI  
    datasets summary taxonomy taxon "\$taxon_clean" > "ncbi_ids/\$output_filename.tsv" 2> "ncbi_ids/\$output_filename.err"

    # Sleep 
    sleep_time=0.4  # default

    if [ -n "${params.ncbi_api_key}" ]; then
        if [ -n "${params.sleep}" ]; then
            # if params.sleep > 0.1
            if awk "BEGIN{exit !(${params.sleep} > 0.1)}"; then
                sleep_time=${params.sleep}
            else
                sleep_time=0.1
            fi
        fi
    else
        if [ -n "${params.sleep}" ]; then
            # if params.sleep < 0.4
            if awk "BEGIN{exit !(${params.sleep} < 0.4)}"; then
                sleep_time=0.4
            else
                sleep_time=${params.sleep}
            fi
        fi
    fi

    sleep \$sleep_time
    """
}

// ===============================
// Process: MERGE_NCBI_TAXONOMIES
// ===============================

process MERGE_NCBI_TAXONOMIES {

    tag "Merge NCBI Taxonomies"

    container "hariszaf/pema-nf:0.0.1"

    publishDir {"${params.outdir}/ncbi_taxonomy"}, mode: 'copy'

    input:
        path tax_files
        path error_files

    output:
        path "taxonomies.tsv", emit: ncbi_taxonomy
        path "not_found.tsv", emit: missed_taxonomies

    script:
        """
        cat ${tax_files.join(' ')}   > taxonomies.tsv

        

        cat ${error_files.join(' ')} > not_found.tsv
        """
}

process UNIQUE_TAXA {

    input:
        path assignments 

    output:
        path "unique_taxa.tsv", emit: unique_taxa_file

    script:
        """
        awk -F';' '{gsub(/^[ \t]+|[ \t]+\$/,"",\$NF); print \$NF}' ${assignments} | sort | uniq > unique_taxa.tsv
        """
}


process MERGE_NCBI_TAXONOMY_TABLE {

    tag "Build taxonomy table with NCBI taxonomy"

    container "hariszaf/pema-nf:0.0.1"

    publishDir { "${params.outdir}/ncbi_taxonomy" }, mode: 'copy'

    input:

        path taxonomy_table

    output:

        path "", emit: ncbi_taxonomy_table

    script:

        """
        
        """

}
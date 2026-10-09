#!/usr/bin/env nextflow

/* Nextflow processes to query NCBI API for a list of taxonomies as returned by a pema classifier

Usage:

    nextflow run modules/ncbi.nf --params-file config_files/ncbi.yaml
    nextflow run modules/ncbi.nf --strings_file buildingPemaNf2/crest_assignment/assignments30.txt --ncbi_api_key <YOUR_KEY> --outdir buildingPemaNf2/ncbi_taxonomy/ --tax_table buildingPemaNf2/ncbi_taxonomy/tax_assigned_table.tsv 
*/



params.max_parallel = params.max_parallel ?: 1
params.ncbi_api_key = params.ncbi_api_key ?: System.getenv('NCBI_API_KEY')
params.sleep        = params.sleep ?: 0.4

workflow {

    strings_ch = channel.fromPath(params.strings_file)
    unique_ch  = UNIQUE_TAXA(strings_ch)

    // -------------------------------
    // Load strings from file
    // -------------------------------
    taxa_ch = unique_ch
        .splitText()
        .map { line -> line.trim() }
        .filter { line -> line }

    // -------------------------------
    // Run API query for each taxon
    // -------------------------------
    ncbi_taxonomies_ch = NCBI_TAXONOMY_QUERY(taxa_ch)

    // -------------------------------
    // Merge all results
    // -------------------------------
    ncbi_taxonomies = MERGE_NCBI_TAXONOMIES(
        ncbi_taxonomies_ch.taxon_file.collect(), 
        ncbi_taxonomies_ch.error_file.collect()
    )

    // -------------------------------
    // Integrate NCBI Taxonomy to taxonomy abundance table
    // -------------------------------
    tax_table_ch = channel.fromPath(params.tax_table)
    MERGE_NCBI_TAXONOMY_TABLE(
        tax_table_ch,
        ncbi_taxonomies.ncbi_taxonomy,
        ncbi_taxonomies.missed_taxonomies
    )

}



process UNIQUE_TAXA {

    tag "Get unique records from the last part of the taxonomies retrieved"

    container "hariszaf/pema-nf:0.0.1" 

    input:
        path assignments 

    output:
        path "unique_taxa.tsv", emit: unique_taxa_file

    script:
        """
        # assignments.txt: <sequence id> TAB <lineage separated by ';'>. Keep the lowest rank only.
        awk -F'\t' '{
            n = split(\$2, ranks, ";")
            taxon = ranks[n]
            gsub(/^[ \t]+|[ \t]+\$/, "", taxon)
            if (taxon != "" && taxon != "No hits") print taxon
        }' ${assignments} | sort -u > unique_taxa.tsv
        """
}


process NCBI_TAXONOMY_QUERY {

    tag "${taxon}"

    container "staphb/ncbi-datasets:18.36.0"

    // Limit parallelism
    maxForks params.max_parallel

    input:
        val taxon

    output:
        path "ncbi_ids/*.tsv", emit: taxon_file
        path "ncbi_ids/*.err", emit: error_file

    script:
        // Single-quote the taxon for the shell, so names with quotes, $ or backticks are safe
        def taxon_q = "'" + taxon.replace("'", "'\\''") + "'"
        def api_key = params.ncbi_api_key ?: ''
        // NCBI allows ~10 requests/sec with an API key and ~3 without one
        def sleep_time = Math.max((params.sleep ?: 0) as double, api_key ? 0.1 : 0.4)
        """
        mkdir -p ncbi_ids

        taxon_clean=\$(printf '%s' ${taxon_q} | tr -d '()' | tr '/:' '__')
        output_filename="\${taxon_clean// /_}"

        ${api_key ? "export NCBI_API_KEY='${api_key}'" : ''}

        # A taxon unknown to NCBI must not fail the run; its error is kept in the .err file
        datasets summary taxonomy taxon "\$taxon_clean" \
            > "ncbi_ids/\$output_filename.tsv" \
            2> "ncbi_ids/\$output_filename.err" || true

        # Drop the client update notice, so the .err file only holds real errors
        sed -i '/^New version of client/d' "ncbi_ids/\$output_filename.err"

        sleep ${sleep_time}
        """
}


process MERGE_NCBI_TAXONOMIES {

    tag "Merge NCBI Taxonomies"

    container "hariszaf/pema-nf:0.0.1"

    publishDir {"${params.outdir}/ncbi_taxonomy"}, mode: 'copy'

    input:
        path tax_files
        path error_files

    output:
        path "taxonomies.json", emit: ncbi_taxonomy
        path "not_found.tsv", emit: missed_taxonomies

    script:
        """
        cat ${tax_files.join(' ')}   > taxonomies.tsv

        python3 - <<'EOF'
    import json

    input_file = "taxonomies.tsv"
    output_file = "taxonomies.json"

    merged = {}

    with open(input_file, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            for report in data.get("reports", []):
                query = report["query"][0]
                merged[query] = report

    with open(output_file, "w") as out:
        json.dump(merged, out, indent=2)
    EOF

        cat ${error_files.join(' ')} > not_found.tsv
        """
}


process MERGE_NCBI_TAXONOMY_TABLE {

    tag "Build taxonomy table with NCBI taxonomy"

    container "hariszaf/datasets:latest"

    publishDir { "${params.outdir}/ncbi_taxonomy" }, mode: 'copy'

    input:

        path taxonomy_table
        path ncbi_taxonomies_json
        path ncbi_errors

    output:

        path "tax_assigned_with_ncbi.tsv", emit: ncbi_taxonomy_table

    script:

        """
        python /opt/ncbi_taxonomy_table.py \
            --taxonomy-table ${taxonomy_table} \
            --ncbi-taxonomies ${ncbi_taxonomies_json} \
            --ncbi-errors ${ncbi_errors} \
            --output tax_assigned_with_ncbi.tsv
        """

}
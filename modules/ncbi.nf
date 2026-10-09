#!/usr/bin/env nextflow

/* Nextflow processes to query NCBI API for a list of taxonomies as returned by a pema classifier

Usage:

    nextflow run modules/ncbi.nf --params-file config_files/ncbi.yaml
    nextflow run modules/ncbi.nf -c nextflow.config --tax_table results/crest_assignment/tax_assigned_table.tsv --outdir results
*/



params.max_parallel = params.max_parallel ?: 1
params.ncbi_api_key = params.ncbi_api_key ?: System.getenv('NCBI_API_KEY')
params.sleep        = params.sleep ?: 0.4

workflow {

    tax_table_ch = channel.fromPath(params.tax_table)
    unique_ch    = UNIQUE_TAXA(tax_table_ch)

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
        ncbi_taxonomies_ch.error_file.collect(),
        ncbi_taxonomies_ch.candidates_file.collect()
    )

    // -------------------------------
    // Integrate NCBI Taxonomy to taxonomy abundance table
    // -------------------------------
    MERGE_NCBI_TAXONOMY_TABLE(
        tax_table_ch,
        ncbi_taxonomies.ncbi_taxonomy,
        ncbi_taxonomies.ambiguous_candidates
    )

}



process UNIQUE_TAXA {

    tag "Get unique records from the last part of the taxonomies retrieved"

    container "hariszaf/pema-nf:0.2.2" 

    input:
        path tax_table

    output:
        path "unique_taxa.tsv", emit: unique_taxa_file

    script:
        """
        # tax_assigned_table.tsv: lineages separated by ';' in the Taxonomy column. Keep the lowest rank only.
        awk -F'\t' '
            NR == 1 { for (i = 1; i <= NF; i++) if (\$i == "Taxonomy") col = i; next }
            {
                n = split(\$col, ranks, ";")
                taxon = ranks[n]
                gsub(/^[ \t]+|[ \t]+\$/, "", taxon)
                if (taxon != "" && taxon != "No hits" && taxon != "Unassigned") print taxon
            }' ${tax_table} | sort -u > unique_taxa.tsv
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
        path "ncbi_ids/*.candidates.jsonl", emit: candidates_file

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

        # A name matching more than one taxid: fetch every candidate, one
        # "<taxon> TAB <json report>" line each (empty file otherwise)
        touch "ncbi_ids/\$output_filename.candidates.jsonl"
        if grep -q "more than one taxid" "ncbi_ids/\$output_filename.err"; then
            taxids=\$(grep -oE 'taxid: [0-9]+' "ncbi_ids/\$output_filename.err" | awk '{print \$2}' | sort -u)
            sleep ${sleep_time}
            datasets summary taxonomy taxon \$taxids --as-json-lines 2>/dev/null \
                | while IFS= read -r report; do
                    printf '%s\t%s\n' ${taxon_q} "\$report"
                done > "ncbi_ids/\$output_filename.candidates.jsonl" || true
        fi

        sleep ${sleep_time}
        """
}


process MERGE_NCBI_TAXONOMIES {

    tag "Merge NCBI Taxonomies"

    container "hariszaf/pema-nf:0.2.2"

    publishDir {"${params.outdir}/ncbi_taxonomy"}, mode: 'copy'

    input:
        path tax_files
        path error_files
        path candidate_files

    output:
        path "taxonomies.json", emit: ncbi_taxonomy
        path "not_found.tsv", emit: missed_taxonomies
        path "ambiguous_candidates.tsv", emit: ambiguous_candidates

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
        cat ${candidate_files.join(' ')} > ambiguous_candidates.tsv
        """
}


process MERGE_NCBI_TAXONOMY_TABLE {

    tag "Build taxonomy table with NCBI taxonomy"

    container "hariszaf/pema-nf:0.2.2"

    publishDir { "${params.outdir}/ncbi_taxonomy" }, mode: 'copy'

    input:

        path taxonomy_table
        path ncbi_taxonomies_json
        path ambiguous_candidates

    output:

        path "tax_assigned_with_ncbi.tsv", emit: ncbi_taxonomy_table

    script:

        """
        python3 /opt/pema/scripts/ncbi_taxonomy_table.py \
            --taxonomy-table ${taxonomy_table} \
            --ncbi-taxonomies ${ncbi_taxonomies_json} \
            --ncbi-candidates ${ambiguous_candidates} \
            --output tax_assigned_with_ncbi.tsv
        """

}
#!/usr/bin/env nextflow

process LINEARIZE {

    tag "Convert a multiline fasta to a single line fasta file."

    publishDir "${params.outdir}/linearized", mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:
        path multiline_fasta

    output:
        path "*.fa", emit: linearized_fasta

    script:
        """
        BASENAME=${multiline_fasta.baseName}
        LINEARIZED_FILE="\${BASENAME}.fa"

        # 'sequence → first header' map
        awk '
            /^>/ {
                if (seq) print seq; print; seq=""; next
            } {seq=seq \$0} END {if (seq) print seq}
        ' "$multiline_fasta" >> "\${LINEARIZED_FILE}"
        """
}

process CONCATENATE_FASTA {

    tag "Combine all hash fasta files in one, keeping total abundance of amplicon in the study."

    publishDir "${params.outdir}", mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:
        path derep_files

    output:
        path "*.fa", emit: all_samples

    script:
        """
        cat ${derep_files} | \
        awk 'BEGIN {RS = ">" ; FS = "[_\\n]"}
            {if (NR != 1) {abundances[\$1] += \$2 ; sequences[\$1] = \$3}}
            END {for (amplicon in sequences) {
                print ">" amplicon "_" abundances[amplicon] "_" sequences[amplicon]}}' | \
        sort --temporary-directory=\$(pwd) -t "_" -k2,2nr -k1.2,1d | \
        sed -e 's/\\_/\\n/2' > hash_all_samples.fa
        """
}

process HASH_DEREP_FASTA {

    tag "Hash each sample to use it across all samples."

    publishDir "${params.outdir}/hashing", mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:
        path linearized_fasta

    output:
        path "*.hash", emit: hash_fasta

    script:
        """
        BASENAME=${linearized_fasta.baseName}
        HASH_FILE="\${BASENAME}.hash"

        awk '
            /^>/ {
                split(\$0, a, ";size=")
                abundance = a[2]
                next
            }
            {print abundance "\\t" \$0}
        ' "$linearized_fasta" | \

        while IFS=\$'\\t' read -r abundance sequence; do
            hash=\$(printf "%s" "\$sequence" | sha1sum | awk '{print \$1}')
            printf ">%s_%d\\n%s\\n" "\$hash" "\$abundance" "\$sequence"
        done > "\${HASH_FILE}"
        """
}

process HASH_MAP {
    
    container "hariszaf/pema-nf:0.0.1"

    publishDir "${params.outdir}/hashing", mode: 'copy'

    tag "${sample}"

    input:
        tuple val(sample), path(derep_fasta), path(nonderep_fasta)

    output:
        path "*.tsv", emit: hash_map

    script:
        """
        BASENAME=${nonderep_fasta.baseName}
        MAPPING_FILE="\${BASENAME}.tsv"

        awk '
            # Step 1: read dereplicated fasta and build sequence -> hash map
            FNR==NR {
                if (/^>/) {
                    split(substr(\$0,2), parts, "_")
                    hash = parts[1]
                    next
                }
                seq[\$0] = hash
                next
            }
            # Step 2: read non-dereplicated fasta and output mapping
            /^>/ {
                split(substr(\$0,2), a, ";size=")
                header = a[1]
                abundance = a[2]
                next
            }
            {
                if (\$0 in seq)
                    print seq[\$0], header, \$0
            }
        ' "$derep_fasta" "$nonderep_fasta" > "\${MAPPING_FILE}"
        """
}

BASENAME=${nonderep_fasta.baseName}
MAPPING_FILE="${BASENAME}_derep_map.tsv"

awk '
################################################
# PASS 1: build sequence → cluster map
################################################
FNR==NR {
    if (/^>/) {
        header = substr($0,2)
        split(header,a,"_")
        cluster = a[1]
        getline seq
        map[seq] = cluster
    }
    next
}

################################################
# PASS 2: scan FASTQ
################################################
NR>FNR && /^@/ {
    read = $0
    getline seq
    getline
    getline

    if (seq in map)
        print read "\t" map[seq] "\t" seq
}
' "$derep_fasta" "$nonderep_fasta" > "$MAPPING_FILE"

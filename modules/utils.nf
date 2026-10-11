#!/usr/bin/env nextflow


def paramsToCliArgs(Map p) {
    if (!p) return ""
    return p.collectMany { k, v ->
        if (v == null) return []       // skip nulls
        if (v instanceof Boolean) return v ? ["--$k"] : []
        if (v instanceof Collection) return v.collect { item -> "--$k $item" }
        return ["--$k $v"]             // scalar
    }.join(' ')
}


// Returns the value of `section` in the YAML file, or null if the key is missing.
// Callers must use `valueOr` (not `?:`) for defaults, so that 0 / false values are kept.
def loadYamlParams(String yamlFilePath, String section) {
    def yamlFile = new File(yamlFilePath)
    if (!yamlFile.exists()) {
        error "YAML file '${yamlFilePath}' not found."
    }
    def content = new groovy.yaml.YamlSlurper().parse(yamlFile) ?: [:]
    return plainCopy(content[section])
}

// YamlSlurper returns lazy maps and lists that break when passed to a process; copy them, recursively
def plainCopy(value) {
    if (value instanceof Map) {
        def copy = new LinkedHashMap()
        value.each { k, v -> copy[k] = plainCopy(v) }
        return copy
    }
    if (value instanceof List) {
        return value.collect { v -> plainCopy(v) }
    }
    return value
}

// Like `value ?: fallback`, but only falls back when value is null (keeps 0 and false).
def valueOr(value, fallback) {
    return value != null ? value : fallback
}

// Finds the paired-end fastq files in `dir` and returns them as [sample, read1, read2] lists.
//
// Accepted extensions: .fastq, .fq, .fastq.gz, .fq.gz
// The mate is given by the last "1"/"2" (optionally "R1"/"R2", any case) between separators (_ . -)
// in the file name, e.g. S1_1.fq.gz, S1_R1.fastq.gz, S1.R1.fastq, S1_S1_L001_R1_001.fastq.gz.
// The sample name is the part of the file name before that marker.
//
// Stops with an error if there are no fastq files, a file has no 1/2 marker,
// a file has no mate, or two pairs end up with the same sample name.
def findReadPairs(String dir) {
    def folder = file(dir)
    if (!folder.isDirectory()) {
        error "raw_reads: '${dir}' is not a directory."
    }

    def extension = ~/(?i)\.(fastq|fq)(\.gz)?$/
    // Greedy prefix → the last marker: <prefix> [R]1|2 <suffix>, the marker between separators or the name ends
    def marker    = ~/(?i)^(.*)(?:^|([._-]))R?([12])(?=[._-]|$)(.*)$/

    def fastqs = folder.listFiles().findAll { f -> !f.isDirectory() && f.name =~ extension }.sort { f -> f.name }
    if (!fastqs) {
        error "raw_reads: no fastq files (.fastq, .fq, .fastq.gz, .fq.gz) found in '${dir}'."
    }

    def problems = []
    def pairs    = [:]   // pair key -> [sample: ..., reads: [1: file, 2: file]]

    fastqs.each { f ->
        def stem    = f.name.replaceFirst(extension, '')
        def m = stem =~ marker
        if (!m.matches()) {
            problems << "${f.name}: cannot tell whether it is read 1 or read 2 (no _1/_2 or _R1/_R2 in the name)"
            return
        }
        def prefix = m.group(1)
        def mate   = m.group(3) as int
        def suffix = m.group(4)
        def sample = prefix.replaceFirst(/[._-]+$/, '')
        if (!sample) {
            problems << "${f.name}: no sample name before the read marker"
            return
        }
        if (sample =~ /\s/) {
            problems << "${f.name}: the sample name '${sample}' contains whitespace"
            return
        }
        // Mates must be identical apart from the marker (e.g. the _001 after R1/R2 in Illumina names)
        def key  = prefix + '\u0000' + suffix
        def pair = pairs.get(key, [sample: sample, reads: [:]])
        if (pair.reads[mate]) {
            problems << "${f.name} and ${pair.reads[mate].name}: both look like read ${mate} of sample '${sample}'"
            return
        }
        pair.reads[mate] = f
    }

    pairs.values().each { pair ->
        [1, 2].each { mate ->
            if (!pair.reads[mate]) {
                def other = pair.reads[3 - mate]
                problems << "${other.name}: no read ${mate} file found for sample '${pair.sample}'"
            }
        }
    }

    def complete = pairs.values().findAll { pair -> pair.reads[1] && pair.reads[2] }
    complete.groupBy { pair -> pair.sample }.each { sample, group ->
        if (group.size() > 1) {
            def names = group.collect { pair -> pair.reads[1].name }.join(', ')
            problems << "${names}: different read pairs give the same sample name '${sample}'"
        }
    }

    if (problems) {
        error "Problems with the input fastq files in '${dir}':\n  - " + problems.join('\n  - ')
    }

    log.info "Found ${complete.size()} paired-end samples in '${dir}': ${complete*.sample.sort().join(', ')}"
    return complete
        .sort { pair -> pair.sample }
        .collect { pair -> [pair.sample, pair.reads[1], pair.reads[2]] }
}

def stripAllExtensions(filePath) {
    def name = filePath.name        // full filename with extensions
    int dotIndex = name.indexOf('.') 
    if (dotIndex >= 0) {
        return name[0..dotIndex-1] // everything before the first dot
    } else {
        return name                // no extension found
    }
}


process GUNZIP {

    tag "Unzip .gz files to original format."

    container "hariszaf/pema-nf:0.3.0"

    input:
        path gzip_file

    output:
        path "*", emit: gunzipped_file

    script:
        """
        # Get base filename without .gz
        BASENAME="\$(basename ${gzip_file} .gz)"

        # Unzip to the original extension
        gunzip -c ${gzip_file} > "\${BASENAME}"
        """
}


// Keep the sequences of `original` that are, or are clustered (in `uc`) with, a sequence of `accepted`
process VSEARCH_MAP_BACK {

    tag "${outfile_name}"

    publishDir { "${params.outdir}/vsearch" }, mode: 'copy'

    container "hariszaf/pema-nf:0.3.0"

    input:
        path original
        path uc
        path accepted
        val outfile_name

    output:
        path "${outfile_name}", emit: fasta

    script:
        """
        python3 /opt/pema/scripts/map_vsearch.py \\
            --original ${original} \\
            --uc ${uc} \\
            --map ${accepted} \\
            > ${outfile_name}
        """
}

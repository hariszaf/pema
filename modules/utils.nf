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
    def value = content[section]
    // YamlSlurper returns lazy maps that break when passed to a process; copy to a plain map
    return value instanceof Map ? new LinkedHashMap(value) : value
}

// Like `value ?: fallback`, but only falls back when value is null (keeps 0 and false).
def valueOr(value, fallback) {
    return value != null ? value : fallback
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

    container "hariszaf/pema-nf:0.2.1"

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


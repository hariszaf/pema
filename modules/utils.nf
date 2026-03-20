#!/usr/bin/env nextflow

// @Grab('org.yaml:snakeyaml:1.33')
// import org.yaml.snakeyaml.Yaml

import groovy.yaml.YamlSlurper


def paramsToCliArgs(Map p) {
    if (!p) return ""
    return p.collectMany { k, v ->
        if (v == null) return []       // skip nulls
        if (v instanceof Boolean) return v ? ["--$k"] : []
        if (v instanceof Collection) return v.collect { "--$k $it" }
        return ["--$k $v"]             // scalar
    }.join(' ')
}


def loadYamlParams(String yamlFilePath, String section) {
    def yamlFile = new File(yamlFilePath)
    if (!yamlFile.exists()) {
        println "Warning: YAML file '${yamlFilePath}' not found."
        return [:]
    }
    def params = new YamlSlurper().parse(yamlFile)
    return params[section] ?: [:]
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

    container "hariszaf/pema-nf:0.0.1"

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


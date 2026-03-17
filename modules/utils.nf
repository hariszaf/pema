#!/usr/bin/env nextflow

@Grab('org.yaml:snakeyaml:1.33')
import org.yaml.snakeyaml.Yaml

// Convert loaded arguments from the YAML file to CLI arguments, 
// e.g. --adapter_sequence AGATCGGAAGAGCACACGTCTGAACTCCAGTCA 
// Attention! We assume whole parameter names and tools that expet two `-` for them
def paramsToCliArgs(Map p) {
    if( !p ) return ""

    return p.collect { k, v ->
        if (v == null)
            return null

        if (v instanceof Boolean)
            return v ? "--$k" : null

        return "--$k $v"
    }.findAll { it }.join(' ')
}

// The `section` corresponds to the nested nature of the YAML file, so you load the part of it you wish.
def loadYamlParams( String yamlFilePath, String section ) {
    def yamlText = new File(yamlFilePath).text
    def yaml     = new Yaml()
    def params   = yaml.load(yamlText)
    return params[section] ?: [:]
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


#!/usr/bin/env nextflow

// Usage:
// nextflow run pema.nf --params-file config_files/pema.yaml


// -------------------- PARAMETERS --------------------

// Load only modules that are needed for parameter loading and parsing.
// The full modules will be included later in the workflow when they are actually needed to allow 
// params to be available for all modules since they are loaded at the beginning of the workflow. 

include { 
    paramsToCliArgs; loadYamlParams; stripAllExtensions 
} from './modules/utils.nf'

params.yaml = params.paramsFile ?: error(
    "Please provide a YAML config file with the required parameters using --params-file."
)

// Load parameters from the YAML file. If a required parameter is missing, an error will be thrown. 
// Optional parameters can have default values or be set to null.
params.raw_reads = loadYamlParams(params.yaml, 'raw_reads') ?: error(
    "Please provide folder with raw reads in the YAML config file (raw_reads_dir)."
)
params.threads         = loadYamlParams(params.yaml, 'threads') ?: 3
params.outdir          = loadYamlParams(params.yaml, 'outdir') ?: "results"
params.clustering_algo = loadYamlParams(params.yaml, 'clustering_algo') ?: "swarm"


// -------------------- MODULES --------------------

include { FASTP } from './modules/fastp.nf'
include { SWARM } from './modules/swarm.nf'
include { TRAIN_CREST_DB; CREST_TAXONOMY_ASSIGNMENT; BUILD_TAXONOMY_TABLE } from './modules/crest.nf'
include { VSEARCH_DEREP } from './modules/vsearch_derep.nf'
include { LINEARIZE; HASH_DEREP_FASTA; HASH_MAP; CONCATENATE_FASTA } from './modules/hash.nf'
include { RDPCLASSIFY } from './modules/rdpclassifier.nf'
include { CONTINGENCY_TABLE; ASVS_CONTINGENCY_TABLE } from './modules/contingency.nf'

// -------------------- WORKFLOW --------------------

workflow {

    // -------------------- CHANNELS --------------------
    def paired1 = Channel.fromFilePairs("${params.raw_reads}/*_{1,2}.fastq.gz", flat: true)
    def paired2 = Channel.fromFilePairs("${params.raw_reads}/*_R{1,2}_*.fastq.gz", flat: true)

    def paired_raw_reads = Channel.empty().mix(paired1).mix(paired2)

    // -------------------- ADJUST PARAMS  --------------------
    def fastpParams = loadYamlParams(params.yaml, 'fastp')

    if (params.clustering_algo == "swarm") {
        fastpParams.n_base_limit = 0
        log.warn "clustering_algo=swarm → forcing fastp --n_base_limit 0 (Swarm does not accept Ns)"
    }

    def swarmParams = loadYamlParams(params.yaml, 'swarm')
   
    if (swarmParams.differences > 1) {
        if (swarmParams.fastidious == true) {
            swarmParams.fastidious = false
            log.warn "Fastidious was set to false. The fastidious option can be applied only if 'differences' equals 1."
        }
        swarmParams.boundary      = null
        swarmParams.ceiling       = null
        swarmParams['bloom-bits'] = null
    } else if (swarmParams.differences == 1) {
        log.warn(
            """Since differences is set to 1, match-reward, mismatch-penalty,
            gap-opening-penalty and gap-extension-penalty parameters were set to null."""
        )
        swarmParams["match-reward"]          = null
        swarmParams["mismatch-penalty"]      = null
        swarmParams["gap-opening-penalty"]   = null
        swarmParams["gap-extension-penalty"] = null
    } 
    println(params)
    println(swarmParams)
    // // -------------------- QUALITY CONTROL --------------------
    qc = FASTP(paired_raw_reads, fastpParams)

    // -------------------- DEREPLICATION --------------------
    derep_samples = VSEARCH_DEREP(qc.merged_reads)
    linearized    = LINEARIZE(derep_samples.derep_fasta)

    //  -------------------- HASHING --------------------
    hashed        = HASH_DEREP_FASTA(linearized.linearized_fasta)
    hash_map      = HASH_MAP(hashed.hash_fasta, linearized.linearized_fasta)

    // -------------------- CONCATENATE --------------------
    all_samples_fasta  = CONCATENATE_FASTA(hashed.hash_fasta.collect())

    //  -------------------- CONTINGENCY TABLE --------------------
    contingency_table = CONTINGENCY_TABLE(hashed.hash_fasta.collect())

    //  -------------------- CLUSTERING --------------------
    swarm = SWARM(all_samples_fasta.all_samples, swarmParams)

    // // -------------------- REMOVE OLIGOTONS -------------------- 


    // -------------------- TAXONOMY ASSIGNMENT -------------------- 


}



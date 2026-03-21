#!/usr/bin/env nextflow

// Usage:  nextflow run pema.nf --params-file config_files/pema.yaml

// -------------------- PARAMETERS --------------------

// Load only modules that are needed for parameter loading and parsing.
// The full modules will be included later in the workflow when they are actually needed to allow 
// params to be available for all modules since they are loaded at the beginning of the workflow. 

import groovy.json.JsonOutput

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
params.min_oligotons   = loadYamlParams(params.yaml, 'min_oligotons') ?: 5
params.classifier      = loadYamlParams(params.yaml, 'classifier') ?: "crest"
params.ncbi_taxonomy   = loadYamlParams(params.yaml, 'ncbi_taxonomy') ?: false

// -------------------- MODULES --------------------

include { FASTP } from './modules/fastp.nf'
include { SWARM } from './modules/swarm.nf'
include { TRAIN_CREST_DB; CREST_TAXONOMY_ASSIGNMENT; BUILD_TAXONOMY_TABLE } from './modules/crest.nf'
include { VSEARCH_DEREP } from './modules/vsearch_derep.nf'
include { LINEARIZE; HASH_DEREP_FASTA; HASH_MAP; CONCATENATE_FASTA } from './modules/hash.nf'
include { RDPCLASSIFY } from './modules/rdpclassifier.nf'
include { CONTINGENCY_TABLE; ASVS_CONTINGENCY_TABLE } from './modules/contingency.nf'
include { REMOVE_OLIGOS_SWARM; } from './modules/oligos.nf'
include { NCBI_TAXONOMY_QUERY; UNIQUE_TAXA; MERGE_NCBI_TAXONOMIES } from './modules/ncbi.nf'

// -------------------- CHANNELS --------------------
def paired1 = Channel.fromFilePairs("${params.raw_reads}/*_{1,2}.fastq.gz", flat: true)
def paired2 = Channel.fromFilePairs("${params.raw_reads}/*_R{1,2}_*.fastq.gz", flat: true)

def paired_raw_reads = Channel.empty().mix(paired1).mix(paired2)

// -------------------- ADJUST PARAMS  --------------------
def fastpParams = loadYamlParams(params.yaml, 'fastp') ?: error (
    "You need to provide 'fastp' on your YAML file along with its corresponding parameters."
)
def swarmParams = loadYamlParams(params.yaml, 'swarm')

if (params.clustering_algo == 'swarm' && !swarmParams) {
    error "clustering_algo is set to 'swarm' but no 'swarm' section was found in the YAML config."
}

if (params.clustering_algo == "swarm") {

    fastpParams.n_base_limit = 0

    log.warn(
        """clustering_algo=swarm → forcing fastp --n_base_limit 0 
        (Swarm does not accept Ns)"""
    )

    if (swarmParams.differences > 1) {

        if (swarmParams.fastidious == true) {
            swarmParams.fastidious = false
            log.warn(
                """Fastidious was set to false. 
                The fastidious option can be applied only if 'differences' equals 1."""
            )
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

} else if (params.clustering_algo == "vsearch") {
    println "hello friend"
} else {
    log.error(
        """The clustering algorithm selected is not supported. 
        Please select between 'vsearch' and 'swarm'."""
    )
}

if (params.classifier == "crest"){

    crest_params             = (loadYamlParams(params.yaml, 'crest') ?: [:])
    crest_params.search_algo = crest_params.search_algo ?: 'blast'
    crest_params.min_score   = crest_params.min_score  != null ? crest_params.min_score  : (crest_params.search_algo == 'blast' ? 155.0 : 0.75)
    crest_params.min_smlrty  = crest_params.min_smlrty != null ? crest_params.min_smlrty : true
    crest_params.score_drop  = crest_params.score_drop != null ? crest_params.score_drop : 2.0
    crest_params.threads     = crest_params.threads    != null ? crest_params.threads : params.threads

    def db = crest_params.database ?: error(
        """
        The database used for the sequence similarity search.
        Either `ssuome`, `silvamod138pr2`, `mitofish`, or `midori253darn`. By default, `ssuome`.
        In case of a custom database, please specify the full path to a directory containing 
        all required files, making sure that is under the `mount_crest_dbs`.
        """
    )

    if( !crest_supported_DBs.contains(db) ) {
        crest_params.database = "/crest4/.crest4/${db}"
        crest_params.mount_crest_dbs = crest_params.mount_crest_dbs ?: error(
        """
        Since you are using a custom database, you need to specify the mount point for the CREST databases.
        Please provide the path to the directory containing the CREST databases on your system (--mount_crest_dbs).
        This should be a directory that is mounted to the CREST container and contains folders with all required files for each database you may want to use.

        For example:
        ls ~/.crest4/
        18S_curated_141222_GenBank  bacteria_in_greece  fish16sDez2023  midori253darn  silvamod128  silvamod138pr2  unite_19_02_2025  unite2025_old

        ls ~/.crest4/unite_19_02_2025/
        unite_19_02_2025.fasta
        unite_19_02_2025.map
        unite_19_02_2025.names
        unite_19_02_2025.tre
        unite_19_02_2025.tsv
        """
        )
    } else {
        crest_params.database = db
    }

}


if (params.ncbi_taxonomy.get_ncbi_taxonomy == true) {
    if (params.ncbi_taxonomy.ncbi_api_key == null) {
        params.ncbi_taxonomy.max_parallel = 1
    } else {
        params.ncbi_taxonomy.max_parallel = params.ncbi_taxonomy.max_parallel ?: 1
    }
} 



// -------------------- WORKFLOW --------------------

workflow {

    // -------------------- QUALITY CONTROL --------------------
    qc = FASTP(paired_raw_reads, fastpParams)

    // -------------------- DEREPLICATION --------------------
    derep_samples = VSEARCH_DEREP(qc.merged_reads)
    linearized    = LINEARIZE(derep_samples.derep_fasta)

    //  -------------------- HASHING --------------------
    hashed   = HASH_DEREP_FASTA(linearized.linearized_fasta)
    hash_map = HASH_MAP(hashed.hash_fasta, linearized.linearized_fasta)

    // -------------------- CONCATENATE --------------------
    all_samples_fasta  = CONCATENATE_FASTA(hashed.hash_fasta.collect())

    //  -------------------- CONTINGENCY TABLE --------------------
    contingency_table = CONTINGENCY_TABLE(hashed.hash_fasta.collect())

    //  -------------------- CLUSTERING --------------------
    
    def hash_taxonomy

    if (params.clustering_algo == "swarm") {

        swarm_ch  = SWARM(all_samples_fasta.all_samples, swarmParams)

        def stats_ch
        def swarms_ch
        def fasta_ch

        if (params.min_oligotons > 0) {

            oligos_ch = REMOVE_OLIGOS_SWARM(
                swarm_ch.swarm_stats,
                swarm_ch.swarm_swarms,
                swarm_ch.hash_fasta,
                params.min_oligotons
            )
            stats_ch  = oligos_ch.swarm_stats_filtered
            swarms_ch = oligos_ch.swarm_swarms_filtered
            fasta_ch  = oligos_ch.hash_fasta_filtered

        } else {

            stats_ch  = swarm_ch.swarm_stats_filtered
            swarms_ch = swarm_ch.swarm_swarms_filtered
            fasta_ch  = swarm_ch.hash_fasta_filtered
        }

        asvs_cont_table = ASVS_CONTINGENCY_TABLE(
            stats_ch,
            swarms_ch,
            fasta_ch,
            contingency_table,
        )

        // ------------ BUILD ASVS CONTINGENCY TABLE ----------


        if (params.classifier == "crest"){

            crest_taxonomy_assignment = CREST_TAXONOMY_ASSIGNMENT(
                asvs_cont_table.asvs_to_tax_assign,
                crest_params_ch
            )

            // Build the taxonomy table by combining the ASV contingency table and the CREST taxonomy assignments.
            tax_table = BUILD_TAXONOMY_TABLE(
                asvs_cont_table.asvs_contingency_hash, 
                crest_taxonomy_assignment.assignments)

            hash_taxonomy = crest_taxonomy_assignment.assignments

        } else {
            println "hello RDP friend"
        }


    } else {
        log.info("hello friend")
    }


    // -------------------- NCBI TAXONOMY MAP -------------------- 

    if (params.ncbi_taxonomy.get_ncbi_taxonomy) {


        unique_ch = UNIQUE_TAXA(hash_taxonomy)

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
        MERGE_NCBI_TAXONOMIES(ncbi_taxonomies_ch)



    }


}

    // log.info("Params for fastp:\n" + JsonOutput.prettyPrint(JsonOutput.toJson(fastpParams)))
    // log.info("Params for swarm:\n" + JsonOutput.prettyPrint(JsonOutput.toJson(swarmParams)))


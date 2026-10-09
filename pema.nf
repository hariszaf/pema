#!/usr/bin/env nextflow

// Usage:  nextflow run pema.nf --params-file config_files/pema.yaml

// -------------------- PARAMETERS --------------------

// Only top-level params live here; params are available to all modules included below.
// The tool-specific sections (fastp, swarm, crest) are resolved inside the workflow.

include { loadYamlParams; valueOr } from './modules/utils.nf'

params.yaml = params.paramsFile ?: error(
    "Please provide a YAML config file with the required parameters using --params-file."
)

// Load parameters from the YAML file. If a required parameter is missing, an error will be thrown.
// Optional parameters fall back to a default only when missing (0 / false values are kept).
params.raw_reads = loadYamlParams(params.yaml, 'raw_reads') ?: error(
    "Please provide folder with raw reads in the YAML config file (raw_reads)."
)
params.threads         = valueOr(loadYamlParams(params.yaml, 'threads'), 3)
params.outdir          = valueOr(loadYamlParams(params.yaml, 'outdir'), "results")
params.clustering_algo = valueOr(loadYamlParams(params.yaml, 'clustering_algo'), "swarm")
params.min_oligotons   = valueOr(loadYamlParams(params.yaml, 'min_oligotons'), 5)
params.classifier      = valueOr(loadYamlParams(params.yaml, 'classifier'), "crest")
params.ncbi_taxonomy   = valueOr(loadYamlParams(params.yaml, 'ncbi_taxonomy'), [:])

// Flat params read by modules/ncbi.nf. Without an API key NCBI allows ~3 requests/sec,
// so parallel queries are only allowed when a key is given.
// The key can also be provided through the NCBI_API_KEY environment variable.
params.ncbi_api_key = params.ncbi_taxonomy.ncbi_api_key ?: System.getenv('NCBI_API_KEY')
params.max_parallel = params.ncbi_api_key ? valueOr(params.ncbi_taxonomy.max_parallel, 1) : 1
params.sleep        = valueOr(params.ncbi_taxonomy.sleep, 0.4)

// -------------------- MODULES --------------------

include { FASTP } from './modules/fastp.nf'
include { SWARM } from './modules/swarm.nf'
include { CREST_TAXONOMY_ASSIGNMENT; BUILD_TAXONOMY_TABLE } from './modules/crest.nf'
include { VSEARCH_DEREP } from './modules/vsearch_derep.nf'
include { LINEARIZE; HASH_DEREP_FASTA; HASH_MAP; CONCATENATE_FASTA } from './modules/hash.nf'
include { CONTINGENCY_TABLE; ASVS_CONTINGENCY_TABLE } from './modules/contingency.nf'
include { REMOVE_OLIGOS_SWARM } from './modules/oligos.nf'
include {
    NCBI_TAXONOMY_QUERY; UNIQUE_TAXA; MERGE_NCBI_TAXONOMIES; MERGE_NCBI_TAXONOMY_TABLE
} from './modules/ncbi.nf'

// -------------------- ADJUST PARAMS  --------------------

def checkSupported() {
    if (!(params.clustering_algo in ['swarm'])) {
        error "clustering_algo '${params.clustering_algo}' is not supported yet. Please select 'swarm'."
    }
    if (!(params.classifier in ['crest'])) {
        error "classifier '${params.classifier}' is not supported yet. Please select 'crest'."
    }
}

def resolveFastpParams() {
    def fastpParams = loadYamlParams(params.yaml, 'fastp') ?: error(
        "You need to provide 'fastp' on your YAML file along with its corresponding parameters."
    )
    if (params.clustering_algo == "swarm") {
        fastpParams.n_base_limit = 0
        log.warn "clustering_algo=swarm → forcing fastp --n_base_limit 0 (Swarm does not accept Ns)"
    }
    return fastpParams
}

def resolveSwarmParams() {
    def swarmParams = loadYamlParams(params.yaml, 'swarm') ?: error(
        "clustering_algo is set to 'swarm' but no 'swarm' section was found in the YAML config."
    )
    def d = valueOr(swarmParams.differences, 1)

    if (d != 1 && swarmParams.fastidious == true) {
        swarmParams.fastidious = false
        log.warn "Fastidious was set to false. The fastidious option can be applied only if 'differences' equals 1."
    }
    // Fastidious options are only valid when fastidious is on (which requires d = 1)
    if (swarmParams.fastidious != true) {
        swarmParams.boundary      = null
        swarmParams.ceiling       = null
        swarmParams['bloom-bits'] = null
    }
    // Pairwise alignment options are only valid when d > 1
    if (d == 1) {
        log.warn """Since differences is set to 1, match-reward, mismatch-penalty,
            gap-opening-penalty and gap-extension-penalty parameters were set to null."""
        swarmParams["match-reward"]          = null
        swarmParams["mismatch-penalty"]      = null
        swarmParams["gap-opening-penalty"]   = null
        swarmParams["gap-extension-penalty"] = null
    }
    return swarmParams
}

def resolveCrestParams() {
    def crestSupportedDBs = ['ssuome', 'silvamod138pr2', 'mitofish', 'midori253darn']

    def crest_params         = loadYamlParams(params.yaml, 'crest') ?: [:]
    crest_params.search_algo = crest_params.search_algo ?: 'blast'
    crest_params.min_score   = valueOr(crest_params.min_score, crest_params.search_algo == 'blast' ? 155.0 : 0.75)
    crest_params.min_smlrty  = valueOr(crest_params.min_smlrty, true)
    crest_params.score_drop  = valueOr(crest_params.score_drop, 2.0)
    crest_params.threads     = valueOr(crest_params.threads, params.threads)

    def db = crest_params.database ?: error(
        """
        The database used for the sequence similarity search.
        Either `ssuome`, `silvamod138pr2`, `mitofish`, or `midori253darn`. By default, `ssuome`.
        In case of a custom database, please specify the full path to a directory containing
        all required files, making sure that is under the `mount_crest_dbs`.
        """
    )

    if (!crestSupportedDBs.contains(db)) {
        crest_params.database = "/crest4/.crest4/${db}"
        crest_params.mount_crest_dbs = crest_params.mount_crest_dbs ?: error(
        """
        Since you are using a custom database, you need to specify the mount point for the CREST databases.
        Please provide the path to the directory containing the CREST databases on your system (mount_crest_dbs).
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
    return crest_params
}


// -------------------- WORKFLOW --------------------

workflow {

    checkSupported()
    def fastpParams  = resolveFastpParams()
    def swarmParams  = resolveSwarmParams()
    def crest_params = resolveCrestParams()

    // -------------------- CHANNELS --------------------
    def paired1 = channel.fromFilePairs("${params.raw_reads}/*_{1,2}.fastq.gz", flat: true)
    def paired2 = channel.fromFilePairs("${params.raw_reads}/*_R{1,2}_*.fastq.gz", flat: true)

    def paired_raw_reads = channel.empty().mix(paired1).mix(paired2)

    // -------------------- QUALITY CONTROL --------------------
    qc = FASTP(paired_raw_reads, fastpParams)

    // -------------------- DEREPLICATION --------------------
    derep_samples = VSEARCH_DEREP(qc.merged_reads)
    linearized    = LINEARIZE(derep_samples.derep_fasta)

    //  -------------------- HASHING --------------------
    hashed = HASH_DEREP_FASTA(linearized.linearized_fasta)

    // Pair each hash file with the linearized fasta of the same sample (channel order is not guaranteed)
    def hash_by_sample       = hashed.hash_fasta.map { f -> [f.baseName, f] }
    def linearized_by_sample = linearized.linearized_fasta.map { f -> [f.baseName, f] }
    HASH_MAP(hash_by_sample.join(linearized_by_sample))

    // -------------------- CONCATENATE --------------------
    all_samples_fasta = CONCATENATE_FASTA(hashed.hash_fasta.collect(sort: { a, b -> a.name <=> b.name }))

    //  -------------------- CONTINGENCY TABLE --------------------
    contingency_table = CONTINGENCY_TABLE(hashed.hash_fasta.collect(sort: { a, b -> a.name <=> b.name }))

    //  -------------------- CLUSTERING --------------------
    swarm_ch = SWARM(all_samples_fasta.all_samples, swarmParams)

    def stats_ch  = swarm_ch.swarm_stats
    def swarms_ch = swarm_ch.swarm_swarms
    def fasta_ch  = swarm_ch.hash_fasta

    if (params.min_oligotons > 0) {
        oligos_ch = REMOVE_OLIGOS_SWARM(stats_ch, swarms_ch, fasta_ch, params.min_oligotons)
        stats_ch  = oligos_ch.swarm_stats_filtered
        swarms_ch = oligos_ch.swarm_swarms_filtered
        fasta_ch  = oligos_ch.hash_fasta_filtered
    }

    // ------------ BUILD ASVS CONTINGENCY TABLE ----------
    asvs_cont_table = ASVS_CONTINGENCY_TABLE(stats_ch, swarms_ch, fasta_ch, contingency_table)

    // -------------------- TAXONOMY ASSIGNMENT --------------------
    crest_taxonomy_assignment = CREST_TAXONOMY_ASSIGNMENT(
        asvs_cont_table.asvs_to_tax_assign,
        crest_params
    )

    // Build the taxonomy table by combining the ASV contingency table and the CREST taxonomy assignments.
    tax_table = BUILD_TAXONOMY_TABLE(
        asvs_cont_table.asvs_contingency_hash,
        crest_taxonomy_assignment.assignments
    )

    // -------------------- NCBI TAXONOMY MAP --------------------
    if (params.ncbi_taxonomy.get_ncbi_taxonomy == true) {

        unique_ch = UNIQUE_TAXA(crest_taxonomy_assignment.assignments)

        // One taxon name per line → one query per taxon
        taxa_ch = unique_ch
            .splitText()
            .map { line -> line.trim() }
            .filter { line -> line }

        ncbi_taxonomies_ch = NCBI_TAXONOMY_QUERY(taxa_ch)

        ncbi_taxonomies = MERGE_NCBI_TAXONOMIES(
            ncbi_taxonomies_ch.taxon_file.collect(),
            ncbi_taxonomies_ch.error_file.collect()
        )

        MERGE_NCBI_TAXONOMY_TABLE(
            tax_table.tax_assigned_table,
            ncbi_taxonomies.ncbi_taxonomy,
            ncbi_taxonomies.missed_taxonomies
        )
    }
}

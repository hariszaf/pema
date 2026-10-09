#!/usr/bin/env nextflow

// Usage:  nextflow run pema.nf --params-file config_files/pema.yaml

// -------------------- PARAMETERS --------------------

// Only top-level params live here; params are available to all modules included below.
// The tool-specific sections (fastp, swarm, vsearch, crest, rdp) are resolved inside the workflow.

include { loadYamlParams; valueOr; findReadPairs } from './modules/utils.nf'

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
include { PREPARE_RDP_TRAINING; TRAIN_RDP_DB; RDP_CLASSIFY; BUILD_RDP_TAXONOMY_TABLE } from './modules/rdpclassifier.nf'
include { LINEARIZE; HASH_DEREP_FASTA; HASH_MAP; CONCATENATE_FASTA } from './modules/hash.nf'
include { CONTINGENCY_TABLE; ASVS_CONTINGENCY_TABLE } from './modules/contingency.nf'
include { REMOVE_OLIGOS_SWARM } from './modules/oligos.nf'
include { VSEARCH_DEREP; VSEARCH_OTUS } from './modules/vsearch.nf'
include {
    NCBI_TAXONOMY_QUERY; UNIQUE_TAXA; MERGE_NCBI_TAXONOMIES; MERGE_NCBI_TAXONOMY_TABLE
} from './modules/ncbi.nf'

// -------------------- ADJUST PARAMS  --------------------

def checkSupported() {
    if (!(params.clustering_algo in ['swarm', 'vsearch'])) {
        error "clustering_algo '${params.clustering_algo}' is not supported. Please select 'swarm' or 'vsearch'."
    }
    if (!(params.classifier in ['crest', 'rdp'])) {
        error "classifier '${params.classifier}' is not supported. Please select 'crest' or 'rdp'."
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

def resolveVsearchParams() {
    def vsearchParams = loadYamlParams(params.yaml, 'vsearch') ?: [:]
    vsearchParams.threshold = valueOr(vsearchParams.threshold, 0.97)
    def t = vsearchParams.threshold as double
    if (t <= 0 || t > 1) {
        error "vsearch threshold must be between 0 and 1 (e.g. 0.97), not ${vsearchParams.threshold}."
    }
    return vsearchParams
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

def resolveRdpParams() {
    def rdp_params = loadYamlParams(params.yaml, 'rdp') ?: error(
        "classifier is set to 'rdp' but no 'rdp' section was found in the YAML config."
    )
    def db = rdp_params.database ?: error(
        """
        Please set `database` in the 'rdp' section: the name of an RDP-trained database folder
        inside `databases_dir`, or the full path to such a folder.
        A database folder contains an rRNAClassifier.properties file and the files it lists.
        """
    )
    rdp_params.confidence = valueOr(rdp_params.confidence, 0.8)
    rdp_params.memory     = valueOr(rdp_params.memory, '8 GB')

    // A database name is looked up in databases_dir; anything with a '/' is taken as a path
    def db_path = (rdp_params.databases_dir && !db.toString().contains('/'))
        ? file("${rdp_params.databases_dir}/${db}")
        : file(db.toString())
    def trained = file("${db_path}/rRNAClassifier.properties").exists()

    // Train the database first, if training files are given and it is not trained yet
    rdp_params.needs_training = false
    if (rdp_params.train?.taxonomy || rdp_params.train?.sequences) {
        if (!rdp_params.databases_dir || db.toString().contains('/')) {
            error "To train an RDP database, set `databases_dir` (where it is saved) and `database` to the name of the new database."
        }
        if (trained) {
            log.info "RDP database '${db_path}' is already trained; using it. Remove it to train it again."
        } else {
            ['taxonomy', 'sequences'].each { key ->
                def f = rdp_params.train[key] ? file(rdp_params.train[key].toString()) : null
                if (!f?.exists()) {
                    error "rdp.train.${key}: file '${rdp_params.train[key]}' not found."
                }
            }
            rdp_params.train.rename_duplicates = valueOr(rdp_params.train.rename_duplicates, false)
            rdp_params.train.memory            = valueOr(rdp_params.train.memory, '16 GB')
            rdp_params.needs_training          = true
            file(rdp_params.databases_dir.toString()).mkdirs()
            log.info "RDP database '${db}' will be trained and saved in '${rdp_params.databases_dir}'."
        }
    } else if (!db_path.isDirectory()) {
        error "RDP database folder '${db_path}' not found. Check `database` and `databases_dir` in the 'rdp' section."
    } else if (!trained) {
        error "No rRNAClassifier.properties in the RDP database folder '${db_path}'."
    }

    rdp_params.database_path = db_path
    return rdp_params
}


// -------------------- WORKFLOW --------------------

workflow {

    checkSupported()
    def fastpParams   = resolveFastpParams()
    def swarmParams   = params.clustering_algo == 'swarm' ? resolveSwarmParams() : null
    def vsearchParams = params.clustering_algo == 'vsearch' ? resolveVsearchParams() : null
    def crest_params  = params.classifier == 'crest' ? resolveCrestParams() : null
    def rdp_params    = params.classifier == 'rdp' ? resolveRdpParams() : null

    // -------------------- CHANNELS --------------------
    def paired_raw_reads = channel.fromList(findReadPairs(params.raw_reads.toString()))

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
    // Both clustering algorithms end with a contingency table linked to the representative
    // sequences by their hash (Seed), and the representative sequences to classify
    def clusters_hash
    def representatives

    if (params.clustering_algo == 'swarm') {

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

        asvs_cont_table = ASVS_CONTINGENCY_TABLE(stats_ch, swarms_ch, fasta_ch, contingency_table)
        clusters_hash   = asvs_cont_table.asvs_contingency_hash
        representatives = asvs_cont_table.asvs_to_tax_assign

    } else {

        otus = VSEARCH_OTUS(
            all_samples_fasta.all_samples,
            contingency_table,
            vsearchParams.threshold,
            params.min_oligotons
        )
        clusters_hash   = otus.contingency_hash
        representatives = otus.representatives
    }

    // -------------------- TAXONOMY ASSIGNMENT --------------------
    // Both classifiers end with a tax_assigned_table.tsv: ASV/OTU, abundance per sample, Taxonomy
    def tax_assigned_table

    if (params.classifier == 'crest') {

        crest_taxonomy_assignment = CREST_TAXONOMY_ASSIGNMENT(
            representatives,
            crest_params
        )
        tax_assigned_table = BUILD_TAXONOMY_TABLE(
            clusters_hash,
            crest_taxonomy_assignment.assignments
        ).tax_assigned_table

    } else {

        def rdp_database = rdp_params.database_path

        // Train a custom database first, if asked
        if (rdp_params.needs_training) {
            training_files = PREPARE_RDP_TRAINING(
                file(rdp_params.train.taxonomy.toString()),
                file(rdp_params.train.sequences.toString()),
                rdp_params
            )
            rdp_database = TRAIN_RDP_DB(training_files.taxonomy, training_files.sequences, rdp_params).database
        }

        rdp_assignment = RDP_CLASSIFY(
            representatives,
            rdp_database,
            rdp_params
        )
        tax_assigned_table = BUILD_RDP_TAXONOMY_TABLE(
            clusters_hash,
            rdp_assignment.assignments,
            rdp_params
        ).tax_assigned_table
    }

    // -------------------- NCBI TAXONOMY MAP --------------------
    if (params.ncbi_taxonomy.get_ncbi_taxonomy == true) {

        unique_ch = UNIQUE_TAXA(tax_assigned_table)

        // One taxon name per line → one query per taxon
        taxa_ch = unique_ch
            .splitText()
            .map { line -> line.trim() }
            .filter { line -> line }

        ncbi_taxonomies_ch = NCBI_TAXONOMY_QUERY(taxa_ch)

        ncbi_taxonomies = MERGE_NCBI_TAXONOMIES(
            ncbi_taxonomies_ch.taxon_file.collect(),
            ncbi_taxonomies_ch.error_file.collect(),
            ncbi_taxonomies_ch.candidates_file.collect()
        )

        MERGE_NCBI_TAXONOMY_TABLE(
            tax_assigned_table,
            ncbi_taxonomies.ncbi_taxonomy,
            ncbi_taxonomies.ambiguous_candidates
        )
    }
}

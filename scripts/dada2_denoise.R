#!/usr/bin/env Rscript
#
# ASV inference with DADA2 (https://benjjneb.github.io/dada2/), on the filtered, not merged, read pairs of all samples
# (<sample>_1.fastq.gz and <sample>_2.fastq.gz in the working directory), as in the DADA2 tutorial:
# the error rates are learned and the reads denoised separately for the forward and the reverse reads,
# then the denoised pairs are merged and the chimeras removed.
#
# Usage: dada2_denoise.R <threads> <pool: false|true|pseudo> <min_overlap> <max_mismatch>
#                        <chimera_method: consensus|pooled|per-sample> <nbases> <min_total_abundance>
#
# Outputs:
#   dada2_seqtab.tsv          the ASVs: sequence, then their abundance in each sample, by decreasing total abundance
#   dada2_read_tracking.tsv   the number of reads of each sample after each step
#   dada2_errors.pdf          the error rates learned for the forward and the reverse reads

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 7) {
    stop("Usage: dada2_denoise.R <threads> <pool> <min_overlap> <max_mismatch> <chimera_method> <nbases> <min_total_abundance>")
}
threads        <- as.integer(args[1])
pool           <- switch(tolower(args[2]), "true" = TRUE, "false" = FALSE, "pseudo" = "pseudo",
                         stop("pool must be false, true or pseudo, not ", args[2]))
min_overlap    <- as.integer(args[3])
max_mismatch   <- as.integer(args[4])
chimera_method <- args[5]
nbases         <- as.numeric(args[6])
min_total      <- max(as.integer(args[7]), 1)

suppressMessages(library(dada2))
cat("dada2", as.character(packageVersion("dada2")), "\n")

# -------------------- INPUT --------------------
fnFs    <- sort(list.files(".", pattern = "_1\\.fastq\\.gz$"))
fnRs    <- sub("_1\\.fastq\\.gz$", "_2.fastq.gz", fnFs)
samples <- sub("_1\\.fastq\\.gz$", "", fnFs)
if (length(fnFs) == 0) stop("No filtered read pairs (<sample>_1.fastq.gz, <sample>_2.fastq.gz) found.")
if (!all(file.exists(fnRs))) stop("Missing reverse reads for: ", paste(samples[!file.exists(fnRs)], collapse = ", "))

count_reads <- function(f) {
    con <- gzfile(f, "r"); on.exit(close(con))
    n <- 0
    while (length(lines <- readLines(con, n = 400000)) > 0) n <- n + length(lines)
    n / 4
}
reads_in <- vapply(fnFs, count_reads, numeric(1))

# Samples with no reads left after the quality control cannot be denoised
empty <- reads_in == 0
if (any(empty)) {
    warning("No reads left after the quality control, left out: ", paste(samples[empty], collapse = ", "))
}
fnFs <- fnFs[!empty]; fnRs <- fnRs[!empty]; samples_kept <- samples[!empty]
if (length(fnFs) == 0) stop("No sample has reads left after the quality control.")

# -------------------- ERROR RATES --------------------
errF <- learnErrors(fnFs, nbases = nbases, multithread = threads)
errR <- learnErrors(fnRs, nbases = nbases, multithread = threads)

pdf("dada2_errors.pdf")
print(plotErrors(errF, nominalQ = TRUE) + ggplot2::ggtitle("Forward reads"))
print(plotErrors(errR, nominalQ = TRUE) + ggplot2::ggtitle("Reverse reads"))
invisible(dev.off())

# -------------------- DENOISING --------------------
dadaFs <- dada(fnFs, err = errF, pool = pool, multithread = threads)
dadaRs <- dada(fnRs, err = errR, pool = pool, multithread = threads)

# -------------------- MERGING --------------------
mergers <- mergePairs(dadaFs, fnFs, dadaRs, fnRs, minOverlap = min_overlap, maxMismatch = max_mismatch)

# With a single sample, dada2 returns the objects themselves rather than lists of them
if (length(fnFs) == 1) {
    dadaFs <- list(dadaFs); dadaRs <- list(dadaRs); mergers <- list(mergers)
}
names(mergers) <- samples_kept

# -------------------- SEQUENCE TABLE AND CHIMERAS --------------------
seqtab <- makeSequenceTable(mergers)
nochim <- removeBimeraDenovo(seqtab, method = chimera_method, multithread = threads, verbose = TRUE)
cat(sprintf("%d ASVs, %d after chimera removal (%.1f%% of the reads kept)\n",
            ncol(seqtab), ncol(nochim), 100 * sum(nochim) / max(sum(seqtab), 1)))

# -------------------- READ TRACKING --------------------
get_n <- function(x) sum(getUniques(x))
track <- data.frame(sample = samples, input = reads_in, denoised_forward = 0, denoised_reverse = 0,
                    merged = 0, non_chimeric = 0, row.names = samples)
track[samples_kept, "denoised_forward"] <- vapply(dadaFs, get_n, numeric(1))
track[samples_kept, "denoised_reverse"] <- vapply(dadaRs, get_n, numeric(1))
track[samples_kept, "merged"]           <- vapply(mergers, get_n, numeric(1))
track[samples_kept, "non_chimeric"]     <- rowSums(nochim)[samples_kept]
write.table(track, "dada2_read_tracking.tsv", sep = "\t", quote = FALSE, row.names = FALSE)

# -------------------- ASV TABLE --------------------
# ASVs as rows, every sample as a column (also those left out, with 0)
tab <- matrix(0, nrow = ncol(nochim), ncol = length(samples), dimnames = list(colnames(nochim), samples))
tab[, samples_kept] <- t(nochim[samples_kept, , drop = FALSE])

# Oligotons: ASVs with a total abundance below min_total
tab <- tab[rowSums(tab) >= min_total, , drop = FALSE]
tab <- tab[order(-rowSums(tab)), , drop = FALSE]
cat(sprintf("%d ASVs with a total abundance of at least %d\n", nrow(tab), min_total))

out <- data.frame(sequence = rownames(tab), tab, check.names = FALSE)
write.table(out, "dada2_seqtab.tsv", sep = "\t", quote = FALSE, row.names = FALSE)

library(ShortRead)
library(Biostrings)


cmd <- paste(commandArgs(), collapse=" ")
cat("How R was invoked:\n");
cat(cmd, "\n")

# Get all arguments
args <- commandArgs()


forward_primer <-args[6]
reverse_primer <-args[7]
data <- args[8]


split_forward <- strsplit(forward_primer, "")[[1]]
split_reverse <- strsplit(reverse_primer, "")[[1]]

forward_reversed <- rev(split_forward)
reverse_reversed <- rev(split_reverse)

forward_reverse <- paste(forward_reversed, collapse = "")
reverse_reverse <- paste(reverse_reversed, collapse = "")


### This is a function to add strings
`+` <- function(e1, e2) {
  if (is.character(e1) | is.character(e2)) {
    paste0(e1, e2)
  } else {
    base::`+`(e1, e2)
  }
}


forward_split <- strsplit(forward_reverse, "")[[1]]
reverse_split <- strsplit(reverse_reverse, "")[[1]]

forward_complement <- ""
for (base in forward_split) {
	if ( base == "T") {
		new_base = "A"
	} else if ( base == "A") {
		new_base ="T"
	} else if ( base == "G" ) {
		new_base = "C"
	} else if ( base =="C") {
		new_base = "G"
	}

	forward_complement = forward_complement + new_base
}

reverse_complement <- ""
for (base in reverse_split) {
        if ( base == "T") {
                new_base = "A"
        } else if ( base == "A") {
                new_base ="T"
        } else if ( base == "G" ) {
                new_base = "C"
        } else if ( base =="C") {
                new_base = "G"
        }

        reverse_complement = reverse_complement + new_base
}


##########################################################################################

# (let us hope) singularity version
cutadapt <- "/usr/bin/cutadapt3"


system2(cutadapt, args = "--version") # Run shell commands from R


path <- data
list.files(path)


fnFs <- sort(list.files(path, pattern = "_1.fastq.gz", full.names = TRUE))
fnRs <- sort(list.files(path, pattern = "_2.fastq.gz", full.names = TRUE))


FWD <- forward_primer
REV <- reverse_primer

path.cut <- file.path(path, "cutadapt")
if(!dir.exists(path.cut)) dir.create(path.cut)
fnFs.cut <- file.path(path.cut, basename(fnFs))

print("fnFs.cut is here:")
print(fnFs.cut)

fnRs.cut <- file.path(path.cut, basename(fnRs))


print("fnFs.cut is:")
print(fnFs.cut)


FWD.RC <- forward_complement
REV.RC <- reverse_complement


# Trim FWD and the reverse-complement of REV off of R1 (forward reads)
R1.flags <- paste("-g", FWD, "-a", REV.RC)

# Trim REV and the reverse-complement of FWD off of R2 (reverse reads)
R2.flags <- paste("-G", REV, "-A", FWD.RC)

# Run Cutadapt
for(i in seq_along(fnFs)) {
  system2(cutadapt, args = c(R1.flags, R2.flags, "-n", 2, "-j", 0,     # -n 2 required to remove FWD and REV from reads
                             "-o", fnFs.cut[i], "-p", fnRs.cut[i],     # output files
                             fnFs[i], fnRs[i]))                        # input files
}

allOrients <- function(primer) {
    # Create all orientations of the input sequence
    require(Biostrings)
    dna <- DNAString(primer)  # The Biostrings works w/ DNAString objects rather than character vectors
    orients <- c(Forward = dna, Complement = complement(dna), Reverse = reverse(dna),
        RevComp = reverseComplement(dna))
    return(sapply(orients, toString))  # Convert back to character vector
}

FWD.orients <- allOrients(FWD)
REV.orients <- allOrients(REV)

primerHits <- function(primer, fn) {
    # Counts number of reads in which the primer is found
    nhits <- vcountPattern(primer, sread(readFastq(fn)), fixed = FALSE)
    return(sum(nhits > 0))
}

rbind(FWD.ForwardReads = sapply(FWD.orients, primerHits, fn = fnFs.cut[[1]]),
    FWD.ReverseReads = sapply(FWD.orients, primerHits, fn = fnRs.cut[[1]]),
    REV.ForwardReads = sapply(REV.orients, primerHits, fn = fnFs.cut[[1]]),
    REV.ReverseReads = sapply(REV.orients, primerHits, fn = fnRs.cut[[1]]))


print("cutadapt has been concluded!")

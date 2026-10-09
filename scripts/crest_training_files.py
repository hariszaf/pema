#!/usr/bin/env python3
"""
Prepare the input files to build a custom crest4 database.

Inputs:

    taxonomy file   tab-separated, no header, one line per sequence:
                        <accession> TAB <lineage> [TAB <name>]
                    The lineage is separated by '/' (crest4, e.g. as exported by ARB):
                        OQ071219  Main genome/Eukaryota/Amorphea/Metazoa/.../Antalis occidentalis  Antalis occidentalis
                    or by ';' (as in the .nds files of the previous CREST versions):
                        SSEQ_1    Bacteria;Firmicutes;Bacilli;Bacillales;Bacillaceae;Bacillus;Bacillus_vallismortis  SSEQ_1
    sequence file   fasta; the first word of each header is the accession; gaps are removed,
                    so an alignment can be used too

Outputs, in the folder <name>/:

    <name>.tsv     accession, lineage separated by '/', name: the input of make_new_crest_db.py
    <name>.fasta   the sequences, ungapped, named by their accession
"""

import argparse
import os
import sys


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--taxonomy", required=True, help="Taxonomy file (tsv, no header)")
    parser.add_argument("--sequences", required=True, help="Sequence file (fasta)")
    parser.add_argument("--name", required=True, help="Name of the new database")
    return parser.parse_args()


def fail(message, problems):
    shown = problems[:20]
    more  = f"\n  ... and {len(problems) - len(shown)} more" if len(problems) > len(shown) else ""
    sys.exit(f"{message}\n  - " + "\n  - ".join(shown) + more)


def read_taxonomy(path):
    """accession -> list of taxa"""
    lineages, problems = {}, []
    with open(path, encoding="utf-8") as f:
        for n, line in enumerate(f, start=1):
            if not line.strip():
                continue
            cols = [c.strip().strip(" ") for c in line.rstrip("\n").split("\t")]
            if len(cols) < 2 or not cols[0] or not cols[1]:
                problems.append(f"line {n}: expected <accession> TAB <lineage> [TAB <name>]")
                continue
            acc, lineage = cols[0], cols[1]
            if ";" in lineage:
                # ';'-separated: a '/' inside a taxon name would be read as a separator by crest4
                taxa = [t.strip().replace("/", "-") for t in lineage.split(";")]
            else:
                taxa = [t.strip() for t in lineage.split("/")]
            taxa = [t for t in taxa if t]
            if not taxa:
                problems.append(f"line {n} ({acc}): empty lineage")
            elif acc in lineages:
                problems.append(f"line {n}: the accession {acc} appears more than once")
            else:
                lineages[acc] = taxa
    if problems:
        fail(f"Problems in the taxonomy file {path}:", problems)
    if not lineages:
        sys.exit(f"No entries in the taxonomy file {path}.")
    return lineages


def read_fasta(path):
    seqs, acc, chunks = {}, None, []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith(">"):
                if acc is not None:
                    seqs[acc] = "".join(chunks)
                acc, chunks = line[1:].split()[0], []
            else:
                chunks.append(line.replace("-", "").replace(".", ""))
    if acc is not None:
        seqs[acc] = "".join(chunks)
    return seqs


def main():
    args = parse_args()

    lineages = read_taxonomy(args.taxonomy)
    seqs     = read_fasta(args.sequences)
    if not seqs:
        sys.exit(f"No sequences found in {args.sequences}.")

    missing = [acc for acc in seqs if acc not in lineages]
    if missing:
        fail(f"{len(missing)} sequences of {args.sequences} are not in the taxonomy file:", missing)
    empty = [acc for acc, s in seqs.items() if not s]
    if empty:
        fail(f"{len(empty)} sequences of {args.sequences} are empty:", empty)

    # Taxonomy entries without a sequence could never be hit; leave them out
    unused = [acc for acc in lineages if acc not in seqs]
    if unused:
        print(f"{len(unused)} accessions of the taxonomy file have no sequence and are left out.", file=sys.stderr)

    os.makedirs(args.name, exist_ok=True)
    with open(f"{args.name}/{args.name}.tsv", "w") as out:
        for acc in seqs:
            taxa = lineages[acc]
            out.write(f"{acc}\t{'/'.join(taxa)}\t{taxa[-1]}\n")
    with open(f"{args.name}/{args.name}.fasta", "w") as out:
        for acc, seq in seqs.items():
            out.write(f">{acc}\n{seq}\n")

    print(f"{len(seqs)} sequences for the crest4 database {args.name}", file=sys.stderr)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Replace the header of each sequence in a dereplicated fasta file (">name;size=N")
with the SHA1 hash of its sequence and its abundance (">sha1_N"), so that the
same amplicon gets the same identifier across samples.

Usage:
    hash_fasta.py input.fa output.hash
"""

import hashlib
import sys


def fasta_iter(path):
    header, chunks = None, []
    with open(path) as f:
        for line in f:
            line = line.rstrip()
            if line.startswith(">"):
                if header is not None:
                    yield header, "".join(chunks)
                header, chunks = line, []
            elif line:
                chunks.append(line)
    if header is not None:
        yield header, "".join(chunks)


def main(in_fasta, out_hash):
    with open(out_hash, "w") as out:
        for header, seq in fasta_iter(in_fasta):
            _, sep, size = header.partition(";size=")
            abundance = int(size.split(";")[0]) if sep else 1
            digest = hashlib.sha1(seq.encode()).hexdigest()
            out.write(f">{digest}_{abundance}\n{seq}\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])

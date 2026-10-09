#!/usr/bin/env python3
"""
Prepare the input files to train the RDP Classifier from a custom reference database.

Inputs (see https://hariszaf.github.io/pema_documentation/training_rdpclassifier/):

    taxonomy file   tab-separated, with a header line: an id column, then one column per rank, e.g.
                        Seq_ID      Kingdom     Phylum      ...     Species
                        SEQ1179093  Eukaryota   Annelida    ...     Eunice_vittata
    sequence file   fasta; the first word of each header is the id used in the taxonomy file

Outputs:

    ready4train_taxonomy.txt   the RDP taxonomy training file: one line per taxon,
                               <taxon id>*<name>*<parent taxon id>*<depth>*<rank>
    ready4train_seqs.fasta     the sequences, with their lineage in the header: >id<TAB>Root;Kingdom;...;Species

This replaces lineage2taxTrain.py and addFullLineage.py (GLBRC Team Microbiome,
https://github.com/GLBRC-TeamMicrobiome/python_scripts), which it follows.

The RDP Classifier does not allow "convergent evolution": the same taxon name, at the same rank,
under different parent lineages (e.g. the genus Thalia, both an animal and a plant).
Such names are reported as an error, or, with --rename-duplicates, renamed to <name>_1, <name>_2, ...
"""

import argparse
import sys
from collections import defaultdict


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--taxonomy", required=True, help="Taxonomy file (tsv, with a header line)")
    parser.add_argument("--sequences", required=True, help="Sequence file (fasta)")
    parser.add_argument("--rename-duplicates", action="store_true",
                        help="Rename taxa with the same name under different parent lineages, instead of failing")
    parser.add_argument("--out-taxonomy", default="ready4train_taxonomy.txt")
    parser.add_argument("--out-sequences", default="ready4train_seqs.fasta")
    return parser.parse_args()


def fail(message, problems):
    shown = problems[:20]
    more  = f"\n  ... and {len(problems) - len(shown)} more" if len(problems) > len(shown) else ""
    sys.exit(f"{message}\n  - " + "\n  - ".join(shown) + more)


def clean(node):
    # Strip whitespace and non-breaking spaces, as addFullLineage.py did
    return node.strip().strip(" ").strip()


def read_taxonomy(path):
    """Ranks, and the lineage (list of names, '' for a missing rank) of each id."""
    with open(path, encoding="utf-8") as f:
        header = f.readline().rstrip("\n").split("\t")
        ranks  = [clean(r) for r in header[1:]]
        if not ranks:
            sys.exit(f"{path}: the header line must have an id column and one column per rank (tab-separated).")

        lineages, problems = {}, []
        for n, line in enumerate(f, start=2):
            if not line.strip():
                continue
            cols = [clean(c) for c in line.rstrip("\n").split("\t")]
            seq_id, names = cols[0], [("" if c == "-" else c) for c in cols[1:]]
            if len(names) != len(ranks):
                problems.append(f"line {n} ({seq_id}): {len(names)} ranks instead of {len(ranks)}")
            elif not names[-1]:
                problems.append(f"line {n} ({seq_id}): no {ranks[-1]}; the lowest rank must be filled in for every sequence")
            elif seq_id in lineages:
                problems.append(f"line {n}: the id {seq_id} appears more than once")
            else:
                lineages[seq_id] = names

    if problems:
        fail(f"Problems in the taxonomy file {path}:", problems)
    return ranks, lineages


def resolve_duplicates(ranks, lineages, rename):
    """Find names used at the same rank under different parents; rename them or stop."""
    parents = defaultdict(set)   # (rank index, name) -> parent lineages
    for names in lineages.values():
        for i, name in enumerate(names):
            if name:
                parents[(i, name)].add(tuple(n for n in names[:i] if n))

    duplicates = {key: sorted(p) for key, p in parents.items() if len(p) > 1}
    if not duplicates:
        return lineages

    if not rename:
        problems = [
            f"{ranks[i]} '{name}' under: " + " | ".join(";".join(p) for p in plist)
            for (i, name), plist in sorted(duplicates.items())
        ]
        fail("The same taxon name appears under different parent lineages, which the RDP Classifier does not allow.\n"
             "Fix the taxonomy file, or set rename_duplicates to rename them to <name>_1, <name>_2, ...:", problems)

    new_name = {
        (i, name, parent): f"{name}_{k}"
        for (i, name), plist in duplicates.items()
        for k, parent in enumerate(plist, start=1)
    }
    print(f"Renamed {len(duplicates)} taxon names found under different parent lineages.", file=sys.stderr)

    renamed = {}
    for seq_id, names in lineages.items():
        out = []
        for i, name in enumerate(names):
            # Look up the original parent lineage, before any renaming
            parent = tuple(n for n in names[:i] if n)
            out.append(new_name.get((i, name, parent), name) if name else name)
        renamed[seq_id] = out
    return renamed


def write_taxonomy(ranks, lineages, path):
    """RDP taxonomy file: each taxon is identified by its full lineage."""
    taxon_id = {(): 0}
    with open(path, "w") as out:
        out.write("0*Root*-1*0*rootrank\n")
        for names in lineages.values():
            lineage = ()
            for i, name in enumerate(names):
                if not name:
                    continue
                parent  = lineage
                lineage = lineage + (name,)
                if lineage in taxon_id:
                    continue
                taxon_id[lineage] = len(taxon_id)
                out.write(f"{taxon_id[lineage]}*{name}*{taxon_id[parent]}*{len(lineage)}*{ranks[i]}\n")


def write_sequences(lineages, fasta, path):
    missing, written, seq_id = [], 0, None
    with open(fasta, encoding="utf-8") as f, open(path, "w") as out:
        for line in f:
            line = clean(line)
            if not line:
                continue
            if line.startswith(">"):
                seq_id = line[1:].split()[0]
                if seq_id not in lineages:
                    missing.append(seq_id)
                    seq_id = None
                    continue
                lineage = ";".join(["Root"] + [n for n in lineages[seq_id] if n])
                out.write(f">{seq_id}\t{lineage}\n")
                written += 1
            elif seq_id is not None:
                out.write(line + "\n")

    if missing:
        fail(f"{len(missing)} sequences of {fasta} are not in the taxonomy file:", missing)
    if written == 0:
        sys.exit(f"No sequences found in {fasta}.")
    return written


def main():
    args = parse_args()

    ranks, lineages = read_taxonomy(args.taxonomy)
    lineages = resolve_duplicates(ranks, lineages, args.rename_duplicates)

    write_taxonomy(ranks, lineages, args.out_taxonomy)
    n = write_sequences(lineages, args.sequences, args.out_sequences)
    print(f"{n} sequences, {len(lineages)} taxonomies, ranks: {', '.join(ranks)}", file=sys.stderr)


if __name__ == "__main__":
    main()

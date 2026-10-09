import argparse

def parse_args():
    parser = argparse.ArgumentParser(
        description="Filter original sequences based on accepted IDs from map and UC mapping."
    )
    parser.add_argument("--original", help="Original FASTA file")
    parser.add_argument("--uc", help="UC mapping file")
    parser.add_argument("--map", help="FASTA file with accepted sequences")
    return parser.parse_args()

def clean_id(s):
    return s.split()[0].split(";")[0].replace("*", "")

def main():
    args = parse_args()

    # Step 1: read map
    accepted = set()
    with open(args.map) as f:
        for line in f:
            if line.startswith(">"):
                seq_id = clean_id(line[1:])
                accepted.add(seq_id)

    # Step 2: read uc file
    with open(args.uc) as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 10:
                continue

            a = clean_id(cols[8]) if cols[8] != "*" else None
            b = clean_id(cols[9]) if cols[9] != "*" else None

            if b and b in accepted and a:
                accepted.add(a)

    # Step 3: filter original
    ok = False
    with open(args.original) as f:
        for line in f:
            if line.startswith(">"):
                seq_id = clean_id(line[1:])
                ok     = seq_id in accepted
            if ok:
                print(line, end="")

if __name__ == "__main__":
    main()

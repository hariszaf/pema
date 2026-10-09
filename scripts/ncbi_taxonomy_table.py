import pandas as pd
import json

# ---------------------------
# File paths
# ---------------------------
import argparse

# ---------------------------
# Argument parser
# ---------------------------
parser = argparse.ArgumentParser(
    description="Enhance taxonomy table with NCBI taxonomies and resolve ambiguities."
)

parser.add_argument(
    "--taxonomy-table", "-t",
    default="tax_assigned_table.tsv",
    help="Path to the input taxonomy table TSV file"
)

parser.add_argument(
    "--ncbi-taxonomies", "-n",
    default="taxonomies.json",
    help="Path to the NCBI merged taxonomies JSON file"
)

parser.add_argument(
    "--ncbi-candidates", "-c",
    default="ambiguous_candidates.tsv",
    help="""TSV with one '<taxon> TAB <NCBI JSON report>' line per candidate taxid,
    for taxon names that match more than one NCBI taxid"""
)

parser.add_argument(
    "--output", "-o",
    default="tax_assigned_with_ncbi.tsv",
    help="Path to save the enhanced taxonomy table TSV"
)

parser.add_argument(
    "--min-prefix-len",
    default=5,
    type=int,
    help="""Number of characters that need to be at least the same in the begining of a taxon name
    to be considered as a matching prefix"""
)

args = parser.parse_args()

# ---------------------------
# Assign to variables
# ---------------------------
taxonomy_table_file  = args.taxonomy_table
ncbi_taxonomies_file = args.ncbi_taxonomies
ncbi_candidates_file = args.ncbi_candidates
output_file          = args.output

# ---------------------------
# Example usage in your script
# ---------------------------
print("Taxonomy table:", taxonomy_table_file)
print("NCBI taxonomies:", ncbi_taxonomies_file)
print("NCBI candidates:", ncbi_candidates_file)
print("Output file:", output_file)


ranks  = ["domain", "kingdom", "phylum", "class", "order", "family", "genus", "species"]
ignore = {"root", "main genome"}

# Load data
with open(ncbi_taxonomies_file) as f:
    ncbi_tax = json.load(f)


# Extract last part of Taxonomy
def last_taxon(tax_str):
    if pd.isna(tax_str):
        return None
    parts = [x.strip() for x in tax_str.split(";")]
    return parts[-1] if parts else None

# Map last_taxon to NCBI classification (single hit)
def get_ncbi_tax(row):

    last_tax = row["last_taxon"]
    tax_data = ncbi_tax.get(last_tax, {})
    classification = tax_data.get("taxonomy", {}).get("classification", {})

    names = {r: classification.get(r, {}).get("name") for r in ranks if classification.get(r)}
    ids   = {r: classification.get(r, {}).get("id") for r in ranks if classification.get(r)}

    row["ncbi_taxonomy"] = ";".join([names[r] for r in ranks if r in names])
    row["ncbi_taxonomy_ids"] = ";".join([str(ids[r]) for r in ranks if r in ids])
    # NCBI Taxonomy id of the taxon itself (the lowest rank that was looked up)
    row["ncbi_taxid"] = tax_data.get("taxonomy", {}).get("tax_id")

    return row

tax_table = pd.read_csv(taxonomy_table_file, sep="\t")

tax_table["last_taxon"] = tax_table["Taxonomy"].apply(last_taxon)

tax_table = tax_table.apply(get_ncbi_tax, axis=1)

# Candidate classifications for taxon names that match more than one NCBI taxid
taxon_ncbi_taxonomies = {}

with open(ncbi_candidates_file) as f:
    for line in f:
        taxon, sep, report = line.rstrip("\n").partition("\t")
        if not sep:
            continue
        try:
            entry = json.loads(report)
        except json.JSONDecodeError:
            continue

        classification = entry.get("taxonomy", {}).get("classification", {})

        names = {r: classification.get(r, {}).get("name") for r in ranks if classification.get(r)}
        ids   = {r: classification.get(r, {}).get("id") for r in ranks if classification.get(r)}

        ncbi_taxonomy     = ";".join([names[r] for r in ranks if r in names])
        ncbi_taxonomy_ids = ";".join([str(ids[r]) for r in ranks if r in ids])

        taxon_ncbi_taxonomies.setdefault(taxon, []).append(
            [ncbi_taxonomy, ncbi_taxonomy_ids, entry.get("taxonomy", {}).get("tax_id")]
        )

# ---------------------------
# Pick best candidate based on overlap
# ---------------------------
def clean_tax(t):
    # Always returns a semicolon-separated string
    if isinstance(t, list):
        t = ";".join(t)
    parts = [x.strip() for x in t.split(";") if x.strip() and x.strip().lower() not in ignore]
    return ";".join(parts)

def longest_common_prefix(a, b):
    a, b = a.lower(), b.lower()
    i = 0
    while i < min(len(a), len(b)) and a[i] == b[i]:
        i += 1
    return i

def taxonomy_similarity(t1, t2, min_prefix_len=5):

    t1_parts = [x.strip().lower() for x in t1.split(";") if x.strip()]
    t2_parts = [x.strip().lower() for x in t2.split(";") if x.strip()]

    # 1. exact overlap
    overlap = len(set(t1_parts) & set(t2_parts))

    # 2. partial prefix match
    prefix_score = 0
    for a in t1_parts:
        for b in t2_parts:
            lcp = longest_common_prefix(a, b)
            if lcp >= min_prefix_len:  # count as partial match
                prefix_score += 2
                break

    return overlap + prefix_score

def pick_best_taxonomy(existing_tax, candidates):

    best       = None
    best_score = -1

    existing_tax_clean = clean_tax(existing_tax)

    for tax_string, tax_ids, taxid in candidates:

        score = taxonomy_similarity(existing_tax_clean, tax_string, args.min_prefix_len)
        if score > best_score:
            best_score = score
            best = (tax_string, tax_ids, taxid)

    return best

def get_ncbi_filtered_tax(row):

    last_tax     = row["last_taxon"]
    existing_tax = row.get("Taxonomy", "")
    candidates   = taxon_ncbi_taxonomies.get(last_tax)

    if not candidates:
        return row

    best = pick_best_taxonomy(existing_tax, candidates)
    if best:
        row["ncbi_taxonomy"] = best[0]
        row["ncbi_taxonomy_ids"] = best[1]
        row["ncbi_taxid"] = best[2]

    return row


tax_table = tax_table.apply(get_ncbi_filtered_tax, axis=1)

# ---------------------------
# Save enhanced table
# ---------------------------
# Taxa not found in NCBI have no taxid; keep the column as integers
if "ncbi_taxid" in tax_table:
    tax_table["ncbi_taxid"] = pd.to_numeric(tax_table["ncbi_taxid"], errors="coerce").astype("Int64")

tax_table.to_csv(output_file, sep="\t", index=False)

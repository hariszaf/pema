import pandas as pd
import json
import re
import subprocess

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
    default="taxonomies_merged.json",
    help="Path to the NCBI merged taxonomies JSON file"
)

parser.add_argument(
    "--ncbi-errors", "-e",
    default="not_found.tsv",
    help="Path to the NCBI errors TSV file containing ambiguous taxids"
)

parser.add_argument(
    "--output", "-o",
    default="tax_assigned_with_ncbi.tsv",
    help="Path to save the enhanced taxonomy table TSV"
)

parser.add_argument(
    "--min-prefix-len",
    default=5,
    help="""Number of characters that need to be at least the same in the begining of a taxon name
    to be considered as a matching prefix"""
)

args = parser.parse_args()

# ---------------------------
# Assign to variables
# ---------------------------
taxonomy_table_file  = args.taxonomy_table
ncbi_taxonomies_file = args.ncbi_taxonomies
ncbi_error_file      = args.ncbi_errors
output_file          = args.output

# ---------------------------
# Example usage in your script
# ---------------------------
print("Taxonomy table:", taxonomy_table_file)
print("NCBI taxonomies:", ncbi_taxonomies_file)
print("NCBI errors:", ncbi_error_file)
print("Output file:", output_file)

# ncbi_taxonomies_file = "taxonomies_merged.json"
# ncbi_error_file      = "not_found.tsv"
# taxonomy_table_file  = "tax_assigned_table.tsv"

# output_file          = "tax_assigned_with_ncbi.tsv"

ranks  = ["kingdom", "phylum", "class", "order", "family", "genus", "species"]
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

    return row

# Handle errors with multiple taxids
def parse_blocks(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    blocks = [block.strip() for block in content.split("\n\n") if block.strip()]
    return blocks

# Get matches with taxon name and NCBI tax id
def extract_taxa(error):
    return re.findall(r"^(.*?)\s*\(.*?taxid:\s*(\d+)\)", error, re.MULTILINE)


tax_table = pd.read_csv(taxonomy_table_file, sep="\t")

tax_table["last_taxon"] = tax_table["Taxonomy"].apply(last_taxon)

tax_table = tax_table.apply(get_ncbi_tax, axis=1)

errors = parse_blocks(ncbi_error_file)
regex  = re.compile(r"exact match.*more than one taxid", re.IGNORECASE)

filtered_errors = [
    error for error in errors if regex.search(error.splitlines()[0])
]

taxon_ncbi_taxonomies = {}

for error in filtered_errors:

    cases = extract_taxa(error)

    for taxon, tax_id in cases:
        # fetch NCBI data
        result = subprocess.run(
            ["datasets", "summary", "taxonomy", "taxon", str(tax_id), "--as-json-lines"],
            capture_output=True, text=True
        )

        try:
            data = [json.loads(line) for line in result.stdout.splitlines()]
        except json.JSONDecodeError:
            continue

        if taxon not in taxon_ncbi_taxonomies:

            taxon_ncbi_taxonomies[taxon] = []

        for entry in data:

            classification = entry.get("taxonomy", {}).get("classification", {})

            names = {r: classification.get(r, {}).get("name") for r in ranks if classification.get(r)}
            ids   = {r: classification.get(r, {}).get("id") for r in ranks if classification.get(r)}

            ncbi_taxonomy     = ";".join([names[r] for r in ranks if r in names])
            ncbi_taxonomy_ids = ";".join([str(ids[r]) for r in ranks if r in ids])

            taxon_ncbi_taxonomies[taxon].append([ncbi_taxonomy, ncbi_taxonomy_ids])

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

    for tax_string, tax_ids in candidates:

        score = taxonomy_similarity(existing_tax_clean, tax_string, args.min_prefix_len)
        if score > best_score:
            best_score = score
            best = (tax_string, tax_ids)

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

    return row


tax_table = tax_table.apply(get_ncbi_filtered_tax, axis=1)

# ---------------------------
# Save enhanced table
# ---------------------------
tax_table.to_csv(output_file, sep="\t", index=False)
print(f"Saved enhanced table to {output_file}")

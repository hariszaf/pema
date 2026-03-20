import pandas as pd
import json

# ---------------------------
# File paths
# ---------------------------
ncbi_taxonomies_file = "taxonomies_merged.json"
taxonomy_table_file  = "tax_assigned_table.tsv"
output_file          = "tax_assigned_with_ncbi.tsv"

ranks = ["kingdom", "phylum", "class", "order", "family", "genus", "species"]

# ---------------------------
# Load data
# ---------------------------
tax_table = pd.read_csv(taxonomy_table_file, sep="\t")
with open(ncbi_taxonomies_file) as f:
    ncbi_tax = json.load(f)

# ---------------------------
# Extract last part of Taxonomy
# ---------------------------
def last_taxon(tax_str):
    if pd.isna(tax_str):
        return None
    parts = [x.strip() for x in tax_str.split(";")]
    return parts[-1] if parts else None

tax_table["last_taxon"] = tax_table["Taxonomy"].apply(last_taxon)

# ---------------------------
# Map last_taxon to NCBI classification
# ---------------------------
def get_ncbi_tax(row):
    last_tax = row["last_taxon"]
    tax_data = ncbi_tax.get(last_tax, {})
    classification = tax_data.get("taxonomy", {}).get("classification", {})

    names = {r: classification.get(r, {}).get("name") for r in ranks if classification.get(r)}
    ids   = {r: classification.get(r, {}).get("id") for r in ranks if classification.get(r)}

    # Combine into single ";"-separated columns, remove missing ranks
    row["ncbi_taxonomy"] = ";".join([names[r] for r in ranks if r in names])
    row["ncbi_taxonomy_ids"] = ";".join([str(ids[r]) for r in ranks if r in ids])

    return row

tax_table = tax_table.apply(get_ncbi_tax, axis=1)

# ---------------------------
# Save enhanced table
# ---------------------------
tax_table.to_csv(output_file, sep="\t", index=False)
print(f"Saved enhanced table to {output_file}")

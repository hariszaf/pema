import os
import re
import sys
import json
import pandas as pd
from ete3 import Tree
from pathlib import Path
from utilsForTables import load_vseach_hash, load_swarm_hash


abd_table       = sys.argv[1]  # "allTab_crest4_vsearch_132.tsv"
epa_placements  = sys.argv[2]  # "epa_result.jplace"
clustering_algo = sys.argv[3]

main_dir       = Path(abd_table).parent.absolute()
placements_dir = Path(epa_placements).parent.absolute()


def extract_node_id(tree_str, taxonomy):
    # Escape underscores or other regex meta-characters in taxonomy
    taxonomy_escaped = re.escape(taxonomy)
    # Ensure taxonomy is followed by a colon and a float, then the ID in braces
    pattern = rf'{taxonomy_escaped}:\d+\.\d+\{{(\d+)\}}'
    match = re.search(pattern, tree_str)
    if match:
        return int(match.group(1))
    return None, taxonomy_escaped

# Clean up non-standard {X} node labels
def strip_curly_annotations(tree_str):
    return re.sub(r'\{[0-9]+\}', '', tree_str)


def get_subtree_before_id(tree_str, target_id):
    """
    Extracts the full subtree (as a Newick-formatted string) that ends at a specific node ID from a larger Newick tree string. 
    This subtree includes the taxa and all internal nodes that are part of the clade immediately preceding the given {target_id}.
    """
    target = f'{{{target_id}}}'
    end_idx = tree_str.find(target)
    if end_idx == -1:
        raise ValueError(f"ID {target_id} not found in tree.")
    # Walk backwards from the position of `{id}` to find matching parenthesis
    stack = []
    i = end_idx
    while i >= 0:
        if tree_str[i] == ')':
            stack.append(')')
        elif tree_str[i] == '(':
            if stack:
                stack.pop()
            else:
                # Found the opening parenthesis for the clade that ends at {target_id}
                return tree_str[i:end_idx + len(target)]
        i -= 1
    # If no outer '(' was found
    return tree_str[:end_idx + len(target)]


def common_prefix(strings):
    # Get the longest common prefix
    lca = os.path.commonprefix(strings)
    # Split the common prefix by underscores
    parts = lca.split('_')
    return ";".join(parts[:-1])


# ------   Load epa-ng output   --------

with open(epa_placements, "r") as f:
    jplace = json.load(f)

epa_tree       = jplace["tree"]
all_placements = jplace["placements"]

# ------   Parse tree   --------

tree_str_clean = strip_curly_annotations(epa_tree)

# Add semicolon if missing
if not tree_str_clean.strip().endswith(";"):
    tree_str_clean += ";"

# Now load
ete_tree = Tree(tree_str_clean, format=1)

taxonomy2id = {}
ete_leaves  = set(x.name for x in ete_tree.get_leaves())
for leave in ete_leaves:
    node_id = extract_node_id(epa_tree, leave)
    if isinstance(node_id, tuple):
        print(leave, node_id[1])
    else:
        taxonomy2id[node_id] = leave

# Check if we got all leaves
if len(ete_tree.get_leaves()) != len(taxonomy2id):
    for x in ete_leaves:
        if x not in taxonomy2id.values():
            print(x)

# ---
# Get for higher levels than the end of the leaves
# ---
# Extract all numbers inside curly braces
ids = re.findall(r'\{(\d+)\}', epa_tree)

# Convert to integers if needed
all_ids = list(map(int, ids))
higher_tax_levels = set(all_ids) - set(taxonomy2id.keys())

higherTaxonomy2id = {}
for id in higher_tax_levels:
    subtree    = get_subtree_before_id(epa_tree, id)
    taxonomies = re.findall(r'([A-Za-z0-9_]+):[\d\.]+{', subtree)
    taxonomies = [x for x in taxonomies if x.startswith("Bacteria") or x.startswith("Archaea")]
    lca        = common_prefix(taxonomies)
    higherTaxonomy2id[id] = lca

# ------   Parse placemets   --------

# NOTE (Haris Zafeiropoulos, 2025-07-06):
# We ll use the placement with the highest likelihood weight ratio (LWR)

hash2tax = {}
counter  = 0
for case in all_placements:
    ahash = case["n"]
    if len(ahash) > 1:
        print(
            "More than one hashes with in the same placement..."
            "Not sure it this is reasonable, don;t know how to process this!"
        )
        continue
    placements  = case["p"]
    best_lwr    = max(placements, key=lambda x: x[2])
    best_tax_id = best_lwr[0]
    if best_tax_id in taxonomy2id:
        hash2tax[ahash[0]] = taxonomy2id[best_tax_id]
    else:
        print(case["n"], higherTaxonomy2id[best_tax_id])
        hash2tax[ahash[0]] = higherTaxonomy2id[best_tax_id]
        counter += 1

print(
    f"\n >> {counter} out of the total {len(all_placements)} placements did not resolve to leaf nodes,"
    "but instead mapped to internal nodes in the tree."
)

# ------   Build table   --------

tax_df = pd.DataFrame.from_dict(hash2tax, orient="index").reset_index()

if clustering_algo == "vsearch":

    abd_df = load_vseach_hash(tax_df, main_dir)

elif clustering_algo == "swarm":

    abd_df = load_swarm_hash(tax_df, main_dir)

# Write table to file
outfile        = placements_dir / "finalTable.tsv"
abd_df.to_csv(outfile, sep="\t", index=False)

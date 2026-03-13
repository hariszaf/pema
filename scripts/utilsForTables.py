import json
import pandas as pd


def load_vseach_hash(tax_df, work_dir):

    # Vsearch case of the taxonomy file
    tax_df.columns = ["OTU", "Taxonomy"]

    # Filename of the contigency table on the vsearch case
    contingency_table = work_dir / "all.otutab_sha.txt"

    # Abundance data
    abd_df         = pd.read_csv(contingency_table, sep="\t")
    abd_df         = abd_df.rename(columns={"amplicon":"Seed"})
    abd_df.columns = [x.replace(".derep.fa", "") for x in abd_df.columns]

    # In the vsearch case, we keep the mapping of each hash to their corresponding otu
    # in a json file
    otu_hash = "map.json"
    with open(otu_hash, "r") as f:
        otu_hash_dict = json.load(f)

    # Add column with the hash id
    abd_df.insert(0, 'OTU', abd_df['Seed'].map(otu_hash_dict))

    # Merge
    abd_df = abd_df.merge(tax_df[["OTU", "Taxonomy"]], on="OTU", how="left")
    abd_df = abd_df.drop(columns=["Seed"])

    return abd_df


def load_swarm_hash(tax_df, work_dir):

    tax_df.columns = ["Seed", "Taxonomy"]

    contingency_table = work_dir / "asvs_contingency_hash.tsv"

    # Abundance data
    abd_df         = pd.read_csv(contingency_table, sep="\t")
    abd_df.columns = [x.replace(".derep.fa", "") for x in abd_df.columns]

    # Merge
    abd_df = abd_df.merge(tax_df[["Seed", "Taxonomy"]], on="Seed", how="left")
    abd_df = abd_df.drop(columns=["Seed"])

    return abd_df

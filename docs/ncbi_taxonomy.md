---
layout: page
title: Mapping to NCBI Taxonomy
---

The taxonomies PEMA assigns come from the reference database used (SILVA, PR2, MIDORI, UNITE, ...), each with its own names and ranks.
To compare or combine results, PEMA can also map them to [NCBI Taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy):

```
ncbi_taxonomy:
  get_ncbi_taxonomy: true
```

PEMA then looks up the lowest taxon of each assigned lineage with the [NCBI Datasets](https://www.ncbi.nlm.nih.gov/datasets/) command line tool,
and adds to the final ASV/OTU table, in `ncbi_taxonomy/tax_assigned_with_ncbi.tsv`:

* `last_taxon`: the taxon that was looked up;
* `ncbi_taxonomy`: its NCBI lineage, from domain to species;
* `ncbi_taxonomy_ids`: the NCBI taxids of that lineage;
* `ncbi_taxid`: the NCBI taxid of the taxon itself.

Synonyms are resolved by NCBI: for example, *Navicula minima* is mapped to its current name, *Eolimna minima*.

Some names match **more than one** NCBI taxon, e.g. the genus *Bacillus*, both a bacterium and a stick insect. For these, PEMA fetches
every candidate and keeps the one whose lineage is the most similar to the lineage assigned by the classifier.
Names that NCBI does not know are listed in `ncbi_taxonomy/not_found.tsv`; they do not stop the run.


## API key

The key is optional. NCBI Datasets allows 5 requests per second without an API key, and 10 with one
(free, [get one here](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/api/api-keys/)). To stay within these limits, PEMA runs up to 2 lookups
at the same time without a key and up to 4 with one (`max_parallel`, which can be lower but not higher), with a pause (`sleep`) after each.
Rather than writing the key in the parameters file, set it in your environment:

```
export NCBI_API_KEY=<your key>
```

If the lookups are interrupted (e.g. by "too many requests" errors), run PEMA again with `-resume`: only the missing lookups are repeated.

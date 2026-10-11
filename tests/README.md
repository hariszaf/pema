# Module tests

Small datasets and parameters files to run single modules of PEMA on their own, e.g. to test a change to one step.
The whole pipeline is tested with the sanity check instead (see [`sanity_check/run_sanity_check.sh`](../sanity_check/run_sanity_check.sh)
and the README of the repository).

| Module | Parameters file | Input data |
|--------|-----------------|------------|
| [`fastp.nf`](../modules/fastp.nf) | [`configs/fastp.yaml`](configs/fastp.yaml) | `data/fastp/`: one sample, 130,200 read pairs |
| [`swarm.nf`](../modules/swarm.nf) | [`configs/swarm.yaml`](configs/swarm.yaml) | `data/swarm/all_samples.fa`: unique amplicons of all samples (`<hash>_<abundance>`), as from `CONCATENATE_FASTA` |
| [`crest.nf`](../modules/crest.nf) | [`configs/crest.yaml`](configs/crest.yaml) | `data/crest/`: ITS ASVs (`all_sequences_grouped.fa`) and their table (`asvs_contingency_hash.tsv`) |

From the root folder of the repository (the paths in the parameters files are relative to it):

```bash
nextflow run modules/fastp.nf --params-file tests/configs/fastp.yaml -c nextflow.config
nextflow run modules/swarm.nf --params-file tests/configs/swarm.yaml -c nextflow.config
nextflow run modules/crest.nf --params-file tests/configs/crest.yaml -c nextflow.config
```

The outputs are written in `results/` (git-ignored). The crest4 test uses the `unite2025` database: set `mount_crest_dbs` in
`configs/crest.yaml` to the folder that has it (`pema.nf` downloads it there the first time it is used for ITS).

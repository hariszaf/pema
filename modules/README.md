# Notes on the Nextflow pipeline


## Nextflow version

The pipeline is written for Nextflow's strict syntax and requires **Nextflow 25.04 or later** (tested with 26.04).
Check the code with:

```bash
nextflow lint pema.nf modules/ nextflow.config
```

With the strict syntax:

* `pema.nf` may only contain `include`s, `params.*` assignments, functions and the `workflow {}` block;
  any other statement must go inside a function or the workflow.
* Groovy `import`s are not allowed; use fully-qualified names (e.g. `new groovy.yaml.YamlSlurper()`).
* Use `channel.<factory>` instead of `Channel.<factory>`, and name closure parameters instead of using `it`.


## How the parameters are loaded

When Nextflow starts, it does roughly this:

1️⃣ Parse the main script (`pema.nf`) and evaluate its top-level `params.*` assignments

2️⃣ Load all included modules

```
include { FASTP } from './modules/fastp.nf'
```

3️⃣ Parse the processes inside those modules

4️⃣ Only after that, the `workflow {}` block is executed

`pema.nf` reads the YAML given with `--params-file` through `loadYamlParams` (in `modules/utils.nf`):

* top-level keys (`raw_reads`, `threads`, `outdir`, ...) become `params.*` in step 1, so the modules can use them;
* the tool sections (`fastp`, `swarm`, `crest`) are resolved inside the workflow and passed to the processes as `val` inputs.

`loadYamlParams` returns `null` for a missing key. Use `valueOr(value, default)` rather than `value ?: default`
for defaults, so that `0` and `false` given by the user are kept.


## Containers and configuration

`nextflow.config` enables Docker by default and defines the `docker`, `podman`, `singularity`, `apptainer` and `reports` profiles.
When a module is run on its own (`nextflow run modules/<module>.nf`), Nextflow does not load the root `nextflow.config`,
so add `-c nextflow.config` to run it in its container.

Processes that use several threads declare `cpus params.threads` and use `${task.cpus}` in their command,
so Nextflow does not start more tasks than the machine can handle.

The images used by each process are listed in [containers/README.md](containers/README.md).
Scripts from `scripts/` run in the `hariszaf/pema-nf` image, so a change in a script needs a new image.


## Resuming

Add `-resume` to re-run only the steps whose input or code changed:

```
nextflow run pema.nf --params-file pema.yaml -resume
```

This can be rather useful if you get errors on getting NCBI Taxonomy Ids,
since you may have a lot of them and get 'Too many queries' like errors.

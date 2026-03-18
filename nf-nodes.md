


When Nextflow starts, it does roughly this:

1️⃣ Parse the main script (`pema.nf`)

2️⃣ Load all included modules

```
include { FASTP } from './modules/fastp.nf'
```

3️⃣ Parse the processes inside those modules

4️⃣ Only after that, the `workflow {}` block is executed


The `--resume` needs to be in the end of the command.

```
nextflow run pema.nf --params-file config_files/pema.yaml -resume
```
---
layout: page
title: Tuning tuning tuning!
---

It is widely known that there is a great range of bioinformatics tools for each step of a metabarcoding analysis.

From the quality control and the pre-processing steps (trimming, merging sequences etc) to the OTU clustering and the taxonomy assignment, there are plenty of software that support each step of the way.

PEMA is a third-party-based software and **does not** claim that includes the *best* software for each step of the analysis. What we would like to highlight is that **no matter** which tool you are about to use, thorough ***tuning*** is more than necessary.

As shown in the [PEMA publication](https://doi.org/10.1093/gigascience/giaa022) (see its supplementary files), even the smallest change of a parameter in the pre-processing steps might change the results of your analysis to a great extent.

We ran PEMA against mock communities and as you can see, as long as you keep tuning the parameters set the results you get may become better or worse.

**Tuning** is rather important for metabarcoding analyses.

PEMA allows you to run multiple tests by **resuming** a run: change some parameters, run PEMA again with `-resume`, and only the steps
affected by the change are run again (see [Basics for running PEMA]({{ '/2.running_general/' | relative_url }})).
Use a different `outdir` for each test, to compare their results.

A good practice is to always have a **mock** community among your samples, this way you may tune your bioinformatics analysis according to that and then run it against you actual data.

Running a metabarcoding analysis by making use of the *by default* parameters of each tool may lead to spurious results or even not results at all, for example in case that your paired-end sequences do not overlap to the extent selected. **You need to have a thorough look in all the parameters** you are about to set their values and **noone can tell you what is the best parameter set for your data**.

>Conceiving **a metabarcoding analysis as an experiment by itsef** is probably the best way to go!

---
layout: page
title: Tuning tuning tuning!
---

It is widely known that there is a great range of bioinformatics tools for each step of a metabarcoding analysis. 

From the quality control and the pre-processing steps (trimming, merging sequences etc) to the OTU clustering and the taxonomy assignment, there are plenty of software that support each step of the way.

PEMA is a third-party-based software and **does not** claim that includes the *best* software for each step of the analysis. What we would like to highlight is that **no matter** which tool you are about to use, thorough ***tuning*** is more than necessary. 

As shown in the PEMA publication (see [Supplementary files](https://oup.silverchair-cdn.com/oup/backfile/Content_public/Journal/gigascience/9/3/10.1093_gigascience_giaa022/2/giaa022_supplement_files.zip?Expires=1612952785&Signature=dGFqtz-VZuMs8yZro0OXu6bw966p6vV5i-VGC0cPD~DtphOkoajg7Cr9DfxyMT5BNk30X4APYcrXIsXNrWF63SyOudRf7ZzxzHwMB1b52qjR-nCFghRnhQz~XmHPi~ZVcj0ZB585fD~dy9e4zB0s7APoAHYZ6MfAbG0tZyPS~yWIx84syXLj1PdiuW2rZZnlwLhDR9HgRf2Au9~VqFDcifsOVipgGiXuzEv8fA0hIxp~0tMqI3O9LE9TFe~1u5mlArt8GRQY0hh~d8r8tEoJbJo03yKyZx9OwpYRh-2vm5rCr0qbYaAB4jld~Frb5d0h0eTojPNRNz1yymW9cjB7NQ__&Key-Pair-Id=APKAIE5G5CRDK6RD3PGA)), even the smallest change of a parameter in the pre-processing steps might change the results of your analysis to a great extent.  

We ran PEMA against mock communities and as you can see, as long as you keep tuning the parameters set the results you get may become better or worse.

**Tuning** is rather important for metabarcoding analyses. 

PEMA allows you to run mutliplous tests by taking advantage of the ***checkpoints*** files produced after each step. 

A good practice is to always have a **mock** community among your samples, this way you may tune your bioinformatics analysis according to that and then run it against you actual data. 

Running a metabarcoding analysis by making use of the *by default* parameters of each tool may lead to spurious results or even not results at all, for example in case that your paired-end sequences do not overlap to the extent selected. **You need to have a thorough look in all the parameters** you are about to set their values and **noone can tell you what is the best parameter set for your data**. 

>Conceiving **a metabarcoding analysis as an experiment by itsef** is probably the best way to go! 



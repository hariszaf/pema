---
layout: default
title: Home
---

# Welcome


<p class="message">

  Hey there! <br />
  This is the PEMA main site for <i>how to use</i> and further metabarcoding tips and hints! <br />
  This documentation is about the current, <b>Nextflow-based PEMA</b>.
  For PEMA v2.x (BigDataScript, run from a Docker or Singularity image), see the
  <a href="{{ '/v2/' | relative_url }}">previous version of this documentation</a>.

</p>


PEMA is a pipeline for environmental DNA metabarcoding analysis of the **16S/18S rRNA**, **12S rRNA**, **ITS** and **COI** marker genes.
It takes paired-end Illumina reads and returns an **ASV or OTU table with the taxonomy** of each ASV/OTU and its abundance in each sample.

PEMA is now written in [Nextflow](https://www.nextflow.io/). Every step runs in its own container, so all you need is Nextflow and a
container engine (Docker, Podman, Singularity or Apptainer); the containers are downloaded automatically.
The same command runs PEMA on a laptop, a server or an HPC cluster, and an interrupted or changed run can be resumed from where it stopped.

Here is what PEMA does:

| Step | Tool |
|------|------|
| Primer removal (ITS only) | [cutadapt](https://cutadapt.readthedocs.io) |
| Quality control and merging of the read pairs | [fastp](https://github.com/OpenGene/fastp) |
| Dereplication | [VSEARCH](https://github.com/torognes/vsearch) |
| ASV inference, or OTU clustering with chimera removal | [Swarm](https://github.com/torognes/swarm) or [DADA2](https://benjjneb.github.io/dada2/), or [VSEARCH](https://github.com/torognes/vsearch) |
| Taxonomy assignment | [crest4](https://github.com/xapple/crest4) or [RDPClassifier](https://github.com/rdpstaff/classifier), with built-in, PEMA-trained or your own databases |
| Mapping to NCBI Taxonomy (optional) | [NCBI Datasets](https://www.ncbi.nlm.nih.gov/datasets/) |

To start, see [Get PEMA]({{ '/1.get_pema/' | relative_url }}) and [Basics for running PEMA]({{ '/2.running_general/' | relative_url }}).

Here is the [PEMA GitHub repository](https://github.com/hariszaf/pema) if you want to have a look on the source code and why not, to [contribute](https://github.com/hariszaf/pema/blob/main/CONTRIBUTING.md) to!


> For any running issues you may have, or for any further features you would like to see included on PEMA, you can reach us through the [PEMA Gitter community](https://gitter.im/pema-helpdesk/community#), by opening an [issue](https://github.com/hariszaf/pema/issues), or at *pema@hcmr.gr* .



Thanks for your interest on PEMA!
Keep metabarcoding!

The PEMA team

<p align="center">
<img src="{{ '/public/pema_logo.png' | relative_url }}" alt="PEMA logo" style="width:300px;"/>
</p>


<p class="message">

  To cite PEMA: <br />
  <a href="https://doi.org/10.1093/gigascience/giaa022">Zafeiropoulos H, Viet HQ, Vasileiadou K, Potirakis A, Arvanitidis C, Topalis P, Pavloudi C, Pafilis E. PEMA: a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S ribosomal RNA, ITS, and COI marker genes. GigaScience. 2020 Mar;9(3):giaa022.</a>

</p>


<table><tr>
  <td><a href="https://www.hcmr.gr/en/"><img src="{{ '/public/hcmr.png' | relative_url }}" alt="HCMR" style="width: 50px;"/></a></td>
  <td><a href="http://imbbc.hcmr.gr/"><img src="{{ '/public/imbbc_logo.png' | relative_url }}" alt="IMBBC" style="width: 150px;"/></a></td>
  <td><a href="http://lab42open.hcmr.gr/"><img src="{{ '/public/lab42open.png' | relative_url }}" alt="lab42open" width="60" /></a></td>
  <td><a href="http://prego.hcmr.gr/"><img src="{{ '/public/prego.png' | relative_url }}" alt="PREGO" width="100" /></a></td>
  <td><a href="https://www.elidek.gr/en/homepage/"><img src="{{ '/public/hfri.png' | relative_url }}" alt="HFRI" width="140" /></a></td>
  <td><a href="http://www.gsrt.gr/central.aspx?sId=119I428I1089I323I488743"><img src="{{ '/public/gsrt.png' | relative_url }}" alt="GSRT" width="100" /></a></td>
  <td><a href="https://reconnect.hcmr.gr/"><img src="{{ '/public/Acronym_Environment_RECONNECT-4_1.jpg' | relative_url }}" alt="RECONNECT" width="120" /></a></td>
</tr></table>

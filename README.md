# Positive Selection
<img width="1252" height="208" alt="image" src="https://github.com/user-attachments/assets/617df4c8-39f7-4175-bc92-f87bf92bfa6f" />

**Pipeline overview**

This repository contains a pipeline to detect signatures of positive selection in protein-coding genes using comparative genomics. The workflow starts from predicted proteomes and identifies high-confidence one-to-one orthologs across multiple species with high-quality genome assemblies.

Orthologous protein sequences are aligned using Clustal Omega, and codon alignments are generated from the corresponding transcript sequences with PAL2NAL, with gaps removed. Phylogenetic trees are then inferred from the codon alignments using IQ-TREE2.

Positive selection is detected using PAML (codeml), and p-values are corrected for multiple testing using the Benjamini–Hochberg procedure. To facilitate downstream analysis, an additional script generates a summary table reporting genes under positive selection, alignment lengths, and amino acid sites inferred to be positively selected based on Bayes Empirical Bayes (BEB) probabilities greater than 0.95.

# Tutorial
## OrthoFinder
OrthoFinder is used to obtain one-to-one orthologs, which are required for the pipeline.

Protein and CDS files must first be downloaded for the species of interest, ideally from Ensembl. Ensembl gene sets often contain multiple transcript isoforms per gene. Running OrthoFinder on unfiltered transcript sets may increase runtime and reduce the accuracy of orthology inference.

To address this, a single representative transcript per gene is selected. The longest transcript variant per gene is retained for both protein and CDS files using the primary_transcript.py script provided with OrthoFinder: https://github.com/davidemms/OrthoFinder

Next, use cdbfasta (https://github.com/gpertea/cdbfasta) to create databases for protein sequences and DNA transcripts:

```bash
# Clean protein headers and create database
for f in *_Proteins.fasta; do awk '{print $1}' "$f" > "Clean${f}"; done
ml cdbfasta
cdbfasta AllCleanProteins.fasta

# Clean transcript headers and create database
for f in *_Transcripts.fasta; do awk '{print $1}' "$f" > "Clean${f}"; done
ml cdbfasta
cdbfasta AllCleanTranscripts.fasta
```

Run OrthoFinder on the cleaned sequences:

```
orthofinder -f primary_transcripts/
```

After OrthoFinder finishes, copy the Orthologous output folder for your species of interest (containing orthologs) into the directory where the databases were created.

To extract one-to-one orthologs (both protein and transcript sequences), run:

```
bash Extract_one_to_one_orthologues.sh
```
Note: All protein and transcript files will share the same gene IDs, ensuring consistency between datasets.

## ClustalO
Align the protein sequences ($r1) using ClustalO

```
clustalo -i $r1 -o $r1.alignment
```
## PAL2NAL
Generate codon alignments using the corresponding transcript sequences and protein alignments with PAL2NAL:

```
pal2nal $r1.alignment $r1.transcript.fasta -output fasta -nogap > $r1.pal2nal
```

## IQTREE2
Construct phylogenetic trees from the PAL2NAL alignments using IQ-TREE2:

```
iqtree2 -s $r1.pal2nal -m TEST -bb 1000 -alrt 1000
```

## Codeml
PAML is used to detect positively selected genes using the branch-site model.

The foreground branch to test for positive selection must be tagged with #1. Tag your branch of interest with:

```
bash tag_one_branch.sh
```
Then create PAML control file for the alternative and null hypotheses:
```bash

#alternative:
for f in *pal2nal; do echo "seqfile = ../"$f" \t treefile = ../"$f.contree"\t outfile = "${f%.*}".alt.out \t noisy = 9 \t verbose = 1 \t runmode = 0 \t seqtype = 1 \t CodonFreq = 2 \t model = 2 \t aaDist = 0 \t NSsites = 2 \t icode = 0 \t fix_kappa = 0 \t kappa = 2 \t fix_omega = 0 \t omega = 1 \t cleandata = 1" > ${f%.*}"codeml_alt.ctl";done

#null:
for f in *pal2nal; do echo "seqfile = ../"$f" \t treefile = ../"$f.contree"\t outfile = "${f%.*}".null.out \t noisy = 9 \t verbose = 1 \t runmode = 0 \t seqtype = 1 \t CodonFreq = 2 \t model = 2 \t aaDist = 0 \t NSsites = 2 \t icode = 0 \t fix_kappa = 0 \t kappa = 2 \t fix_omega = 1 \t omega = 1 \t cleandata = 1" > ${f%.*}"codeml_null.ctl";done

# Organise control files:
for f in *ctl; do mkdir ${f}dir; mv $f ${f}dir/codeml.ctl; done
sed -i 's/\\t/\n/g' *.ctldir/codeml.ctl
```
Then extract p-values for each gene running: https://github.com/david-thybert/dt-positive_selection/blob/main/scripts/calculate_codeml_pval.py 

## Multiple testing correction

Perform multiple testing correction to control the False Discovery Rate (FDR):

```
python multipletesting_correction.py
```

After correction, retain genes with significant p-values:

- Save them in positive_sel_alt_out_fdr.txt
- Save the corresponding PAL2NAL files in positive_sel_pal2nal_fdr.txt

## Summary Table of Positively Selected Sites

Run the following script to generate a summary table that includes:
- Gene names identified as being under positive selection
- Alignment lengths
- Amino acid sites under positive selection based on Bayes Empirical Bayes (BEB) analysis with probabilities greater than 0.95
  
```
bash get_AA_lenght_and_AA_selected.sh
```

# Dependencies
| Tool                         | Purpose                                | Installation / Notes                                                                                                       |
| ---------------------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **OrthoFinder**              | Ortholog detection                     | [GitHub](https://github.com/davidemms/OrthoFinder). Install via conda: `conda install -c bioconda orthofinder`             |
| **cdbfasta**                 | Build protein and transcript databases | [GitHub](https://github.com/gpertea/cdbfasta). Install via conda: `conda install -c bioconda cdbfasta`                     |
| **Clustal Omega (ClustalO)** | Protein sequence alignment             | `conda install -c bioconda clustalo`                                                                                       |
| **PAL2NAL**                  | Generate codon alignments              | [Website](http://www.bork.embl.de/pal2nal/). Download binary or Perl script.                                               |
| **IQ-TREE2**                 | Phylogenetic tree construction         | `conda install -c bioconda iqtree`                                                                                         |
| **PAML (Codeml)**            | Positive selection analysis            | [Website](https://github.com/abacus-gene/paml). Install from source or conda: `conda install -c bioconda paml`             |

## Python packages
```bash
# Create a dedicated environment (recommended)
conda create -n positive_selection python=3.10
conda activate positive_selection

# Install required packages
conda install -c conda-forge pandas statsmodels
```





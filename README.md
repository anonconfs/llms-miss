# What Language Models Miss in the Option Spaces of the Programs They Call

Replication package for the ICSE 2027 paper (submission #450).

We measure how far language models reach into the documented option spaces of 403 programs (GNU coreutils, Git, CI tooling), comparing them against human authors and a Linux kernel expert reference. About nine in ten options go unused by everyone, and models land on the same narrow slice as the average human.

## Structure

`corpus/` has the mined scripts split into human and LLM sets for GNU, Git, and CI. The GNU set also includes the kernel expert scripts.

`data/groundtruth/` has one file per program listing all its documented options, plus `summary.csv` with counts and `versions.txt` with the tool versions used.

`scripts/` is the pipeline. Numbered scripts run in order. The `analysis/` subfolder does the cross dataset analysis and `notebooks/` generates the figures.

`results/` has every CSV and figure from the paper.

## Reproducing

Prerequisites are bash 5+, awk, grep with Perl regex, Python 3.10+ with pandas, matplotlib, numpy, jupyter.

Run the analysis on the bundled corpus (no network needed)

```
cd scripts
bash 03-analyse-coreutils-usage.sh
bash 05-analyse-human-vs-llm.sh
bash 07-analyse-ci-workflows.sh
bash git/03-analyze-git-dataset.sh
cd analysis && bash run-all.sh
```

Regenerate figures with `python3 make_paper_figures.py` or run the notebooks in `scripts/notebooks/`.

Mining scripts (02, 04, 06, git/02) re clone upstream repos and are optional. The agent pilot (08) downloads trajectories from Hugging Face for the Section V analysis.

## Datasets

403 programs, 9,604 documented options, ~31,000 invocations total.

GNU covers 118 programs (2,716 options). CI covers 135 units across Docker, npm, pip (1,864 options). Git covers 150 subcommands (5,024 options).

Tool versions are pinned in [data/groundtruth/versions.txt](data/groundtruth/versions.txt).

# What Language Models Miss in the Option Spaces of the Programs They Call

> [!NOTE]
> The artifacts were committed on time, but the repository had to be recreated because an author's identifying information was leaked in a last commit.

Replication package for the ICSE 2027 paper (submission #450).

## What we measure

Ask a model to "create a release archive of the source tree" and it writes `tar -czf release.tar.gz src/`. Valid, but `tar` documents over 200 options, and a couple (`--sort=name`, `--mtime`) would have made the archive reproducible. The model never looked into `tar`'s options space.

We recover each program's documented option set from its own `--help` output, then measure how far real callers reach into it, comparing a language-model cohort against human authors with a Linux kernel expert reference. About nine in ten options go unused by anyone, where models reach 5.4% of the GNU space against the human average, the expert 7.03%, and command executing AI-agents under 1.3%.

## Layout

- `corpus/`:  mined invocations, split into human and LLM sets for GNU, Git, and CI. GNU also carries the kernel expert scripts.
- `data/groundtruth/`: one file per program listing its documented options, with per-program counts in `summary.csv` and pinned tool versions in `versions.txt`.
- `scripts/`:  the pipeline: numbered mining/analysis scripts, `analysis/`: for the cross-dataset metrics, `notebooks/` for the figures.
- `results/`: every CSV and figure in the paper.

## Reproducing

Needs bash 5+, awk, grep (PCRE), and Python 3.10+ with pandas, matplotlib, numpy, jupyter.

The analysis runs on the bundled corpus, no network required:

```
cd scripts
bash 03-analyse-coreutils-usage.sh    # -> results/gnu/
bash 05-analyse-human-vs-llm.sh       # -> results/gnu/
bash 07-analyse-ci-workflows.sh       # -> results/ci/
cd analysis && bash run-all.sh        # -> results/analysis/
```

The figures come from the notebooks in `scripts/notebooks/` (namely, `rq1_saturation`, `rq2_divergence`, `rq4_style2`, `agent_pilot_out`), which read the CSVs in `results/analysis/`.

The mining scripts (02, 04, 06, `git/02`) re-clone upstream repos and are only needed to rebuild the corpus. The agent pilot (08) pulls trajectories from Hugging Face for the Section V analysis.

## Datasets

403 programs, 9,604 documented options, 31,145 invocations across three domains (GNU coreutils, Git subcommands, CI tooling), each split into a human and a model cohort, with a kernel expert reference for GNU. Exact per-program option counts are in [data/groundtruth/summary.csv](data/groundtruth/summary.csv); tool versions in [data/groundtruth/versions.txt](data/groundtruth/versions.txt).

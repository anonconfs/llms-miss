# The Narrow Reach of LLMs into Program Option Spaces: A Case for Configuration Manifests

Replication package for our MSR 2027 submission.

## The study

We measure how many of the documented options of command-line programs appear
in the invocations that LLMs write and run, and compare them with the options
that developers use.

For example, `tar` documents 215 options in its help output, and the command
`tar -czf release.tar.gz src/` uses three of them (`-c`, `-z`, and `-f`).
Over all their `tar` invocations, the scripts attributed to LLMs in our corpus
use 10 of the 215 options, and the scripts written by developers use 7.

We do this for 403 programs and subcommands from GNU utilities, Git, and CI
tooling (9,604 documented options in total), using 31,017 invocations mined
from 851 public repositories. The invocations come from scripts and CI
workflows attributed to LLMs, from scripts and workflows written by
developers, and from the build and automation scripts of the Linux kernel. In
each dataset, 90% to 98% of the documented options are never used. Scripts
attributed to LLMs reach 5.45% of the GNU options, developer scripts 5.38%,
and the kernel scripts 7.03%. Two LLM agents that resolve GitHub issues reach
at most 1.40% in 16,172 executed invocations.

## Layout

- `corpus/`: the mined artifacts of the three datasets, `gnu/{human,llm,linux}`,
  `git/{human,llm}`, and `ci/{human,llm}`, with the mining manifests, and the
  agent trajectories in `agents/` (`raw/` for SWE-agent, `raw_kimi/` for
  DeepSWE-Agent).
- `data/groundtruth/`: one file per program or subcommand with its documented
  options, the help text it was extracted from (`raw_help/`), per-program
  counts (`summary.csv`), and the tool versions (`versions.txt`).
- `scripts/`: the numbered mining and extraction scripts, `analysis/` for the
  cross-dataset tables, and `notebooks/replication.ipynb`, which extracts the
  commands of the LLM agents, runs the corpus size check, draws the figures and
  Table II, prints the numbers quoted in the paper, and checks the
  cross-dataset tables.
- `results/`: per-dataset outputs (`gnu/`, `ci/`, `git/`), cross-dataset
  tables (`analysis/`), agent outputs (`agents/`), and the figures and
  Table II of the paper (`figures/`).

## Reproducing

Requirements: bash 5+, gawk, grep with PCRE support, jq, and Jupyter with
Python 3.10+, pandas, numpy, scipy, and matplotlib.

The figures, Table II, and the numbers of the paper come from the notebook,
which runs on the bundled corpus and tables without network access:

```
cd scripts/notebooks
jupyter nbconvert --to notebook --execute --inplace replication.ipynb
```

The tables it reads can be rebuilt from the bundled corpus with:

```
cd scripts
bash 03-analyse-coreutils-usage.sh   # -> results/gnu/
bash 05-analyse-human-vs-llm.sh      # -> results/gnu/
bash 07-analyse-ci-workflows.sh      # -> results/ci/
bash analysis/run-all.sh             # -> results/analysis/
```

The mining scripts (`02`, `04`, `06b`, `git/02`) and `08`, which downloads the
SWE-agent trajectories, need network access and are only needed to rebuild the
corpus.

## Note on the CI numbers

The CI numbers in Figures 1 and 2 and in Table II (reach, partition,
concentration, and the most used options) come from the tables in
`results/analysis/`, which were built from an earlier run of the CI extractor
(96 developer and 186 LLM invocations). Figure 3c, the number of options per
CI invocation, uses `results/ci/*_ci_invocations.csv` from the current
extractor (`07-analyse-ci-workflows.sh`, 262 and 330 invocations).

If you run `analysis/run-all.sh`, `results/analysis/` is rebuilt from the
current extractor and the CI values change, for example to a reach of 2.09%
for developers and 1.61% for LLMs instead of 1.07% and 1.13%. The GNU, Git,
kernel, and agent values stay the same. The last section of the notebook
flags one more small difference: `a7_distribution.csv` counts one more LLM CI invocation
without options than `invocations_long.csv` (55.9% instead of 55.4%), which
only affects that label in Figure 1b.

## Datasets

| | GNU | CI | Git |
|---|---|---|---|
| Programs and subcommands | 118 | 135 | 150 |
| Documented options | 2,716 | 1,864 | 5,024 |
| Files, developer / LLM / kernel | 293 / 298 / 1,081 | 210 / 210 | 276 / 468 |
| Repositories, developer / LLM / kernel | 25 / 264 / 1 | 28 / 180 | 48 / 364 |
| Invocations, developer / LLM / kernel | 4,837 / 8,795 / 15,271 | 96 / 186 | 564 / 1,268 |

The agent trajectories come from two public Hugging Face datasets,
[nebius/SWE-agent-trajectories](https://huggingface.co/datasets/nebius/SWE-agent-trajectories)
(600 runs, 570 with Llama 70B and 30 with Llama 8B) and
[SWE-Factory/DeepSWE-Agent-Kimi-K2-Trajectories-2.8K](https://huggingface.co/datasets/SWE-Factory/DeepSWE-Agent-Kimi-K2-Trajectories-2.8K)
(600 runs with Kimi K2).

## Licence

The scripts are released under the MIT licence, and our data and results
(ground truth, tables, and figures) under CC BY 4.0, see [LICENSE](LICENSE).
The scripts and workflows in `corpus/` and the agent trajectories come from
public repositories and datasets and keep the licences of their projects.

## Use of generative AI

Claude Opus 4.6 and 5.5 assisted in writing the analysis scripts and charts,
all of which the authors verified.

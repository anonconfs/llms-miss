# Human vs LLM configuration-space analysis

Bash scripts (`scripts/analysis/*.sh`) do all data processing and write CSVs
into `results/analysis/`. The notebooks in `scripts/notebooks/` only *read*
those CSVs and draw the paper figures, so figures and CSVs never disagree.

## How to run

```bash
# 1. processing (bash) -> results/analysis/*.csv
bash scripts/analysis/run-all.sh

# 2. figures (notebooks) -> results/analysis/figures/*.pdf
jupyter nbconvert --to notebook --execute --inplace scripts/notebooks/*.ipynb
```

## Pipeline steps

| Script | Question it answers | Main outputs |
|--------|---------------------|--------------|
| `00-build-foundation.sh` | normalize everything into one table | `invocations_long.csv`, `groundtruth_long.csv` |
| `01-program-and-option-counts.sh` | how many programs/options, what is shared vs never used | `a1_dataset_summary.csv`, `a1_unit_coverage.csv` |
| `02-shared-options-and-popularity.sh` | which options are shared, and how *often* each side uses them | `a2_option_popularity.csv`, `a2_shared_options.csv` |
| `03-extract-aliases.sh` | short<->long alias map from each tool's `--help` | `aliases_long.csv`, `data/groundtruth/raw_help/` |
| `04-short-long-preference.sh` | short-vs-long form preference | `a4_form_preference.csv` |
| `06-option-cooccurrence.sh` | which options are used together (per population) | `a6_cooccurrence.csv` |

## Key definitions (so the numbers are unambiguous)

- **unit** = the analysed program, matching one ground-truth file:
  GNU -> tool (`cat`), git -> subcommand (`commit`), CI -> program_subcommand
  (`docker_build`). The unit *universe* (ground truth) is identical for humans
  and LLMs. Only which units each population *invokes* differs.
- **option use** = one option token in one command invocation. `grep -i -E`
  contributes one use to `-i` and one to `-E` (invocation-weighted popularity).
- **logical option** = a short form and its long alias collapsed into one
  (`-n` + `--number`). Lets us measure short-vs-long preference and detect when
  both populations use the same feature via different spellings.
- **shared** option = used by both populations (presence). The popularity
  columns then tell you whether it is used with similar *frequency*.

## Notes / on limitations

- Alias extraction re-reads each tool's `--help`. Tool versions are pinned in
  `data/groundtruth/versions.txt` and match the capture machine. The raw help
  text is saved under `data/groundtruth/raw_help/` for reproducibility.
- Only ground-truth (real) options are counted in coverage. Non-ground-truth /
  hallucinated tokens are intentionally excluded here.

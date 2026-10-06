# Individual differences in spillover

![paper](https://img.shields.io/static/v1?label=paper&message=under%20review&color=orange)


This repository contains code for the paper: *Individual Differences in Spillover During Naturalistic Reading*

## Data and models

Eye-tracking data and fitted models are large and are **not** stored in this Git repository. Download them from the OSF project:

**[https://osf.io/e4f23](https://osf.io/e4f23)**

After downloading, make sure to name corresponding folders `data/` and `models/` and make them sit at the repository root. The notebooks in `r-script/` read those folders with paths such as `../data/...` and `../models/...`. Knit or run them from `r-script/`. In some cases, maybe we overlooked some cases where the paths are not correct, so please let us know if you encounter any issues.

Expected layout after the OSF download:

```text
data/
  indico/                   indico_et.csv, psychometric_scores.csv  # Note, you need to request the access to indico data from the IndiCo authors ([Haller et al., 2026](https://doi.org/10.1111/cogs.70121)). We cannot share it here.
  potec/                    potec_expertise.csv
  onestop/                  onestop_repeat.csv
  hkc/                      hkc_sent.csv, hkc_para.csv
  geco-nl/                  geco_nl_l1nl.csv, geco_nl_l2en.csv
  geco-zh/                  geco_zh_l1zh.csv, geco_zh_l2en.csv
  fit_input/                preprocessed csv files written by r-script/correlation_estimate.Rmd (you need to generate them yourself)
    et_indico.csv
    potec.csv
    onestop.csv
    geconl.csv
    gecozh.csv
    hkc.csv
models/
  cor_scaled/                main models fitted by r-script/correlation_estimate.Rmd (Paper section 2)
  psycho-profile/            InDiCo models with psychometric predictors (Paper section 3)
  behavior/                  bivariate correlation models (spillover vs. reading behavior) (Paper section 4)
  meta/                      models fitted by r-script/meta_analysis.Rmd (Paper section 2.3.2)
  interaction_w_context/     robustness checks in Appendix A.2
```

Summary statistics and LaTeX tables are already in `results/` and do not require the OSF download.

## Repository structure

```text
.
├── cluster/                 HPC jobs (we run most of the models on a cluster)
│   ├── scripts/             SLURM wrappers (one corpus each)
│   └── src/                 R fitting scripts
├── r-script/                Analysis notebooks (R Markdown and HTML)
├── stan_models/             Stan model for bivariate correlations
├── data/                    Data files
├── models/                  Model files
├── visualization/           Plots for the paper
├── results/
│   ├── stats/               CSV summaries of effects, reliability, and correlations
│   └── latex/               Tables formatted for the paper
├── LICENSE
└── README.md
```

## Notes on reading contexts

Note, in the model formulas, `c1` and `c2` are indicators for the two reading contexts. Reliability is the posterior correlation between a participant’s slope in reading context 1 and the same participant’s slope in reading context 2. For more details, see the paper Table 1.

| Dataset | Contrast | What varies within a reader |
| --- | --- | --- |
| InDiCo | Cross-session | Eye-tracking session 1 vs. session 2 (Zurich participants) |
| PoTeC | Cross-domain | Text domain matches the reader’s discipline vs. does not |
| OneStop | Cross-regime | Repeated reading vs. normal reading |
| GECO-NL | Cross-language | L1 Dutch vs. L2 English |
| GECO-ZH | Cross-language | L1 Chinese vs. L2 English |
| HKC | Cross-context length | Paragraph reading vs. sentence reading |

## Citation

To be added.
# Paper template (R Markdown) + config layer

Reproducible paper template with **R scripts + R Markdown**, a shared setup layer (`00_setup.R`), and YAML-based configuration.

The pipeline is based on the way I write manuscripts with R and R Markdown and reflects many years of experience in writing research papers with an empirical focus. I used ChatGPT and Claude to refine the template and to prepare it for publication. More on [marcoluenich.com](https://marcoluenich.com/project/paper-template/).

Architecture, data flow, helper reference and conventions: [`docs/architecture.md`](docs/architecture.md). Working rules for LLM sessions: [`CLAUDE.md`](CLAUDE.md). Version history: [`CHANGELOG.md`](CHANGELOG.md).

## Quick start

1. Open `paper-template.Rproj` in RStudio.
2. Place raw data in `data/raw/` (not versioned except `example.csv`) or point `paths$raw_data_dir` to it, machine-specific paths in `config/params.local.yml` (gitignored, merged over `config/params.yml`).
3. Run the full pipeline:

```r
source("R/00_run_all.R")
```

This runs `R/01_import.R` to `R/04_figures_tables.R` (+ `R/10_appendix.R`), renders `manuscript/paper.Rmd` and `manuscript/appendix.Rmd` to `output/YYMMDD_*.pdf` (plus `*_blind.pdf` if `render$anonymous: true`), and writes `output/word_count.txt` and `output/session_info.txt`.

4. For an OSF reproduction package (no raw data): `source("R/99_export_osf.R")`.

## Adapting to a new paper

1. Replace `data/raw/example.csv`; adapt `R/01_import.R`.
2. Expand `R/02_clean.R`; replace the model in `R/03_analysis.R`.
3. Build figures (`save_fig()`), tables (`tbl_tex()`) and inline values (`rpt`) in `R/04_figures_tables.R`.
4. Add chunks to `manuscript/paper.Rmd` / `appendix.Rmd`; edit title, author, `references.bib`.
5. Adjust `required_pkgs` in `R/00_setup.R` and `config/params.yml` (e.g. `analysis$weight_var`).

## Requirements

R (>= 4.1), a LaTeX distribution with XeLaTeX (e.g. TinyTeX), and the packages in `required_pkgs` (`R/00_setup.R`). Missing packages stop the run with an error (no automatic installation). `survey` is required only if `analysis$weight_var` is set, `zip` only for `R/99_export_osf.R`.

Optional renv: set `use_renv <- TRUE` in `R/00_run_all.R` (default `FALSE`).

## Use and license

Create your own copy via **Use this template** on GitHub (or clone). Code and documentation: [MIT License](LICENSE). `manuscript/apa.csl`: CC BY-SA 3.0, from the [Citation Style Language styles repository](https://github.com/citation-style-language/styles).

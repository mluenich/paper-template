# Paper template (R Markdown) + config layer

Reproducible paper template with **R scripts + R Markdown**, a shared setup layer (`00_setup.R`), and YAML-based configuration.

## Structure

```
project-root/
├── config/
│   └── params.yml              # Project parameters (paths, seed, render switches)
├── data/
│   ├── raw/                    # Raw inputs (do not edit in place)
│   └── derived/                # Derived datasets (reproducible outputs of scripts)
├── R/
│   ├── 99_config.R             # YAML reader with defaults
│   ├── 00_setup.R              # Shared setup: config, paths, packages, helpers
│   ├── 00_run_all.R            # Master script: runs pipeline + renders manuscript
│   ├── 01_import.R             # Data import
│   ├── 02_clean.R              # Data cleaning and recoding
│   ├── 03_analysis.R           # Statistical models → output/checkpoints/
│   ├── 04_figures_tables.R     # Figures + LaTeX table objects → tables_tex.rds
│   └── 10_appendix.R           # Optional: supplementary analyses
├── manuscript/
│   ├── paper.Rmd               # R Markdown manuscript
│   └── references.bib          # Bibliography
├── output/
│   ├── figures/                # Generated figures (.png, .pdf)
│   ├── tables/                 # Generated tables (.csv, .html)
│   └── checkpoints/            # Intermediate R objects (.rds)
└── README.md
```

## Architecture

### Config layer (`config/params.yml` → `R/99_config.R`)

All paths, seeds, and switches are centralised in `config/params.yml`. `99_config.R` reads this file and applies defaults for any missing fields. No script hardcodes paths.

### Shared setup (`R/00_setup.R`)

Sourced by every pipeline script and by the manuscript at render time. Provides:

- `cfg` — parsed config
- `paths` — named list of all directory paths
- `artifacts` — conventional filenames for pipeline outputs
- IO wrappers: `path_raw()`, `path_derived()`, `path_ckpt()`, `write_derived()`, `read_checkpoint()`, etc.
- Formatting helpers: `fmt_num()`, `fmt_p()` (with leading-zero stripping)
- Missing-value recoding: `recode_missing()`
- Package loading with fail-fast behaviour

### Pipeline scripts (`R/01–04`)

Each script:
1. Sources `R/00_setup.R` (standalone-capable)
2. Reads from `data/derived/` or `output/checkpoints/`
3. Writes to `data/derived/` or `output/checkpoints/`

The pipeline is linear: `01_import → 02_clean → 03_analysis → 04_figures_tables`.

### Table objects for the manuscript

`04_figures_tables.R` builds `kableExtra` table objects and saves them as `output/checkpoints/tables_tex.rds`. The manuscript loads this single `.rds` and calls `tables_tex$t1`, `tables_tex$t2`, etc. in `results='asis'` chunks.

### Manuscript (`manuscript/paper.Rmd`)

- Sets `root.dir` to `here::here()` (project root), so all `path_*()` helpers work.
- Sources `R/00_setup.R` for access to config, paths, helpers.
- Loads pre-built artifacts (`dat`, `fit`, `tables_tex`) — no computation in the .Rmd itself.
- Uses `pdf_document` with `xelatex`, `number_sections: true`, and standard LaTeX packages.
- Abstract is unnumbered (`{-}`), Introduction starts at Section 1.
- LaTeX cross-references via `\ref{tab:...}` / `\ref{fig:...}` (not bookdown `@ref()`).
- `kbl(... label = "labelname")` generates `\label{tab:labelname}` automatically.

## Quick start

1. Open the `.Rproj` file in RStudio (or `setwd()` to project root).
2. Place raw data in `data/raw/`.
3. Run the full pipeline:

```r
source("R/00_run_all.R")
```

This will:
- Read `config/params.yml`
- Create all output directories (if missing)
- Run `R/01_import.R` → `R/04_figures_tables.R`
- Optionally run appendix scripts (`R/10_appendix.R`)
- Render `manuscript/paper.Rmd` into `output/`
- Optionally prepend a date prefix to the output filename

## Config usage

All scripts use:

```r
source("R/00_setup.R")
# cfg, paths, artifacts, fmt_num(), fmt_p() etc. are now available
```

Override config file via environment variable:

```r
Sys.setenv(PAPER_CONFIG = "config/params_alt.yml")
source("R/00_run_all.R")
```

## Key conventions

| Convention | Details |
|---|---|
| Artifact filenames | Defined in `00_setup.R` → `artifacts` list |
| Table labels | `kbl(... label = "shortname")` → `\ref{tab:shortname}` in text |
| Figure labels | Manual `\label{fig:...}` in LaTeX include block |
| Appendix numbering | `\appendix` + `\renewcommand{\thetable}{A\arabic{table}}` |
| Footnote escaping | `kableExtra` with `escape = FALSE` strips one backslash level; double-escape LaTeX commands in footnotes (`$\\\\beta$`) |

## Using renv (optional)

```r
install.packages("renv")
renv::init()
renv::snapshot()
```

To restore on another machine:

```r
renv::restore()
```

Set `use_renv <- TRUE` in `R/00_run_all.R` to auto-restore before each run.

## Notes

- `data/derived/` is not versioned by default (add to `.gitignore`).
- `output/` is safe to delete and rebuild via `source("R/00_run_all.R")`.
- The manuscript renders from pre-built artifacts only; it does not run the analysis pipeline.

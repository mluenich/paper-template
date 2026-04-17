# Architecture — Paper Template (R Markdown)

> **Purpose of this file:** Stable project summary for cheap context reconstruction in new LLM sessions. Read this first; it replaces the need to scan all source files for orientation.

## 1 Project Goal

Reproducible research-paper template: linear R pipeline (import → clean → analyse → figures/tables) + R Markdown manuscript that renders from pre-built artifacts only. All paths, seeds, and switches are centralised in a single YAML config; no script hardcodes paths.

## 2 Folder Structure

```
project-root/
├── config/
│   └── params.yml                # Single source of truth for paths, seeds, switches
├── data/
│   ├── raw/                      # Immutable inputs (tracked)
│   └── derived/                  # Pipeline outputs (.rds) — gitignored, reproducible
├── R/
│   ├── 99_config.R               # YAML reader + defaults
│   ├── 00_setup.R                # Shared setup: config, paths, packages, helpers
│   ├── 00_run_all.R              # Master orchestrator
│   ├── 01_import.R               # Raw → derived (import)
│   ├── 02_clean.R                # Cleaning, recoding
│   ├── 03_analysis.R             # Statistical models → checkpoint
│   ├── 04_figures_tables.R       # Figures (PNG) + LaTeX table objects (RDS)
│   └── 10_appendix.R             # (optional) Supplementary analyses
├── manuscript/
│   ├── paper.Rmd                 # Manuscript — loads artifacts, no computation
│   └── references.bib            # BibTeX bibliography
├── output/                       # Gitignored, fully reproducible
│   ├── figures/                  # .png, .pdf
│   ├── tables/                   # .csv, .html
│   └── checkpoints/              # .rds (models, table objects)
├── docs/
│   └── architecture.md           # ← this file
└── README.md
```

**Gitignored:** `output/`, `data/derived/`, `.Rproj.user/`, LaTeX intermediates, renv library.

## 3 End-to-End Workflow

```
source("R/00_run_all.R")
  │
  ├─ (optional) renv::restore()
  ├─ source("R/00_setup.R")          → cfg, paths, artifacts, helpers into globalenv()
  ├─ source("R/01_import.R")         → data/derived/01_import.rds
  ├─ source("R/02_clean.R")          → data/derived/02_clean.rds
  ├─ source("R/03_analysis.R")       → output/checkpoints/models.rds
  ├─ source("R/04_figures_tables.R") → output/figures/figure1.png
  │                                   → output/checkpoints/tables_tex.rds
  │                                   → output/tables/table1.csv
  ├─ (optional) source("R/10_appendix.R")
  └─ rmarkdown::render("manuscript/paper.Rmd") → output/<date>_paper.pdf
```

Pipeline scripts run in isolated `new.env()` environments; each sources `00_setup.R` independently and is standalone-capable. The manuscript renders from pre-built artifacts — it never runs pipeline logic.

## 4 Configuration & Parameter Handling

### 4.1 `config/params.yml`

Three sections:

| Section    | Keys                                                             | Purpose                                      |
|------------|------------------------------------------------------------------|----------------------------------------------|
| `paths`    | `raw_data_dir`, `derived_data_dir`, `output_dir`, `figures_dir`, `tables_dir`, `checkpoints_dir` | All directory paths                          |
| `analysis` | `seed`, `fast_mode`, `scipen`, `miss_codes`                      | Analysis globals                             |
| `render`   | `enable`, `input`, `output_dir`, `date_prefix`                   | Manuscript rendering control                 |

### 4.2 `R/99_config.R` — Config reader

```r
config_path_default() → character
  # Returns env var PAPER_CONFIG or "config/params.yml"

read_config(path) → list
  # Reads YAML, applies hardcoded defaults for every missing field.
  # Returns nested list: cfg$paths, cfg$analysis, cfg$render
```

**Override mechanism:** `Sys.setenv(PAPER_CONFIG = "config/params_alt.yml")` before sourcing.

### 4.3 `R/00_setup.R` — Shared setup (sourced by every script)

Side effects on source:
- Sources `99_config.R`, calls `read_config()` → `cfg`
- `set.seed(cfg$analysis$seed)`
- `options(scipen = ...)`
- Creates all output directories (idempotent)
- Loads and attaches `dplyr`, `tidyr`, `tibble`

**Exports to calling environment:**

| Object/Function         | Type       | Description                                                      |
|-------------------------|------------|------------------------------------------------------------------|
| `cfg`                   | list       | Parsed config                                                    |
| `paths`                 | named list | All directory paths (7 entries incl. `render_output_dir`)        |
| `artifacts`             | named list | Conventional filenames: `import_rds`, `clean_rds`, `models_rds` |
| `FAST_MODE`             | logical    | From `cfg$analysis$fast_mode`                                    |
| `miss_codes`            | numeric    | From `cfg$analysis$miss_codes`, default `c(-98, -99)`            |
| `path_raw(...)`         | function   | → `file.path(paths$raw_data_dir, ...)`                           |
| `path_derived(...)`     | function   | → `file.path(paths$derived_data_dir, ...)`                       |
| `path_out_fig(...)`     | function   | → `file.path(paths$figures_dir, ...)`                            |
| `path_out_tab(...)`     | function   | → `file.path(paths$tables_dir, ...)`                             |
| `path_ckpt(...)`        | function   | → `file.path(paths$checkpoints_dir, ...)`                        |
| `write_derived(x, fn)`  | function   | `saveRDS` to `data/derived/`, compress xz                        |
| `read_derived(fn)`      | function   | `readRDS` from `data/derived/`                                   |
| `write_checkpoint(x, fn)` | function | `saveRDS` to `output/checkpoints/`, compress xz                  |
| `read_checkpoint(fn)`   | function   | `readRDS` from `output/checkpoints/`                             |
| `recode_missing(df, vars, codes)` | function | Replaces `miss_codes` values with `NA` in selected columns |
| `fmt_num(x, d=3)`       | function   | Format numeric, strip leading zero, NA → em-dash                 |
| `fmt_p(p, d=3, thr=.001)` | function | Format p-value, `< .001` threshold, strip leading zero           |
| `strip_leading_zero(x)` | function   | `gsub("^(-?)0\\.", "\\1.", x)`                                   |
| `stop_if_missing(path)` | function   | `stop()` if file does not exist                                  |
| `ensure_dirs(dirs)`     | function   | Create directories recursively, idempotent                       |
| `load_pkgs(pkgs, install)` | function | Fail-fast package check, optional install                       |
| `%||%`                  | operator   | Null-coalescing                                                  |

## 5 Module-Level Responsibilities

### 5.1 `R/00_run_all.R` — Master orchestrator

- Flags: `use_renv` (bool, default `TRUE`), `render_manuscript` (bool, AND-ed with `cfg$render$enable`)
- Saves/restores `options(warn)` via `on.exit()`; sets `warn = 1` during run
- renv: restores from `renv.lock` if present; initialises bare renv otherwise
- Infers project root from script location, `setwd()` if sourced from `R/`
- Runs pipeline scripts sequentially via `run_step(label, expr)` (timed, messaged)
- Pipeline scripts execute in `new.env()`; setup is sourced into `globalenv()`
- Detects `.qmd` vs `.Rmd` for render engine (Quarto vs rmarkdown)
- `add_date_prefix()`: renames output file with `YYYYMMDD_` prefix if `cfg$render$date_prefix` is TRUE

### 5.2 `R/01_import.R`

| Aspect  | Detail                                    |
|---------|-------------------------------------------|
| Input   | `data/raw/example.csv`                    |
| Output  | `data/derived/01_import.rds`              |
| Logic   | `readr::read_csv()` (UTF-8 locale), `write_derived()` |
| Adapt   | Replace `example.csv` with actual data source; adjust read function |

### 5.3 `R/02_clean.R`

| Aspect  | Detail                                    |
|---------|-------------------------------------------|
| Input   | `data/derived/01_import.rds`              |
| Output  | `data/derived/02_clean.rds`               |
| Logic   | Type coercion (`factor`, `as.numeric`). `recode_missing()` available but commented out |
| Adapt   | Add variable-specific cleaning, filtering, recoding |

### 5.4 `R/03_analysis.R`

| Aspect  | Detail                                    |
|---------|-------------------------------------------|
| Input   | `data/derived/02_clean.rds`               |
| Output  | `output/checkpoints/models.rds`           |
| Logic   | Example: `lm(y ~ x + group)`. Single model object checkpointed |
| Adapt   | Replace model specification; store multiple models as named list; use `FAST_MODE` for expensive computations |

### 5.5 `R/04_figures_tables.R`

| Aspect  | Detail                                    |
|---------|-------------------------------------------|
| Input   | `data/derived/02_clean.rds`, `output/checkpoints/models.rds` |
| Output  | `output/figures/figure1.png`, `output/checkpoints/tables_tex.rds`, `output/tables/table1.csv` |
| Logic   | Base R plot → PNG; `kableExtra::kbl()` with `format="latex"` → named list `tables_tex`; CSV export for inspection |
| Convention | Tables as `tables_tex$t1`, `$t2`, etc. Labels via `kbl(... label = "regression")` → `\ref{tab:regression}` |
| Adapt   | Add figures/tables; extend `tables_tex` list; adjust `col.names` to keep `t` and `p` columns labelled exactly |

### 5.6 `R/10_appendix.R` (stub)

Ships as no-op stub. Sourced by `00_run_all.R` if present. Intended for supplementary analyses; outputs should go to `output/checkpoints/` or `output/tables/`.

## 6 Manuscript Rendering Logic (`manuscript/paper.Rmd`)

- **Output format:** `pdf_document`, engine `xelatex`, `number_sections: true`, `fontsize: 12pt`, `linestretch: 1.5`, `geometry: margin=2.5cm`
- **LaTeX packages:** booktabs, longtable, array, float, amsmath, graphicx, setspace, geometry, threeparttable(x), multirow, rotating, caption
- **Root dir:** `knitr::opts_knit$set(root.dir = here::here())` — all `path_*()` helpers resolve from project root
- **Setup chunk:** sources `R/00_setup.R`, loads `dat`, `fit`, `tables_tex` from pre-built artifacts
- **No computation in .Rmd** — display only
- **Tables:** `results='asis'` chunks printing `tables_tex$t1` etc.
- **Figures:** `knitr::include_graphics()` via `path_out_fig()`; chunk label becomes `\label{fig:...}` automatically
- **Cross-references:** `\ref{tab:...}`, `\ref{fig:...}` (LaTeX native, not bookdown `@ref()`)
- **keep_tex:** `true` — retains `.tex` for journal submission / debugging (gitignored via `*.tex`)
- **Bibliography:** Pandoc citeproc via `references.bib`; CSL slot present but commented out (defaults to Chicago-like)
- **Section structure:** Abstract `{-}` (unnumbered) → Introduction (§1) → Method → Results → Discussion → Conclusion → References

## 7 Key Artifacts — Read/Write Map

| Artifact                          | Written by          | Read by                     | Location                          |
|-----------------------------------|---------------------|-----------------------------|-----------------------------------|
| `01_import.rds`                   | `01_import.R`       | `02_clean.R`                | `data/derived/`                   |
| `02_clean.rds`                    | `02_clean.R`        | `03_analysis.R`, `04_figures_tables.R`, `paper.Rmd` | `data/derived/`  |
| `models.rds`                      | `03_analysis.R`     | `04_figures_tables.R`, `paper.Rmd` | `output/checkpoints/`        |
| `tables_tex.rds`                  | `04_figures_tables.R` | `paper.Rmd`               | `output/checkpoints/`             |
| `figure1.png`                     | `04_figures_tables.R` | `paper.Rmd`               | `output/figures/`                 |
| `table1.csv`                      | `04_figures_tables.R` | (human inspection)         | `output/tables/`                  |
| `<date>_paper.pdf`               | `00_run_all.R` (render) | —                        | `output/`                         |

## 8 Customisation Points (adapting template to a new paper)

1. **Data source:** Replace `data/raw/example.csv`; adapt `01_import.R` read logic.
2. **Cleaning:** Expand `02_clean.R` with project-specific recoding, filtering, variable construction.
3. **Analysis:** Replace model in `03_analysis.R`; store multiple models as named list if needed.
4. **Figures/tables:** Add entries in `04_figures_tables.R`; extend `tables_tex` list; add corresponding chunks in `paper.Rmd`.
5. **Packages:** Edit `required_pkgs` in `00_setup.R`.
6. **Config:** Adjust `config/params.yml` (seed, miss_codes, fast_mode, render switches).
7. **Manuscript metadata:** Title, author, affiliation, CSL style in `paper.Rmd` YAML header.
8. **Bibliography:** Populate `references.bib`; optionally add `.csl` file and uncomment `csl:` line.
9. **Appendix:** Expand `R/10_appendix.R` (ships as stub); auto-sourced by `00_run_all.R`.

## 9 Resolved Issues & Remaining Notes

All issues from the initial audit have been addressed:

| Original issue | Resolution |
|----------------|------------|
| Unused `scored_rds` artifact slot | Removed from `artifacts` list in `00_setup.R`. |
| `10_appendix.R` missing | Stub file created; structure matches README. |
| `render_output_dir` fallback divergence | Fallback in `00_setup.R` aligned to `"output"` (matches config default). |
| Figure include via tempdir | Replaced with `knitr::include_graphics()` using `path_out_fig()`. |
| `keep_tex: false` | Changed to `true`; `.tex` output is gitignored. |
| No explicit encoding in `read.csv` | Switched to `readr::read_csv()` with `locale(encoding = "UTF-8")`; `readr` added to `required_pkgs`. |
| `warn = 1` not restored | `on.exit(options(warn = .warn_prev))` added in `00_run_all.R`. |
| No renv by default | `use_renv` default changed to `TRUE`; init block handles missing `renv.lock` gracefully. |

**Remaining design notes** (not bugs, but worth knowing):

- `renv.lock` is not shipped with the template. On first run, renv initialises bare; user must `renv::snapshot()` after installing packages.
- The manuscript uses `here::here()` for `root.dir`. This requires the `here` package and a project root marker (`.Rproj` or `.here` file). Both are present.
- `kableExtra` table labels (`kbl(... label = "x")`) generate `\label{tab:x}`. Figure labels come from knitr chunk labels (`fig1` → `\label{fig:fig1}`). The two mechanisms differ — keep this in mind when adding cross-references.
